'use strict';
// check-relayout-repaints-selftest.js — check-relayout-repaints.js (a tombstone) proved able to BITE, by running the REAL
// gate on a planted copy of src/ and of the tests repo's harness (lib/planted-src.js): each retired suppression verb
// fails, and so does a spelling that only contains one (`_disableTrackChanges`), and so does a retired verb in a harness
// file, named by its path in the harness copy (the gate prints absolute paths); the control is the copy plus the copy
// of the REAL harness src, which the gate reads beside it, and its pass line counts both. Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate, SRC } = require('./lib/planted-src');
const { compiledFiles } = require('./lib/source-files');

const expected = compiledFiles({ src: SRC }).length;

proveGate({
  name: 'check-relayout-repaints',
  gate: path.join(__dirname, 'check-relayout-repaints.js'),
  testsRepo: true,
  pass: new RegExp(`^\\[relayout-repaints\\] OK -- ${expected} file\\(s\\)`, 'm'),
  runs: [{
    label: 'both retired verbs and a renamed one',
    plants: { 'BiteProofRetiredSuppression.coffee': 'class BiteProofRetiredSuppression\n  a: ->\n    world.disableTrackChanges()\n    world.maybeEnableTrackChanges()\n    @_disableTrackChanges()\n' },
    expect: { RETIRED_VERB: /^  \/.*\/BiteProofRetiredSuppression\.coffee:3  world\.disableTrackChanges\(\)$/m },
    lines: [/BiteProofRetiredSuppression\.coffee:4  world\.maybeEnableTrackChanges\(\)$/m, /BiteProofRetiredSuppression\.coffee:5  @_disableTrackChanges\(\)$/m],
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessRetiredSuppression.coffee': 'class BiteProofHarnessRetiredSuppression\n  a: ->\n    world.disableTrackChanges()\n' },
    expect: { RETIRED_VERB: /^  \/.*\/Automator-and-test-harness-src\/BiteProofHarnessRetiredSuppression\.coffee:3  world\.disableTrackChanges\(\)$/m },
  }],
});
