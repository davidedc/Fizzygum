'use strict';
// check-dead-methods-selftest.js — check-dead-methods.js's own decisions on synthetic inputs (no tests repo needed):
// the settle-twin symmetry rule, the class-side inventory, and a src line read as code and then by the reference
// rule. The rule's and the tests-repo reader's own cases are lib/method-references-selftest.js and
// lib/tests-repo-code-selftest.js. Those are unit tests of the engine; the gate's rules are proven to BITE at the end, by
// running the REAL gate (the src walk, the tests repo's references, the allowlist, the exit) on a planted copy of src/
// and of the tests repo's code (lib/planted-src.js), a method defined in a harness file and reached nowhere failing as
// dead, named harness/<path>. Run by buildSystem/run-selftests.js on every build.

const { twinName, inventoryOf, independentlyReferenced } = require('./check-dead-methods');
const { coffeeMask } = require('./lib/coffee-mask');
const { readAllowlist } = require('./lib/allowlist-file');
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
// string interpolation stays reached (plan P4.2 regression), a method called after a `#` that a string or a regex
// holds stays reached, and a comment reaches nothing.
const lineCases = [
  ['x = "#{@onlyCalledInInterpolation()}" # real comment @notThis()', ['onlyCalledInInterpolation'], ['notThis']],
  ["s = '# not a comment'; @afterHashInString()", ['afterHashInString'], []],
  ['r = /#\\d+/; @afterHashInRegex() # @notThisEither()', ['afterHashInRegex'], ['notThisEither']],
];
for (const [inp, must, mustNot] of lineCases) {
  const names = methodRefs.methodReferences(coffeeMask(inp)[0].code).names;
  t.check(must.every((n) => names.includes(n)) && mustNot.every((n) => !names.includes(n)), `src line ${JSON.stringify(inp)} -> ${JSON.stringify(names)}`);
}

// ---- the REAL gate on a planted src copy ---------------------------------------------------------------------------
// A header the shared matcher cannot see stops the gate before every other rule, so it is a run of its own. The
// stale-entry plants name REAL allowlist entries, read at run time: a public entry gains a reference, another public
// entry gains a live settle twin (so the symmetry rule already exempts it), and a third entry's only definer is
// deleted.
const fs = require('fs');
const path = require('path');
const { proveGate, SRC } = require('./lib/planted-src');
const { compiledFiles } = require('./lib/source-files');
const allow = [...readAllowlist(path.join(__dirname, 'dead-method-allowlist.txt')).keys()];
const publicEntries = allow.filter((n) => /^[a-z]/.test(n));
const [referenced, twinned] = publicEntries;
// an entry whose every definition among the compiled sources the gate reads lives in ONE src file (the plant can
// delete only the copy's), so deleting that file leaves it defined nowhere; its path is the copy's, src-relative
const definers = (n) => compiledFiles({ src: SRC })
  .filter((f) => new RegExp(`^  @?${n}\\s*:`, 'm').test(fs.readFileSync(f, 'utf8')))
  .map((f) => path.relative(SRC, f));
const undefinedEntry = allow.find((n) => n !== referenced && n !== twinned && definers(n).length === 1 && !definers(n)[0].startsWith('..'));
const cls = (name, ...body) => [`class ${name} extends Widget`, ...body, ''].join('\n');
proveGate({
  name: 'dead-methods',
  cases: t,
  gate: path.join(__dirname, 'check-dead-methods.js'),
  testsRepo: true,
  pass: /^\[dead-methods\] OK — /m,
  control: {
    plants: {
      'BiteProofReachedWdgt.coffee': cls('BiteProofReachedWdgt',
        '  bpNames: ["biteProofByString", "biteProofUser"]',
        '  bpLabel: "(open"',
        '  biteProofByString: -> 1',
        '  biteProofPub: -> 1',
        '  _biteProofPubNoSettle: -> 1',
        '  biteProofUser: -> @_biteProofPubNoSettle()'),
    },
    lines: [/^\[dead-methods\] NOTE — .*biteProofPub↔_biteProofPubNoSettle/m],
  },
  runs: [{
    label: 'a header the shared matcher cannot see',
    plants: { 'BiteProofUnseen.coffee': cls('BiteProofUnseen', '  biteProofWrapped: (a,', '    b) ->', '    1') },
    expect: { UNSEEN_HEADER: /^   BiteProofUnseen\.coffee:2: biteProofWrapped: \(a,$/m },
  }, {
    label: 'a dead method; allowlist entries referenced, redundant, defined nowhere',
    plants: {
      'BiteProofDead.coffee': cls('BiteProofDead', '  biteProofNeverReached: -> 1'),
      'BiteProofAllowlistPlants.coffee': cls('BiteProofAllowlistPlants',
        '  bpNames: ["bpUseIt", "bpTwinCaller"]',
        `  bpUseIt: -> @x.${referenced}()`,
        `  _${twinned}NoSettle: -> 1`,
        `  bpTwinCaller: -> @x._${twinned}NoSettle()`),
    },
    unplant: [definers(undefinedEntry)[0]],
    expect: {
      DEAD_METHOD: /^  biteProofNeverReached  \(BiteProofDead\.coffee:2\)$/m,
      STALE_ENTRY_REFERENCED: new RegExp(`^  STALE_ALLOWLIST_ENTRY ${referenced} — no longer dead: it is referenced$`, 'm'),
      STALE_ENTRY_REDUNDANT: new RegExp(`^  STALE_ALLOWLIST_ENTRY ${twinned} — auto-exempt by settle-tier symmetry \\(live twin _${twinned}NoSettle\\)`, 'm'),
      STALE_ENTRY_UNDEFINED: new RegExp(`^  STALE_ALLOWLIST_ENTRY ${undefinedEntry} — no method of that name is defined in the compiled sources$`, 'm'),
    },
  }, {
    label: 'a harness file',
    plants: { 'harness/BiteProofHarnessDead.coffee': cls('BiteProofHarnessDead', '  biteProofHarnessNeverReached: -> 1') },
    expect: { DEAD_METHOD: /^  biteProofHarnessNeverReached  \(harness\/BiteProofHarnessDead\.coffee:2\)$/m },
  }],
});

t.done();
