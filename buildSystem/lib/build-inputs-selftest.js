'use strict';
// build-inputs-selftest.js — the build's record holds its inputs to what each was: compareRecords, the pure core of
// buildStaleness, over planted record lines. Its ship gate: no change of an input (its time, its size, its presence,
// its name) reads as unchanged, and an unchanged record reads as no change.
const { compareRecords } = require('./build-inputs');
const t = require('./selftest-verdict').cases('build-inputs-selftest');

const base = ['Fizzygum/src/A.coffee\t100.5\t10', 'Fizzygum/src/B.coffee\t200\t20', 'Fizzygum/font-assets/f.js\t300\t30'];
const cases = [
  ['unchanged', base, base, { changed: [], added: [], removed: [] }],
  ['an edit (newer time)', base, ['Fizzygum/src/A.coffee\t150\t10', base[1], base[2]], { changed: ['Fizzygum/src/A.coffee'], added: [], removed: [] }],
  ['put back with an OLDER time', base, ['Fizzygum/src/A.coffee\t50\t10', base[1], base[2]], { changed: ['Fizzygum/src/A.coffee'], added: [], removed: [] }],
  ['same time, another size', base, [base[0], 'Fizzygum/src/B.coffee\t200\t21', base[2]], { changed: ['Fizzygum/src/B.coffee'], added: [], removed: [] }],
  ['deleted', base, [base[0], base[1]], { changed: [], added: [], removed: ['Fizzygum/font-assets/f.js'] }],
  ['added with an old time', base, [...base, 'Fizzygum/font-assets/g.js\t1\t30'], { changed: [], added: ['Fizzygum/font-assets/g.js'], removed: [] }],
  ['renamed', base, ['Fizzygum/src/A2.coffee\t100.5\t10', base[1], base[2]], { changed: [], added: ['Fizzygum/src/A2.coffee'], removed: ['Fizzygum/src/A.coffee'] }],
  ['order does not matter', base, [base[2], base[0], base[1]], { changed: [], added: [], removed: [] }],
];
for (const [label, recorded, current, want] of cases) {
  const got = compareRecords(recorded, current);
  t.check(JSON.stringify(got) === JSON.stringify(want), label, 'got ' + JSON.stringify(got) + ' wanted ' + JSON.stringify(want));
}
t.done();
