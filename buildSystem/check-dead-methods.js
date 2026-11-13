#!/usr/bin/env node
// check-dead-methods.js — build lint: flag methods DEFINED in the compiled sources but REACHED nowhere.
//
// Mirrors buildSystem/check-layering.js (a heuristic line scanner, exit 0 clean / 1 violation /
// 2 operational). It finds every method header in the compiled sources (lib/source-files.js compiledFiles:
// src/ and the tests repo's harness) — a class's 2-space ones and the class-side `@name:` methods alike (lib/coffee-method-header.js; a class-side method is inventoried under
// its BARE name, which is how it is called: `Class.name` from outside, `@name` between the statics of one
// class) — then reads every place a method could be reached FROM, as code: the compiled sources
// (lib/coffee-mask.js, each reference attributed to its enclosing method) and the sibling Fizzygum-tests repo's
// macro sources and scripts/ rigs (lib/tests-repo-code.js; its metadata prose, reference records and manifests
// are not code). What counts as reaching a method is lib/method-references.js, the one
// definition: a property access (`@m`, `x.m`, `C::m`), a whole-name string (`"m"`, string dispatch), a name
// template (`"_#{@action}Connector"`, every method it matches) or a computed access on a named class
// (`FormulaHelpers[name]`, every method on that side). A bare word — a local, a parameter, an object key, a
// def's own name — reaches nothing, and neither does a comment. A method nothing reaches is DEAD.
//
// The rare genuine exception (intentional public API kept for a family's symmetry, a method dispatched by a
// name assembled with `+` or through an arbitrary object, `@target[action]`) goes in dead-method-allowlist.txt
// with its reason. Every limit of the reference rule errs toward ALIVE (method-references.js's header), so
// what this flags really is dead; the price of matching by name stands: two same-named methods on unrelated
// classes cover each other.
//
// The lint FAILS on any dead method NOT in the allowlist, and on a STALE allowlist entry
// (STALE_ALLOWLIST_ENTRY: a name no longer dead, or now auto-exempt by settle-tier symmetry), which
// excuses nothing today and would excuse the next dead method of that name. Run with
// --update-allowlist to (re)seed the allowlist file with the current dead set (the baseline).
//
// It reads the sibling Fizzygum-tests repo for the reference set, on every build whatever the profile ships (the build
// requires that repo; lib/source-files.js sourceRoots refuses a hand run without it).

const fs = require('fs');
const path = require('path');

const ALLOWLIST = path.resolve(__dirname, 'dead-method-allowlist.txt');

// methodSpans / methodBoundary group src into class methods
const { methodBoundary, methodSpans, unseenMethodHeaders } = require('./lib/coffee-method-header');
const { coffeeMask } = require('./lib/coffee-mask');
const { readAllowlist } = require('./lib/allowlist-file');
const testsRepo = require('./lib/tests-repo-code');
const methodRefs = require('./lib/method-references');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { compiledFiles, sourceRoots, sourceName, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);
let ROOTS;   // main() reads the rails

// ── settle-tier symmetry helpers (pure; check-dead-methods-selftest.js drives them) ─────────────────
// A public `<name>` and its private core `_<name>NoSettle` form ONE self-settling pair. When one side is
// dead we may RETAIN it for symmetry — but ONLY if the OTHER side is INDEPENDENTLY used. `twinName` maps a
// member to its partner; `independentlyReferenced` answers "is `token` referenced by some owner OTHER than
// `excluded`?" (owner = a compiled source's method name, '@toplevel' for class-level code, or '@external' for the
// tests repo's macros and rigs).
// The `excluded` guard is what closes the masking hole: a dead public wrapper's body is the one place that
// references its core (`setLabel -> @_setLabelNoSettle`), so without excluding that body the core looks "used"
// and a pair dead on BOTH sides would be saved. Excluding it, a both-dead pair is retained by neither.
function twinName(n) {
  const core = /^_(.+)NoSettle$/.exec(n);
  return core ? core[1] : '_' + n + 'NoSettle';
}
// The INVENTORY of one file's methods: an instance method under its own
// name, a class-side method under its BARE name, tagged classSide so a report can say which. A class-side
// DATA key (`@NAME: 5`) is no method, and methodSpans gives it no span.
function inventoryOf(lines) {
  return methodSpans(lines).map((sp) => ({ name: sp.static ? sp.name.slice(1) : sp.name, line: sp.line, classSide: sp.static }));
}
function independentlyReferenced(token, excluded, referrers) {
  const owners = referrers.get(token);
  if (!owners) return false;
  for (const o of owners) if (o !== excluded) return true;   // a referrer other than the dead method itself
  return false;
}

