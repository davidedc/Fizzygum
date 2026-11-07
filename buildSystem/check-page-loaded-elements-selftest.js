'use strict';
// check-page-loaded-elements-selftest.js — check-page-loaded-elements.js proved able to BITE, by running the REAL
// gate on a planted copy of src/ (lib/planted-src.js), one throwaway widget per clause of its rule:
//   (a) a field holding an element the page loads must be a serialization transient,
//   (b) the class chain must re-make it after a restore AND after a copy (both hooks defined),
//   and an element built on a line that assigns it to no field must say why no widget holds it.
// Each violation must fail on its OWN violation line — "  <Class>.<field>  (<file>:<n>) — <the clause>", or the
// unattributed line itself — never on the summary, which names every element field it saw; the fully declared widget,
// the stated unheld element and the unplanted copy must pass. Run by buildSystem/run-selftests.js on every build.

const { plantedSrc, runGate } = require('./lib/planted-src');
const t = require('./lib/selftest-verdict').cases('check-page-loaded-elements');

const GATE = 'check-page-loaded-elements.js';
const FILE = 'BiteProofImageHolderWdgt.coffee';
const CLS = 'BiteProofImageHolderWdgt';
const FIELD = 'bpPlantedImage';
const holder = ({ transient, restore, copy }) => [
  `class ${CLS} extends Widget`,
  ...(transient ? [`  @serializationTransients: ["${FIELD}"]`] : []),
  '',
  '  _bpLoadImage: ->',
  `    @${FIELD} = new Image()`,
  ...(restore ? ['', '  _afterDeserialization: ->', '    @_bpLoadImage()'] : []),
  ...(copy ? ['', '  _reactToBeingCopied: ->', '    @_bpLoadImage()'] : []),
  '',
].join('\n');
const unheld = (stated) => [
  `class ${CLS} extends Widget`,
  '',
  '  _bpDecode: (dataURL) ->',
  ...(stated ? ['    # page-element-not-held: the bite-proof fixture of check-page-loaded-elements-selftest.js'] : []),
  '    img = new Image()',
  '    img.src = dataURL',
  '',
].join('\n');

const tree = plantedSrc();
const passes = (r) => r.status === 0 && /\[page-loaded-elements\] OK/.test(r.out);
const failsWith = (r, re) => r.status === 1 && re.test(r.out);
const violation = (clause) => new RegExp(`^  ${CLS}\\.${FIELD}  \\(${CLS}\\.coffee:\\d+\\) — .*${clause}`, 'm');

const control = runGate(GATE, tree.dir);
t.check(passes(control), 'the unplanted copy passes', control.why);

tree.plant(FILE, holder({ transient: false, restore: true, copy: true }));
const notTransient = runGate(GATE, tree.dir);
t.check(failsWith(notTransient, violation('not a serialization transient')), `(a) @${FIELD} not a serialization transient fails naming the class and the field`, notTransient.why);

tree.plant(FILE, holder({ transient: true, restore: true, copy: false }));
const noCopy = runGate(GATE, tree.dir);
t.check(failsWith(noCopy, violation('no _reactToBeingCopied')), '(b) no _reactToBeingCopied in the chain fails naming the class and the hook', noCopy.why);

tree.plant(FILE, holder({ transient: true, restore: false, copy: true }));
const noRestore = runGate(GATE, tree.dir);
t.check(failsWith(noRestore, violation('no _afterDeserialization')), '(b) no _afterDeserialization in the chain fails naming the class and the hook', noRestore.why);

tree.plant(FILE, holder({ transient: true, restore: true, copy: true }));
const declared = runGate(GATE, tree.dir);
t.check(passes(declared), 'the fully declared holder passes', declared.why);

tree.plant(FILE, unheld(false));
const unattributed = runGate(GATE, tree.dir);
t.check(failsWith(unattributed, new RegExp(`^  ${CLS}\\.coffee:\\d+  img = new Image\\(\\)`, 'm')), 'an element assigned to no field, unexplained, fails naming the line', unattributed.why);

tree.plant(FILE, unheld(true));
const stated = runGate(GATE, tree.dir);
t.check(passes(stated), 'the same element with # page-element-not-held: passes', stated.why);

t.done();
