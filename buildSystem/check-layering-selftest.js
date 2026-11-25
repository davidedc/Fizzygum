'use strict';
// check-layering-selftest.js — check-layering.js proved able to BITE, rule by rule, by running the REAL gate on a
// planted copy of src/ and of the tests repo's code (lib/planted-src.js). One planted run carries a throwaway class per
// rule (each violation matched on its OWN line, naming the plant); a second run makes each exemption table stale by
// editing the real holders it excuses in the copy (anchored, so a holder that moved fails loudly); a third plants an [A]
// violation in a harness file, named harness/<path>; a fourth points [D]'s whole-file half at a planted tests dir. The
// control is the unplanted copy plus every sanctioned form, which must pass. Each run prints the advice of the rules it
// fires that carry a row, each row once (lib/gate-advice.js), and the stale tables none. [A] and [G]'s settling-call
// marker excuses its one line, on it or on the comment lines right above it, and only with a reason; every call it
// excuses is counted against the ceiling -- the last two runs, sized from the control's count, are where a marked call
// is seen passing and a second call on a marked line is seen counting, since a tree at its ceiling cannot carry one
// more in the control -- and a marker marking no settling call (a blank line below it included) is stale. It is the one
// form either half takes: the retired per-method [G] sign-off excuses nothing. A member tested for presence is no call,
// to [A] [G] [C] or [T], whichever way the test ends or goes on (the control's probes); a soak call is one, an inline if
// as its argument included (the first run). Run by buildSystem/run-selftests.js on every build.

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
fs.writeFileSync(path.join(testsDir, 'SystemTest_BiteProofMacro', 'SystemTest_BiteProofMacro.js'), 'var SystemTest_BiteProofMacro = {};\n');
fs.writeFileSync(path.join(testsDir, 'SystemTest_BiteProofMacro', 'SystemTest_BiteProofMacro_automationCommands.js'),
  'var SystemTest_BiteProofMacro_automationCommands = { "mainMacroSource": `\n  w = world.firstChild()\n  w._biteProofTestsHalfCall()\n` };\n');
// the same tests dir with a directory that is no test (lib/tests-repo-code.js testNames refuses it): [D] cannot read it
const malformedTestsDir = fs.mkdtempSync(path.join(os.tmpdir(), 'check-layering-selftest-malformed-'));
process.on('exit', () => fs.rmSync(malformedTestsDir, { recursive: true, force: true }));
fs.cpSync(testsDir, malformedTestsDir, { recursive: true });
fs.mkdirSync(path.join(malformedTestsDir, 'scratch'));

