'use strict';
// check-trailing-whitespace-selftest.js — check-trailing-whitespace.js proved able to BITE, by running the REAL gate on
// a planted copy of src/ (lib/planted-src.js): a line ending in a space, one ending in a tab and a CRLF line with a
// space before its \r each fail it, named by file and line; a line that is only indentation passes. Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

proveGate({
  name: 'check-trailing-whitespace',
  gate: path.join(__dirname, 'check-trailing-whitespace.js'),
  pass: /^\[trailing-whitespace\] OK/m,
  control: { plants: { 'BiteProofIndentOnlyLine.coffee': 'class BiteProofIndentOnlyLine\n  a: -> 1\n    \n  b: -> 2\n' } },
  runs: [{
    label: 'a space, a tab, a CRLF',
    plants: { 'BiteProofTrailingWhitespace.coffee': 'class BiteProofTrailingWhitespace\n  aSpace: -> 1 \n  aTab: -> 2\t\n  aCrlf: -> 3 \r\n' },
    expect: { TRAILING_WHITESPACE: /^  BiteProofTrailingWhitespace\.coffee:2$/m },
    lines: [/^  BiteProofTrailingWhitespace\.coffee:3$/m, /^  BiteProofTrailingWhitespace\.coffee:4$/m],
    absent: [/BiteProofIndentOnlyLine/],
  }],
});
