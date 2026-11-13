#!/usr/bin/env node
// check-call-arguments.js — every call's ARGUMENTS against its callee, over every call site in BOTH repos, as an exact
// zero. Three rules, one table (lib/call-sites.js):
//
//   HOLE — the hole test (R3 of docs/architecture/constructor-and-parameter-conventions.md):
//       if any call site must pass `undefined` to reach a later argument, the parameter list is wrong
//     A hole is not a style blemish. It is PROOF that the skipped parameter is configuration rather than identity, and
//     that no single positional order serves every caller — the remedy is a trailing `opts = {}` (or, for a class
//     exempt under the doc's §3, a reorder), or, read as a diagnosis, a dead argument to delete.
//   EXTRA_ARGUMENT — a call passes more arguments than any definition it can reach declares: an argument no parameter
//     receives. Dead (a size handed to a constructor that takes none), or worse, MIS-BOUND: a spelling that compiles
//     to something its author did not write (`[ f "a",⏎ f "b" ]` is ONE element, `f("a", f("b"))`), or a positional
//     argument handed past an `(opts = {})` head.
//   POSITIONAL_INTO_OPTIONS — an argument of a kind the parse shows is no options object (`@`, a literal, an array, a
//     function, a `new`) lands in a parameter defaulting to `{}`: the options object it is silently taken AS — the trap
//     of every conversion to options (`new SimpleButtonWdgt @` after the head became `(opts = {})`).
//
// WHAT IT READS: lib/call-sites.js's table — every class fragment of Fizzygum/src and of the tests repo's harness as
// the browser's meta-compiler splits and rewrites it (a `super` is an ordinary call there), every boot file, every
// macro source as the page compiles it (each test's, and each verb: a Macro.fromString literal of src or
// the harness), and the tests repo's scripts (acorn) — and every definition those make. Real parsers: an implicit
// object is ONE argument, a nested paren-less call is one argument of the outer call, a string's contents are never a
// call.
//
// THE CALLERS TEST (HOLE), mechanized (lib/call-sites.js `callersTest`): a site with an `undefined` BEFORE a present
// argument is a candidate; it is a HOLE iff another site of the same callee, of known arity, reaches LESS FAR (passes
// fewer arguments, a trailing `undefined` counting as omitted) — that site is its WITNESS, printed beside it. Otherwise
// every caller supplies the whole list and the `undefined` is the operand's VALUE (`_paintInLocalScope aContext,
// clip, undefined, bodyFn` — all of its callers pass four). Callees are grouped BY NAME whatever the receiver (more
// witnesses can only invent a hole, loudly — never hide one); absence is `undefined` alone (`null` is a value).
//
// THE ARITY TEST (EXTRA_ARGUMENT, POSITIONAL_INTO_OPTIONS; lib/call-sites.js `arityTest`, its header has the full
// reading): a call is judged only where its TARGET is certainly among the definitions it reaches — what runs where it
// runs (page code, a macro program, a script module, each seeing its own), a bare call resolved lexically, a `new` of
// the one class its name means there, a send whose receiver is `@`/`this` or `X.` of a class whose whole chain the
// reader read (never an `Array` or an `EventEmitter` above it) — and every one of them is a function. The declared
// count is the widest of them: a wider definition elsewhere can only hide an extra argument, never invent one.
// Matching by name alone would read `Math.max a, b, c` against `Point::max` — a foreign API's definitions are
// invisible.
//
// Owner rulings (docs/archive/argument-holes-both-repos-plan.md, docs/archive/call-arguments-gate-plan.md): no
// sanction marker and no baseline — a call the tests misjudge is reshaped.
//
// STATED LIMITS — what it does not judge: a callee no code in either repo defines (`JSON.stringify`, DOM, Node) and a
// `new` whose class no code defines or is computed (`new (classNamed name)`); the this-arg of `.call` / `.apply` /
// `.bind` — so `fn.call undefined, a, undefined, b`, which forwards into `fn`, goes unread; code inside a string other
// than the lifted heredocs (a spreadsheet formula, a `page.evaluate("…")` string); a site of unknown arity (a spread,
// a forwarding bare `super`) is never a witness and is never judged for arity. A bare call of a PARAMETER or of a
// binding nested in a function is its own callee; a top-level function's calls group by name, from every file. For
// the arity test besides: a send to a receiver the parse cannot see (`frame.m a`, `w.tripleActivated pos`), or in a
// class with a foreign ancestor; a callee some code also binds or assigns as a VALUE (`canvas.width = …` leaves every
// `@width()` unjudged; a field holding a closure; a parameter); a callee taking any number (a splat, `arguments`); a
// method no code defines as a member or field (assembled at run time); a script's bare call of a name its module
// neither binds nor imports (Node's global, or the page's in a page.evaluate body); `new @constructor`. And a lone
// variable handed to an options slot (`new X target`): only an argument whose kind the parse shows is judged there.
//
// Exit 0 = zero violations; 1 = a rule fired; 2 = INVALID, never a pass: a source it cannot parse (an interpolated
// heredoc included), a super it cannot place on a class chain, a source tree lib/source-files.js refuses
// (SOURCE_TREE_MALFORMED: a symlink, a src or a harness holding no .coffee file) or a tooling tree lib/what-runs.js
// refuses (TOOLING_TREE_MALFORMED: a symlink among the scripts), or a half that read nothing (no class fragment in
// src; no macro source or no script in the tests repo).
//
// Run from Fizzygum/ (build_it_please.sh does): node ./buildSystem/check-call-arguments.js [--src=DIR]
// [--tests-repo=DIR] [--values]. The rails (lib/source-files.js sourceRoots) check another tree (a planted one); both
// repos are always read. --values lists the absences judged values, each with its callee's site count. That every rule BITES — the value/hole distinction as a minimal pair, a hole in each repo,
// an extra argument and a positional into options in each repo, and both INVALIDs — is proven on every build by
// check-call-arguments-selftest.js.

