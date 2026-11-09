'use strict';
// check-coffee-syntax-selftest.js — check-coffee-syntax.js proved able to BITE, by running the REAL gate (its listing
// through build.py --list-shippable --src=, the real meta-compiler, the real boot helper globals) on a planted src
// tree (lib/planted-src.js): a class member that does not parse fails, named by its FILE line; a mixin that does not
// parse fails; members whose compiled head declares a helper the strip cuts (`%%` → modulo, a parameter-default
// temporary → ref) fail, named by class and member. The forms the fragmented compile tolerates — a field set before
// a bare `super`, the three provided helpers (`in`, a slice, `for own`), and a mixin using `%%` (a mixin keeps its
// helpers) — pass; and a harness file's member that does not parse fails, named as the listing names it. The tree is
// src/meta + src/boot + the plants, beside a copy of the tests repo's code: the gate reads the meta-compiler and the
// helper globals from those, and the listing finds the plants where core's part claims the src root and the harness
// part claims the harness. Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { proveGate, SRC } = require('./lib/planted-src');

const base = fs.mkdtempSync(path.join(os.tmpdir(), 'check-coffee-syntax-selftest-'));
process.on('exit', () => fs.rmSync(base, { recursive: true, force: true }));
for (const d of ['meta', 'boot']) fs.cpSync(path.join(SRC, d), path.join(base, d), { recursive: true });

const lines = (...l) => [...l, ''].join('\n');
proveGate({
  name: 'check-coffee-syntax',
  gate: path.join(__dirname, 'check-coffee-syntax.js'),
  from: base,
  testsRepo: true,
  pass: /^syntax check: \d+ files \(\d+ classes, \d+ mixins, \d+ skipped\) — 0 error\(s\); [1-9]\d* class-member fragments checked against the provided helpers \[.*\] — 0 losing a helper$/m,
  control: {
    plants: {
      'BiteProofSyntaxExemptWdgt.coffee': lines('class BiteProofSyntaxExemptWdgt extends Widget', '',
        '  constructor: ->', '    @biteProofField = 1', '    super', '',
        '  biteProofIndexOf: (a) ->', '    1 in a', '', '  biteProofSlice: (a) ->', '    a[1..]', '',
        '  biteProofHasProp: (o) ->', '    (k for own k of o)'),
      'BiteProofHelperExemptMixin.coffee': lines('BiteProofHelperExemptMixin =', '',
        '  onceAddedClassProperties: (fromClass) ->', '    @addInstanceProperties fromClass,', '',
        '      biteProofModulo: (a, b) ->', '        a %% b'),
    },
  },
  runs: [{
    label: 'a member and a mixin that do not parse, two members losing a helper',
    plants: {
      'BiteProofParseErrorWdgt.coffee': lines('class BiteProofParseErrorWdgt extends Widget', '',
        '  biteProofOk: ->', '    1', '', '  biteProofBroken: ->', '    if (', '    2'),
      'BiteProofParseErrorMixin.coffee': lines('BiteProofParseErrorMixin =', '',
        '  onceAddedClassProperties: (fromClass) ->', '    @addInstanceProperties fromClass,', '',
        '      biteProofBroken: ->', '        if (', '        2'),
      'BiteProofHelperLossWdgt.coffee': lines('class BiteProofHelperLossWdgt extends Widget', '',
        '  biteProofModulo: (a, b) ->', '    a %% b', '', '  biteProofTemp: (c = @color ? @fallback()) ->', '    c'),
    },
    expect: {
      PARSE_ERROR: /^FAIL src\/BiteProofParseErrorWdgt\.coffee \(8:\d+\)$/m,
      LOST_HELPER: /^FAIL src\/BiteProofHelperLossWdgt\.coffee  BiteProofHelperLossWdgt\.biteProofModulo: its compiled form declares `modulo`/m,
    },
    lines: [/^FAIL src\/BiteProofParseErrorMixin\.coffee \(8:\d+\)$/m,
            /^FAIL src\/BiteProofHelperLossWdgt\.coffee  BiteProofHelperLossWdgt\.biteProofTemp: its compiled form declares `ref`/m],
  }, {
    label: 'a harness file: a member that does not parse',
    plants: { 'harness/BiteProofHarnessParseError.coffee': lines('class BiteProofHarnessParseError', '',
      '  biteProofBroken: ->', '    if (', '    2') },
    expect: { PARSE_ERROR: /^FAIL \.\.\/Fizzygum-tests\/Automator-and-test-harness-src\/BiteProofHarnessParseError\.coffee \(5:\d+\)$/m },
  }],
});
