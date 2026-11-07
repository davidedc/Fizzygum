'use strict';
// check-argument-holes-selftest.js — check-argument-holes.js proved able to BITE, by running the REAL gate on a planted
// fixture (lib/planted-src.js): a src tree holding the real meta/Class.coffee + meta/Mixin.coffee (the gate reads
// classes through the browser's own meta-compiler) and fixture classes, and a fixture TESTS REPO per run, named by the
// run's `--tests-repo=` (the check-layering-selftest.js precedent for a second tree).
//   control — only VALUES and forms that are no hole: `@bpCallee 1, undefined, 3` beside `@bpCallee 4, 5, 6` (every
//     site fills the list), a trailing `undefined`, a string holding "undefined, then 1", a `.call undefined` this-arg,
//     a foreign `JSON.stringify s, undefined, 2`, `@bpOpts undefined, face: 2, tip: 3` beside `@bpOpts 1, face: 4` (an
//     implicit object is ONE argument: both reach 2 — a reader counting its keys would call it a hole), and a tests
//     repo whose macro and script hold values only;                                         → OK
//   the callers test FLIPS that value: the control plus one more site, `@bpCallee 8`       → HOLE, naming the witness
//   a hole in the tests repo: a macro's `new BpButton undefined, undefined, face: "x"` beside `new BpButton face: "y"`,
//     a script's `bpLocal(1, undefined, 3)` beside `bpLocal(1)`, a harness class's `@bpH 1, undefined, 3` beside
//     `@bpH 1`                                                                               → HOLE in each file
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
  ''].join('\n');
const BUTTON = ['class BpButton', '  constructor: (a, b, opts = {}) ->', '    @a = a', ''].join('\n');
const WITNESS = ['class BpWitness', '  callers: ->', '    @bpCallee 8', ''].join('\n');
const src = (extra = {}) => Object.assign({ 'BpTarget.coffee': TARGET, 'BpButton.coffee': BUTTON }, meta, extra);

// fixture tests repos, each a harness dir + tests/ + scripts/
const repos = [];
const HARNESS = 'Automator-and-test-harness-src/BpHarness.coffee';
const harness = (body) => ['class BpHarness', '  bpH: (a, b, c) -> a', '  callers: ->', ...body.map((l) => '    ' + l), ''].join('\n');
const repo = (files) => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'check-argument-holes-selftest-repo-'));
  repos.push(dir);
  fs.mkdirSync(path.join(dir, 'Automator-and-test-harness-src'), { recursive: true });
  fs.mkdirSync(path.join(dir, 'tests'), { recursive: true });
  for (const [rel, text] of Object.entries(files)) { const p = path.join(dir, rel); fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, text); }
  return '--tests-repo=' + dir;
};
process.on('exit', () => { for (const d of repos) fs.rmSync(d, { recursive: true, force: true }); });
const macro = (body) => 'var c = { "mainMacroSource": `m_Macro = ->\n' + body + '\n` };\n';
const MACRO = 'tests/SystemTest_bp/SystemTest_bp_automationCommands.js';
const valuesRepo = repo({
  [HARNESS]: harness(['@bpH 1, undefined, 3', '@bpH 4, 5, 6']),
  [MACRO]: macro('  @bpCallee 9, undefined, 9'),
  'scripts/s.js': 'function bpLocal(a, b, c) { return a; }\nbpLocal(1, undefined, 3);\nbpLocal(4, 5, 6);\n',
});
const holesRepo = repo({
  [HARNESS]: harness(['@bpH 1, undefined, 3', '@bpH 1']),
  [MACRO]: macro('  x = new BpButton undefined, undefined, face: "x"\n  y = new BpButton face: "y"'),
  'scripts/s.js': 'function bpLocal(a, b, c) { return a; }\nbpLocal(1, undefined, 3);\nbpLocal(1);\n',
});
const badRepo = repo({ [HARNESS]: harness(['@bpH 1, 2, 3']), [MACRO]: macro('  f ('), 'scripts/s.js': 'ok();\n' });
const emptyRepo = repo({});

proveGate({
  name: 'check-argument-holes',
  gate: path.join(__dirname, 'check-argument-holes.js'),
  from: null,
  // 5 values: src `@bpCallee 1, undefined, 3`, src `@bpOpts undefined, face: …` (an implicit object read as its keys
  // would make it a HOLE and fail the control), the harness's `@bpH 1, undefined, 3`, the macro's
  // `@bpCallee 9, undefined, 9`, the script's bpLocal
  pass: /^\[argument-holes\] OK — 0 holes over \d+ calls \(src \d+, harness [1-9]\d*, macros 1, scripts \d+\); 5 absence\(s\) judged values/m,
  control: { plants: src(), args: [valuesRepo], absent: [/HOLE/] },
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
    label: 'a macro that does not parse',
    plants: src(),
    args: [badRepo],
    exit: 2,
    lines: [/SystemTest_bp_automationCommands\.js.*CoffeeScript/, /^\[argument-holes\] INVALID — 1 source\(s\) it cannot read/m],
  }, {
    label: 'a tests repo holding no harness, no macro and no script',
    plants: src(),
    args: [emptyRepo],
    exit: 2,
    lines: [/^\[argument-holes\] INVALID — it read 0 harness file\(s\), 0 macro source\(s\) and 0 script\(s\)/m],
  }],
});
