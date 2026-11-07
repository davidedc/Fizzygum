'use strict';
// census-widget-conformance-selftest.js — census-widget-conformance.js --gate proved able to BITE, by running the REAL
// gate on a planted copy of src/ (lib/planted-src.js): a widget writing a field it never declares fails — written
// with `=` or lazily with `?=` — named with the class; one more _reLayout prologue copy takes the ratchet over its
// floor and fails, named. The declaration forms the facet accepts ride the control: a class-level declaration, a
// field a mixin donates, a write inside a block string (data, not code), a comparison, a bound function. Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

const lines = (...l) => [...l, ''].join('\n');
proveGate({
  name: 'census-widget-conformance',
  gate: path.join(__dirname, 'census-widget-conformance.js'),
  args: ['--gate'],
  pass: /^\[widget-conformance\] OK -- undeclared fields 0\/0 \(baseline 0\/0\)/m,
  control: {
    plants: {
      'BiteProofDeclaredFieldsWdgt.coffee': lines('class BiteProofDeclaredFieldsWdgt extends Widget', '  @augmentWith BiteProofDonorMixin', '',
        '  bpDeclared: undefined', '', '  bpSet: ->', '    @bpDeclared = 1', '    @bpDonated = 2', '    same = @bpDeclared == 1', '    bound = @bpDeclared => 1',
        '    @bpDeclared ?= 3', '  bpData: ->', '    """', '      @bpInAString = 4', '    """'),
      'BiteProofDonorMixin.coffee': lines('BiteProofDonorMixin =', '', '  onceAddedClassProperties: (fromClass) ->',
        '    @addInstanceProperties fromClass,', '', '      bpDonated: undefined'),
    },
  },
  runs: [{
    label: 'an undeclared field and one more prologue copy',
    plants: {
      'BiteProofUndeclaredWdgt.coffee': lines('class BiteProofUndeclaredWdgt extends Widget', '  bpSet: ->', '    @bpUndeclared = 1', '  bpLazy: ->', '    @bpLazyField ?= 2'),
      'BiteProofPrologueWdgt.coffee': lines('class BiteProofPrologueWdgt extends Widget', '  _reLayout: (newBoundsForThisLayout) ->',
        '    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout', '    @_applyGrantedBounds newBoundsForThisLayout'),
    },
    expect: {
      UNDECLARED_FIELD: /^      BiteProofUndeclaredWdgt \(BiteProofUndeclaredWdgt\.coffee\): bpLazyField, bpUndeclared$/m,
      PROLOGUE_COPY: /^      BiteProofPrologueWdgt \(BiteProofPrologueWdgt\.coffee\)$/m,
    },
    absent: [/BiteProofDeclaredFieldsWdgt/],
  }],
});
