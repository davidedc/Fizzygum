'use strict';
// check-constructors-build-selftest.js — check-constructors-build.js proved able to BITE, by running the REAL gate on a
// planted copy of src/ (lib/planted-src.js): a constructor that adds its own child fails, named by class and line,
// and so does a one-line constructor doing it after its arrow, and one doing it after a string holding `#`. A class-side member after the constructor ends it (its
// `@add` is not the constructor's). The marker above the constructor and the marker in its body each excuse one
// (counted), and building into a sub-child or calling the settling builder pass. Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { spawnSync } = require('child_process');
const { proveGate, FIZZYGUM } = require('./lib/planted-src');

const GATE = path.join(__dirname, 'check-constructors-build.js');
const real = Number((/\[ctor-build\] (\d+) marked-exempt/.exec(spawnSync(process.execPath, [GATE], { cwd: FIZZYGUM, encoding: 'utf8' }).stdout) || [0, -99])[1]);
const cls = (name, ...body) => [`class ${name} extends Widget`, ...body, ''].join('\n');

proveGate({
  name: 'check-constructors-build',
  gate: GATE,
  pass: /^\[ctor-build\] OK — no constructor builds its own children inline\.$/m,
  control: {
    plants: {
      'BiteProofCtorExemptAboveWdgt.coffee': cls('BiteProofCtorExemptAboveWdgt', '  # constructor-build-exempt: the bite-proof fixture, above', '  constructor: ->', '    super()', '    @add new Widget()'),
      'BiteProofCtorExemptInsideWdgt.coffee': cls('BiteProofCtorExemptInsideWdgt', '  constructor: ->', '    super()', '    # constructor-build-exempt: the bite-proof fixture, inside', '    @addNoSettle new Widget()'),
      'BiteProofCtorFineWdgt.coffee': cls('BiteProofCtorFineWdgt', '  constructor: ->', '    super()', '    @contents._addNoSettle new Widget()', '    @_buildAndConnectChildren()',
        '  @bpClassSide: (w) ->', '    @add w'),
    },
    lines: [new RegExp(`^\\[ctor-build\\] ${real + 2} marked-exempt constructor\\(s\\) checked\\.$`, 'm')],
  },
  runs: [{
    label: 'a building constructor and a one-liner',
    plants: {
      'BiteProofCtorBuildWdgt.coffee': cls('BiteProofCtorBuildWdgt', '  constructor: ->', '    super()', '    @add new Widget()'),
      'BiteProofCtorOneLinerWdgt.coffee': cls('BiteProofCtorOneLinerWdgt', '  constructor: -> @__add new Widget()'),
      'BiteProofCtorAfterHashWdgt.coffee': cls('BiteProofCtorAfterHashWdgt', '  constructor: ->', '    super()', '    q = "#"; @add new Widget()'),
    },
    expect: { CTOR_BUILDS_CHILDREN: /^  BiteProofCtorBuildWdgt  \(BiteProofCtorBuildWdgt\.coffee:4\)$/m },
    lines: [/^  BiteProofCtorOneLinerWdgt  \(BiteProofCtorOneLinerWdgt\.coffee:2\)$/m,
            /^  BiteProofCtorAfterHashWdgt  \(BiteProofCtorAfterHashWdgt\.coffee:4\)$/m],
  }],
});
