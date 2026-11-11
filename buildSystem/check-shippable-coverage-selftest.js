'use strict';
// check-shippable-coverage-selftest.js — check-shippable-coverage.js proved able to BITE, by running the REAL gate (and
// through it, build.py's --list-shippable) on planted copies of src/ and of the tests repo's code (lib/planted-src.js;
// the full set is the compiled sources): a .coffee file in a directory no part claims fails, and so do a file in a dot
// directory and a dot file; one in a NEW subdirectory of a claimed directory fails too (a part's dirs are not
// recursive), in src and in the harness; and a src/boot file no part declares (build.py --list-boot) fails. A file in a
// claimed directory, of src and of the harness, passes, and so does every src/boot file the parts declare (the real
// tree's own). And boot's by-name fetches: a fetch renamed in globalFunctions alone fails both ways (a name no part
// declares, a declared script nothing fetches), while a comment naming a retired script passes. Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

proveGate({
  name: 'check-shippable-coverage',
  gate: path.join(__dirname, 'check-shippable-coverage.js'),
  testsRepo: true,
  pass: /^shippable-coverage check: \d+ \.coffee files under src\/ and the harness, all covered — 0 gap\(s\); \d+ boot fetch\(es\) of \d+ declared boot script\(s\), all agreeing$/m,
  control: {
    plants: {
      'BiteProofClaimedWdgt.coffee': 'class BiteProofClaimedWdgt extends Widget\n',
      'harness/BiteProofClaimedHarness.coffee': 'class BiteProofClaimedHarness\n',
    },
    // a COMMENT naming a script is no fetch: it neither satisfies the rule nor trips it
    edits: [['boot/globalFunctions.coffee', /^/, '# a comment naming js/src/biteproof-retired-min.js is no fetch\n']],
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
  }, {
    label: 'a boot fetch renamed on one side only',
    edits: [['boot/globalFunctions.coffee', /js\/src\/logging-div-min\.js/, 'js/src/biteproof-renamed-min.js']],
    expect: {
      BOOT_FETCH_UNDECLARED: /^  BOOT_FETCH_UNDECLARED src\/boot\/globalFunctions\.coffee:\d+ fetches js\/src\/biteproof-renamed-min\.js, which no bootScript of its own part \(core\) declares$/m,
      BOOT_SCRIPT_UNFETCHED: /^  BOOT_SCRIPT_UNFETCHED src\/boot\/logging-div\.coffee \(a bootScript of core\) is fetched by no code line of its part's boot files as js\/src\/logging-div-min\.js$/m,
    },
  }],
});
