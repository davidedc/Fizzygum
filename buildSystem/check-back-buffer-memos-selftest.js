'use strict';
// check-back-buffer-memos-selftest.js — check-back-buffer-memos.js proved able to BITE, by running the REAL gate on a
// planted copy of src/ and of the tests repo's harness (lib/planted-src.js): a back-buffer builder recording a memo of
// what it painted fails, naming the class and the field, also when a regex holding a quote comes first on its line, and
// also in a harness file (named harness/<path>); a builder header spelled so the
// shared matcher cannot see it, and a builder declared in a
// mixin, are refused (the gate would be blind there). The memo field declared either way the rule accepts — a
// serialization transient, or saved content — passes. Run by buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

const builder = (cls, ...declaration) => [`class ${cls} extends Widget`, ...declaration, '',
  '  _createRefreshOrGetBackBuffer: ->', '    @bpLastPaintedSize = @extent()', '    [@backBuffer, @backBufferContext]', ''].join('\n');

proveGate({
  name: 'check-back-buffer-memos',
  gate: path.join(__dirname, 'check-back-buffer-memos.js'),
  testsRepo: true,
  pass: /^\[back-buffer-memos\] OK/m,
  control: {
    plants: {
      'BiteProofMemoTransientWdgt.coffee': builder('BiteProofMemoTransientWdgt', '  @serializationTransients: ["bpLastPaintedSize"]'),
      'BiteProofMemoContentWdgt.coffee': builder('BiteProofMemoContentWdgt', '  # saved-content: the bite-proof fixture of check-back-buffer-memos-selftest.js', '  bpLastPaintedSize: undefined'),
    },
  },
  runs: [{
    label: 'a memo, an unseen builder header, a builder in a mixin',
    plants: {
      'BiteProofMemoWdgt.coffee': builder('BiteProofMemoWdgt'),
      'BiteProofMemoAfterRegexWdgt.coffee': ['class BiteProofMemoAfterRegexWdgt extends Widget', '  _createRefreshOrGetBackBuffer: ->',
        '    q = /"/; @bpMemoAfterRegex = @extent()', '    [@backBuffer, @backBufferContext]', ''].join('\n'),
      'BiteProofUnseenBuilderWdgt.coffee': ['class BiteProofUnseenBuilderWdgt extends Widget', '  _createRefreshOrGetBackBuffer: (a,', '      b) ->', '    [@backBuffer, @backBufferContext]', ''].join('\n'),
      'BiteProofBuilderMixin.coffee': ['BiteProofBuilderMixin =', '', '  onceAddedClassProperties: (fromClass) ->', '    @addInstanceProperties fromClass,', '',
        '      _createRefreshOrGetBackBuffer: ->', '        [@backBuffer, @backBufferContext]', ''].join('\n'),
    },
    expect: {
      MEMO_RIDES_A_SAVE: /^  BiteProofMemoWdgt\.bpLastPaintedSize  \(BiteProofMemoWdgt\.coffee:4, in _createRefreshOrGetBackBuffer\)$/m,
      UNSEEN_BUILDER_HEADER: /^  BiteProofUnseenBuilderWdgt\.coffee:2  a _createRefreshOrGetBackBuffer header in a spelling the shared matcher cannot see/m,
      BUILDER_IN_MIXIN: /^  BiteProofBuilderMixin\.coffee:6  a _createRefreshOrGetBackBuffer declared in the mixin BiteProofBuilderMixin/m,
    },
    lines: [/^  BiteProofMemoAfterRegexWdgt\.bpMemoAfterRegex  \(BiteProofMemoAfterRegexWdgt\.coffee:3, in _createRefreshOrGetBackBuffer\)$/m],
    absent: [/BiteProofMemoTransientWdgt|BiteProofMemoContentWdgt/],
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessMemoWdgt.coffee': builder('BiteProofHarnessMemoWdgt') },
    expect: { MEMO_RIDES_A_SAVE: /^  BiteProofHarnessMemoWdgt\.bpLastPaintedSize  \(harness\/BiteProofHarnessMemoWdgt\.coffee:4, in _createRefreshOrGetBackBuffer\)$/m },
  }],
});
