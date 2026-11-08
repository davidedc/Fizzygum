'use strict';
// check-call-arguments-selftest.js — check-call-arguments.js proved able to BITE, rule by rule, by running the REAL gate
// on a planted fixture (lib/planted-src.js): a src tree holding the real meta/Class.coffee + meta/Mixin.coffee (the
// gate reads classes through the browser's own meta-compiler) and fixture classes, and a fixture TESTS REPO per run,
// named by the run's `--tests-repo=` (the check-layering-selftest.js precedent for a second tree).
//   control — only VALUES and forms that are no violation: `@bpCallee 1, undefined, 3` beside `@bpCallee 4, 5, 6`
//     (every site fills the list), a trailing `undefined`, a string holding "undefined, then 1", a `.call undefined`
//     this-arg, a foreign `JSON.stringify s, undefined, 2`, `@bpOpts undefined, face: 2, tip: 3` beside `@bpOpts 1,
//     face: 4` (an implicit object is ONE argument: both reach 2 — a reader counting its keys would call it a hole),
//     `Math.bpTrail 1, 2, 3` (a receiver no reader sees: by name alone it would be an extra argument), an object in an
//     options slot, and a tests repo whose macro and script hold values only;               → OK
//   the callers test FLIPS that value: the control plus one more site, `@bpCallee 8`       → HOLE, naming the witness
//   a hole in the tests repo: a macro's `new BpButton undefined, undefined, face: "x"` beside `new BpButton face: "y"`,
//     a script's `bpLocal(1, undefined, 3)` beside `bpLocal(1)`, a harness class's `@bpH 1, undefined, 3` beside
//     `@bpH 1`                                                                               → HOLE in each file
//   src: `@bpTrail 1, 2, 3` against `bpTrail: (a, b)`, the swallowed-element spelling `[ bpOne "a",⏎ bpOne "b" ]`
//     (one element, `bpOne("a", bpOne("b"))`), and `new BpButton 1, 2, "label"` into its `opts = {}`
//                                                              → EXTRA_ARGUMENT ×2, POSITIONAL_INTO_OPTIONS
//   the tests repo: a harness `@bpH 1, 2, 3, 4`, a script `bpLocal(1, 2, 3, 4)`, a macro `new BpButton 1, 2, @`
//                                                              → EXTRA_ARGUMENT ×2, POSITIONAL_INTO_OPTIONS
//   a macro that does not parse; a tests repo with no harness, no macro and no script     → INVALID (exit 2), no rule
// Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { proveGate, SRC } = require('./lib/planted-src');

const meta = {};
for (const m of ['Class.coffee', 'Mixin.coffee']) meta['meta/' + m] = fs.readFileSync(path.join(SRC, 'meta', m), 'utf8');
const TARGET = [
  'class BpTarget',
  '  bpCallee: (a, b, c) -> a',
  '  bpTrail: (a, b) -> a',
  '  bpOpts: (a, opts) -> a',
  '  callers: ->',
  '    @bpCallee 1, undefined, 3',          // 6
  '    @bpCallee 4, 5, 6',
  '    @bpTrail 7, undefined',
  '    s = "use undefined, then 1"',
  '    fn.call undefined, 1',
  '    JSON.stringify s, undefined, 2',
  '    @bpOpts undefined, face: 2, tip: 3',
  '    @bpOpts 1, face: 4',
  '    Math.bpTrail 1, 2, 3',
  '    new BpButton 1, 2, face: "f"',
  ''].join('\n');
const BUTTON = ['class BpButton', '  constructor: (a, b, opts = {}) ->', '    @a = a', ''].join('\n');
const WITNESS = ['class BpWitness', '  callers: ->', '    @bpCallee 8', ''].join('\n');
const EXTRA = ['class BpExtra', '  callers: ->', '    @bpTrail 1, 2, 3', '    new BpButton 1, 2, "label"', ''].join('\n');
const SWALLOWED = ['bpOne = (a) -> a', 'bpBoth = [', '  bpOne "a",', '  # a comment between', '  bpOne "b"', ']', ''].join('\n');
const src = (extra = {}) => Object.assign({ 'BpTarget.coffee': TARGET, 'BpButton.coffee': BUTTON }, meta, extra);

