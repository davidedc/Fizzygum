'use strict';
// check-doc-narration-selftest.js — check-doc-narration.js (the gauntlet refs leg's docs ratchet) proved able to BITE,
// by running the REAL gate on a planted docs tree (lib/planted-src.js, --docs=): a present-tense doc carrying one line
// of each narration shape fails, every line named with its rule (an inline-code Thing included); the forms the rules
// leave alone ride the control — a dated provenance stamp, a `narration-ok` line, a fenced block, inline code, and
// the same narration in a chronological bucket the gate does not scan. BACKLOG.md's closed items the same way: a
// closed task item under each bullet shape (nested, `*` with `[X]`, numbered, quoted) fails, each named; open items at
// two depths, a `- [x]` named inside a line, one in a fenced block and `[x]` glued to its text ride the control; a tree
// with no BACKLOG.md is INVALID. Run by buildSystem/run-selftests.js on every build.

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
// the open-items index every run needs (a tree without one is no pass): two open items, and prose naming a closed one
const BACKLOG = ['# Backlog', '- [ ] An open plant.', '  - [ ] A nested open plant.', 'A line that names a - [x] item.',
  '- [x]glued, not a task item', '```', '- [x] A fenced plant.', '```', ''].join('\n');

proveGate({
  name: 'check-doc-narration',
  gate: path.join(__dirname, 'check-doc-narration.js'),
  from: null,
  rail: '--docs=',
  pass: /^OK — 1 docs in architecture\/tooling; 0 narration line\(s\), baseline 0; BACKLOG\.md 2 open item\(s\), 0 closed\.$/m,
  control: {
    plants: {
      'BACKLOG.md': BACKLOG,
      'architecture/bite-proof-clean.md': ['# Clean', 'The plant was removed, as measured 2026-01-02.',
        'This line used to say more. <!-- narration-ok: the bite-proof fixture -->', '```', 'The plant was removed.', '```',
        'Run `the plant used to` here.', ''].join('\n'),
      'specs/bite-proof-chronological.md': 'The plant used to be here, and was removed.\n',
    },
  },
  runs: [{
    label: 'one narration line per rule',
    plants: {
      'BACKLOG.md': BACKLOG,
      'architecture/bite-proof-narration.md': ['# Narration', ...ids.map((id) => LINES[id]), 'Use the old-`Plant` here.', ''].join('\n'),
    },
    expect: Object.fromEntries(ids.map((id, k) => [id, new RegExp(`^  ${esc(DOC)}:${k + 2}  \\[[^\\]]+\\]  …${esc(LINES[id])}$`, 'm')])),
    lines: [new RegExp(`^  ${esc(DOC)}:${ids.length + 2}  \\[the then-/old-<Thing>\\]  …Use the old- here\\.$`, 'm')],
  }, {
    label: 'a closed task item in BACKLOG.md under each bullet shape',
    plants: {
      'architecture/bite-proof-clean.md': '# Clean\n',
      'BACKLOG.md': ['# Backlog', '- [ ] An open plant.', '- [x] A closed plant.', '  - [x] A nested closed plant.',
        '* [X] A starred plant.', '1. [x] A numbered plant.', '> -\t[x] A quoted plant.', ''].join('\n'),
    },
    expect: { BACKLOG_CLOSED_ITEM: /^  docs\/BACKLOG\.md:3  \[closed item\]  …- \[x\] A closed plant\.$/m },
    lines: [
      /^  docs\/BACKLOG\.md:4  \[closed item\]  …- \[x\] A nested closed plant\.$/m,
      /^  docs\/BACKLOG\.md:5  \[closed item\]  …\* \[X\] A starred plant\.$/m,
      /^  docs\/BACKLOG\.md:6  \[closed item\]  …1\. \[x\] A numbered plant\.$/m,
      /^  docs\/BACKLOG\.md:7  \[closed item\]  …> -\t\[x\] A quoted plant\.$/m,
      /^BACKLOG HOLDS CLOSED ITEMS — 5 line\(s\):$/m,
    ],
  }, {
    label: 'a docs tree with no BACKLOG.md',
    plants: { 'architecture/bite-proof-clean.md': '# Clean\n' },
    exit: 2,
    lines: [/^\[doc-narration\] ERROR — no .*BACKLOG\.md: a run that cannot read the open-items index checked nothing there — no pass$/m],
  }],
});
