'use strict';
// check-source-vault-selftest.js — check-source-vault.js (a tombstone) proved able to BITE, by running the REAL gate on
// a planted copy of src/ and of the tests repo's harness (lib/planted-src.js): the retired `_coffeSource` identifier
// fails anywhere, a harness file included (named harness/<path>); a scan of the window's own keys fails in src/boot,
// with and without parentheses; the exemption fails as stale when its file is gone, and when the file holds no hit
// left to excuse. The same scan OUTSIDE src/boot, and a boot scan of a table hung on the window, pass. Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

proveGate({
  name: 'check-source-vault',
  gate: path.join(__dirname, 'check-source-vault.js'),
  testsRepo: true,
  pass: /^\[source-vault\] OK/m,
  control: {
    plants: {
      'BiteProofWindowScanOutsideBoot.coffee': 'class BiteProofWindowScanOutsideBoot\n  a: ->\n    names = Object.keys(window)\n',
      'boot/BiteProofBootTableScan.coffee': 'class BiteProofBootTableScan\n  a: ->\n    names = Object.keys(window.FIZZYGUM_PARTS)\n',
    },
  },
  runs: [{
    label: 'the identifier, the boot scan, the exempt file gone',
    plants: {
      'BiteProofCoffeSource.coffee': 'class BiteProofCoffeSource\n  a: ->\n    x = window.Widget_coffeSource\n',
      'boot/BiteProofBootScan.coffee': 'class BiteProofBootScan\n  a: ->\n    names = Object.keys window\n  b: ->\n    names = Object.keys(window)\n',
    },
    unplant: ['boot/source-vault.coffee'],
    expect: {
      'coffeSource-global': /^    src\/BiteProofCoffeSource\.coffee:3: x = window\.Widget_coffeSource$/m,
      'boot-window-key-scan': /^    src\/boot\/BiteProofBootScan\.coffee:3: names = Object\.keys window$/m,
      STALE_EXEMPT_MISSING: /STALE_ALLOWLIST_ENTRY EXEMPT 'src\/boot\/source-vault\.coffee': no such src file/,
    },
    lines: [/^    src\/boot\/BiteProofBootScan\.coffee:5: names = Object\.keys\(window\)$/m],
  }, {
    label: 'the exempt file excusing nothing',
    plants: { 'boot/source-vault.coffee': 'class SourceVault\n' },
    expect: { STALE_EXEMPT_UNUSED: /STALE_ALLOWLIST_ENTRY EXEMPT 'src\/boot\/source-vault\.coffee': the file holds no hit/ },
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessCoffeSource.coffee': 'class BiteProofHarnessCoffeSource\n  a: ->\n    x = window.Widget_coffeSource\n' },
    expect: { 'coffeSource-global': /^    harness\/BiteProofHarnessCoffeSource\.coffee:3: x = window\.Widget_coffeSource$/m },
  }],
});
