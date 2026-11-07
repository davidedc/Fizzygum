'use strict';
// check-relayout-repaints-selftest.js — check-relayout-repaints.js (a tombstone) proved able to BITE, by running the REAL
// gate on a planted copy of src/ (lib/planted-src.js): each retired suppression verb fails, and so does a spelling
// that only contains one (`_disableTrackChanges`); the control is the copy plus the REAL harness src, which the gate
// reads beside it, and its pass line counts both. Run by buildSystem/run-selftests.js on every build.

const fs = require('fs');
const path = require('path');
const { proveGate, SRC } = require('./lib/planted-src');

const coffeeIn = (dir) => fs.readdirSync(dir, { recursive: true }).filter((f) => String(f).endsWith('.coffee')).length;
const HARNESS = path.resolve(__dirname, '../../Fizzygum-tests/Automator-and-test-harness-src');
const expected = coffeeIn(SRC) + (fs.existsSync(HARNESS) ? coffeeIn(HARNESS) : 0);

proveGate({
  name: 'check-relayout-repaints',
  gate: path.join(__dirname, 'check-relayout-repaints.js'),
  pass: new RegExp(`^\\[relayout-repaints\\] OK -- ${expected} file\\(s\\)`, 'm'),
  runs: [{
    label: 'both retired verbs and a renamed one',
    plants: { 'BiteProofRetiredSuppression.coffee': 'class BiteProofRetiredSuppression\n  a: ->\n    world.disableTrackChanges()\n    world.maybeEnableTrackChanges()\n    @_disableTrackChanges()\n' },
    expect: { RETIRED_VERB: /^  \/.*\/BiteProofRetiredSuppression\.coffee:3  world\.disableTrackChanges\(\)$/m },
    lines: [/BiteProofRetiredSuppression\.coffee:4  world\.maybeEnableTrackChanges\(\)$/m, /BiteProofRetiredSuppression\.coffee:5  @_disableTrackChanges\(\)$/m],
  }],
});
