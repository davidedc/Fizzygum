#!/usr/bin/env node
// check-dead-methods.js — build lint: flag methods DEFINED in src but referenced NOWHERE.
//
// Mirrors buildSystem/check-layering.js (a heuristic line scanner, exit 0 clean / 1 violation /
// 2 operational). It finds every class-method header in src/**/*.coffee, then harvests every
// identifier used anywhere a method could be CALLED — across src (.coffee), the test harness
// (Fizzygum-tests/Automator-and-test-harness-src/*.coffee) and the macro SystemTests
// (Fizzygum-tests/tests/**/*.js, whose mainMacroSource strings carry the verbs they call). A
// method name that appears ONLY on its own def header (and in comments) is DEAD.
//
// Fizzygum's dynamic dispatch is PROPERTY-based (DeepCopierMixin walks @[property]); it does not
// BUILD method names at runtime, and even a string-dispatched name ("foo") is caught as a token —
// so the false-positive rate is low. The rare genuine exception (intentional public API, a method
// dispatched by a computed name, a known gap to fix later) goes in dead-method-allowlist.txt.
//
// The lint FAILS on any dead method NOT in the allowlist. Run with --update-allowlist to (re)seed
// the allowlist file with the current dead set (the baseline).
//
// NOTE: needs the sibling Fizzygum-tests repo for an accurate reference set; if it is absent
// (e.g. a --homepage build that stripped tests) the check SKIPS rather than false-fail.

const fs = require('fs');
const path = require('path');

const SRC      = path.resolve(__dirname, '../src');
const TESTS    = path.resolve(__dirname, '../../Fizzygum-tests/tests');
const HARNESS  = path.resolve(__dirname, '../../Fizzygum-tests/Automator-and-test-harness-src');
const ALLOWLIST = path.resolve(__dirname, 'dead-method-allowlist.txt');

const HEADER = /^  ([A-Za-z_]\w*): (\(.*?\) )?[-=]>/;   // a 2-space-indent class method header
const WORD   = /[A-Za-z_]\w*/g;

function walk(dir, ext, acc) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, ext, acc);
    else if (e.name.endsWith(ext)) acc.push(p);
  }
  return acc;
}
function stripComment(line) { const i = line.indexOf('#'); return i < 0 ? line : line.slice(0, i); }

// ── settle-tier symmetry helpers (pure; unit-tested via --self-test) ────────────────────────────────
// A public `<name>` and its private core `_<name>NoSettle` form ONE self-settling pair. When one side is
// dead we may RETAIN it for symmetry — but ONLY if the OTHER side is INDEPENDENTLY used. `twinName` maps a
// member to its partner; `independentlyReferenced` answers "is `token` referenced by some owner OTHER than
// `excluded`?" (owner = a src method name, '@toplevel' for class-level src, or '@external' for harness/tests).
// The `excluded` guard is what closes the masking hole: a dead public wrapper's body is the one place that
// references its core (`setLabel -> @_setLabelNoSettle`), so without excluding that body the core looks "used"
// and a pair dead on BOTH sides would be saved. Excluding it, a both-dead pair is retained by neither.
function twinName(n) {
  const core = /^_(.+)NoSettle$/.exec(n);
  return core ? core[1] : '_' + n + 'NoSettle';
}
function independentlyReferenced(token, excluded, referrers) {
  const owners = referrers.get(token);
  if (!owners) return false;
  for (const o of owners) if (o !== excluded) return true;   // a referrer other than the dead method itself
  return false;
}

