'use strict';
// check-stinks-selftest.js — check-stinks.js proved able to BITE, by running the REAL gate on a planted copy of src/
// and of the tests repo's harness (lib/planted-src.js). Every stink is a ratchet, so the plant is sized from the counts
// the CONTROL prints: one file at the src root carries, per stink, (baseline − count + 1) lines of a spelling only that
// stink matches — each stink then FAILS, its own hit lines naming the plant — a code stink also after a string holding
// `#` on its line, while a string that only mentions it, or holds a comment's words, is no hit. A sanctioned member holding one literal more than its entry says fails as
// SANCTION COUNT; in a second run, the sanctioned file deleted fails as STALE SANCTION and an excluded directory deleted
// fails as a stale exclude; in a third, a harness file carrying (baseline − count + 1) `nil` lines fails nil-literal,
// its hit lines named harness/<path>. Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

// one spelling per stink, each hitting that stink alone (comment stinks read the comment, the rest the code)
const PLANT = {
  'debugger-statement': 'debugger',
  'nil-literal': 'bpNil = nil',
  'null-literal': 'bpNull = null',
  'wall-clock': 'bpT = Date.now()',
  'timer': 'setTimeout (-> 1), 0',
  'math-random': 'bpR = Math.random()',
  'instanceof-type-test': 'bpI = bpX instanceof Widget',
  'raw-chrome-color': 'bpC = new Color 1, 2, 3',
  'comment-meta-edit': '# to be clear, the bite-proof plant',
  'comment-narration': '# this used to be the bite-proof plant',
  'commented-out-debug': '# debugger',
  'comment-past-receipt': '# formerly the bite-proof plant',
};
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

proveGate({
  name: 'check-stinks',
  gate: path.join(__dirname, 'check-stinks.js'),
  testsRepo: true,
  pass: /^\[stinks\] OK -- all stinks within baseline\.$/m,
  runs: (control) => {
    const counts = new Map([...control.out.matchAll(/^\[stinks\] (\S+): (\d+) site\(s\) \(baseline (\d+)\)/gm)].map((m) => [m[1], Number(m[3]) - Number(m[2]) + 1]));
    const lines = ['class BiteProofStinks', '  bpAll: ->'];
    for (const [id, text] of Object.entries(PLANT)) for (let k = 0; k < Math.max(1, counts.get(id) || 1); k++) lines.push('    ' + text);
    lines.push('    bpH = "#"; bpNullAfterHash = null', '    bpS = "null"', '    bpQ = "# this used to be text, not a comment"');
    return [{
      label: 'every stink over its baseline, a sanction miscounted',
      plants: { 'BiteProofStinks.coffee': lines.join('\n') + '\n' },
      edits: [['WorldWdgt.coffee', /^(  _showDamageRects: \(aContext\) ->\n)/m, '$1    bpC = new Color 1, 2, 3\n']],
      expect: {
        ...Object.fromEntries(Object.entries(PLANT).map(([id, text]) => [id, new RegExp(`^    BiteProofStinks\\.coffee:\\d+: ${esc(text)}$`, 'm')])),
        SANCTION_COUNT: /^    SANCTION COUNT WorldWdgt\.coffee::_showDamageRects — expects 1, found 2/m,
      },
      lines: [/^    BiteProofStinks\.coffee:\d+: bpH = "#"; bpNullAfterHash = null$/m],
      absent: [/BiteProofStinks\.coffee:\d+: bpS = "null"$/m, /BiteProofStinks\.coffee:\d+: bpQ = "# this used to be/m],
    }, {
      label: 'a sanctioned file and an excluded directory deleted',
      unplant: ['ColorPickerWdgt.coffee', 'examples-icons'],
      expect: {
        STALE_SANCTION: /^    STALE SANCTION \(STALE_ALLOWLIST_ENTRY\) ColorPickerWdgt\.coffee::constructor — no hit left there/m,
        STALE_EXCLUDE: /^    STALE_ALLOWLIST_ENTRY exclude 'examples-icons\/' — no src path starts with it/m,
      },
    }, {
      label: 'a harness file',
      plants: { 'harness/BiteProofHarnessStinks.coffee': ['class BiteProofHarnessStinks', '  bpAll: ->',
        ...Array.from({ length: Math.max(1, counts.get('nil-literal') || 1) }, () => `    ${PLANT['nil-literal']}`), ''].join('\n') },
      expect: { 'nil-literal': new RegExp(`^    harness/BiteProofHarnessStinks\\.coffee:3: ${esc(PLANT['nil-literal'])}$`, 'm') },
    }];
  },
});
