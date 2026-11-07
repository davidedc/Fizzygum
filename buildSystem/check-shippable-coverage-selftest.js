'use strict';
// check-shippable-coverage-selftest.js — check-shippable-coverage.js proved able to BITE, by running the REAL gate (and
// through it, build.py's --list-shippable) on a planted copy of src/ (lib/planted-src.js): a .coffee file in a
// directory no part claims fails, and so does one in a NEW subdirectory of a claimed one (a part's dirs are not
// recursive); the src/boot/ exemption fails as stale once the copy has no boot dir. A file in a claimed directory and
// one under src/boot/ pass. Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

proveGate({
  name: 'check-shippable-coverage',
  gate: path.join(__dirname, 'check-shippable-coverage.js'),
  pass: /^shippable-coverage check: \d+ \.coffee files under src\/, all covered \(or allowlisted\) — 0 gap\(s\)$/m,
  control: {
    plants: {
      'BiteProofClaimedWdgt.coffee': 'class BiteProofClaimedWdgt extends Widget\n',
      'boot/BiteProofBootOnly.coffee': 'class BiteProofBootOnly\n',
    },
  },
  runs: [{
    label: 'an unclaimed directory and an unclaimed subdirectory',
    plants: {
      'biteproof-unclaimed/BiteProofUnclaimedWdgt.coffee': 'class BiteProofUnclaimedWdgt extends Widget\n',
      'basic-widgets/biteproof-nested/BiteProofNestedWdgt.coffee': 'class BiteProofNestedWdgt extends Widget\n',
    },
    expect: { UNSHIPPED: /^  UNSHIPPED src\/biteproof-unclaimed\/BiteProofUnclaimedWdgt\.coffee$/m },
    lines: [/^  UNSHIPPED src\/basic-widgets\/biteproof-nested\/BiteProofNestedWdgt\.coffee$/m],
  }, {
    label: 'the boot exemption excusing nothing',
    unplant: ['boot'],
    expect: { STALE_ALLOWLIST_PREFIX: /STALE_ALLOWLIST_ENTRY ALLOWLIST_PREFIXES 'src\/boot\/' — it exempts no unshipped \.coffee file/ },
  }],
});