proveGate({
  name: 'check-layering',
  gate: path.join(__dirname, 'check-layering.js'),
  testsRepo: true,
  pass: /^layering gate: \d+ source\(s\) \+ \d+ macro\(s\) — 0 violations/m,
  control: {
    plants: {
      'BiteProofSanctionedLayeringWdgt.coffee': cls('BiteProofSanctionedLayeringWdgt',
        '  _biteProofLowLevelCanvas: (ctx) ->', '    ctx.moveTo 0, 0',
        '  doOneCycle: ->', '    world.recalculateLayouts()',
        '  biteProofHandler: ->', '    # layout-apply-sanctioned: the bite-proof fixture', '    @_reLayoutChildren()',
        // a member named and tested for presence is no call, to either half: a wrapper's and a text setter's (a
        // one-liner's body), a geometry setter's and @add's
        '  _biteProofPresenceProbe: (w) -> w.close? and w.setText?',
        '  _biteProofPresenceProbes: (w) ->', '    if w.setExtent? then @add?',
        // ... and every way a test of presence ends or goes on: a closing bracket or a separator, an operator
        '  _biteProofPresenceEnds: (w) ->', '    x = [(w.close?), w.setText?, {a: w.setExtent?}, w.close?]; y = @add?; @bpValue = x',
        '  _biteProofPresenceOperators: (w) ->', '    w.close? or w.setText? is true or w.setExtent? isnt false',
        '    w.setExtent? && @add? || w.close? == w.setText? != true',
        // [C] and [T] read a presence test as no call too
        '  setHeight: (h) ->', '    super', '    @bpValue = h if @setExtent?',
        '  biteProofSettlingProbe: ->', '    @_settleLayoutsAfter => @_biteProofCoreNoSettle()',
        '    @bpValue = 2 if @setExtent? and @setText? and @biteProofGuardedWrapper? and @add?',
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
  runs: (control) => [{
    label: 'one class per rule',
    plants: {
      'BiteProofAWdgt.coffee': cls('BiteProofAWdgt',
        '  _biteProofLowLevelSetter: ->', '    @setExtent new Point 10, 10',
        '  _biteProofLowLevelText: (s) ->', '    s.setText "bite"',
        '  _biteProofLowLevelRecalc: ->', '    world.recalculateLayouts()',
        '  _biteProofOneLiner: (p) -> @setExtent p'),
      // [A][G]'s marker: excusing nothing on a line with no settling call, in a method neither half judges, and overtaken
      // by a second marker before any code; and a marker with no reason, which excuses nothing in either half
      'BiteProofAGMarkerWdgt.coffee': cls('BiteProofAGMarkerWdgt',
        '  _biteProofStaleMarker: ->', '    # settling-call-sanctioned: the bite-proof fixture, above a line with no settling call', '    @bpValue = 1',
        '  biteProofPublicMarked: ->', '    @setExtent new Point 1, 1   # settling-call-sanctioned: the bite-proof fixture, in a method neither half judges',
        '  _biteProofOvertaken: ->', '    # settling-call-sanctioned: the bite-proof fixture, overtaken', '    # settling-call-sanctioned: the bite-proof fixture, overtaking', '    @bpValue = 2',
        '  _biteProofBareMarkerA: (w) ->', '    w.setText "b"   # settling-call-sanctioned:',
        '  _biteProofBareMarkerG: (w) ->', '    # settling-call-sanctioned', '    @add w',
        // the line scope: a marker above a block marks the block's head, not the call inside it; and a blank line
        // between a marker and its call leaves it marking nothing
        '  _biteProofMarkerOverBlock: (w) ->', '    # settling-call-sanctioned: the bite-proof fixture, above a block', '    if w?', '      w.setText "d"',
        '  _biteProofMarkerOverBlank: (w) ->', '    # settling-call-sanctioned: the bite-proof fixture, a blank line below', '', '    w.setText "e"',
        // a soak call still calls (a wrapper's, a text setter's with an argument), and so does the call beside a
        // presence test of the same member; and the retired per-method [G] sign-off excuses nothing, on its line or below
        '  _biteProofSoakCall: (w) ->', '    w.close?()', '    w.setText? "f"',
        '  _biteProofPresenceThenCall: (w) ->', '    w.close? and w.close()',
        '  _biteProofRetiredSignOff: (w) ->', '    # nosettle-sanctioned: the bite-proof fixture, a retired token', '    @add w', '    w.close()',
        // a soak call whose argument is an inline if, which the `? if` / `? unless` starting it must not hide
        '  _biteProofInlineIfSoak: (w, c) ->', '    w.setText? if c then "a" else "b"', '    w.close? unless c then 1 else 2', '    @add? if c then w'),
      'BiteProofBWdgt.coffee': cls('BiteProofBWdgt', '  biteProofRecalc: ->', '    world.recalculateLayouts()'),
      // [D] a verb anywhere in src, in a '''-heredoc: every Macro.fromString literal is a macro source
      'BiteProofVerbHost.coffee': ['class BiteProofVerbHost', '  biteProofVerbs: ->', "    Macro.fromString '''",
        '      biteProofOtherFile_Macro = (w) ->', '        w._biteProofVerbElsewhere()', "    '''", ''].join('\n'),
      'BiteProofHeregexWdgt.coffee': cls('BiteProofHeregexWdgt', '  biteProofAfterHeregex: ->', "    r = ///'''///", '    world.recalculateLayouts()'),
      // [C] judges a soak call, an inline if as its argument included
      'BiteProofCWdgt.coffee': cls('BiteProofCWdgt', '  setWidth: (w) ->', '    super', '    @setExtent new Point w, 10',
        '  setHeight: (h) ->', '    super', '    @setExtent? new Point 10, h', '    @setExtent? if h then new Point 10, h'),
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
        '    @setExtent new Point 5, 5', '    @setText "x"', '    @biteProofTWrapper()', '    @add w',
        // [T] judges a soak call, an inline if as its argument included
        '  biteProofSoakDoubleSettle: (w) ->', '    @_settleLayoutsAfter => @_biteProofTCoreNoSettle()', '    @setText? if w then "z"'),
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
      AG_STALE_MARKER: /^  \[A\]\[G\] STALE_ALLOWLIST_ENTRY # settling-call-sanctioned at src\/BiteProofAGMarkerWdgt\.coffee:3 — the line it marks \(src\/BiteProofAGMarkerWdgt\.coffee:4\) makes no settling call \[A\] or \[G\] judges/m,
    },
    // every rule this run fires carries a row; the rules sharing one print it once, its header naming them all
    advised: ['A_PUBLIC_SETTER', 'A_TEXT_SETTER', 'A_RECALC', 'B_RECALC_CALLER', 'C_SETTER_CALLS_SETTER', 'D_MACRO_PRIVATE_CALL',
      'E_MUTATOR_INVALIDATES', 'E_MUTATOR_VALVE', 'F_OFF_SETTLE_APPLY', 'G_SETTLING_WRAPPER', 'G_SELF_ADD', 'I_LEAF_ORCHESTRATES',
      'J_HOOK_SETTLES', 'K_TWIN_SEAM', 'K_TWIN_DISPATCH', 'K_COMMIT_REACTS', 'L_CALLBACK_NOSETTLE', 'L_MALFORMED_CALLBACK',
      'L_LEGACY_CALLBACK_FRAGMENT', 'M_RETIRED_FRAGMENT', 'M_RETIRED_ANDNOTIFY', 'N_RETIRED_SEAM_VERB', 'O_DEFERRED_SETTLE_CALLER',
      'P_JOIN_LANE_CALLER', 'Q_CONNECTOR_CALLER', 'R_USERLAND_PRIVATE', 'T_DOUBLE_SETTLE'],
    lines: [
      // the one-liner's inline body is read, and every second spelling of a rule its own line
      line('[A] low-level _biteProofOneLiner() calls public setter .setExtent()', 'BiteProofAWdgt', 8),
      line('[B] recalculateLayouts() called from _biteProofLowLevelRecalc()', 'BiteProofAWdgt', 7),
      /^  \[G\] low-level _biteProofLowLevelDotted\(\) calls self-settling wrapper \.biteProofSharedName\(\) — .*NB.*BiteProofGPlainWdgt.*  — src\/BiteProofGWdgt\.coffee:11$/m,
      /^  \[D\] macro calls private\/low-level \.rawBiteProofPixel\(\)/m,
      /^  \[D\] macro calls private\/low-level \._biteProofBareMarker\(\)/m,
      /^  \[D\] macro calls private\/low-level \._biteProofLeakedSanction\(\)/m,
      /^  \[D\] macro calls private\/low-level \._biteProofAfterHashCall\(\)/m,
      /^  \[D\] macro calls private\/low-level \._biteProofVerbElsewhere\(\) — \S*BiteProofVerbHost\.coffee:5 /m,
      line('[B] recalculateLayouts() called from biteProofAfterHeregex()', 'BiteProofHeregexWdgt', 4),
      /^  \[T\] biteProofDoubleSettle\(\) self-settles .* AND @-calls settling text setter @setText\(\)/m,
      /^  \[T\] biteProofDoubleSettle\(\) self-settles .* AND @-calls settling wrapper @biteProofTWrapper\(\)/m,
      /^  \[T\] biteProofDoubleSettle\(\) self-settles .* AND @-calls settling @add \(self == Widget\.add\)/m,
      /^  \[H\] biteProofThinWrapper\(\) has a guard return at src\/BiteProofHWdgt\.coffee:3 BEFORE its _settleLayoutsAfter/m,
      /^  \[A\]\[G\] STALE_ALLOWLIST_ENTRY # settling-call-sanctioned at src\/BiteProofAGMarkerWdgt\.coffee:6 — the line it marks \(src\/BiteProofAGMarkerWdgt\.coffee:6\)/m,
      /^  \[A\]\[G\] STALE_ALLOWLIST_ENTRY # settling-call-sanctioned at src\/BiteProofAGMarkerWdgt\.coffee:8 — the line it marks \(src\/BiteProofAGMarkerWdgt\.coffee:9, another marker\)/m,
      /^  \[A\]\[G\] STALE_ALLOWLIST_ENTRY # settling-call-sanctioned at src\/BiteProofAGMarkerWdgt\.coffee:9 — the line it marks \(src\/BiteProofAGMarkerWdgt\.coffee:10\)/m,
      /^  \[A\] low-level _biteProofBareMarkerA\(\) calls self-settling text setter \.setText\(\) — .* NB the # settling-call-sanctioned at src\/BiteProofAGMarkerWdgt\.coffee:12 gives no reason, so it excuses nothing.*  — src\/BiteProofAGMarkerWdgt\.coffee:12$/m,
      /^  \[G\] low-level _biteProofBareMarkerG\(\) calls @add \(self == Widget\.add\) — .* NB the # settling-call-sanctioned at src\/BiteProofAGMarkerWdgt\.coffee:14 gives no reason, so it excuses nothing.*  — src\/BiteProofAGMarkerWdgt\.coffee:15$/m,
      /^  \[A\]\[G\] STALE_ALLOWLIST_ENTRY # settling-call-sanctioned at src\/BiteProofAGMarkerWdgt\.coffee:17 — the line it marks \(src\/BiteProofAGMarkerWdgt\.coffee:18\)/m,
      line('[A] low-level _biteProofMarkerOverBlock() calls self-settling text setter .setText()', 'BiteProofAGMarkerWdgt', 19),
      /^  \[A\]\[G\] STALE_ALLOWLIST_ENTRY # settling-call-sanctioned at src\/BiteProofAGMarkerWdgt\.coffee:21 — the line it marks \(src\/BiteProofAGMarkerWdgt\.coffee:22, a blank line\)/m,
      line('[A] low-level _biteProofMarkerOverBlank() calls self-settling text setter .setText()', 'BiteProofAGMarkerWdgt', 23),
      line('[G] low-level _biteProofSoakCall() calls self-settling wrapper .close()', 'BiteProofAGMarkerWdgt', 25),
      line('[A] low-level _biteProofSoakCall() calls self-settling text setter .setText()', 'BiteProofAGMarkerWdgt', 26),
      line('[G] low-level _biteProofPresenceThenCall() calls self-settling wrapper .close()', 'BiteProofAGMarkerWdgt', 28),
      line('[G] low-level _biteProofRetiredSignOff() calls @add (self == Widget.add)', 'BiteProofAGMarkerWdgt', 31),
      line('[G] low-level _biteProofRetiredSignOff() calls self-settling wrapper .close()', 'BiteProofAGMarkerWdgt', 32),
      line('[A] low-level _biteProofInlineIfSoak() calls self-settling text setter .setText()', 'BiteProofAGMarkerWdgt', 34),
      line('[G] low-level _biteProofInlineIfSoak() calls self-settling wrapper .close()', 'BiteProofAGMarkerWdgt', 35),
      line('[G] low-level _biteProofInlineIfSoak() calls @add (self == Widget.add)', 'BiteProofAGMarkerWdgt', 36),
      line('[C] public setter setHeight() calls another public setter .setExtent()', 'BiteProofCWdgt', 7),
      line('[C] public setter setHeight() calls another public setter .setExtent()', 'BiteProofCWdgt', 8),
      /^  \[T\] biteProofSoakDoubleSettle\(\) self-settles \(src\/BiteProofTWdgt\.coffee:13\) AND @-calls settling text setter @setText\(\) — .*  — src\/BiteProofTWdgt\.coffee:14$/m,
    ],
    absent: [/_biteProofLowLevelPlainSelf/, /_applyExtentBase/],
  }, {
    label: 'every exemption table excusing nothing',
    edits: [
      ...['IconGridPanelWdgt', 'basic-widgets/ViewportWdgt', 'basic-widgets/Widget',
        'authoring/StretchableWidgetContainerWdgt'].map((f) => [`${f}.coffee`, /^  add(\s*:)/m, '  addBiteProofRenamed$1']),
      ['HandleWdgt.coffee', /DeferredSettle\b/g, 'DeferredSettleBiteProofStale'],
      ['StackElementsSizeAdjustingWdgt.coffee', /DeferredSettle\b/g, 'DeferredSettleBiteProofStale'],
      ['meta-tools/SplitGripWdgt.coffee', /DeferredSettle\b/g, 'DeferredSettleBiteProofStale'],
      ...['authoring/CalculatingPatchNodeWdgt', 'patch-programming-experimental/RegexSubstitutionPatchNodeWdgt',
        'patch-programming-experimental/DiffingPatchNodeWdgt'].map((f) => [`${f}.coffee`, /\._setTextConnector\b/g, '._setTextBiteProofStaleCall']),
      ['basic-widgets/Widget.coffee', /(\n  _applyExtent:[\s\S]*?)@_scheduleRelayoutRespectingPhase\(\)/, '$1@_biteProofRenamedValve()'],
      ['harness/AutomatorPlayer.coffee', /world\.recalculateLayouts\(\) unless world\._recalculatingLayouts/, 'world.biteProofNoFlush() unless world._recalculatingLayouts'],
    ],
    unplant: ['basic-widgets/menu-system/MenusHelper.coffee'],
    expect: {
      G_STALE_WRAPPER_EXCLUDED: /^  \[G\] STALE_ALLOWLIST_ENTRY WRAPPER_EXCLUDED 'add' — /m,
      O_STALE_CALLER_ALLOWLIST: /^  \[O\] STALE_ALLOWLIST_ENTRY DEFERRED_SETTLE_CALLER_ALLOWLIST 'nonFloatDragging' — /m,
      Q_STALE_CALLER_ALLOWLIST: /^  \[Q\] STALE_ALLOWLIST_ENTRY CONNECTOR_CALLER_ALLOWLIST 'recalculateOutput' — /m,
      E_STALE_VALVE_EXEMPTION: /^  \[E\] STALE_ALLOWLIST_ENTRY the schedule-valve exemption Widget\._applyExtent — /m,
      R_STALE_USERLAND_FILES: /^  \[R\] STALE_ALLOWLIST_ENTRY USERLAND_FILES 'src\/basic-widgets\/menu-system\/MenusHelper\.coffee' — /m,
      B_STALE_RECALC_ORACLE: /^  \[B\] STALE_ALLOWLIST_ENTRY RECALC_ORACLES '_checkPaintTruthfulness' — /m,
    },
    // a stale entry's own line gives its one answer: no advice
    advised: [],
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessAWdgt.coffee': cls('BiteProofHarnessAWdgt', '  _biteProofLowLevelSetter: ->', '    @setExtent new Point 10, 10') },
    expect: { A_PUBLIC_SETTER: /^  \[A\] low-level _biteProofLowLevelSetter\(\) calls public setter \.setExtent\(\).*  — harness\/BiteProofHarnessAWdgt\.coffee:3$/m },
    advised: ['A_PUBLIC_SETTER'],
  }, {
    label: "[D]'s whole-file half over a planted tests dir",
    args: ['--tests-dir=' + testsDir],
    expect: { D_MACRO_PRIVATE_CALL: /^  \[D\] macro calls private\/low-level \._biteProofTestsHalfCall\(\) — \S*SystemTest_BiteProofMacro_automationCommands\.js:3 /m },
    advised: ['D_MACRO_PRIVATE_CALL'],
  }, {
    label: 'a tests dir holding a directory that is no test',
    args: ['--tests-dir=' + malformedTestsDir],
    exit: 2,
    lines: [/TESTS_DIRECTORY_MALFORMED: \S*\/scratch — /],
  }, (() => {
    // marked calls past the ceiling, sized from the count the control prints (a ceiling above the count, a gain not yet
    // banked, needs more), at least one of each kind: [A] a geometry and a text setter, [G] a wrapper and @add, marked on
    // the line and above it (its reason running on), each excused itself; beside them the line scope (the call after a
    // marked line fires) and recalculateLayouts on a marked line, which the marker never excuses
    const m = /; (\d+)\/(\d+) settling call\(s\) sanctioned\)/.exec(control.out) || [0, 0, 0];
    const k = Math.max(4, Number(m[2]) - Number(m[1]) + 1);
    const kinds = [
      (i) => [`  _biteProofMarked${i}: (w) ->`, '    w.setExtent new Point 1, 1   # settling-call-sanctioned: the bite-proof fixture, on the line'],
      (i) => [`  _biteProofMarked${i}: (w) ->`, '    # settling-call-sanctioned: the bite-proof fixture, above the line,', '    #   its reason running on', '    w.setText "c"'],
      (i) => [`  _biteProofMarked${i}: (w) ->`, '    # settling-call-sanctioned: the bite-proof fixture, above the line', '    w.biteProofMarkedWrapper()'],
      (i) => [`  _biteProofMarked${i}: (w) ->`, '    @add w   # settling-call-sanctioned: the bite-proof fixture, on the line'],
    ];
    return {
      label: 'one settling-call marker more than its ceiling',
      plants: { 'BiteProofAGMarkedWdgt.coffee': cls('BiteProofAGMarkedWdgt',
        '  biteProofMarkedWrapper: ->', '    @_settleLayoutsAfter => @_biteProofMarkedCoreNoSettle()',
        '  _biteProofMarkedCoreNoSettle: ->', '    @bpValue = 1',
        '  _biteProofLineScope: (w) ->', '    w.setText "h"   # settling-call-sanctioned: the bite-proof fixture, its one line', '    w.setExtent new Point 2, 2',
        '  _biteProofRecalcOnMarkedLine: (w) ->', '    w.setText "i"; world.recalculateLayouts()   # settling-call-sanctioned: the bite-proof fixture, beside a recalc',
        ...Array.from({ length: k }, (_, i) => kinds[i % kinds.length](i)).flat()) },
      expect: {
        AG_MARKER_COUNT_ABOVE_CEILING: /^  \[A\]\[G\] \d+ settling calls excused by # settling-call-sanctioned \(ceiling \d+\) — a low-level method newly makes a self-settling call on its reason's word: .*src\/BiteProofAGMarkedWdgt\.coffee:\d+/m,
        A_PUBLIC_SETTER: line('[A] low-level _biteProofLineScope() calls public setter .setExtent()', 'BiteProofAGMarkedWdgt', 8),
        A_RECALC: line('[A] low-level _biteProofRecalcOnMarkedLine() calls recalculateLayouts()', 'BiteProofAGMarkedWdgt', 10),
        B_RECALC_CALLER: line('[B] recalculateLayouts() called from _biteProofRecalcOnMarkedLine()', 'BiteProofAGMarkedWdgt', 10),
      },
      advised: ['AG_MARKER_COUNT_ABOVE_CEILING', 'A_PUBLIC_SETTER', 'A_RECALC', 'B_RECALC_CALLER'],
      absent: [/\[[AG]\] low-level _biteProofMarked/, /calls self-settling text setter .*  — src\/BiteProofAGMarkedWdgt\.coffee:(7|10)$/m],
    };
  })(), (() => {
    // a second settling call appended to a marked line, the tree topped up to exactly its ceiling first (sized from
    // the control's count): counted per line it would pass; counted per call it is one over, the line named twice
    const m = /; (\d+)\/(\d+) settling call\(s\) sanctioned\)/.exec(control.out) || [0, 0, 0];
    const topUp = Math.max(0, Number(m[2]) - Number(m[1]));
    return {
      label: 'a second call on a marked line',
      plants: topUp ? { 'BiteProofAGTopUpWdgt.coffee': cls('BiteProofAGTopUpWdgt', ...Array.from({ length: topUp }, (_, i) =>
        [`  _biteProofTopUp${i}: (w) ->`, '    w.setText "j"   # settling-call-sanctioned: the bite-proof fixture, a top-up']).flat()) } : {},
      edits: [['authoring/FormatAsCodeButtonWdgt.coffee', /(\n    subject\.setFontName fontName)(?=\n)/, '$1; subject.setFontSize 12']],
      expect: { AG_MARKER_COUNT_ABOVE_CEILING: /^  \[A\]\[G\] \d+ settling calls excused by # settling-call-sanctioned \(ceiling \d+\) — .*src\/authoring\/FormatAsCodeButtonWdgt\.coffee:(\d+), src\/authoring\/FormatAsCodeButtonWdgt\.coffee:\1\b/m },
      advised: ['AG_MARKER_COUNT_ABOVE_CEILING'],
      absent: [/\[A\] low-level _actOn\(\) calls self-settling text setter/],
    };
  })()],
});
