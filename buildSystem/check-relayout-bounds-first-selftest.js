'use strict';
// check-relayout-bounds-first-selftest.js — check-relayout-bounds-first.js proved able to BITE, by running the REAL
// gate on a planted copy of src/ and of the tests repo's harness (lib/planted-src.js): a _reLayout reading its own
// geometry before applying its bounds fails, and so does one reading before it delegates to the own-contents template,
// one whose only "super" is in a string, one reading after a string holding `#` on its line, and one in a harness file
// (named harness/<path>); a _layOutOwnContents hook whose class never routes through the template fails. Every accepted
// shape rides the control and is COUNTED into its bucket (apply-first ×4: granted bounds, the setBounds twin,
// move + extent, super; template ×2: a delegating class and its hook-only subclass; no geometry read ×1; the marker
// ×1). Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { spawnSync } = require('child_process');
const { proveGate, FIZZYGUM } = require('./lib/planted-src');

const GATE = path.join(__dirname, 'check-relayout-bounds-first.js');
const COUNT = /\[relayout-bounds-first\] (\d+) apply-first \+ (\d+) own-contents template \+ (\d+) param-driven\/no-child \+ (\d+) exempt/;
const real = (COUNT.exec(spawnSync(process.execPath, [GATE], { cwd: FIZZYGUM, encoding: 'utf8' }).stdout) || [0, -99, -99, -99, -99]).slice(1).map(Number);
const relayout = (cls, parent, ...body) => [`class ${cls} extends ${parent}`, '  _reLayout: (newBoundsForThisLayout) ->', ...body, ''].join('\n');

proveGate({
  name: 'check-relayout-bounds-first',
  gate: GATE,
  testsRepo: true,
  pass: /^\[relayout-bounds-first\] OK -- every _reLayout applies its own bounds before reading its own geometry\.$/m,
  control: {
    plants: {
      'BiteProofApplyGrantedWdgt.coffee': relayout('BiteProofApplyGrantedWdgt', 'Widget', '    @_applyGrantedBounds newBoundsForThisLayout', '    @bpX = @width()'),
      'BiteProofApplyBoundsWdgt.coffee': relayout('BiteProofApplyBoundsWdgt', 'Widget', '    @_applyBounds newBoundsForThisLayout', '    @bpX = @width()'),
      'BiteProofApplyMoveExtentWdgt.coffee': relayout('BiteProofApplyMoveExtentWdgt', 'Widget', '    @_applyMoveTo newBoundsForThisLayout.origin', '    @_applyExtent newBoundsForThisLayout.extent()', '    @bpX = @width()'),
      'BiteProofApplySuperWdgt.coffee': relayout('BiteProofApplySuperWdgt', 'Widget', '    super', '    @bpX = @width()'),
      'BiteProofTemplateWdgt.coffee': [relayout('BiteProofTemplateWdgt', 'Widget', '    @_reLayoutWithOwnContents newBoundsForThisLayout').trimEnd(), '  _layOutOwnContents: ->', '    @bpX = @width()', ''].join('\n'),
      'BiteProofTemplateHookOnlyWdgt.coffee': ['class BiteProofTemplateHookOnlyWdgt extends BiteProofTemplateWdgt', '  _layOutOwnContents: ->', '    @bpX = @height()', ''].join('\n'),
      'BiteProofNoGeomReadWdgt.coffee': relayout('BiteProofNoGeomReadWdgt', 'Widget', '    @bpLast = newBoundsForThisLayout'),
      'BiteProofExemptReLayoutWdgt.coffee': ['class BiteProofExemptReLayoutWdgt extends Widget', '  # relayout-bounds-first-exempt: the bite-proof fixture', '  _reLayout: (newBoundsForThisLayout) ->', '    @bpX = @width()', ''].join('\n'),
    },
    lines: [new RegExp(`^\\[relayout-bounds-first\\] ${real[0] + 4} apply-first \\+ ${real[1] + 2} own-contents template \\+ ${real[2] + 1} param-driven\\/no-child \\+ ${real[3] + 1} exempt`, 'm')],
  },
  runs: [{
    label: 'reads before applying, before delegating, a string super; a dead hook',
    plants: {
      'BiteProofReadFirstWdgt.coffee': relayout('BiteProofReadFirstWdgt', 'Widget', '    @bpX = @width()', '    @_applyGrantedBounds newBoundsForThisLayout'),
      'BiteProofReadBeforeDelegateWdgt.coffee': relayout('BiteProofReadBeforeDelegateWdgt', 'Widget', '    @bpX = @width()', '    @_reLayoutWithOwnContents newBoundsForThisLayout'),
      'BiteProofStringSuperWdgt.coffee': relayout('BiteProofStringSuperWdgt', 'Widget', '    @bpS = "super"', '    @bpX = @width()'),
      'BiteProofReadAfterHashWdgt.coffee': relayout('BiteProofReadAfterHashWdgt', 'Widget', '    q = "#"; @bpX = @width()', '    @_applyGrantedBounds newBoundsForThisLayout'),
      'BiteProofDeadHookWdgt.coffee': ['class BiteProofDeadHookWdgt extends Widget', '  _layOutOwnContents: ->', '    @bpX = @width()', ''].join('\n'),
    },
    expect: {
      READS_BEFORE_APPLY: /^  BiteProofReadFirstWdgt\._reLayout  \(BiteProofReadFirstWdgt\.coffee:2\) -- first own-geometry read at line 3:  @bpX = @width\(\)$/m,
      HOOK_WITHOUT_TEMPLATE: /^  BiteProofDeadHookWdgt\._layOutOwnContents  \(BiteProofDeadHookWdgt\.coffee:2\) -- first own-geometry read at line 3:/m,
    },
    lines: [/^  BiteProofReadBeforeDelegateWdgt\._reLayout  \(BiteProofReadBeforeDelegateWdgt\.coffee:2\)/m,
            /^  BiteProofStringSuperWdgt\._reLayout  \(BiteProofStringSuperWdgt\.coffee:2\) -- first own-geometry read at line 4:/m,
            /^  BiteProofReadAfterHashWdgt\._reLayout  \(BiteProofReadAfterHashWdgt\.coffee:2\) -- first own-geometry read at line 3:/m],
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessReadFirstWdgt.coffee': relayout('BiteProofHarnessReadFirstWdgt', 'Widget', '    @bpX = @width()', '    @_applyGrantedBounds newBoundsForThisLayout') },
    expect: { READS_BEFORE_APPLY: /^  BiteProofHarnessReadFirstWdgt\._reLayout  \(harness\/BiteProofHarnessReadFirstWdgt\.coffee:2\) -- first own-geometry read at line 3:  @bpX = @width\(\)$/m },
  }],
});
