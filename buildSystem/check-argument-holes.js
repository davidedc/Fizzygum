#!/usr/bin/env node
// check-argument-holes.js — the HOLE TEST (R3 of docs/architecture/constructor-and-parameter-conventions.md), over
// every call site in BOTH repos, as an exact zero:
//
//     if any call site must pass `undefined` to reach a later argument, the parameter list is wrong
//
// A hole is not a style blemish. It is PROOF that the skipped parameter is configuration rather than identity, and
// that no single positional order serves every caller — the remedy is a trailing `opts = {}` (or, for a class exempt
// under the doc's §3, a reorder), or, read as a diagnosis, a dead argument to delete.
//
// WHAT IT READS: lib/call-sites.js's table — every class fragment of Fizzygum/src and of the tests repo's harness as
// the browser's meta-compiler splits and rewrites it (a `super` is an ordinary call there), every mixin and boot
// file, every macro source as the page compiles it, the MacroToolkit heredocs, and the tests repo's scripts (acorn).
// Real parsers: an implicit object is ONE argument, a nested paren-less call is one argument of the outer call, a
// string's contents are never a call.
//
// THE CALLERS TEST, mechanized (lib/call-sites.js `callersTest`): a site with an `undefined` BEFORE a present argument
// is a candidate; it is a HOLE iff another site of the same callee, of known arity, reaches LESS FAR (passes fewer
// arguments, a trailing `undefined` counting as omitted) — that site is its WITNESS, printed beside it. Otherwise
// every caller supplies the whole list and the `undefined` is the operand's VALUE (`_paintInLocalScope aContext,
// clip, undefined, bodyFn` — all of its callers pass four). Owner rulings (docs/archive/argument-holes-both-repos-plan.md):
// callees are grouped BY NAME whatever the receiver (more witnesses can only invent a hole, loudly — never hide one);
// absence is `undefined` alone (`null` is a value by the house rule); no sanction marker — a value the test misjudges
// is reshaped.
//
// STATED LIMITS — what it does not judge: a callee no code in either repo defines (`JSON.stringify`, DOM, Node) and a
// `new` whose class no code defines or is computed (`new (classNamed name)`); the this-arg of `.call` / `.apply` /
// `.bind` — so `fn.call undefined, a, undefined, b`, which forwards into `fn`, goes unread; code inside a string other
// than the lifted heredocs (a spreadsheet formula, a `page.evaluate("…")` string); a site of unknown arity (a spread,
// a forwarding bare `super`) is never a witness; a positional argument handed to an `(opts = {})` head (no
// `undefined` appears). A bare call of a PARAMETER or of a function nested in another is its own callee; a top-level
// function's calls group by name, from every file.
//
// Exit 0 = zero holes; 1 = holes (rule HOLE); 2 = INVALID, never a pass: a source it cannot parse (an interpolated
// heredoc included), a super it cannot place on a class chain, or a half that read nothing while its input is there
// (no class fragment in src; no harness file, no macro source or no script in a tests repo that exists).
//
// Run from Fizzygum/ (build_it_please.sh does): node ./buildSystem/check-argument-holes.js [--src=DIR]
// [--tests-repo=DIR] [--values]. The rails check another tree (a planted one); a tests repo that is absent is skipped
// and the pass line says so. --values lists the absences judged values, each with its callee's site count. That every
// rule BITES — the value/hole distinction as a minimal pair, a hole in each repo, and both INVALIDs — is proven on
// every build by check-argument-holes-selftest.js.

const fs = require('fs');
const path = require('path');
const { callSites, callersTest, describeCallee } = require('./lib/call-sites');
const { rejectUnknownArgs, rejectPositionalArgs, dirArg } = require('./lib/cli-args');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, ['--src=', '--tests-repo=', '--values'], 'argument-holes');
rejectPositionalArgs(ARGV, 'argument-holes', 'trees are named with --src=DIR and --tests-repo=DIR');
const SRC_DIR = dirArg(ARGV, '--src=', path.resolve(__dirname, '../src'), 'argument-holes');
const TESTS_ARG = ARGV.find((a) => a.startsWith('--tests-repo='));
const TESTS_DIR = TESTS_ARG ? path.resolve(TESTS_ARG.slice('--tests-repo='.length)) : path.resolve(__dirname, '../../Fizzygum-tests');
const SHOW_VALUES = ARGV.includes('--values');
const ROOT = path.resolve(__dirname, '..', '..');
const rel = (f) => path.relative(ROOT, f);

function invalid(msg) { console.error(`[argument-holes] INVALID — ${msg}`); process.exit(2); }

if (TESTS_ARG && !fs.existsSync(TESTS_DIR)) invalid(`--tests-repo names no directory: ${TESTS_DIR}`);
const { sites, unreadable, counts } = callSites({ srcDir: SRC_DIR, testsRepoDir: TESTS_DIR });
if (unreadable.length) {
  for (const u of unreadable) console.error(`  ${rel(u.file)}${u.line ? ':' + u.line : ''}  ${u.message}`);
  invalid(`${unreadable.length} source(s) it cannot read — a call there is unjudged, so the count above would be a guess`);
}
if (counts.fragments === 0) invalid(`it read no class fragment in ${SRC_DIR}`);
const testsPresent = fs.existsSync(path.join(TESTS_DIR, 'tests'));
if (testsPresent && !counts.testsRepo) invalid(`${TESTS_DIR} has tests/ but no Automator-and-test-harness-src/ — not a tests repo it can read`);
if (counts.testsRepo && (counts.harness === 0 || counts.macro === 0 || counts.script === 0)) {
  invalid(`it read ${counts.harness} harness file(s), ${counts.macro} macro source(s) and ${counts.script} script(s) in ${TESTS_DIR}`);
}

const verdict = callersTest(sites);
const args = (s) => '[ ' + s.args.map((a) => a.text).join(' | ') + ' ]';

for (const { site, witness } of verdict.holes) {
  console.error(rules.fired('HOLE', `  ${rel(site.file)}:${site.line}  ${describeCallee(site)}  ${args(site)}  — HOLE: ${rel(witness.file)}:${witness.line} passes ${witness.reach}`));
}
if (SHOW_VALUES) for (const { site, sites: n } of verdict.values) console.log(`  value  ${rel(site.file)}:${site.line}  ${describeCallee(site)}  ${args(site)}  — every one of its ${n} site(s) fills the list`);

const by = (w) => sites.filter((s) => s.where === w).length;
const unknown = sites.filter((s) => !s.knownArity).length;
const over = `${sites.length} calls (src ${by('src')}, harness ${by('harness')}, macros ${by('macro') + by('heredoc')}, scripts ${by('script')})`
  + (counts.testsRepo ? '' : ` — the tests repo at ${TESTS_DIR} is absent, so only src is judged`);
const n = verdict.holes.length;
if (n > 0) {
  console.error(`\n[argument-holes] FAIL — ${n} hole(s) over ${over}.`);
  console.error('Each `undefined` above fills a slot only to reach a later argument: its witness passes fewer. The list is');
  console.error('wrong (R3) — move the operands every caller does not supply into a trailing `opts = {}`, reorder a class');
  console.error('exempt under §3, or, if the argument it reaches is dead, delete it. Law:');
  console.error('docs/architecture/constructor-and-parameter-conventions.md');
  process.exit(1);
}
console.log(`[argument-holes] OK — 0 holes over ${over}; ${verdict.values.length} absence(s) judged values (--values lists them); `
  + `${verdict.foreign.length} in calls of foreign APIs and ${verdict.excluded.length} this-args not judged; ${unknown} site(s) of unknown arity never witness.`);
