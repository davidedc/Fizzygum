'use strict';
// check-region-markers-selftest.js — check-region-markers.js (a tombstone) proved able to BITE, by running the REAL gate
// on a planted copy of src/ and of the tests repo's harness (lib/planted-src.js): an opener of each retired kind fails,
// named by file and line, an opener that never closes fails as unpaired, and a »>> marker of no known kind fails as
// unknown, in src and in a harness file (named harness/<path>) alike; prose ABOUT the mechanism passes. Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

const region = (cls, opener, closed = true) =>
  [`class ${cls}`, `  # »>> ${opener}`, '  a: -> 1', ...(closed ? ['  # «'] : []), ''].join('\n');

proveGate({
  name: 'check-region-markers',
  gate: path.join(__dirname, 'check-region-markers.js'),
  testsRepo: true,
  pass: /^\[region-markers\] OK/m,
  control: { plants: { 'BiteProofRegionProse.coffee': 'class BiteProofRegionProse\n  # the retired »>> region markers are described here\n  a: -> 1\n' } },
  runs: [{
    label: 'each kind, an unpaired opener, an unknown marker',
    plants: {
      'BiteProofRegionHomepage.coffee': region('BiteProofRegionHomepage', 'this part is excluded from the fizzygum homepage build'),
      'BiteProofRegionMacros.coffee': region('BiteProofRegionMacros', 'this part is only needed for Macros'),
      'BiteProofRegionVideo.coffee': region('BiteProofRegionVideo', 'this part is only needed for VideoPlayer'),
      'BiteProofRegionUnpaired.coffee': region('BiteProofRegionUnpaired', 'this part is only needed for Macros', false),
      'BiteProofRegionUnknown.coffee': region('BiteProofRegionUnknown', 'this part is only needed for Demos'),
    },
    expect: {
      homepage: /^    BiteProofRegionHomepage\.coffee:2$/m,
      macros: /^    BiteProofRegionMacros\.coffee:2$/m,
      videoplayer: /^    BiteProofRegionVideo\.coffee:2$/m,
      UNPAIRED_OPENER: /^  BiteProofRegionUnpaired\.coffee:2 \(macros\)$/m,
      UNKNOWN_MARKER: /^  BiteProofRegionUnknown\.coffee:2$/m,
    },
    lines: [/homepage=1\/0 macros=2\/0 videoplayer=1\/0$/m],
    absent: [/BiteProofRegionProse/],
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessRegionUnknown.coffee': region('BiteProofHarnessRegionUnknown', 'this part is only needed for Demos') },
    expect: { UNKNOWN_MARKER: /^  harness\/BiteProofHarnessRegionUnknown\.coffee:2$/m },
  }],
});
