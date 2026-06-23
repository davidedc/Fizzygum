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
function harvest(files, stripHdr, stripCmt) {
  for (const p of files) {
    for (let line of fs.readFileSync(p, 'utf8').split('\n')) {
      if (stripHdr && HEADER.test(line)) { const gt = line.indexOf('>'); line = gt >= 0 ? line.slice(gt + 1) : ''; }
      const code = stripCmt ? stripComment(line) : line;
      const ws = code.match(WORD);
      if (ws) for (const w of ws) referenced.add(w);
    }
  }
}
harvest(walk(SRC, '.coffee', []), true, true);
harvest(walk(HARNESS, '.coffee', []), true, true);
harvest(walk(TESTS, '.js', []), false, false);

const dead = [...defs.keys()].filter((n) => !referenced.has(n)).sort();

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
    '# Remove a name once you delete the method (or it gains a real caller). One name per line; # = comment.\n\n';
  fs.writeFileSync(ALLOWLIST, header + dead.join('\n') + '\n');
  console.log(`[dead-methods] wrote ${dead.length} names to ${path.relative(process.cwd(), ALLOWLIST)}`);
  process.exit(0);
}

const newDead = dead.filter((n) => !allow.has(n));
const stale = [...allow].filter((n) => !dead.includes(n));   // allowlisted but no longer dead/defined

if (stale.length) {
  console.log(`[dead-methods] NOTE — ${stale.length} allowlist entr${stale.length === 1 ? 'y is' : 'ies are'} no longer dead (delete from the allowlist): ${stale.join(', ')}`);
}

if (newDead.length) {
  console.error(`\n[dead-methods] FAIL — ${newDead.length} method(s) defined but referenced nowhere (src/tests/harness) and not allowlisted:`);
  for (const n of newDead) console.error(`  ${n}  (${defs.get(n)[0]})`);
  console.error('\nEither DELETE the method, or — if it is intentional public API / dispatched by a computed name —');
  console.error('add its name to buildSystem/dead-method-allowlist.txt with a one-line reason.');
  process.exit(1);
}

console.log(`[dead-methods] OK — ${defs.size} method names scanned, ${dead.length} dead (all allowlisted), 0 new.`);
process.exit(0);
