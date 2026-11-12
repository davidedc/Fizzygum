'use strict';
// check-page-loaded-elements-selftest.js — check-page-loaded-elements.js proved able to BITE, by running the REAL gate
// on a planted copy of src/ and of the tests repo's harness (lib/planted-src.js), one throwaway widget per clause, each
// failing on its OWN violation line ("  <Class>.<field>  (<file>:<n>) — <the clause>"), never the summary (which names
// every element field it saw): a field holding an element the page loads that is not a serialization transient; a
// chain re-making it after a copy but not a restore; after a restore but not a copy; an element built into no field and
// not said to be unheld, in src and in a harness file (named harness/<path>) alike; a hook header the shared matcher
// cannot see; and a hook neither walker calls (the copy's walkers edited so they never call it). The fully declared holder and the stated unheld element pass, and so
// does an element named only in a comment after a regex holding a quote (no string is open there). Run by
// buildSystem/run-selftests.js on every build.

const path = require('path');
const { proveGate } = require('./lib/planted-src');

const holder = (cls, { transient, restore, copy }) => [`class ${cls} extends Widget`,
  ...(transient ? ['  @serializationTransients: ["bpPlantedImage"]'] : []), '',
  '  _bpLoadImage: ->', '    @bpPlantedImage = new Image()',
  ...(restore ? ['', '  _afterDeserialization: ->', '    @_bpLoadImage()'] : []),
  ...(copy ? ['', '  _reactToBeingCopied: ->', '    @_bpLoadImage()'] : []), ''].join('\n');
const clause = (cls, text) => new RegExp(`^  ${cls}\\.bpPlantedImage  \\(${cls}\\.coffee:\\d+\\) — .*${text}`, 'm');

proveGate({
  name: 'check-page-loaded-elements',
  gate: path.join(__dirname, 'check-page-loaded-elements.js'),
  testsRepo: true,
  pass: /^\[page-loaded-elements\] OK/m,
  control: {
    plants: {
      'BiteProofDeclaredHolderWdgt.coffee': holder('BiteProofDeclaredHolderWdgt', { transient: true, restore: true, copy: true }),
      'BiteProofCommentAfterRegexWdgt.coffee': ['class BiteProofCommentAfterRegexWdgt extends Widget', '', '  _bpNote: ->',
        '    q = /"/ # new Image() is named in this comment, built nowhere', ''].join('\n'),
      'BiteProofStatedUnheldWdgt.coffee': ['class BiteProofStatedUnheldWdgt extends Widget', '', '  _bpDecode: (dataURL) ->',
        '    # page-element-not-held: the bite-proof fixture of check-page-loaded-elements-selftest.js', '    img = new Image()', '    img.src = dataURL', ''].join('\n'),
    },
  },
  runs: [{
    label: 'one widget per clause, a refused hook header',
    plants: {
      'BiteProofNotTransientWdgt.coffee': holder('BiteProofNotTransientWdgt', { transient: false, restore: true, copy: true }),
      'BiteProofNoRestoreWdgt.coffee': holder('BiteProofNoRestoreWdgt', { transient: true, restore: false, copy: true }),
      'BiteProofNoCopyWdgt.coffee': holder('BiteProofNoCopyWdgt', { transient: true, restore: true, copy: false }),
      'BiteProofUnheldWdgt.coffee': ['class BiteProofUnheldWdgt extends Widget', '', '  _bpDecode: (dataURL) ->', '    img = new Image()', '    img.src = dataURL', ''].join('\n'),
      'BiteProofUnseenHookWdgt.coffee': ['class BiteProofUnseenHookWdgt extends Widget', '  _afterDeserialization: (a,', '      b) ->', '    1', ''].join('\n'),
    },
    expect: {
      NOT_TRANSIENT: clause('BiteProofNotTransientWdgt', 'not a serialization transient'),
      NO_RESTORE_HOOK: clause('BiteProofNoRestoreWdgt', 'no _afterDeserialization'),
      NO_COPY_HOOK: clause('BiteProofNoCopyWdgt', 'no _reactToBeingCopied'),
      UNATTRIBUTED_ELEMENT: /^  BiteProofUnheldWdgt\.coffee:4  img = new Image\(\)$/m,
      UNSEEN_HOOK_HEADER: /^  BiteProofUnseenHookWdgt\.coffee:2  a hook header in a spelling the shared matcher cannot see/m,
    },
    absent: [/BiteProofDeclaredHolderWdgt\.bpPlantedImage|BiteProofStatedUnheldWdgt/],
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessUnheldWdgt.coffee': ['class BiteProofHarnessUnheldWdgt extends Widget', '', '  _bpDecode: (dataURL) ->', '    img = new Image()', '    img.src = dataURL', ''].join('\n') },
    expect: { UNATTRIBUTED_ELEMENT: /^  harness\/BiteProofHarnessUnheldWdgt\.coffee:4  img = new Image\(\)$/m },
  }, {
    label: 'a hook neither walker calls',
    edits: [['duplication/Duplicator.coffee', /\._reactToBeingCopied\??\(/g, '._bpRenamedHook(']],   // its one caller
    expect: { HOOK_NOT_CALLED: /^  HOOKS names _reactToBeingCopied, which neither walker \(src\/serialization, src\/duplication\) calls/m },
  }],
});