// --self-test: prove the symmetry decision on synthetic referrer maps (runs without the sibling test repo).
if (process.argv.includes('--self-test')) {
  const R = (pairs) => new Map(pairs.map(([t, owners]) => [t, new Set(owners)]));
  const cases = [
    // [dead member, referrers-of-its-twin, expect RETAINED?]
    ['setLabel',     R([['_setLabelNoSettle', ['setLabel', 'buildFridgeMagnets']]]), true],  // core used elsewhere -> keep the dead wrapper
    ['setLabel',     R([['_setLabelNoSettle', ['setLabel']]]),                       false], // core used ONLY by the dead wrapper -> both dead
    ['setLabel',     R([]),                                                          false], // nothing references the core at all
    ['_fooNoSettle', R([['foo', ['someExternalCaller']]]),                           true],  // public twin live -> keep the dead core
    ['_fooNoSettle', R([['foo', ['_fooNoSettle']]]),                                 false], // public twin referenced only from the core -> both dead
  ];
  let ok = true;
  for (const [n, referrers, expect] of cases) {
    const got = independentlyReferenced(twinName(n), n, referrers);
    console[(got === expect) ? 'log' : 'error'](`  ${got === expect ? 'ok  ' : 'FAIL'} ${n}: retained=${got} (expected ${expect})`);
    if (got !== expect) ok = false;
  }
  console.log(ok ? '[dead-methods] self-test PASS' : '[dead-methods] self-test FAIL');
  process.exit(ok ? 0 : 1);
}

if (!fs.existsSync(TESTS) || !fs.existsSync(HARNESS)) {
  console.log('[dead-methods] SKIP — sibling Fizzygum-tests not present (needs it for an accurate reference set).');
  process.exit(0);
}

// 1. every method header in src -> name => [first def location, ...]
const defs = new Map();
for (const p of walk(SRC, '.coffee', [])) {
  fs.readFileSync(p, 'utf8').split('\n').forEach((line, i) => {
    const m = HEADER.exec(line);
    if (m) { if (!defs.has(m[1])) defs.set(m[1], []); defs.get(m[1]).push(path.relative(SRC, p) + ':' + (i + 1)); }
  });
}

// 2. every identifier USED (not on a def header, not in a comment)
const referenced = new Set();
const referrers = new Map();   // token -> Set of owners that reference it (a src method name / '@toplevel' / '@external')
function addRef(token, owner) {
  referenced.add(token);
  let s = referrers.get(token);
  if (!s) referrers.set(token, (s = new Set()));
  s.add(owner);
}
// src: attribute each reference to its ENCLOSING method, so we can later tell whether a settle-twin is used by
// something OTHER than the dead method itself. A 2-space header opens a method; its inline body (after `->`)
// and the 4+-space-indented lines below belong to it; class-level lines (indent < 4, not a header) are '@toplevel'.
// (`referenced` ends up the SAME set as the old flat harvest — the per-owner map is purely additive.)
function harvestSrc(files) {
  for (const p of files) {
    let cur = null;
    for (const raw of fs.readFileSync(p, 'utf8').split('\n')) {
      const m = HEADER.exec(raw);
      let code, owner;
      if (m) {
        cur = m[1];
        const gt = raw.indexOf('>');
        code = stripComment(gt >= 0 ? raw.slice(gt + 1) : '');
        owner = cur;
      } else {
        code = stripComment(raw);
        const indent = raw.length - raw.trimStart().length;
        owner = (indent >= 4 && cur) ? cur : '@toplevel';
      }
      const ws = code.match(WORD);
      if (ws) for (const w of ws) addRef(w, owner);
    }
  }
}
// harness (.coffee) + macro tests (.js): every reference is an INDEPENDENT anchor ('@external') — it lives
// outside the src pair, so it always counts as "the twin is used". (.coffee strips headers+comments as src does.)
function harvestExternal(files, isCoffee) {
  for (const p of files) {
    for (let line of fs.readFileSync(p, 'utf8').split('\n')) {
      if (isCoffee && HEADER.test(line)) { const gt = line.indexOf('>'); line = gt >= 0 ? line.slice(gt + 1) : ''; }
      const code = isCoffee ? stripComment(line) : line;
      const ws = code.match(WORD);
      if (ws) for (const w of ws) addRef(w, '@external');
    }
  }
}
harvestSrc(walk(SRC, '.coffee', []));
harvestExternal(walk(HARNESS, '.coffee', []), true);
harvestExternal(walk(TESTS, '.js', []), false);

const dead = [...defs.keys()].filter((n) => !referenced.has(n)).sort();

