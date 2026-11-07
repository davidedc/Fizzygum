'use strict';
// check-plane-discipline-selftest.js — check-plane-discipline.js proved able to BITE, by running the REAL gate on a
// planted copy of src/ (lib/planted-src.js). A: a bare scrollOffset write outside _writeScrollOffset fails, a compound
// `+=` too. B: one more line mixing two receivers' positions takes the count over its baseline; a NOT_POSITIONAL entry
// the derivation no longer catches (the copy's Widget predicate given a parameter) fails as stale; and, in a run of its
// own, a real mixing line rewritten takes the count UNDER the baseline, which fails too (the count is exact). C1: a
// scroll provider's escalated `activated` reading its `pos` fails, in a subclass too; C2: `nonFloatDragging` reading
// its raw screen `pos` unmapped fails. The accepted forms ride the control: the write inside _writeScrollOffset, a
// class-level offset declaration, a comparison; one receiver's own positions; a mapped mix; the escalated-pos marker,
// an `ignored` parameter, a handler that only forwards; a mapped raw position. Run by buildSystem/run-selftests.js on
// every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

const cls = (name, parent, ...body) => [`class ${name} extends ${parent}`, ...body, ''].join('\n');
proveGate({
  name: 'check-plane-discipline',
  gate: path.join(__dirname, 'check-plane-discipline.js'),
  pass: /^\[plane-discipline C\] positions not in the receiver's plane: 0 reads -- OK/m,
  control: {
    plants: {
      'BiteProofPlaneAcceptedWdgt.coffee': cls('BiteProofPlaneAcceptedWdgt', 'Widget',
        '  scrollOffsetX: 0',
        '  _writeScrollOffset: (x) ->', '    @scrollOffsetX = x',
        '  bpSame: (x) ->', '    same = @scrollOffsetX == x',
        '  bpOwn: ->', '    @bpW = @right() - @left()', '    @bpV = @bounds.left() - @left()',
        '  bpMapped: (a, b) ->', '    @bpGap = a.left() - @screenPointToMyPlane(b.left())'),
      'BiteProofPlaneProviderOkWdgt.coffee': cls('BiteProofPlaneProviderOkWdgt', 'Widget',
        '  scrollTranslationOfChild: (child) ->', '    undefined',
        '  bpForward: (pos) ->', '    @escalateEvent "activated", pos',
        '  # escalated-pos-sanctioned: the bite-proof fixture',
        '  doubleActivated: (pos) ->', '    @bpAt = pos',
        '  activated: (ignored) ->', '    @bpAt = 1',
        '  nonFloatDragging: (start, pos, delta) ->', '    @bpAt = @screenPointToMyPlane pos'),
    },
    lines: [/^\[plane-discipline A\] offset funnel: 0 bare writes -- OK$/m, /^\[plane-discipline B\] cross-plane positional mixing: (\d+) \(baseline \1\) -- OK/m],
  },
  runs: [{
    label: 'a bare offset write, a new mix, a stale exclusion, escalated and raw positions read',
    plants: {
      'BiteProofOffsetWriteWdgt.coffee': cls('BiteProofOffsetWriteWdgt', 'Widget', '  bpScrollTo: (x) ->', '    @scrollOffsetX = x', '  bpNudge: (d) ->', '    @scrollOffsetY += d'),
      'BiteProofMixWdgt.coffee': cls('BiteProofMixWdgt', 'Widget', '  bpMix: (a, b) ->', '    @bpGap = a.left() - b.left()'),
      'BiteProofEscalatedPosWdgt.coffee': cls('BiteProofEscalatedPosWdgt', 'Widget',
        '  scrollTranslationOfChild: (child) ->', '    undefined', '  bpForward: (pos) ->', '    @escalateEvent "activated", pos',
        '  activated: (pos) ->', '    @bpAt = pos'),
      'BiteProofEscalatedPosSubWdgt.coffee': cls('BiteProofEscalatedPosSubWdgt', 'BiteProofEscalatedPosWdgt', '  activated: (pos) ->', '    @bpAt = pos'),
      'BiteProofRawScreenPosWdgt.coffee': cls('BiteProofRawScreenPosWdgt', 'Widget', '  nonFloatDragging: (start, pos, delta) ->', '    @bpAt = pos'),
    },
    edits: [['basic-widgets/Widget.coffee', /^  hasMaybeChangedPaintBounds: ->/m, '  hasMaybeChangedPaintBounds: (bp) ->']],
    expect: {
      A_BARE_OFFSET_WRITE: /^    BiteProofOffsetWriteWdgt\.coffee:3: \[in bpScrollTo\] @scrollOffsetX = x$/m,
      B_MIX_ROSE: /^    New mixed-positional line\(s\)/m,
      B_STALE_NOT_POSITIONAL: /NOT_POSITIONAL names 1 method\(s\) the POSITIONAL derivation no longer catches on Widget: hasMaybeChangedPaintBounds — a stale exclusion/,
      C1_ESCALATED_POS: /^    BiteProofEscalatedPosWdgt\.coffee:7: BiteProofEscalatedPosWdgt\.activated reads its escalated 'pos'/m,
      C2_RAW_SCREEN_POS: /^    BiteProofRawScreenPosWdgt\.coffee:3: BiteProofRawScreenPosWdgt\.nonFloatDragging reads the raw screen 'pos' unmapped/m,
    },
    lines: [/^    BiteProofOffsetWriteWdgt\.coffee:5: \[in bpNudge\] @scrollOffsetY \+= d$/m,
            /^    BiteProofMixWdgt\.coffee:3: \[a vs b\] @bpGap = a\.left\(\) - b\.left\(\)$/m,
            /^    BiteProofEscalatedPosSubWdgt\.coffee:3: BiteProofEscalatedPosSubWdgt\.activated reads its escalated 'pos'/m],
  }, {
    label: 'a real mixing line rewritten: the count drops',
    edits: [['fizzytiles/FridgeWdgt.coffee', /m\.rightCenter\(\)\.distanceTo\(aMagnet\.leftCenter\(\)\)/, 'm.distanceTo(aMagnet)']],
    expect: { B_MIX_DROPPED: /^    Count DROPPED — good: lower the baseline to lock it in\./m },
  }],
});
