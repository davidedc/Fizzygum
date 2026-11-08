'use strict';
// check-layering-selftest.js — check-layering.js proved able to BITE, rule by rule, by running the REAL gate on a
// planted copy of src/ (lib/planted-src.js). One planted run carries a throwaway class per rule (each violation
// matched on its OWN line, naming the plant); a second run makes each exemption table stale by editing the real
// holders it excuses in the copy (anchored, so a holder that moved fails loudly); a third points [D]'s whole-file
// half at a planted tests dir. The control is the unplanted copy plus every sanctioned form, which must pass. Run by
// buildSystem/run-selftests.js on every build.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { proveGate } = require('./lib/planted-src');

const cls = (name, ...body) => [`class ${name} extends Widget`, ...body, ''].join('\n');
const at = (file, n) => `src/${file}.coffee:${n}`;
const line = (head, file, n) => new RegExp(`^  ${head.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}.*  — ${at(file, n).replace(/\./g, '\\.')}$`, 'm');
const Q3 = '"""';

// [D]'s whole-file half reads the tests repo's macro sources: a planted tests dir with one test holding a private call
const testsDir = fs.mkdtempSync(path.join(os.tmpdir(), 'check-layering-selftest-tests-'));
process.on('exit', () => fs.rmSync(testsDir, { recursive: true, force: true }));
fs.mkdirSync(path.join(testsDir, 'SystemTest_BiteProofMacro'));
fs.writeFileSync(path.join(testsDir, 'SystemTest_BiteProofMacro', 'SystemTest_BiteProofMacro_automationCommands.js'),
  'var SystemTest_BiteProofMacro_automationCommands = { "mainMacroSource": `\n  w = world.firstChild()\n  w._biteProofTestsHalfCall()\n` };\n');