// fixture tests repos, each a harness dir + tests/ + scripts/
const repos = [];
const HARNESS = 'Automator-and-test-harness-src/BpHarness.coffee';
const harness = (body) => ['class BpHarness', '  bpH: (a, b, c) -> a', '  callers: ->', ...body.map((l) => '    ' + l), ''].join('\n');
const repo = (files) => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'check-call-arguments-selftest-repo-'));
  repos.push(dir);
  fs.mkdirSync(path.join(dir, 'Automator-and-test-harness-src'), { recursive: true });
  fs.mkdirSync(path.join(dir, 'tests'), { recursive: true });
  for (const [rel, text] of Object.entries(files)) { const p = path.join(dir, rel); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); }
  return '--tests-repo=' + dir;
};
process.on('exit', () => { for (const d of repos) fs.rmSync(d, { recursive: true, force: true }); });
const macro = (body) => 'var c = { "mainMacroSource": `m_Macro = ->\n' + body + '\n` };\n';
const MACRO = 'tests/SystemTest_bp/SystemTest_bp_automationCommands.js';
const META = { 'tests/SystemTest_bp/SystemTest_bp.js': 'var SystemTest_bp = {};\n' };   // a test is its two files
const valuesRepo = repo({
  [HARNESS]: harness(['@bpH 1, undefined, 3', '@bpH 4, 5, 6']),
  ...META,
  [MACRO]: macro('  @bpCallee 9, undefined, 9'),
  'scripts/s.js': 'function bpLocal(a, b, c) { return a; }\nbpLocal(1, undefined, 3);\nbpLocal(4, 5, 6);\n',
});
const holesRepo = repo({
  [HARNESS]: harness(['@bpH 1, undefined, 3', '@bpH 1']),
  ...META,
  [MACRO]: macro('  x = new BpButton undefined, undefined, face: "x"\n  y = new BpButton face: "y"'),
  'scripts/s.js': 'function bpLocal(a, b, c) { return a; }\nbpLocal(1, undefined, 3);\nbpLocal(1);\n',
});
const arityRepo = repo({
  [HARNESS]: harness(['@bpH 1, 2, 3, 4']),
  ...META,
  [MACRO]: macro('  b = new BpButton 1, 2, @'),
  'scripts/s.js': 'function bpLocal(a, b, c) { return a; }\nbpLocal(1, 2, 3, 4);\n',
});
const badRepo = repo({ [HARNESS]: harness(['@bpH 1, 2, 3']), ...META, [MACRO]: macro('  f ('), 'scripts/s.js': 'ok();\n' });
const emptyRepo = repo({});

