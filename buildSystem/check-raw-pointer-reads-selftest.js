'use strict';
// check-raw-pointer-reads-selftest.js — check-raw-pointer-reads.js proved able to BITE, by running the REAL gate on a
// planted copy of src/ and of the tests repo's harness (lib/planted-src.js). A dispatched handler, and a drag-scroll
// consumer named in EXTRA_HANDLER_NAMES, reading world.hand.position() unmapped fail, named — and so does one whose
// sanction marker sits in the PREVIOUS method's body, or that follows a string holding `#` on its line, or that lives in
// a harness file (named harness/<path>); an EXTRA_HANDLER_NAMES entry no
// class defines fails as stale. The handler table is
// held against ActivePointerWdgt both ways, so the copy's dispatcher is edited (each edit anchored) until every kind of
// disagreement fires: a table name it never names, a position handed to a name the table lacks, a plane position
// handed to a handler the table says takes none, a POSITION_QUERIES entry no longer handed one, a plane handler no
// dispatch maps for; and the dispatcher gone altogether. Mapping on the line, the marker above the header (a blank
// line between), a read in a helper or a comment, and a dispatch named in the dispatcher's comment after a regex holding
// a quote pass. Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

const cls = (name, ...body) => [`class ${name} extends Widget`, ...body, ''].join('\n');
const APW = 'ActivePointerWdgt.coffee';
proveGate({
  name: 'check-raw-pointer-reads',
  gate: path.join(__dirname, 'check-raw-pointer-reads.js'),
  testsRepo: true,
  pass: /^  raw-pointer-reads gate OK — \d+ pointer-handler bodies scanned, 1 exempt, 0 raw reads\.$/m,
  control: {
    plants: {
      'BiteProofMappedPointerWdgt.coffee': cls('BiteProofMappedPointerWdgt',
        '  pressBegan: (pos) ->', '    @bpAt = @screenPointToMyPlane world.hand.position()', '    # world.hand.position() in a comment',
        '  # raw-screen-pointer-sanctioned: the bite-proof fixture', '',
        '  pressEnded: (pos) ->', '    @bpAt = world.hand.position()',
        '  bpHelper: ->', '    @bpAt = world.hand.position()'),
    },
    edits: [[APW, /\s*$/, '\n\n  bpCommentAfterRegex: (w) ->\n    q = /"/ # w.bpUnlistedHandler @_pointerPositionInPlaneOf w\n']],
  },
  runs: [{
    label: 'raw reads, a marker in the wrong body, a stale extra name',
    plants: {
      'BiteProofRawPointerWdgt.coffee': cls('BiteProofRawPointerWdgt',
        '  pressBegan: (pos) ->', '    @bpAt = world.hand.position()',
        '  takeStrokeScrollFrom: (p) ->', '    @bpAt = world.hand.position()',
        '  bpHelper: ->', '    # raw-screen-pointer-sanctioned: inside the previous body, so it exempts nothing', '    x = 1',
        '  pressEnded: (pos) ->', '    @bpAt = world.hand.position()', '    q = "#"; @bpAt = world.hand.position()'),
    },
    edits: [['basic-widgets/ViewportWdgt.coffee', /^  latchStrokeScroll(\s*:)/m, '  latchStrokeScrollBiteProofRenamed$1']],
    expect: {
      RAW_READ: /^  \[raw-pointer\] BiteProofRawPointerWdgt\.pressBegan reads world\.hand\.position\(\) unmapped — src\/BiteProofRawPointerWdgt\.coffee:3$/m,
      STALE_EXTRA_HANDLER_NAME: /^  STALE_ALLOWLIST_ENTRY EXTRA_HANDLER_NAMES 'latchStrokeScroll' — /m,
    },
    lines: [/^  \[raw-pointer\] BiteProofRawPointerWdgt\.takeStrokeScrollFrom reads .* — src\/BiteProofRawPointerWdgt\.coffee:5$/m,
            /^  \[raw-pointer\] BiteProofRawPointerWdgt\.pressEnded reads .* — src\/BiteProofRawPointerWdgt\.coffee:10$/m,
            /^  \[raw-pointer\] BiteProofRawPointerWdgt\.pressEnded reads .* — src\/BiteProofRawPointerWdgt\.coffee:11$/m],
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessRawPointerWdgt.coffee': cls('BiteProofHarnessRawPointerWdgt', '  pressBegan: (pos) ->', '    @bpAt = world.hand.position()') },
    expect: { RAW_READ: /^  \[raw-pointer\] BiteProofHarnessRawPointerWdgt\.pressBegan reads world\.hand\.position\(\) unmapped — harness\/BiteProofHarnessRawPointerWdgt\.coffee:3$/m },
  }, {
    label: 'the handler table disagreeing with the dispatcher, every way',
    edits: [
      [APW, /\bscrolledBy\b/g, 'scrolledByBiteProofRenamed'],
      [APW, /wdgt\.dockSideAt wdgt\.screenPointToMyPlane @position\(\)/, 'wdgt.dockSideAt @position()'],
      [APW, /w\.tripleActivated @_pointerPositionInPlaneOf\(w\)/, 'w.tripleActivated()'],
      [APW, /\s*$/, '\n\n  bpTableProbe: (w) ->\n    w.bpUnlistedHandler @_pointerPositionInPlaneOf w\n    w.hoverEntered @_pointerPositionInPlaneOf w\n'],
    ],
    expect: {
      TABLE_UNKNOWN_NAME: /^  'scrolledBy' is in the handler table but ActivePointerWdgt never names it/m,
      TABLE_UNLISTED_DISPATCH: /^  ActivePointerWdgt hands a pointer position to 'bpUnlistedHandler', which the handler table does not know/m,
      TABLE_POS_MISMATCH: /^  ActivePointerWdgt hands 'hoverEntered' a plane-mapped position, but the table says pos=none$/m,
      TABLE_STALE_POSITION_QUERY: /^  POSITION_QUERIES lists 'dockSideAt', which ActivePointerWdgt no longer hands a position/m,
      TABLE_UNMAPPED_PLANE_HANDLER: /^  the table says 'tripleActivated' is handed a plane-mapped position, but no dispatch of it/m,
    },
  }, {
    label: 'the dispatcher gone',
    unplant: [APW],
    expect: { TABLE_SOURCE_MISSING: /^  ActivePointerWdgt\.coffee not found at \S+ — the handler table cannot be checked$/m },
  }],
});
