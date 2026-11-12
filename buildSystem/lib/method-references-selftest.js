'use strict';
// method-references-selftest.js — the method-reference rule's cases (lib/method-references.js): each a code line and
// what it must, and must not, reach; where each occurrence starts and how it is reached; and computed dispatch through
// a class's ancestors. Run by buildSystem/run-selftests.js on every build.

const { methodReferences, reachedByComputedDispatch } = require('./method-references');
const t = require('./selftest-verdict').cases('method-references');

const CASES = [
  // [line, names it must reach, names it must not, templates, classes]
  ['  draw: (ctx, x = @defaultParam()) ->', ['defaultParam'], ['draw', 'ctx', 'x'], [], []],
  ['  @make: (a) ->', [], ['make', 'mak', 'a'], [], []],
  ['    {spanFactor, other: renamed, @fromSelf} = world.toolkit', ['spanFactor', 'other', 'fromSelf'], ['renamed', 'world'], [], []],
  ['    const { isDesktopShortcut, ...rest } = w', ['isDesktopShortcut'], ['w'], [], []],   // `.rest`: the stated spread limit
  ['    pick = ({face}) -> face; obj = {notRead: 1}; same = a == {b}', ['face'], ['notRead', 'b'], [], []],
  ['    w.callIt(); z?.optional; Foo::proto; f()["whole"]', ['callIt', 'optional', 'proto', 'whole'], ['w', 'z', 'f', 'Foo'], [], []],
  ['    for eachThing in someThings then elsewhere = { keyedBy: 1 }', [], ['eachThing', 'someThings', 'elsewhere', 'keyedBy'], [], []],
  ['    @addMenuItem "A label…", true, @, "dispatched"', ['addMenuItem', 'dispatched'], ['A', 'label'], [], []],
  ['    "a sentence naming prose"', [], ['sentence', 'naming', 'prose'], [], []],
  ['    @rcvr["_#{@verbName}Connector"]?.call @rcvr', ['rcvr', 'verbName'], [], ['_*Connector'], []],
  ['    s = "#{x}"; t = `${y}`; u = \'#{z}Single\'', [], [], [], []],
  ['    h = `on${kind}Changed`', [], [], ['on*Changed'], []],
  ['    return FormulaHelpers[name] if hasIt', [], ['FormulaHelpers'], [], [{ cls: 'FormulaHelpers', side: 'class' }]],
  ['    Widget::[member]; Point.prototype[k]', [], [], [], [{ cls: 'Widget', side: 'instance' }, { cls: 'Point', side: 'instance' }]],
  ['    Registry[key] = value; Other[k] ?= v; Seen[k] != v', [], [], [], [{ cls: 'Seen', side: 'class' }]],
  ['    FormulaHelpers?[a]; Maybe?.[b]; Built["set" + c]', [], [], [], [{ cls: 'FormulaHelpers', side: 'class' }, { cls: 'Maybe', side: 'class' }, { cls: 'Built', side: 'class' }]],
  ['    new SwitchButtonWdgt [a, b]; Klass["literal"]', ['literal'], [], [], []],
];
for (const [line, must, mustNot, tpls, cls] of CASES) {
  const r = methodReferences(line);
  const good = must.every((n) => r.names.includes(n)) && mustNot.every((n) => !r.names.includes(n)) &&
    JSON.stringify(r.templates) === JSON.stringify(tpls) && JSON.stringify(r.classes) === JSON.stringify(cls);
  t.check(good, `method references of ${JSON.stringify(line.trim())}${good ? '' : ' -> ' + JSON.stringify(r)}`);
}
// each occurrence says where its name starts and how it is reached
const occ = methodReferences('  a.viaDot(); @viaSelf; x = "viaString"').occurrences.map((o) => `${o.name}@${o.index}:${o.via}`).join(' ');
const occWant = 'viaDot@4:. viaSelf@15:@ viaString@29:string';
t.check(occ === occWant, `occurrences ${occ} (expected ${occWant})`);
const methods = [{ name: '_setFooConnector', cls: 'A', classSide: false }, { name: 'setFoo', cls: 'A', classSide: false },
  { name: 'mix', cls: 'FormulaHelpers', classSide: true }, { name: 'instanceOnly', cls: 'FormulaHelpers', classSide: false }];
methods.push({ name: 'inheritedOne', cls: 'Base', classSide: false }, { name: 'middleOne', cls: 'Middle', classSide: false },
  { name: 'unrelated', cls: 'Other', classSide: false });
const chain = (c) => (c === 'Derived' ? ['Derived', 'Middle', 'Base'] : [c]);
const reached = [...reachedByComputedDispatch(['_*Connector'], [{ cls: 'FormulaHelpers', side: 'class' }, { cls: 'Derived', side: 'instance' }], methods, chain)].sort().join(',');
const want = '_setFooConnector,inheritedOne,middleOne,mix';
t.check(reached === want, `computed dispatch reaches ${reached} (expected ${want})`);

t.done();
