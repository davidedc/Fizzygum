'use strict';
// check-invalidation-receivers-selftest.js — check-invalidation-receivers.js proved able to BITE, by running the REAL
// gate on a planted copy of src/ (lib/planted-src.js): reaching over to invalidate another widget fails — in the
// private spelling, the legacy public one, the world's paint executor, with a sanction marker that gives no
// reason, and after a string holding `#` on its line; the paint executor renamed away fails the gate as STALE. The sanction on the line and directly above, and
// a self-call written `@` or `this`, pass. Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

proveGate({
  name: 'check-invalidation-receivers',
  gate: path.join(__dirname, 'check-invalidation-receivers.js'),
  pass: /invalidation-receivers gate OK/,
  control: {
    plants: {
      'BiteProofSanctionedInvalidationWdgt.coffee': [
        'class BiteProofSanctionedInvalidationWdgt extends Widget',
        '  onTheLine: (other) ->',
        '    other._changed()   # cross-invalidation-sanctioned: the bite-proof fixture, on the line',
        '  above: (other) ->',
        '    # cross-invalidation-sanctioned: the bite-proof fixture, directly above',
        '    other._fullChanged()',
        '  selfCalls: ->',
        '    @_changed()',
        '    this._fullChanged()',
        '',
      ].join('\n'),
    },
  },
  runs: [{
    label: 'four reaching-over spellings',
    plants: {
      'BiteProofInvalidationWdgt.coffee': [
        'class BiteProofInvalidationWdgt extends Widget',
        '  reachOver: (other) ->',
        '    other._changed()',
        '  legacy: (other) ->',
        '    other.fullChanged()',
        '  executor: ->',
        '    world._repaintDamagedRects()',
        '  bareMarker: (other) ->',
        '    other._changed()   # cross-invalidation-sanctioned:',
        '  afterHashString: (other) ->',
        '    label = "#"; other._changed()',
        '',
      ].join('\n'),
    },
    expect: { CROSS_INVALIDATION: /^  \[invalidation\] src\/BiteProofInvalidationWdgt\.coffee:3 — `other\._changed\(\)` invalidates another widget$/m },
    lines: [
      /^  \[invalidation\] src\/BiteProofInvalidationWdgt\.coffee:5 — `other\.fullChanged\(\)`/m,
      /^  \[invalidation\] src\/BiteProofInvalidationWdgt\.coffee:7 — `world\._repaintDamagedRects\(\)`/m,
      /^  \[invalidation\] src\/BiteProofInvalidationWdgt\.coffee:9 — `other\._changed\(\)`/m,
      /^  \[invalidation\] src\/BiteProofInvalidationWdgt\.coffee:11 — `other\._changed\(\)`/m,
    ],
    absent: [/BiteProofSanctionedInvalidationWdgt/],
  }, {
    label: 'the paint executor renamed away',
    edits: [['WorldWdgt.coffee', /^  _repaintDamagedRects(\s*:)/m, '  _repaintDamagedRectsBiteProofRenamed$1']],
    expect: { STALE_PAINT_EXECUTOR: /STALE — WorldWdgt\.coffee defines no _repaintDamagedRects/ },
  }],
});