// SYMMETRY-AWARE (Topic 2): a public `<name>` and its private `_<name>NoSettle` core form ONE self-settling
// pair (the same pairing check-thin-wraps.js enforces). If a member is dead but its settle-twin is LIVE, it is
// RETAINED FOR SYMMETRY, not genuinely dead — the gate exempts it WITHOUT a manual allowlist entry. Safe in
// both directions: a dead public wrapper whose core is live (e.g. LabelButtonWdgt.setLabel, whose
// _setLabelNoSettle core FridgeMagnets construction calls), and a dead core whose public API is live.
// CRUCIALLY the twin must be used INDEPENDENTLY — referenced by some owner OTHER than `n` itself. A dead
// public wrapper's body is the one place that references its core, so counting that self-reference would
// SAVE a pair that is dead on BOTH sides. Excluding it (independentlyReferenced's `excluded` arg), a
// both-dead pair is retained by neither and both get flagged. Returns the live twin's name or null.
function liveSettleTwin(n) {
  const twin = twinName(n);
  return independentlyReferenced(twin, n, referrers) ? twin : null;
}
const symmetryRetained = dead.filter((n) => liveSettleTwin(n));
const flaggableDead = dead.filter((n) => !liveSettleTwin(n));   // dead AND not covered by a live settle-twin

// 3. allowlist
const allow = new Set();
if (fs.existsSync(ALLOWLIST)) {
  for (const l of fs.readFileSync(ALLOWLIST, 'utf8').split('\n')) {
    const t = stripComment(l).trim();
    if (t) allow.add(t);
  }
}

if (process.argv.includes('--update-allowlist')) {
  const header =
    '# Dead-method allowlist for buildSystem/check-dead-methods.js\n' +
    '# Methods DEFINED in src but referenced nowhere (src + tests + harness).\n' +
    '# Seeded as a BASELINE to triage/delete later; the lint FAILS on any NEW dead method not here.\n' +
    '# Remove a name once you delete the method (or it gains a real caller). One name per line; # = comment.\n' +
    '# (Settle-tier wrapper/core symmetry pairs are auto-exempt — see liveSettleTwin — so they are NOT seeded.)\n\n';
  fs.writeFileSync(ALLOWLIST, header + flaggableDead.join('\n') + '\n');
  console.log(`[dead-methods] wrote ${flaggableDead.length} names to ${path.relative(process.cwd(), ALLOWLIST)} (${symmetryRetained.length} symmetry pairs auto-exempt)`);
  process.exit(0);
}

const newDead = flaggableDead.filter((n) => !allow.has(n));
const stale = [...allow].filter((n) => !dead.includes(n));                  // allowlisted but no longer dead/defined
const redundant = [...allow].filter((n) => symmetryRetained.includes(n));  // allowlisted but now auto-exempt by symmetry

if (symmetryRetained.length) {
  console.log(`[dead-methods] NOTE — ${symmetryRetained.length} dead method(s) auto-retained for settle-tier symmetry (live twin): ${symmetryRetained.map((n) => `${n}↔${liveSettleTwin(n)}`).join(', ')}`);
}
if (redundant.length) {
  console.log(`[dead-methods] NOTE — ${redundant.length} allowlist entr${redundant.length === 1 ? 'y is' : 'ies are'} now redundant (covered by symmetry-awareness — delete from the allowlist): ${redundant.join(', ')}`);
}
if (stale.length) {
  console.log(`[dead-methods] NOTE — ${stale.length} allowlist entr${stale.length === 1 ? 'y is' : 'ies are'} no longer dead (delete from the allowlist): ${stale.join(', ')}`);
}

if (newDead.length) {
  console.error(`\n[dead-methods] FAIL — ${newDead.length} method(s) defined but referenced nowhere (src/tests/harness) and not allowlisted:`);
  for (const n of newDead) console.error(`  ${n}  (${defs.get(n)[0]})`);
  console.error('\nEither DELETE the method, or — if it is intentional public API / dispatched by a computed name —');
  console.error('add its name to buildSystem/dead-method-allowlist.txt with a one-line reason.');
  console.error('(A wrapper/core twin kept for symmetry needs NO entry — auto-exempt when its settle-twin is live.)');
  process.exit(1);
}

console.log(`[dead-methods] OK — ${defs.size} method names scanned, ${dead.length} dead (${flaggableDead.length} allowlisted + ${symmetryRetained.length} symmetry-exempt), 0 new.`);
process.exit(0);
