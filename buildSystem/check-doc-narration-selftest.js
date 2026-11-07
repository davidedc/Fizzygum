'use strict';
// check-doc-narration-selftest.js — check-doc-narration.js (the gauntlet refs leg's docs ratchet) proved able to BITE,
// by running the REAL gate on a planted docs tree (lib/planted-src.js, --docs=): a present-tense doc carrying one line
// of each narration shape fails, every line named with its rule (an inline-code Thing included); the forms the rules
// leave alone ride the control — a dated provenance stamp, a `narration-ok` line, a fenced block, inline code, and
// the same narration in a chronological bucket the gate does not scan. Run by buildSystem/run-selftests.js on every
// build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

// one line per rule, each matching that rule alone (the gate takes a line's FIRST matching rule)
const LINES = {
  USED_TO: 'This path used to be the plant.',
  LONG_SAID: 'The plant long said otherwise.',
  WAS_REWORDED: 'The plant was reworded.',
  PAST_TENSE_CHANGE: 'The plant was removed.',
  FORMERLY: 'The plant is formerly a thing.',
  SINCE_PARTICIPLE: 'The plant, since retired.',
  EXECUTED_DATE: 'Executed 2026 by the plant.',
  VERB_DATE: 'The plant landed 2026-01-02.',
  UNTIL_SINCE_DATE: 'The plant until 2026-01-02 held.',
  IN_MONTH_YEAR: 'The plant in March 2026 held.',
  THE_THEN_OLD_THING: 'Use the old-Plant here.',
};
const DOC = 'docs/architecture/bite-proof-narration.md';
const ids = Object.keys(LINES);
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

proveGate({
  name: 'check-doc-narration',
  gate: path.join(__dirname, 'check-doc-narration.js'),
  from: null,
  rail: '--docs=',
  pass: /^OK — 1 docs in architecture\/tooling; 0 narration line\(s\), baseline 0\.$/m,
  control: {
    plants: {
      'architecture/bite-proof-clean.md': ['# Clean', 'The plant was removed, as measured 2026-01-02.',
        'This line used to say more. <!-- narration-ok: the bite-proof fixture -->', '```', 'The plant was removed.', '```',
        'Run `the plant used to` here.', ''].join('\n'),
      'specs/bite-proof-chronological.md': 'The plant used to be here, and was removed.\n',
    },
  },
  runs: [{
    label: 'one narration line per rule',
    plants: {
      'architecture/bite-proof-narration.md': ['# Narration', ...ids.map((id) => LINES[id]), 'Use the old-`Plant` here.', ''].join('\n'),
    },
    expect: Object.fromEntries(ids.map((id, k) => [id, new RegExp(`^  ${esc(DOC)}:${k + 2}  \\[[^\\]]+\\]  …${esc(LINES[id])}$`, 'm')])),
    lines: [new RegExp(`^  ${esc(DOC)}:${ids.length + 2}  \\[the then-/old-<Thing>\\]  …Use the old- here\\.$`, 'm')],
  }],
});
