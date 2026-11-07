'use strict';
// check-call-separation-selftest.js — check-call-separation.js's [S] rule proved able to BITE, by running the REAL
// gate on a planted copy of src/ (lib/planted-src.js): a private method that self-calls a public command must fail
// the gate naming the site, and the same method marked `# public-call-sanctioned:` must not. The census's call-shape
// decisions are census-public-private-calls-selftest.js; this is the verdict over them — the baseline compare, the
// sanction, the exit code. Run by buildSystem/run-selftests.js on every build.

const { plantedSrc, runGate } = require('./lib/planted-src');
const t = require('./lib/selftest-verdict').cases('check-call-separation');

const GATE = 'check-call-separation.js';
const FILE = 'BiteProofCallSeparationWdgt.coffee';
// the callee: a public command of the chain the census classifies SETTLING (`destroy` settles); if it is ever
// reclassified the planted case fails, and its detail says what to pick instead
const CALLEE = 'destroy';
const plantText = (sanction) => [
  'class BiteProofCallSeparationWdgt extends Widget',
  '',
  '  _bpPlantedPrivate: ->',
  ...(sanction ? ['    # public-call-sanctioned: the bite-proof fixture of check-call-separation-selftest.js'] : []),
  `    @${CALLEE}()`,
  '',
].join('\n');
const SITE = `BiteProofCallSeparationWdgt._bpPlantedPrivate -> @${CALLEE}`;

const tree = plantedSrc();

const control = runGate(GATE, tree.dir);
t.check(control.status === 0 && /\[call-separation\] OK/.test(control.out),
  'the unplanted copy passes', control.why);

tree.plant(FILE, plantText(false));
const planted = runGate(GATE, tree.dir);
t.check(planted.status === 1 && /call-separation gate FAILED/.test(planted.out) && planted.out.includes(SITE),
  `the plant fails [S], naming ${SITE}`,
  `${planted.why} — if the gate passed, @${CALLEE} may no longer be a SETTLING/EFFECTFUL public command to the census (node buildSystem/census-public-private-calls.js --full)`);

tree.plant(FILE, plantText(true));
const sanctioned = runGate(GATE, tree.dir);
t.check(sanctioned.status === 0 && /\[call-separation\] OK/.test(sanctioned.out),
  'the same site marked # public-call-sanctioned: passes', sanctioned.why);

t.done();