proveGate({
  name: 'check-layering',
  gate: path.join(__dirname, 'check-layering.js'),
  pass: /^layering gate: \d+ source\(s\) \+ \d+ macro\(s\) — 0 violations/m,
  control: {
    plants: {
      'BiteProofSanctionedLayeringWdgt.coffee': cls('BiteProofSanctionedLayeringWdgt',
        '  _biteProofLowLevelCanvas: (ctx) ->', '    ctx.moveTo 0, 0',
        '  doOneCycle: ->', '    world.recalculateLayouts()',
        '  biteProofHandler: ->', '    # layout-apply-sanctioned: the bite-proof fixture', '    @_reLayoutChildren()',
        '  _biteProofLowLevelSanctioned: (w) ->', '    # nosettle-sanctioned: the bite-proof fixture', '    @add w',
        '  biteProofGuardedWrapper: (v) ->', '    return if v', '    # early-return-sanctioned: the bite-proof fixture',
        '    @_settleLayoutsAfter => @_biteProofCoreNoSettle()',
        '  _biteProofCoreNoSettle: ->', '    @bpValue = 1',
        '  _reactToBeingBiteProofedQuietly: ->', '    @_biteProofCoreNoSettle()',
        '  _reactToChildBiteProofed: ->',
        '  fullBiteProofBounds: ->', '  _commitBiteProofAndNotify: ->',
        '  _announceBiteProofElsewhere: ->',
        '  nonFloatDragging: ->', '    @_setExtentDeferredSettle new Point 1, 1',
        '  _biteProofPConnector: (v) ->', '    @_settleLayoutsAfterOrJoinEnclosingPass => @_biteProofCoreNoSettle()',
        '  recalculateOutput: ->', '    @_biteProofPConnector 1',
        '  biteProofSanctionedDouble: (w) ->', '    @_settleLayoutsAfter => @_biteProofCoreNoSettle()', '    @setExtent new Point 5, 5',
        '    # double-settle-sanctioned: the bite-proof fixture'),
    },
    edits: [['macros/MacroToolkit.coffee', /\s*$/, `\n\n  biteProofSanctionedMacros: ->\n    Macro.fromString ${Q3}\n      w._biteProofOracleA()   # macro-private-call-sanctioned: the bite-proof fixture, on the line\n      # macro-private-call-sanctioned: the bite-proof fixture, the line above\n      w._biteProofOracleB()\n    ${Q3}\n`],
            ['basic-widgets/menu-system/MenusHelper.coffee', /\s*$/, '\n\n  biteProofUserlandSanctioned: (w) ->\n    w._biteProofSanctionedCore()   # private-use-sanctioned: the bite-proof fixture\n    @_biteProofOwnCore()\n    this._biteProofOwnCore()\n']],
  },
  runs: [{
    label: 'one class per rule',
    plants: {
      'BiteProofAWdgt.coffee': cls('BiteProofAWdgt',
        '  _biteProofLowLevelSetter: ->', '    @setExtent new Point 10, 10',
        '  _biteProofLowLevelText: (s) ->', '    s.setText "bite"',
        '  _biteProofLowLevelRecalc: ->', '    world.recalculateLayouts()',
        '  _biteProofOneLiner: (p) -> @setExtent p'),
      'BiteProofBWdgt.coffee': cls('BiteProofBWdgt', '  biteProofRecalc: ->', '    world.recalculateLayouts()'),
      'BiteProofHeregexWdgt.coffee': cls('BiteProofHeregexWdgt', '  biteProofAfterHeregex: ->', "    r = ///'''///", '    world.recalculateLayouts()'),
      'BiteProofCWdgt.coffee': cls('BiteProofCWdgt', '  setWidth: (w) ->', '    super', '    @setExtent new Point w, 10'),
      'BiteProofEWdgt.coffee': cls('BiteProofEWdgt', '  _moveLeftSideTo: (x) ->', '    @_invalidateLayout()', '  _moveRightSideTo: (x) ->', '    @_scheduleRelayoutRespectingPhase()'),
      'BiteProofFWdgt.coffee': cls('BiteProofFWdgt', '  biteProofHandler: ->', '    @_reLayoutChildren()'),
      'BiteProofGWdgt.coffee': cls('BiteProofGWdgt',
        '  biteProofSettlingWrapper: ->', '    @_settleLayoutsAfter => @_biteProofCoreNoSettle()',
        '  biteProofSharedName: ->', '    @_settleLayoutsAfter => @_biteProofCoreNoSettle()',
        '  _biteProofCoreNoSettle: ->', '    @bpValue = 1',
        '  _biteProofLowLevelWrapper: ->', '    @biteProofSettlingWrapper()',
        '  _biteProofLowLevelDotted: (w) ->', '    w.biteProofSharedName()',
        '  _biteProofLowLevelAdd: (w) ->', '    @add w'),
      'BiteProofGPlainWdgt.coffee': cls('BiteProofGPlainWdgt', '  biteProofSharedName: ->', '    1', '  _biteProofLowLevelPlainSelf: ->', '    @biteProofSharedName()'),
      'BiteProofHWdgt.coffee': cls('BiteProofHWdgt', '  biteProofThinWrapper: (v) ->', '    return if v', '    @_settleLayoutsAfter => @_biteProofHCoreNoSettle()', '  _biteProofHCoreNoSettle: ->', '    @bpValue = 1'),
      'BiteProofIWdgt.coffee': cls('BiteProofIWdgt', '  __biteProofLeaf: ->', '    @_invalidateLayout()'),
      'BiteProofJWdgt.coffee': cls('BiteProofJWdgt', '  _reactToBeingBiteProofed: ->', '    @_settleLayoutsAfter => @_biteProofJCoreNoSettle()', '  _biteProofJCoreNoSettle: ->', '    @bpValue = 1'),
      'BiteProofKWdgt.coffee': cls('BiteProofKWdgt',
        '  _applyMoveToBase: (p) ->', '    @_reFitContainerBiteProof()',
        '  _applyExtentBase: (e) ->', '    @_changed()',
        '  _applyMoveByBase: (d) ->', '    @_applyMoveBy d',
        '  _commitBounds: (b) ->', '    @_changed()'),
      'BiteProofLWdgt.coffee': cls('BiteProofLWdgt', '  _reactToBeingBiteProofedNoSettle: ->', '  _reactToBiteProof: ->', '  justBeenBiteProofed: ->'),
      'BiteProofMWdgt.coffee': cls('BiteProofMWdgt', '  rawBiteProofGeometry: ->', '  _applyBiteProofAndNotify: ->'),
      'BiteProofNWdgt.coffee': cls('BiteProofNWdgt', '  _announceBiteProofToContainer: ->'),
      'BiteProofOWdgt.coffee': cls('BiteProofOWdgt', '  biteProofDiscrete: ->', '    @_setExtentDeferredSettle new Point 1, 1'),
      'BiteProofPWdgt.coffee': cls('BiteProofPWdgt', '  biteProofJoiner: ->', '    @_settleLayoutsAfterOrJoinEnclosingPass => @_biteProofPCoreNoSettle()', '  _biteProofPCoreNoSettle: ->', '    @bpValue = 1'),
      'BiteProofQWdgt.coffee': cls('BiteProofQWdgt', '  biteProofConnectorCaller: ->', '    @_biteProofQConnector 1'),
      'BiteProofTWdgt.coffee': cls('BiteProofTWdgt',
        '  biteProofTWrapper: ->', '    @_settleLayoutsAfter => @_biteProofTCoreNoSettle()',
        '  _biteProofTCoreNoSettle: ->', '    @bpValue = 1',
        '  biteProofDoubleSettle: (w) ->', '    @_settleLayoutsAfter => @_biteProofTCoreNoSettle()',
        '    @setExtent new Point 5, 5', '    @setText "x"', '    @biteProofTWrapper()', '    @add w'),
    },
    edits: [
      // [D] the toolkit's heredoc half: a private call, a raw* call, a marker with no reason, and a marker ending one
      // heredoc that must not excuse the first call of the next
      ['macros/MacroToolkit.coffee', /\s*$/, `\n\n  biteProofMacros: ->\n    Macro.fromString ${Q3}\n      biteProofPrivateCall_Macro = (w) ->\n        w._biteProofPrivateVerb()\n        w.rawBiteProofPixel()\n        w._biteProofBareMarker()   # macro-private-call-sanctioned:\n        q = "#"; w._biteProofAfterHashCall()\n        # macro-private-call-sanctioned: ends this heredoc\n    ${Q3}\n  biteProofMacrosNext: ->\n    Macro.fromString ${Q3}\n      w._biteProofLeakedSanction()\n    ${Q3}\n`],
      // [R] the userland exemplar reaching into a private
      ['basic-widgets/menu-system/MenusHelper.coffee', /\s*$/, '\n\n  biteProofUserland: (w) ->\n    w._biteProofPrivateCore()\n'],
    ],
    expect: {
      A_PUBLIC_SETTER: line('[A] low-level _biteProofLowLevelSetter() calls public setter .setExtent()', 'BiteProofAWdgt', 3),
      A_TEXT_SETTER: line('[A] low-level _biteProofLowLevelText() calls self-settling text setter .setText()', 'BiteProofAWdgt', 5),
      A_RECALC: line('[A] low-level _biteProofLowLevelRecalc() calls recalculateLayouts()', 'BiteProofAWdgt', 7),
      B_RECALC_CALLER: line('[B] recalculateLayouts() called from biteProofRecalc()', 'BiteProofBWdgt', 3),
      C_SETTER_CALLS_SETTER: line('[C] public setter setWidth() calls another public setter .setExtent()', 'BiteProofCWdgt', 4),
      D_MACRO_PRIVATE_CALL: /^  \[D\] macro calls private\/low-level \._biteProofPrivateVerb\(\) — \S*\/macros\/MacroToolkit\.coffee:\d+ /m,
      E_MUTATOR_INVALIDATES: line('[E] immediate mutator _moveLeftSideTo() calls _invalidateLayout()', 'BiteProofEWdgt', 3),
      E_MUTATOR_VALVE: line('[E] immediate mutator _moveRightSideTo() calls _scheduleRelayoutRespectingPhase()', 'BiteProofEWdgt', 5),
      F_OFF_SETTLE_APPLY: line('[F] off-settle synchronous layout apply ._reLayoutChildren() in biteProofHandler()', 'BiteProofFWdgt', 3),
      G_SETTLING_WRAPPER: line('[G] low-level _biteProofLowLevelWrapper() calls self-settling wrapper @biteProofSettlingWrapper()', 'BiteProofGWdgt', 9),
      G_SELF_ADD: line('[G] low-level _biteProofLowLevelAdd() calls @add (self == Widget.add)', 'BiteProofGWdgt', 13),
      I_LEAF_ORCHESTRATES: line('[I] __ leaf __biteProofLeaf() @-calls _invalidateLayout()', 'BiteProofIWdgt', 3),
      J_HOOK_SETTLES: line('[J] notification hook _reactToBeingBiteProofed() calls _settleLayoutsAfter', 'BiteProofJWdgt', 3),
      K_TWIN_SEAM: line('[K] bypass twin _applyMoveToBase() fires the re-fit seam', 'BiteProofKWdgt', 3),
      K_TWIN_DISPATCH: line('[K] bypass twin _applyMoveByBase() dispatches to polymorphic _applyMoveBy()', 'BiteProofKWdgt', 7),
      K_COMMIT_REACTS: line('[K] commit corner _commitBounds() reacts via _changed()', 'BiteProofKWdgt', 9),
      L_CALLBACK_NOSETTLE: line('[L] callback _reactToBeingBiteProofedNoSettle() carries NoSettle', 'BiteProofLWdgt', 2),
      L_MALFORMED_CALLBACK: line('[L] malformed callback _reactToBiteProof()', 'BiteProofLWdgt', 3),
      L_LEGACY_CALLBACK_FRAGMENT: line('[L] legacy callback fragment justBeenBiteProofed()', 'BiteProofLWdgt', 4),
      M_RETIRED_FRAGMENT: line('[M] retired naming fragment rawBiteProofGeometry()', 'BiteProofMWdgt', 2),
      M_RETIRED_ANDNOTIFY: line('[M] retired apply-notify suffix _applyBiteProofAndNotify()', 'BiteProofMWdgt', 3),
      N_RETIRED_SEAM_VERB: line('[N] retired container-seam verb _announceBiteProofToContainer()', 'BiteProofNWdgt', 2),
      O_DEFERRED_SETTLE_CALLER: line('[O] biteProofDiscrete() calls _setExtentDeferredSettle() outside the deferred-settle-caller allowlist', 'BiteProofOWdgt', 3),
      P_JOIN_LANE_CALLER: line('[P] biteProofJoiner() calls _settleLayoutsAfterOrJoinEnclosingPass() but is not a _<name>Connector entrypoint', 'BiteProofPWdgt', 3),
      Q_CONNECTOR_CALLER: line('[Q] biteProofConnectorCaller() calls _biteProofQConnector() outside the connector-caller allowlist', 'BiteProofQWdgt', 3),
      R_USERLAND_PRIVATE: /^  \[R\] userland biteProofUserland\(\) reaches into a private: w\._biteProofPrivateCore\(\) — .*  — src\/basic-widgets\/menu-system\/MenusHelper\.coffee:\d+$/m,
      T_DOUBLE_SETTLE: /^  \[T\] biteProofDoubleSettle\(\) self-settles \(src\/BiteProofTWdgt\.coffee:7\) AND @-calls settling public setter @setExtent\(\) — .*  — src\/BiteProofTWdgt\.coffee:8$/m,
    },
    lines: [
      // the one-liner's inline body is read, and every second spelling of a rule its own line
      line('[A] low-level _biteProofOneLiner() calls public setter .setExtent()', 'BiteProofAWdgt', 8),
      line('[B] recalculateLayouts() called from _biteProofLowLevelRecalc()', 'BiteProofAWdgt', 7),
      /^  \[G\] low-level _biteProofLowLevelDotted\(\) calls self-settling wrapper \.biteProofSharedName\(\) — .*NB.*BiteProofGPlainWdgt.*  — src\/BiteProofGWdgt\.coffee:11$/m,
      /^  \[D\] macro calls private\/low-level \.rawBiteProofPixel\(\)/m,
      /^  \[D\] macro calls private\/low-level \._biteProofBareMarker\(\)/m,
      /^  \[D\] macro calls private\/low-level \._biteProofLeakedSanction\(\)/m,
      /^  \[D\] macro calls private\/low-level \._biteProofAfterHashCall\(\)/m,
      line('[B] recalculateLayouts() called from biteProofAfterHeregex()', 'BiteProofHeregexWdgt', 4),
      /^  \[T\] biteProofDoubleSettle\(\) self-settles .* AND @-calls settling text setter @setText\(\)/m,
      /^  \[T\] biteProofDoubleSettle\(\) self-settles .* AND @-calls settling wrapper @biteProofTWrapper\(\)/m,
      /^  \[T\] biteProofDoubleSettle\(\) self-settles .* AND @-calls settling @add \(self == Widget\.add\)/m,
      /^  \[H\] biteProofThinWrapper\(\) has a guard return at src\/BiteProofHWdgt\.coffee:3 BEFORE its _settleLayoutsAfter/m,
    ],
    absent: [/_biteProofLowLevelPlainSelf/, /_applyExtentBase/],
  }, {
    label: 'every exemption table excusing nothing',
    edits: [
      ...['VerticalStackPanelWdgt', 'FrameWdgt', 'IconGridPanelWdgt', 'basic-widgets/ViewportWdgt', 'basic-widgets/Widget',
        'authoring/StretchableWidgetContainerWdgt', 'app-kit/ToolPanelWdgt'].map((f) => [`${f}.coffee`, /^  add(\s*:)/m, '  addBiteProofRenamed$1']),
      ['HandleWdgt.coffee', /DeferredSettle\b/g, 'DeferredSettleBiteProofStale'],
      ['StackElementsSizeAdjustingWdgt.coffee', /DeferredSettle\b/g, 'DeferredSettleBiteProofStale'],
      ...['authoring/CalculatingPatchNodeWdgt', 'patch-programming-experimental/RegexSubstitutionPatchNodeWdgt',
        'patch-programming-experimental/DiffingPatchNodeWdgt'].map((f) => [`${f}.coffee`, /\._setTextConnector\b/g, '._setTextBiteProofStaleCall']),
      ['basic-widgets/Widget.coffee', /(\n  _applyExtent:[\s\S]*?)@_scheduleRelayoutRespectingPhase\(\)/, '$1@_biteProofRenamedValve()'],
    ],
    unplant: ['basic-widgets/menu-system/MenusHelper.coffee'],
    expect: {
      G_STALE_WRAPPER_EXCLUDED: /^  \[G\] STALE_ALLOWLIST_ENTRY WRAPPER_EXCLUDED 'add' — /m,
      O_STALE_CALLER_ALLOWLIST: /^  \[O\] STALE_ALLOWLIST_ENTRY DEFERRED_SETTLE_CALLER_ALLOWLIST 'nonFloatDragging' — /m,
      Q_STALE_CALLER_ALLOWLIST: /^  \[Q\] STALE_ALLOWLIST_ENTRY CONNECTOR_CALLER_ALLOWLIST 'recalculateOutput' — /m,
      E_STALE_VALVE_EXEMPTION: /^  \[E\] STALE_ALLOWLIST_ENTRY the schedule-valve exemption Widget\._applyExtent — /m,
      R_STALE_USERLAND_FILES: /^  \[R\] STALE_ALLOWLIST_ENTRY USERLAND_FILES 'src\/basic-widgets\/menu-system\/MenusHelper\.coffee' — /m,
    },
  }, {
    label: "[D]'s whole-file half over a planted tests dir",
    args: ['--tests-dir=' + testsDir],
    expect: { D_MACRO_PRIVATE_CALL: /^  \[D\] macro calls private\/low-level \._biteProofTestsHalfCall\(\) — \S*SystemTest_BiteProofMacro_automationCommands\.js:3 /m },
  }],
});
