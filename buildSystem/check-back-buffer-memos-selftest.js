'use strict';
// check-back-buffer-memos-selftest.js — check-back-buffer-memos.js proved able to BITE, by running the REAL gate on a
// planted copy of src/ (lib/planted-src.js). A throwaway widget whose back-buffer builder records a memo of what it
// painted must fail the gate naming the field; the same field declared either way the rule accepts — a serialization
// transient, or saved content — must pass, and so must the unplanted copy. Run by buildSystem/run-selftests.js on every
// build.

const { plantedSrc, runGate } = require('./lib/planted-src');
const t = require('./lib/selftest-verdict').cases('check-back-buffer-memos');

const GATE = 'check-back-buffer-memos.js';
const FILE = 'BiteProofMemoWdgt.coffee';
const FIELD = 'bpLastPaintedSize';
const plantText = (declaration) => [
  'class BiteProofMemoWdgt extends Widget',
  ...declaration,
  '',
  '  _createRefreshOrGetBackBuffer: ->',
  `    @${FIELD} = @extent()`,
  '    [@backBuffer, @backBufferContext]',
  '',
].join('\n');

const tree = plantedSrc();
const passes = (r) => r.status === 0 && /\[back-buffer-memos\] OK/.test(r.out);

const control = runGate(GATE, tree.dir);
t.check(passes(control), 'the unplanted copy passes', control.why);

tree.plant(FILE, plantText([]));
const memo = runGate(GATE, tree.dir);
// its own violation line: "  <Class>.<field>  (<file>:<n>, in <builder>)"
t.check(memo.status === 1 && new RegExp(`^  BiteProofMemoWdgt\\.${FIELD}  \\(BiteProofMemoWdgt\\.coffee:\\d+, in _createRefreshOrGetBackBuffer\\)`, 'm').test(memo.out),
  `a builder writing @${FIELD}, neither transient nor saved content, fails naming the class and the field`, memo.why);

tree.plant(FILE, plantText([`  @serializationTransients: ["${FIELD}"]`]));
const transient = runGate(GATE, tree.dir);
t.check(passes(transient), 'the same field declared a serialization transient passes', transient.why);

tree.plant(FILE, plantText(['  # saved-content: the bite-proof fixture of check-back-buffer-memos-selftest.js', `  ${FIELD}: undefined`]));
const content = runGate(GATE, tree.dir);
t.check(passes(content), 'the same field declared # saved-content: passes', content.why);

t.done();
