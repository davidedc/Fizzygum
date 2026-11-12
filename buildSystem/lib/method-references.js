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
//      method of that class, `C::[k]` / `C.prototype[k]` every instance method — its own and its ancestors'
//      (the caller supplies the chain). A key that is one whole literal (`C["m"]`) is clause 2's, and a
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
// gives the class names a lookup on `cls` resolves through — itself, then its ancestors (by default itself).
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

module.exports = { methodReferences, reachedByComputedDispatch };
