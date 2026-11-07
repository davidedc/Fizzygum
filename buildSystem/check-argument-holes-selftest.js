'use strict';
// check-argument-holes-selftest.js — check-argument-holes.js proved able to BITE, by running the REAL gate on a planted
// src tree (lib/planted-src.js). The gate is a RATCHET, so the tree is built to its baseline (read from the gate, never
// restated): the control holds exactly BASELINE holes, one per line, and passes with its OK line; the planted run adds
// ONE more and fails, naming the new site. The forms that are not holes — a trailing `undefined`, a foreign API's
// this-arg (`.call undefined`), a commented call, a multi-line call ending in `undefined` — ride the planted run and
// must not be counted (the FAIL line says BASELINE + 1 exactly). The tree is small on purpose: the gate reads only
// the .coffee files under its rail, and the real tree's 2 sites are value-`undefined`s the baseline already counts.
// Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const path = require('path');
const { proveGate } = require('./lib/planted-src');

const BASELINE = Number(/^const BASELINE = (\d+);/m.exec(fs.readFileSync(path.join(__dirname, 'check-argument-holes.js'), 'utf8'))[1]);
const holes = (cls, n) => [`class ${cls}`, '  callee: (a, b) -> b', '  callers: ->',
  ...Array.from({ length: n }, (_, i) => `    @callee undefined, ${i}`), ''].join('\n');
const notHoles = ['class BiteProofNotHoles', '  callee: (a, b) -> b', '  callers: ->',
  '    @callee 1, undefined', '    fn.call undefined, 1', '    # @callee undefined, 1', '    @callee(1,', '      undefined)', ''].join('\n');

proveGate({
  name: 'check-argument-holes',
  gate: path.join(__dirname, 'check-argument-holes.js'),
  from: null,
  pass: new RegExp(`^\\[argument-holes\\] OK — ${BASELINE} site\\(s\\) \\(baseline ${BASELINE}\\)\\.$`, 'm'),
  control: { plants: { 'BiteProofBaselineHoles.coffee': holes('BiteProofBaselineHoles', BASELINE) } },
  runs: [{
    label: 'one hole over the baseline',
    plants: {
      'BiteProofBaselineHoles.coffee': holes('BiteProofBaselineHoles', BASELINE),
      'BiteProofNewHole.coffee': holes('BiteProofNewHole', 1),
      'BiteProofNotHoles.coffee': notHoles,
    },
    expect: { OVER_BASELINE: /^  \S*\/BiteProofNewHole\.coffee:4  callee  \[ undefined \| 0 \]$/m },
    lines: [new RegExp(`^\\[argument-holes\\] FAIL — ${BASELINE + 1} site\\(s\\), baseline ${BASELINE}\\.$`, 'm')],
    absent: [/BiteProofNotHoles/],
  }],
});
