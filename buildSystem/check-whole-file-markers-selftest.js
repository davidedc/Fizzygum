'use strict';
// check-whole-file-markers-selftest.js — check-whole-file-markers.js (a tombstone) proved able to BITE, by running the
// REAL gate on a planted copy of src/ (lib/planted-src.js): each retired per-file exclusion comment fails, named by
// file and line; prose QUOTING a marker passes (only the exact comment line is the mechanism). Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

const marked = (cls, marker) => `${marker}\nclass ${cls}\n  a: -> 1\n`;
proveGate({
  name: 'check-whole-file-markers',
  gate: path.join(__dirname, 'check-whole-file-markers.js'),
  pass: /^\[whole-file-markers\] OK/m,
  control: { plants: { 'BiteProofQuotedMarker.coffee': '# the retired "# this file is only needed for Macros" comment\nclass BiteProofQuotedMarker\n' } },
  runs: [{
    label: 'each retired marker',
    plants: {
      'BiteProofWholeFileHomepage.coffee': marked('BiteProofWholeFileHomepage', '# this file is excluded from the fizzygum homepage build'),
      'BiteProofWholeFileMacros.coffee': marked('BiteProofWholeFileMacros', '# this file is only needed for Macros'),
      'BiteProofWholeFileVideo.coffee': marked('BiteProofWholeFileVideo', '# this file is only needed for VideoPlayer'),
    },
    expect: {
      homepage: /^    src\/BiteProofWholeFileHomepage\.coffee:1$/m,
      macros: /^    src\/BiteProofWholeFileMacros\.coffee:1$/m,
      'video-player': /^    src\/BiteProofWholeFileVideo\.coffee:1$/m,
    },
    absent: [/BiteProofQuotedMarker/],
  }],
});
