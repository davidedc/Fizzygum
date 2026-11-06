'use strict';
// check-dead-methods-selftest.js — check-dead-methods.js's own decisions on synthetic inputs (no tests repo needed):
// the settle-twin symmetry rule, the class-side inventory, and a src line read as code and then by the reference
// rule. The rule's and the tests-repo reader's own cases are lib/method-references-selftest.js and
// lib/tests-repo-code-selftest.js. Run by buildSystem/run-selftests.js on every build.

const { twinName, inventoryOf, independentlyReferenced } = require('./check-dead-methods');
const { codeOfCoffeeLine } = require('./lib/coffee-mask');
const methodRefs = require('./lib/method-references');
const t = require('./lib/selftest-verdict').cases('dead-methods');

// the symmetry decision on synthetic referrer maps: [dead member, referrers-of-its-twin, expect RETAINED?]
const R = (pairs) => new Map(pairs.map(([token, owners]) => [token, new Set(owners)]));
const symmetry = [
  ['setLabel',     R([['_setLabelNoSettle', ['setLabel', 'buildFridgeMagnets']]]), true],  // core used elsewhere -> keep the dead wrapper
  ['setLabel',     R([['_setLabelNoSettle', ['setLabel']]]),                       false], // core used ONLY by the dead wrapper -> both dead
  ['setLabel',     R([]),                                                          false], // nothing references the core at all
  ['_fooNoSettle', R([['foo', ['someExternalCaller']]]),                           true],  // public twin live -> keep the dead core
  ['_fooNoSettle', R([['foo', ['_fooNoSettle']]]),                                 false], // public twin referenced only from the core -> both dead
];
for (const [n, referrers, expect] of symmetry) {
  const got = independentlyReferenced(twinName(n), n, referrers);
  t.check(got === expect, `${n}: retained=${got} (expected ${expect})`);
}

// the inventory: a class-side method under its bare name and tagged, a class-side DATA key not at all,
// and the instance method written after the class-side ones still its own entry
const invLines = ['class K', '  @SOME_CONSTANT: 5', '  @make: (a) ->', '    @_helper a', '  @_helper: (a) -> a', '  @OTHER: "x"', '  doIt: ->', '    K.make 1'];
const inv = JSON.stringify(inventoryOf(invLines).map((d) => `${d.name}${d.classSide ? '(class-side)' : ''}@${d.line + 1}`));
const invWant = JSON.stringify(['make(class-side)@3', '_helper(class-side)@5', 'doIt@7']);
t.check(inv === invWant, `inventoryOf(class-side corpus) -> ${inv}`);

// A src line is read as code (coffee-mask) and then by the reference rule: a method reached ONLY inside a
// string interpolation stays reached (plan P4.2 regression), and a comment reaches nothing.
const lineCases = [
  ['x = "#{@onlyCalledInInterpolation()}" # real comment @notThis()', ['onlyCalledInInterpolation'], ['notThis']],
  ["s = '# not a comment'; @afterHashInString()", ['afterHashInString'], []],
];
for (const [inp, must, mustNot] of lineCases) {
  const names = methodRefs.methodReferences(codeOfCoffeeLine(inp, null).code).names;
  t.check(must.every((n) => names.includes(n)) && mustNot.every((n) => !names.includes(n)), `src line ${JSON.stringify(inp)} -> ${JSON.stringify(names)}`);
}

t.done();
