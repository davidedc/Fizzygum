// method-references.js — HOW A PROGRAM REACHES A METHOD BY NAME: the one definition, for every gate and census
// that asks whether a method is used (check-dead-methods.js: is it reached at all? census-public-private-calls.js
// R4: is it reached other than by its own class's @-self-calls?).
//
// A method is reached in exactly four ways, in CoffeeScript and JS alike:
//   1. a PROPERTY ACCESS: `@m`, `x.m`, `x?.m`, `C::m`, and a destructuring read of one (`{m, n: k} = x`,
//      `const { m } = x`, `({m}) ->`, `for {m} in xs`). A class-side def key (`@m:`) is not one.
//   2. a WHOLE-NAME STRING: `"m"`, `'m'`, `` `m` `` — string dispatch, the idiom of menu actions, PinSpec setters,
//      `x["m"]` and a harness's `@staticMembersToInstall`.
//   3. a NAME TEMPLATE: an interpolated string shaped like a name with a literal part (`"_#{@action}Connector"`,
//      `` `on${kind}Changed` ``) reaches every method it matches, each interpolation a wildcard. One with no
//      literal part (`"#{x}"`) is a coercion, not a name.
//   4. a COMPUTED ACCESS ON A NAMED CLASS: `FormulaHelpers[name]` (or `C?[k]`, `C?.[k]`) reaches every class-side
//      method of that class, `C::[k]` / `C.prototype[k]` every instance method — its own, its mixins' and its
//      ancestors' (the caller supplies the chain). A key that is one whole literal (`C["m"]`) is clause 2's, and a
//      write (`C[k] = …`) reaches nothing.
// NOT a reference: a BARE WORD — a local, a parameter, an object key, a def's own name — and anything a comment
// or prose says. Callers pass CODE lines (comments cut: lib/coffee-mask.js, lib/tests-repo-code.js). Strings are
// read as code, because this codebase keeps code in strings (macro sources, tool-code blurbs, "#{@m()}").
//
// Every limit errs toward ALIVE, so it can only hide an unused method, never invent one:
//   - a string that reads like code counts (a label 'MenuWdgt[own]', an e-mail's `@host`);
//   - a whole-word string equal to a method's name counts, because a scan cannot tell a dispatch string from a
//     table string;
//   - a spread `...rest` reads as `.rest`;
//   - a regex literal's text is read like a string;
//   - a coercion template with a short literal part (`"#{n}px"`) reaches every method it matches (every name ending
//     in `px`): only the literal part decides.
// BLIND, as any name scan is: a name assembled with `+`, a computed access on an arbitrary object
// (`@target[action]`), and two same-named methods on unrelated classes. Those are an allowlist's job.

