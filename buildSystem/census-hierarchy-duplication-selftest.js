'use strict';
// census-hierarchy-duplication-selftest.js — census-hierarchy-duplication.js --gate proved able to BITE, by running the
// REAL gate on a planted copy of src/ and of the tests repo's harness (lib/planted-src.js): an override whose signature
// and body equal the definition it inherits, with no `super` in its body, fails, named with its class and the one it
// equals — also an EMPTY one, one whose parameter default holds a call (the list is read to its balanced parenthesis),
// one whose only `super` is inside a string, one whose sanction marker gives no reason, and one in a harness file
// (named harness/<path>). The forms the gate must NOT judge ride the control: an identical override whose body holds
// `super` (it stays advisory), one sanctioned on its header line and one in the comment block above it, a different
// parameter list, a default holding a call against no list at all, a different arrow, and a method identical to an
// ancestor's with a FIELD of the same name in a class between. The control's pass line names no count: the real tree
// may hold sanctioned or `super`-holding copies. A failing run prints the rule's advice once (lib/gate-advice.js). Run
// by buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

const lines = (...l) => [...l, ''].join('\n');
const PARENT = lines('class BiteProofIdenticalParentWdgt extends Widget', '',
  '  bpPlain: (a, opts = {}) ->', '    @bpRead a, opts',
  '  bpWithSuper: (a) ->', '    super a', '    @bpRead a',
  '  bpSanctionedInline: -> @bpRead 1',
  '  bpSanctionedAbove: -> @bpRead 2',
  '  bpOtherSignature: (a) -> @bpRead a',
  '  bpSuperInAString: -> @bpSay "super"',
  '  bpReasonless: -> @bpRead 3',
  '  bpHarness: -> @bpRead 4',
  '  bpEmpty: (droppedWidget) ->',
  '  bpDefaultCall: (w = @bpTop()) -> @bpRead w',
  '  bpDefaultCallVsNone: (w = @bpTop()) -> @bpRead w',
  '  bpArrow: -> @bpRead 5',
  '  bpShadowedByAField: -> @bpRead 6');
// a class between the parent and the control child, holding a FIELD named like a parent method: the child inherits
// the field, so the child's copy of the parent's method is no duplicate
const MIDDLE = lines('class BiteProofIdenticalMiddleWdgt extends BiteProofIdenticalParentWdgt', '', '  bpShadowedByAField: 6');

proveGate({
  name: 'census-hierarchy-duplication',
  gate: path.join(__dirname, 'census-hierarchy-duplication.js'),
  args: ['--gate'],
  testsRepo: true,
  pass: /^\[hierarchy-duplication\] OK -- 0 overrides identical to what they inherit with no `super` in them \(\d+ sanctioned; \d+ holding `super` stay advisory\)\.$/m,
  control: {
    plants: {
      'BiteProofIdenticalParentWdgt.coffee': PARENT,
      'BiteProofIdenticalMiddleWdgt.coffee': MIDDLE,
      'BiteProofIdenticalControlWdgt.coffee': lines('class BiteProofIdenticalControlWdgt extends BiteProofIdenticalMiddleWdgt', '',
        '  # a body holding super is a link in the chain: advisory, never judged',
        '  bpWithSuper: (a) ->', '    super a', '    @bpRead a',
        '  bpSanctionedInline: -> @bpRead 1 # identical-override-sanctioned: the bite-proof reads its ownership',
        '  # the prototype must own this one:',
        '  # identical-override-sanctioned: the bite-proof reads its ownership',
        '  bpSanctionedAbove: -> @bpRead 2',
        '  bpOtherSignature: (a, b) -> @bpRead a',
        '  # here `w` is a free name, where the parent binds it as a parameter: a different method',
        '  bpDefaultCallVsNone: -> @bpRead w',
        '  bpArrow: => @bpRead 5',
        '  bpShadowedByAField: -> @bpRead 6'),
    },
  },
  runs: [{
    label: 'identical overrides: plain, empty, a default holding a call, super only in a string, a reasonless marker',
    plants: {
      'BiteProofIdenticalParentWdgt.coffee': PARENT,
      'BiteProofIdenticalChildWdgt.coffee': lines('class BiteProofIdenticalChildWdgt extends BiteProofIdenticalParentWdgt', '',
        '  bpPlain: (a, opts = {}) ->', '    @bpRead a, opts',
        '  bpSuperInAString: -> @bpSay "super"',
        '  # identical-override-sanctioned:',
        '  bpReasonless: -> @bpRead 3',
        '  bpEmpty: (droppedWidget) ->',
        '  bpDefaultCall: (w = @bpTop()) -> @bpRead w'),
    },
    expect: {
      IDENTICAL_OVERRIDE: /^  IDENTICAL_OVERRIDE BiteProofIdenticalChildWdgt\.coffee:3: BiteProofIdenticalChildWdgt\.bpPlain == BiteProofIdenticalParentWdgt\.bpPlain  \[BiteProofIdenticalParentWdgt\.coffee:3\]$/m,
    },
    lines: [
      /^  IDENTICAL_OVERRIDE BiteProofIdenticalChildWdgt\.coffee:5: BiteProofIdenticalChildWdgt\.bpSuperInAString == /m,
      /^  IDENTICAL_OVERRIDE BiteProofIdenticalChildWdgt\.coffee:7: BiteProofIdenticalChildWdgt\.bpReasonless == /m,
      /^  IDENTICAL_OVERRIDE BiteProofIdenticalChildWdgt\.coffee:8: BiteProofIdenticalChildWdgt\.bpEmpty == /m,
      /^  IDENTICAL_OVERRIDE BiteProofIdenticalChildWdgt\.coffee:9: BiteProofIdenticalChildWdgt\.bpDefaultCall == /m,
    ],
    advised: ['IDENTICAL_OVERRIDE'],
  }, {
    label: 'a harness file',
    plants: {
      'BiteProofIdenticalParentWdgt.coffee': PARENT,
      'harness/BiteProofHarnessIdenticalWdgt.coffee': lines('class BiteProofHarnessIdenticalWdgt extends BiteProofIdenticalParentWdgt', '',
        '  bpHarness: -> @bpRead 4'),
    },
    expect: {
      IDENTICAL_OVERRIDE: /^  IDENTICAL_OVERRIDE harness\/BiteProofHarnessIdenticalWdgt\.coffee:3: BiteProofHarnessIdenticalWdgt\.bpHarness == BiteProofIdenticalParentWdgt\.bpHarness  \[BiteProofIdenticalParentWdgt\.coffee:13\]$/m,
    },
    advised: ['IDENTICAL_OVERRIDE'],
  }],
});