function main() {
  // Run from the Fizzygum/ repo root (build_it_please.sh does): node ./buildSystem/check-dead-methods.js [--src=DIR]
  // [--tests-repo=DIR] — the rails read another src tree or tests repo (a copy carrying a plant). That every rule
  // BITES, and that every way of reaching a method keeps it alive, is proven on every build by
  // check-dead-methods-selftest.js.
  const argv = process.argv.slice(2);
  rejectUnknownArgs(argv, ['--update-allowlist', ...SOURCE_RAILS], 'check-dead-methods');
  rejectPositionalArgs(argv, 'check-dead-methods', 'a src tree is named with --src=DIR');
  ROOTS = sourceRoots(argv, 'check-dead-methods');
  if (argv.includes('--update-allowlist') && argv.some((a) => SOURCE_RAILS.some((r) => a.startsWith(r)))) {
    console.error('[dead-methods] ERROR — --update-allowlist writes the real allowlist: it never reads another src tree or tests repo');
    process.exit(2);
  }
  // 1. every method header in the compiled sources -> name => [first def location, ...]
  // This gate owns the method INVENTORY, so it also carries the guard for headers the shared matcher
  // cannot see: an unseen header is not a missing warning, it is a method NO gate checks at all.
  // A class-side method is inventoried under its BARE name (inventoryOf), and its own body is attributed to
  // it in the harvest below, so one static calling another (`@other` inside `@name`) is that other's reference.
  const defs = new Map();
  const methods = [];   // { name, cls, classSide }: what computed dispatch is resolved against (one class per file)
  const parentOf = new Map();   // the class chain a computed access resolves through
  const unseen = [];
  const masked = new Map();   // each compiled source's lib/coffee-mask.js reading, read once for both passes
  for (const p of compiledFiles(ROOTS)) {
    const text = fs.readFileSync(p, 'utf8');
    const lines = text.split('\n');
    masked.set(p, coffeeMask(text, sourceName(p, ROOTS)));
    const cls = path.basename(p, '.coffee');
    for (const l of lines) {
      const c = /^class\s+([A-Za-z_]\w*)(?:\s+extends\s+([A-Za-z_]\w*))?/.exec(l);
      if (c && c[1] === cls && c[2]) parentOf.set(cls, c[2]);
    }
    for (const def of inventoryOf(lines)) {
      if (!defs.has(def.name)) defs.set(def.name, []);
      defs.get(def.name).push(sourceName(p, ROOTS) + ':' + (def.line + 1) + (def.classSide ? ' (class-side)' : ''));
      methods.push({ name: def.name, cls: path.basename(p, '.coffee'), classSide: def.classSide });
    }
    for (const u of unseenMethodHeaders(lines, masked.get(p))) unseen.push(`${sourceName(p, ROOTS)}:${u.line}: ${u.text}`);
  }
  if (unseen.length) {
    console.error(`[dead-methods] FAIL — ${unseen.length} method header(s) the shared matcher cannot see:`);
    for (const u of unseen) console.error(rules.fired('UNSEEN_HEADER', '   ' + u));
    console.error('\nA method whose signature wraps must break immediately after the `(`, so that the header line');
    console.error('ends there — every build gate groups a .coffee file by that shape, and a header none of them');
    console.error('matches makes the WHOLE METHOD invisible to all of them, silently. Re-wrap the signature, or');
    console.error('widen METHOD_HEADER in buildSystem/lib/coffee-method-header.js and re-run every gate.');
    process.exit(1);
  }

  // 2. every method REACHED (lib/method-references.js), read from code
  const referenced = new Set();
  const referrers = new Map();   // token -> Set of owners that reference it (a compiled source's method name / '@toplevel' / '@external' / '@computed')
  const templates = [], computedClasses = [];
  function addRef(token, owner) {
    referenced.add(token);
    let s = referrers.get(token);
    if (!s) referrers.set(token, (s = new Set()));
    s.add(owner);
  }
  function harvestLine(code, owner) {
    const r = methodRefs.methodReferences(code);
    for (const n of r.names) addRef(n, owner);
    templates.push(...r.templates);
    computedClasses.push(...r.classes);
  }
  // the compiled sources: attribute each reference to its ENCLOSING method, so we can later tell whether a settle-twin is used by
  // something OTHER than the dead method itself. A method header (a class's 2-space one) opens a method; the header line itself (its default parameters, an inline body) and the 4+-space-indented
  // lines below belong to it; class-level lines (indent < 4, not a header) are '@toplevel'. A def's own name is a
  // key, never a reference, so a header needs no special case. (`referenced` is the flat set; the per-owner map
  // is purely additive.)
  function harvestSrc(files) {
    for (const p of files) {
      let cur = null;
      fs.readFileSync(p, 'utf8').split('\n').forEach((raw, i) => {
        const b = methodBoundary(raw);
        let owner;
        // the owner is the method's INVENTORY name (a class-side one's bare name, as inventoryOf names it), so
        // the symmetry check below excludes a dead method's references to its own twin whichever side it is on
        if (b && b.kind === 'header') owner = cur = (b.static ? b.method.slice(1) : b.method);
        else owner = (raw.length - raw.trimStart().length >= 4 && cur) ? cur : '@toplevel';
        harvestLine(masked.get(p)[i].code, owner);
      });
    }
  }
  harvestSrc([...masked.keys()]);
  // the tests repo's macros and rigs: every reference there is an INDEPENDENT anchor ('@external') — it lives outside
  // the compiled pair, so it always counts as "the twin is used". Its harness is a compiled source, read above with
  // each reference attributed to its method: read again as '@external', a dead harness wrapper's call of its own core
  // would save the pair.
  for (const { kind, lines } of testsRepo.testsRepoCode(ROOTS.testsRepo)) {
    if (kind !== 'harness') for (const line of lines) harvestLine(line, '@external');
  }
  // computed dispatch, resolved last against the whole inventory (a template or a class access may sit anywhere)
  // a class's chain: itself, then its ancestors' chains — where a lookup on it resolves
  function chainOf(cls, seen = new Set()) {
    if (seen.has(cls)) return [];
    seen.add(cls);
    return [cls, ...(parentOf.has(cls) ? chainOf(parentOf.get(cls), seen) : [])];
  }
  for (const n of methodRefs.reachedByComputedDispatch(templates, computedClasses, methods, chainOf)) addRef(n, '@computed');

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
  const allow = new Set(readAllowlist(ALLOWLIST).keys());

  if (process.argv.includes('--update-allowlist')) {
    const header =
      '# Dead-method allowlist for buildSystem/check-dead-methods.js\n' +
      '# Methods DEFINED in the compiled sources (src + the harness) but reached nowhere (they + the tests repo\'s code;\n' +
      '# lib/method-references.js).\n' +
      '# Seeded as a BASELINE to triage/delete later; the lint FAILS on any NEW dead method not here.\n' +
      '# Remove a name once you delete the method (or it gains a real caller): a stale entry FAILS the lint.\n' +
      '# One name per line; # = comment.\n' +
      '# (Settle-tier wrapper/core symmetry pairs are auto-exempt — see liveSettleTwin — so they are NOT seeded.)\n\n';
    fs.writeFileSync(ALLOWLIST, header + flaggableDead.join('\n') + '\n');
    console.log(`[dead-methods] wrote ${flaggableDead.length} names to ${path.relative(process.cwd(), ALLOWLIST)} (${symmetryRetained.length} symmetry pairs auto-exempt)`);
    process.exit(0);
  }

  const newDead = flaggableDead.filter((n) => !allow.has(n));
  // A STALE allowlist entry excuses nothing today and would excuse the next dead method of that name, so it FAILS:
  // one no longer dead (it gained a reference, or no method of that name is defined any more), or one now
  // auto-exempt by settle-tier symmetry (its twin is live, so the entry is redundant).
  const stale = [...allow].filter((n) => !dead.includes(n)).map((n) => defs.has(n)
    ? rules.fired('STALE_ENTRY_REFERENCED', `${n} — no longer dead: it is referenced`)
    : rules.fired('STALE_ENTRY_UNDEFINED', `${n} — no method of that name is defined in the compiled sources`));
  const redundant = [...allow].filter((n) => symmetryRetained.includes(n)).map((n) => rules.fired('STALE_ENTRY_REDUNDANT', `${n} — auto-exempt by settle-tier symmetry (live twin ${liveSettleTwin(n)}), so the entry is redundant`));

  if (symmetryRetained.length) {
    console.log(`[dead-methods] NOTE — ${symmetryRetained.length} dead method(s) auto-retained for settle-tier symmetry (live twin): ${symmetryRetained.map((n) => `${n}↔${liveSettleTwin(n)}`).join(', ')}`);
  }

  if (newDead.length) {
    console.error(`\n[dead-methods] FAIL — ${newDead.length} method(s) defined but reached nowhere (src, harness, macros, rigs) and not allowlisted:`);
    for (const n of newDead) console.error(rules.fired('DEAD_METHOD', `  ${n}  (${defs.get(n)[0]})`));
    console.error('\nNothing reaches it by property access, whole-name string, name template or computed class access');
    console.error('(lib/method-references.js). Either DELETE the method, or — if it is intentional public API, or');
    console.error('dispatched by a name assembled with `+` or through an arbitrary object —');
    console.error('add its name to buildSystem/dead-method-allowlist.txt with a one-line reason.');
    console.error('(A wrapper/core twin kept for symmetry needs NO entry — auto-exempt when its settle-twin is live.)');
  }
  if (stale.length || redundant.length) {
    console.error(`\n[dead-methods] FAIL — ${stale.length + redundant.length} stale entr${stale.length + redundant.length === 1 ? 'y' : 'ies'} in buildSystem/dead-method-allowlist.txt (delete each):`);
    for (const s of [...stale, ...redundant]) console.error(`  STALE_ALLOWLIST_ENTRY ${s}`);
  }
  if (newDead.length || stale.length || redundant.length) process.exit(1);

  console.log(`[dead-methods] OK — ${defs.size} method names scanned, ${dead.length} dead (${flaggableDead.length} allowlisted + ${symmetryRetained.length} symmetry-exempt), 0 new.`);
  process.exit(0);
}

module.exports = { twinName, inventoryOf, independentlyReferenced };

if (require.main === module) main();
