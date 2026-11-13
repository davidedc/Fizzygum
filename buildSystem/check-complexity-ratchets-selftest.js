'use strict';
// check-complexity-ratchets-selftest.js — check-complexity-ratchets.js proved able to BITE, by running the REAL gate on a
// planted copy of src/ and of the tests repo's harness (lib/planted-src.js): one more method in Widget fails its
// ceiling, and a recorded function made more complex its record; a new tangled function fails the complexity ceiling,
// in src and in the harness alike, named by its key and line; a recorded function renamed leaves its record STALE
// (and its new name above the ceiling unrecorded); a held class's file removed leaves its ceiling STALE; a source the
// analyzer cannot parse is read INVALID (exit 2) before any rule is judged. Run by buildSystem/run-selftests.js on
// every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

// a function well above the ceiling (four nested ifs, a loop holding a guarded while): 20
const TANGLED = (cls) => `class ${cls}
  tangled: (a, b, c, d) ->
    if a
      if b
        if c
          if d
            1
    for x in [1, 2]
      if x
        while c
          if d
            break
    2
`;

proveGate({
  name: 'check-complexity-ratchets',
  gate: path.join(__dirname, 'check-complexity-ratchets.js'),
  testsRepo: true,
  pass: /^\[complexity-ratchets\] OK/m,
  control: { plants: { 'BiteProofSimple.coffee': 'class BiteProofSimple\n  plain: (a) ->\n    if a then 1 else 2\n' } },
  runs: [{
    label: 'one more method in a held class, and a recorded function made more complex',
    edits: [['basic-widgets/Widget.coffee', /^class Widget extends TreeNode\n/m, 'class Widget extends TreeNode\n\n  biteProofOneMoreMethod: -> 1\n'],
      ['WorldInventory.coffee', /^  takeInventory: ->\n/m, '  takeInventory: ->\n    if biteProofA\n      if biteProofB\n        biteProofC = 1\n']],
    expect: {
      METHOD_COUNT_ABOVE_CEILING: /^  METHOD_COUNT_ABOVE_CEILING  Widget: \d+ methods \(ceiling \d+\) — basic-widgets\/Widget\.coffee$/m,
      COMPLEXITY_ABOVE_RECORD: /^  COMPLEXITY_ABOVE_RECORD  WorldInventory#takeInventory: 133 \(recorded 130\) — WorldInventory\.coffee:\d+$/m,
    },
  }, {
    label: 'a new function above the ceiling, in src and in the harness',
    plants: { 'BiteProofTangled.coffee': TANGLED('BiteProofTangled'), 'harness/BiteProofHarnessTangled.coffee': TANGLED('BiteProofHarnessTangled') },
    expect: { COMPLEXITY_ABOVE_CEILING: /^  COMPLEXITY_ABOVE_CEILING  BiteProofTangled#tangled: 20 \(ceiling 15\) — BiteProofTangled\.coffee:2$/m },
    lines: [/^  COMPLEXITY_ABOVE_CEILING  BiteProofHarnessTangled#tangled: 20 \(ceiling 15\) — harness\/BiteProofHarnessTangled\.coffee:2$/m],
  }, {
    label: 'a recorded function renamed, and a held class file removed',
    edits: [['WorldInventory.coffee', /^  takeInventory: ->\n/m, '  takeInventoryRenamed: ->\n']],
    unplant: ['FrameWdgt.coffee'],
    expect: {
      STALE_ALLOWLIST_ENTRY: /^  STALE_ALLOWLIST_ENTRY  RECORDED\['WorldInventory#takeInventory'\] \(130\) names no function above the ceiling/m,
      COMPLEXITY_ABOVE_CEILING: /^  COMPLEXITY_ABOVE_CEILING  WorldInventory#takeInventoryRenamed: 130 \(ceiling 15\)/m,
    },
    lines: [/^  STALE_ALLOWLIST_ENTRY  METHOD_CEILINGS\.FrameWdgt names FrameWdgt\.coffee, which does not exist/m],
  }, {
    // measured FIRST: a source it cannot parse makes the run INVALID before any rule is judged — even with a class
    // over its method ceiling in the same tree
    label: 'a source the analyzer cannot parse, beside one more method in a held class',
    plants: { 'BiteProofUnparsable.coffee': 'class BiteProofUnparsable\n  broken: ->\n    if (\n' },
    edits: [['basic-widgets/Widget.coffee', /^class Widget extends TreeNode\n/m, 'class Widget extends TreeNode\n\n  biteProofOneMoreMethod: -> 1\n']],
    exit: 2,
    lines: [/^\[complexity-ratchets\] ERROR — the analyzer cannot parse BiteProofUnparsable\.coffee/m],
    absent: [/METHOD_COUNT_ABOVE_CEILING/],
  }],
});