proveGate({
  name: 'check-call-arguments',
  gate: path.join(__dirname, 'check-call-arguments.js'),
  from: null,
  // 5 values: src `@bpCallee 1, undefined, 3`, src `@bpOpts undefined, face: …` (an implicit object read as its keys
  // would make it a HOLE and fail the control), the harness's `@bpH 1, undefined, 3`, the macro's
  // `@bpCallee 9, undefined, 9`, the script's bpLocal
  pass: /^\[call-arguments\] OK — 0 holes, 0 extra arguments, 0 positionals into options over \d+ calls \(src \d+, harness [1-9]\d*, macros 1, scripts \d+\); 5 absence\(s\) judged values/m,
  control: { plants: src(), args: [valuesRepo], absent: [/HOLE/, /EXTRA_ARGUMENT/, /POSITIONAL_INTO_OPTIONS/] },
  runs: [{
    label: 'the callers test flips a value into a hole: one more site reaching less far',
    plants: src({ 'BpWitness.coffee': WITNESS }),
    args: [valuesRepo],
    expect: { HOLE: /^  \S*BpTarget\.coffee:6  @bpCallee  \[ 1 \| undefined \| 3 \]  — HOLE: \S*BpWitness\.coffee:3 passes 1$/m },
    absent: [/bpOpts/, /bpTrail/, /stringify/, /fn\.call/],
  }, {
    label: 'a hole in the tests repo: a macro and a script',
    plants: src(),
    args: [holesRepo],
    expect: { HOLE: /^  \S*SystemTest_bp_automationCommands\.js:2  new BpButton  \[ undefined \| undefined \| face: "x" \]  — HOLE: \S*SystemTest_bp_automationCommands\.js:3 passes 1$/m },
    lines: [/^  \S*scripts\/s\.js:2  bpLocal  \[ 1 \| undefined \| 3 \]  — HOLE: \S*scripts\/s\.js:3 passes 1$/m,
      /^  \S*BpHarness\.coffee:4  @bpH  \[ 1 \| undefined \| 3 \]  — HOLE: \S*BpHarness\.coffee:5 passes 1$/m],
  }, {
    label: 'src: an extra argument, the swallowed-element spelling, a positional into options',
    plants: src({ 'BpExtra.coffee': EXTRA, 'boot/bp-swallowed.coffee': SWALLOWED }),
    args: [valuesRepo],
    expect: {
      EXTRA_ARGUMENT: /^  \S*BpExtra\.coffee:3  @bpTrail  \[ 1 \| 2 \| 3 \]  — EXTRA_ARGUMENT: passes 3, \S*BpTarget\.coffee:3 declares 2$/m,
      POSITIONAL_INTO_OPTIONS: /^  \S*BpExtra\.coffee:4  new BpButton  \[ 1 \| 2 \| "label" \]  — POSITIONAL_INTO_OPTIONS: argument 3 is a literal, where \S*BpButton\.coffee:2 takes `opts = \{\}`$/m,
    },
    lines: [/^  \S*bp-swallowed\.coffee:3  bpOne  \[ "a" \| bpOne "b" \]  — EXTRA_ARGUMENT: passes 2, \S*bp-swallowed\.coffee:1 declares 1$/m],
    absent: [/Math/],
  }, {
    label: 'the tests repo: an extra argument in the harness and a script, a positional into options in a macro',
    plants: src(),
    args: [arityRepo],
    expect: {
      EXTRA_ARGUMENT: /^  \S*BpHarness\.coffee:4  @bpH  \[ 1 \| 2 \| 3 \| 4 \]  — EXTRA_ARGUMENT: passes 4, \S*BpHarness\.coffee:2 declares 3$/m,
      POSITIONAL_INTO_OPTIONS: /^  \S*SystemTest_bp_automationCommands\.js:2  new BpButton  \[ 1 \| 2 \| @ \]  — POSITIONAL_INTO_OPTIONS: argument 3 is `@`, where \S*BpButton\.coffee:2 takes `opts = \{\}`$/m,
    },
    lines: [/^  \S*scripts\/s\.js:2  bpLocal  \[ 1 \| 2 \| 3 \| 4 \]  — EXTRA_ARGUMENT: passes 4, \S*scripts\/s\.js:1 declares 3$/m],
  }, {
    label: 'a macro that does not parse',
    plants: src(),
    args: [badRepo],
    exit: 2,
    lines: [/SystemTest_bp_automationCommands\.js.*CoffeeScript/, /^\[call-arguments\] INVALID — 1 source\(s\) it cannot read/m],
  }, {
    label: 'a tests repo holding no harness, no macro and no script',
    plants: src(),
    args: [emptyRepo],
    exit: 2,
    lines: [/^\[call-arguments\] INVALID — it read 0 harness file\(s\), 0 macro source\(s\) and 0 script\(s\)/m],
  }],
});
