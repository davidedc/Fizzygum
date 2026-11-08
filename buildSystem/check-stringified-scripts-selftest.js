'use strict';
// check-stringified-scripts-selftest.js — check-stringified-scripts.js proved able to BITE, by running the REAL gate on
// a planted copy of src/ (lib/planted-src.js): a ScriptWdgt built from a """ block, a ''' block, a parenthesised
// block and a one-line string each fail it, and so do a sanction with no reason, one cut off by a blank line, and the
// words of one written after a heredoc's opening quotes (heredoc text, not a comment); the sanction directly above
// (through a second comment line) and on the line itself both pass, counted. Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

const Q3 = '"""';
proveGate({
  name: 'check-stringified-scripts',
  gate: path.join(__dirname, 'check-stringified-scripts.js'),
  pass: /^\[stringified-scripts\] OK/m,
  control: {
    plants: {
      'BiteProofSanctionedScripts.coffee': [
        'class BiteProofSanctionedScripts',
        '  above: ->',
        '    # stringified-script-sanctioned: the bite-proof fixture of check-stringified-scripts-selftest.js',
        '    # a second comment line keeps the block contiguous',
        `    s = new ScriptWdgt ${Q3}`,
        '      1 + 1',
        `    ${Q3}`,
        '  onTheLine: ->',
        '    s = new ScriptWdgt "1 + 1" # stringified-script-sanctioned: the same fixture, on the line',
        '',
      ].join('\n'),
    },
    lines: [/^\[stringified-scripts\] scan done \(2 sanctioned\)\.$/m],
  },
  runs: [{
    label: 'four string spellings and two failed sanctions',
    plants: {
      'BiteProofStringifiedScript.coffee': [
        'class BiteProofStringifiedScript',
        '  triple: ->',
        `    s = new ScriptWdgt ${Q3}`,
        `    ${Q3}`,
        "  single: ->",
        "    s = new ScriptWdgt '''",
        "    '''",
        '  paren: ->',
        `    s = new ScriptWdgt(${Q3}`,
        `    ${Q3})`,
        '  oneLine: ->',
        '    s = new ScriptWdgt "1 + 1"',
        '  emptyReason: ->',
        '    # stringified-script-sanctioned:',
        '    s = new ScriptWdgt "1"',
        '  cutOff: ->',
        '    # stringified-script-sanctioned: separated by a blank line, so it excuses nothing',
        '',
        '    s = new ScriptWdgt "2"',
        '  heredocText: ->',
        `    s = new ScriptWdgt ${Q3} # stringified-script-sanctioned: inside the heredoc, so text, not a marker`,
        `    ${Q3}`,
        '',
      ].join('\n'),
    },
    expect: { STRINGIFIED_SCRIPT: /^  BiteProofStringifiedScript\.coffee:3$/m },
    lines: [6, 9, 12, 15, 19, 21].map((n) => new RegExp(`^  BiteProofStringifiedScript\\.coffee:${n}$`, 'm')),
  }],
});
