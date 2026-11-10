'use strict';
// check-shippable-coverage-selftest.js — check-shippable-coverage.js proved able to BITE, by running the REAL gate (and
// through it, build.py's --list-shippable) on planted copies of src/ and of the tests repo's code (lib/planted-src.js;
// the full set is the compiled sources): a .coffee file in a directory no part claims fails, and so do a file in a dot
// directory and a dot file; one in a NEW subdirectory of a claimed directory fails too (a part's dirs are not
// recursive), in src and in the harness; and a src/boot file no part declares (build.py --list-boot) fails. A file in a
// claimed directory, of src and of the harness, passes, and so does every src/boot file the parts declare (the real
// tree's own). Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

proveGate({
  name: 'check-shippable-coverage',
  gate: path.join(__dirname, 'check-shippable-coverage.js'),
  testsRepo: true,
  pass: /^shippable-coverage check: \d+ \.coffee files under src\/ and the harness, all covered — 0 gap\(s\)$/m,
  control: {
    plants: {
      'BiteProofClaimedWdgt.coffee': 'class BiteProofClaimedWdgt extends Widget\n',
      'harness/BiteProofClaimedHarness.coffee': 'class BiteProofClaimedHarness\n',
    },
  },
  runs: [{
    label: 'an unclaimed directory and an unclaimed subdirectory',
    plants: {
      'biteproof-unclaimed/BiteProofUnclaimedWdgt.coffee': 'class BiteProofUnclaimedWdgt extends Widget\n',
      'basic-widgets/biteproof-nested/BiteProofNestedWdgt.coffee': 'class BiteProofNestedWdgt extends Widget\n',
      // a dot directory and a dot file are read like any other (lib/source-files.js), so they fail here, never unseen
      '.biteproof-hidden/BiteProofHidden.coffee': 'class BiteProofHidden\n',
      'basic-widgets/.BiteProofDotFile.coffee': 'class BiteProofDotFile\n',
    },
    expect: { UNSHIPPED: /^  UNSHIPPED src\/biteproof-unclaimed\/BiteProofUnclaimedWdgt\.coffee$/m },
    lines: [/^  UNSHIPPED src\/basic-widgets\/biteproof-nested\/BiteProofNestedWdgt\.coffee$/m,
      /^  UNSHIPPED src\/\.biteproof-hidden\/BiteProofHidden\.coffee$/m, /^  UNSHIPPED src\/basic-widgets\/\.BiteProofDotFile\.coffee$/m],
  }, {
    label: 'a new subdirectory of the harness',
    plants: { 'harness/biteproof-nested/BiteProofNestedHarness.coffee': 'class BiteProofNestedHarness\n' },
    expect: { UNSHIPPED: /^  UNSHIPPED \.\.\/Fizzygum-tests\/Automator-and-test-harness-src\/biteproof-nested\/BiteProofNestedHarness\.coffee$/m },
  }, {
    label: 'a src/boot file no part declares',
    plants: { 'boot/BiteProofBootOnly.coffee': 'biteProofBootOnly = 1\n', 'boot/extensions/BiteProofExtension.coffee': 'x = 1\n' },
    expect: { UNSHIPPED: /^  UNSHIPPED src\/boot\/BiteProofBootOnly\.coffee$/m },
    lines: [/^  UNSHIPPED src\/boot\/extensions\/BiteProofExtension\.coffee$/m],
  }],
});