const path = require('path');
const { callSites, callersTest, arityTest, describeCallee } = require('./lib/call-sites');
const { rejectUnknownArgs, rejectPositionalArgs } = require('./lib/cli-args');
const { sourceRoots, SOURCE_RAILS } = require('./lib/source-files');
const rules = require('./lib/gate-rules').forGate(__filename);

const ARGV = process.argv.slice(2);
rejectUnknownArgs(ARGV, [...SOURCE_RAILS, '--values'], 'call-arguments');
rejectPositionalArgs(ARGV, 'call-arguments', 'trees are named with --src=DIR and --tests-repo=DIR');
const ROOTS = sourceRoots(ARGV, 'call-arguments');
const SRC_DIR = ROOTS.src;
const TESTS_DIR = ROOTS.testsRepo;
const SHOW_VALUES = ARGV.includes('--values');
const ROOT = path.resolve(__dirname, '..', '..');
const rel = (f) => path.relative(ROOT, f);

function invalid(msg) { console.error(`[call-arguments] INVALID — ${msg}`); process.exit(2); }

let table;
try { table = callSites({ srcDir: SRC_DIR, testsRepoDir: TESTS_DIR }); } catch (e) {
  // a source tree lib/source-files.js refuses is read by no one: a call there is unjudged
  if (/^(SOURCE|TOOLING)_TREE_MALFORMED /.test(e.message)) invalid(e.message);
  throw e;
}
const { sites, unreadable, counts } = table;
if (unreadable.length) {
  for (const u of unreadable) console.error(`  ${rel(u.file)}${u.line ? ':' + u.line : ''}  ${u.message}`);
  invalid(`${unreadable.length} source(s) it cannot read — a call there is unjudged, so the count above would be a guess`);
}
if (counts.fragments === 0) invalid(`it read no class fragment in ${SRC_DIR}`);
// (a harness with no file is refused above, SOURCE_TREE_MALFORMED)
if (counts.macro === 0 || counts.script === 0) {
  invalid(`it read ${counts.macro} macro source(s) and ${counts.script} script(s) in ${TESTS_DIR}`);
}

const verdict = callersTest(sites);
const arity = arityTest(table);
const args = (s) => '[ ' + s.args.map((a) => a.text).join(' | ') + ' ]';
const where = (d) => (d.implicit ? `${d.implicit} (no constructor up its chain)` : `${rel(d.file)}:${d.line}`);

for (const { site, witness } of verdict.holes) {
  console.error(rules.fired('HOLE', `  ${rel(site.file)}:${site.line}  ${describeCallee(site)}  ${args(site)}  — HOLE: ${rel(witness.file)}:${witness.line} passes ${witness.reach}`));
}
for (const { site, widest } of arity.extra) {
  console.error(rules.fired('EXTRA_ARGUMENT', `  ${rel(site.file)}:${site.line}  ${describeCallee(site)}  ${args(site)}  — EXTRA_ARGUMENT: passes ${site.args.length}, ${where(widest)} declares ${widest.arity}`));
}
for (const { site, index, def } of arity.intoOptions) {
  console.error(rules.fired('POSITIONAL_INTO_OPTIONS', `  ${rel(site.file)}:${site.line}  ${describeCallee(site)}  ${args(site)}  — POSITIONAL_INTO_OPTIONS: argument ${index + 1} is ${site.args[index].kind === 'this' ? '`@`' : 'a ' + site.args[index].kind}, where ${where(def)} takes \`opts = {}\``));
}
if (SHOW_VALUES) for (const { site, sites: n } of verdict.values) console.log(`  value  ${rel(site.file)}:${site.line}  ${describeCallee(site)}  ${args(site)}  — every one of its ${n} site(s) fills the list`);

const by = (w) => sites.filter((s) => s.where === w).length;
const unknown = sites.filter((s) => !s.knownArity).length;
const over = `${sites.length} calls (src ${by('src')}, harness ${by('harness')}, macros ${by('macro') + by('heredoc')}, scripts ${by('script')})`;
const failed = verdict.holes.length + arity.extra.length + arity.intoOptions.length;
if (failed > 0) {
  console.error(`\n[call-arguments] FAIL — ${verdict.holes.length} hole(s), ${arity.extra.length} extra argument(s), ${arity.intoOptions.length} positional(s) into options over ${over}.`);
  if (verdict.holes.length) {
    console.error('HOLE: each `undefined` fills a slot only to reach a later argument — its witness passes fewer. The list is');
    console.error('wrong (R3): move the operands every caller does not supply into a trailing `opts = {}`, reorder a class');
    console.error('exempt under §3, or, if the argument it reaches is dead, delete it.');
  }
  if (arity.extra.length) {
    console.error('EXTRA_ARGUMENT: no parameter receives the extra argument. Delete it if it is dead; if the call reads');
    console.error('differently than it compiles (check with buildSystem/compile-fragment.js), spell it so it compiles to what is meant.');
  }
  if (arity.intoOptions.length) console.error('POSITIONAL_INTO_OPTIONS: that argument is taken AS the options object — pass `key: value` pairs.');
  console.error('Law: docs/architecture/constructor-and-parameter-conventions.md');
  process.exit(1);
}
console.log(`[call-arguments] OK — 0 holes, 0 extra arguments, 0 positionals into options over ${over}; `
  + `${verdict.values.length} absence(s) judged values (--values lists them); ${arity.judged} call(s) judged for arity; `
  + `${verdict.foreign.length} absence(s) in calls of foreign APIs and ${verdict.excluded.length} this-args not judged; ${unknown} site(s) of unknown arity.`);