const NAMES = /@([A-Za-z_$][\w$]*)(?![\w$])(?!\s*:(?!:))|(?:\.|::)\s*([A-Za-z_$][\w$]*)|(['"`])([A-Za-z_$][\w$]*)\3/g;
const TEMPLATES = /"((?:[\w$]|#\{[^}"]*\})+)"|`((?:[\w$]|\$\{[^}`]*\})+)`/g;
const INTERPOLATION = /#\{[^}]*\}|\$\{[^}]*\}/g;
// a destructuring pattern: `{…}` assigned from (`= x`), taken as a parameter (`) ->`, `) =>`) or looped over
const DESTRUCTURING = /\{([^{}]*)\}\s*(?:=(?![=>])|\)\s*[-=]>|\s(?:in|of)\b)/g;
const COMPUTED_ON_CLASS = /\b([A-Z][\w$]*)(::|\.prototype)?(?:\?\.?)?\[(?!\s*(?:'[^']*'|"[^"]*"|`[^`]*`|\d+)\s*\])[^\]]*\](?!\s*(?:\*\*|<<|>>>|>>|&&|\|\||\?\?|[-+*/%&|^?])?=(?!=))/g;

// The references on one code line: `names` (clauses 1–2), the same as `occurrences` ({ name, index, via }: where the
// name starts, and how it is reached — '@', '.' (also `?.` and `::`) or 'string'), `templates` (clause 3, as
// `*`-wildcard patterns) and `classes` (clause 4, as { cls, side: 'class' | 'instance' }).
function methodReferences(line) {
  const names = [], occurrences = [], templates = [], classes = [];
  let m;
  NAMES.lastIndex = 0;
  while ((m = NAMES.exec(line))) {
    const name = m[1] || m[2] || m[4];
    const via = m[1] ? '@' : m[2] ? '.' : 'string';
    names.push(name);
    occurrences.push({ name, index: via === '.' ? m.index + m[0].length - name.length : m.index + 1, via });
  }
  DESTRUCTURING.lastIndex = 0;
  while ((m = DESTRUCTURING.exec(line))) {
    let at = m.index + 1;
    for (const item of m[1].split(',')) {
      const key = /^\s*@?([A-Za-z_$][\w$]*)\s*(?::|=|$)/.exec(item);
      if (key && !/^\s*\.\.\./.test(item)) {
        names.push(key[1]);
        occurrences.push({ name: key[1], index: at + item.indexOf(key[1]), via: '.' });
      }
      at += item.length + 1;
    }
  }
  TEMPLATES.lastIndex = 0;
  while ((m = TEMPLATES.exec(line))) {
    const s = m[1] || m[2];
    if (s.replace(INTERPOLATION, '') !== s && s.replace(INTERPOLATION, '') !== '') templates.push(s.replace(INTERPOLATION, '*'));
  }
  COMPUTED_ON_CLASS.lastIndex = 0;
  while ((m = COMPUTED_ON_CLASS.exec(line))) classes.push({ cls: m[1], side: m[2] ? 'instance' : 'class' });
  return { names, occurrences, templates, classes };
}

// The methods computed dispatch reaches: every method whose name matches a template, and every method on the
// computed side of a named class or of anything in its chain. `methods` is [{ name, cls, classSide }]; `chainOf(cls)`
// gives the class names a lookup on `cls` resolves through — itself, its mixins, its ancestors (by default itself).
function reachedByComputedDispatch(templates, classes, methods, chainOf = (cls) => [cls]) {
  const patterns = [...new Set(templates)].map((t) => new RegExp('^' + t.split('*').map((p) => p.replace(/\$/g, '\\$')).join('[\\w$]*') + '$'));
  const sides = new Set();
  for (const c of classes) for (const k of chainOf(c.cls)) sides.add(k + ':' + c.side);
  const reached = new Set();
  for (const d of methods) {
    if (patterns.some((p) => p.test(d.name)) || sides.has(d.cls + ':' + (d.classSide ? 'class' : 'instance'))) reached.add(d.name);
  }
  return reached;
}

// The rule's cases: each a code line and what it must (and must not) reach. Run by check-dead-methods.js and
// census-public-private-calls.js --self-test (the rule's two consumers). `log(ok, what)` reports one case; returns whether all passed.
function selfTest(log) {
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
  let ok = true;
  for (const [line, must, mustNot, tpls, cls] of CASES) {
    const r = methodReferences(line);
    const good = must.every((n) => r.names.includes(n)) && mustNot.every((n) => !r.names.includes(n)) &&
      JSON.stringify(r.templates) === JSON.stringify(tpls) && JSON.stringify(r.classes) === JSON.stringify(cls);
    if (!good) ok = false;
    log(good, `method references of ${JSON.stringify(line.trim())}${good ? '' : ' -> ' + JSON.stringify(r)}`);
  }
  // each occurrence says where its name starts and how it is reached
  const occ = methodReferences('  a.viaDot(); @viaSelf; x = "viaString"').occurrences.map((o) => `${o.name}@${o.index}:${o.via}`).join(' ');
  const occWant = 'viaDot@4:. viaSelf@15:@ viaString@29:string';
  if (occ !== occWant) ok = false;
  log(occ === occWant, `occurrences ${occ} (expected ${occWant})`);
  const methods = [{ name: '_setFooConnector', cls: 'A', classSide: false }, { name: 'setFoo', cls: 'A', classSide: false },
    { name: 'mix', cls: 'FormulaHelpers', classSide: true }, { name: 'instanceOnly', cls: 'FormulaHelpers', classSide: false }];
  methods.push({ name: 'inheritedOne', cls: 'Base', classSide: false }, { name: 'mixedIn', cls: 'SomeMixin', classSide: false },
    { name: 'unrelated', cls: 'Other', classSide: false });
  const chain = (c) => (c === 'Derived' ? ['Derived', 'SomeMixin', 'Base'] : [c]);
  const reached = [...reachedByComputedDispatch(['_*Connector'], [{ cls: 'FormulaHelpers', side: 'class' }, { cls: 'Derived', side: 'instance' }], methods, chain)].sort().join(',');
  const want = '_setFooConnector,inheritedOne,mix,mixedIn';
  if (reached !== want) ok = false;
  log(reached === want, `computed dispatch reaches ${reached} (expected ${want})`);
  return ok;
}

module.exports = { methodReferences, reachedByComputedDispatch, selfTest };
