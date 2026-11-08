'use strict';
// call-sites.js — EVERY CALL SITE in both repos and every DEFINITION its callee can have, read by real parsers, and the
// two tests over them, the CALLERS TEST and the ARITY TEST: the one reader behind check-call-arguments.js (the gate)
// and census-call-arity.js (the advisory queries), so the two can never disagree about what a call is.
//
// WHAT IS READ, AND HOW (each the way the code actually runs):
//   - Fizzygum/src and the tests repo's harness: every CLASS through the browser's own meta-compiler
//     (lib/meta-compiler.js) — each member fragment AFTER Class.coffee's super rewrite, so a `super` is an ordinary
//     call `<Cls>.__super__.<member>.call this, …` (a bare `super` forwards: `.apply(this, arguments)`); every MIXIN
//     as one source after Mixin.coffee's rewrite; every other file (boot) whole. Parsed with the bundled
//     CoffeeScript 2.0.3 `nodes()` — the browser's own grammar.
//   - every macro source (lib/macro-sources.js: the COOKED text the page compiles, each line on its file line), as
//     authored — before Macro.coffee rewrites verb calls into `yield from`: each test's, and every verb's (a
//     `Macro.fromString "…"` literal of a CoffeeScript file, CODE in a string).
//   - the tests repo's scripts and each macro file's JS shell: acorn (vendor/acorn), skipping the shell's macro
//     sources (their spans, from the same testMacroSourcesIn read). The file set is tests-repo-code's testsRepoFiles.
// ⚠ The 2.0.3 bundle is MINIFIED, so node kinds are told STRUCTURALLY, by their `children` names. A call is one of
//   THREE shapes (found by cross-checking every call against CoffeeScript 2.7's `ast: true`, archive plan §9):
//   a Call {variable, args} (`isNew` for `new X(args)` / `new X args`); an ARGUMENT-LESS `new X`, which is NOT a
//   Call but `Op('new', X)`; and `new X(args).prop`, an `Op('new')` over a property chain around a NON-new Call.
//
// A SITE: { file, line (1-based, where the call STARTS), where ('src'|'harness'|'macro'|'heredoc'|'script'), lang,
//   home, kind ('new'|'super'|'bare'|'send'), name, receiver, via, cls, args: [{ text, kind, absent, spread }],
//   forwarding, callee }. Its HOME is where it runs: 'page' (src, the harness), 'verbs' (the MacroToolkit heredocs),
//   'macro:<file>' (one test's macro program), 'node:<file>' (a script module; a test file's JS shell runs in the
//   page). `via` says what a send's receiver is when the parse alone shows it: 'this' — `@m` / `this.m` inside one of
//   its unit's RECEIVER functions (a class member; a macro or a verb; a mixin's member, inside onceAddedClassProperties;
//   a JS class's method or field initializer), through any `=>` / arrow, never under a `->` / `function` (it rebinds
//   `this`) nor at a unit's top level (a boot file's `@` is `window`), with `cls` the class it is ('MacroToolkit' for a
//   macro's), or a JS `super.m` — or 'name:<X>' for `X.m`. An argument's `kind` is what the parse alone shows it is:
//   'this', 'literal' (a string, number, boolean, `null`, a regex), 'array', 'function', 'new', 'object', 'absent',
//   'spread', else 'expression'. `absent` = the argument is the bare identifier `undefined` — the codebase's ONE
//   absence value (`null` is a value by the house rule, `void 0` is spelled by no one). `callee` is the site's
//   identity: `{ key }` — `ctor:<Owner>` for a `new` or a constructor super (the nearest class up the chain that
//   defines a constructor; the classes are src's and the harness's, and those a script or a macro program defines;
//   `new a.b.X` names X, `new @constructor` the class it is written in), `name:<m>` for a send or a bare call of a
//   name some code defines (BY NAME, whatever the receiver — owner ruling D2(a): grouping more sites under one callee
//   only adds witnesses, so it can invent a hole, loudly, never hide one), `local:<scope>#<frame>#<n>` for a bare call
//   of a name a FUNCTION binds, resolved LEXICALLY: a parameter belongs to its own function; in CoffeeScript an
//   assignment (a destructured or loop variable included) belongs to the outermost enclosing function that binds the
//   name — and to the unit's top level when that assigns it (an assignment captures an outer variable); in JS a
//   declaration to its function (a block's `let` read as its function's). A name no function binds is the top level's
//   — a boot global, a JS module's function — called by name from other files too: one `name:` group, else a witness
//   in another file would hide. Or `{ foreign }` (a name no code in either repo defines, a `new` of a class none
//   defines or a computed one) or `{ excluded }` (`.call`/`.apply`/`.bind`: their first argument is a foreign API's
//   this-arg). A `Macro.fromString` argument computed at run time (an interpolated heredoc) is UNREADABLE, never
//   skipped. "Ours" is lib/name-definitions.js harvestDefs over every CoffeeScript text read (one answer to "is this
//   name ours?" across gates), plus the JS definitions, plus every function a macro program assigns (indented, so
//   beyond harvestDefs' line forms; a macro links with the verbs into one program, so its helpers are names, not
//   locals).
//
// THE CALLERS TEST (R3 of docs/architecture/constructor-and-parameter-conventions.md, mechanized): a site whose
// `undefined` comes BEFORE a present argument is a candidate; its REACH is 1 + the index of its last present
// argument (a spread counts as present). It is a HOLE iff another site of the same callee, of known arity, reaches
// LESS FAR — that site, the WITNESS, shows the tail is omittable, so this caller filled slots only to get past them.
// Otherwise it is a VALUE (every caller supplies the whole list: the `undefined` is the operand). Reach is the
// EFFECTIVE arity, so a trailing `undefined` written out is an omission like any other. A site whose arity is
// unknown (a spread, a forwarding super) is never a witness.
//
// A DEFINITION (`defs`: callee key → [{ file, line, home, form, fn, arity, optsAt }]) is every binding of a callee's
// name the code makes, keyed as its calls are, with the HOME it is made in. `form` says which calls can reach it: a
// 'binding' (a plain name — an assignment, a function declaration, a parameter, a destructured or loop variable; a
// BARE call reaches it, and `window.m = …` is one too), a 'member' (a class's or a mixin's member; a SEND reaches it —
// a `constructor` is its class's `ctor:`), a 'field' (a property assigned: `@m = …`, `a.m = …`, `X::m = …`, `(@m) ->`;
// a send reaches it), a 'key' (an object-literal key). `fn` false is DATA — a value whose arity no reader can know (a
// closure held in a field, a parameter, a reassigned name, a JS getter's result); else `arity` is the parameter count
// (Infinity when a splat, an expansion or a body reading `arguments` takes any number — a forwarding bare `super`
// reads it, through the rewrite) and `optsAt` the OPTIONS slot, a parameter defaulting to `{}` (-1: none). A name a
// script's top level destructures, unrenamed, from a RELATIVE `require(…)` is an IMPORT (`imports`): it reaches that
// module's own binding of the name. `classDefs` holds every class definition with its home (`classes` the first, by
// name, for the identity).
//
// THE ARITY TEST: a call is judged only where its TARGET is certainly among the definitions it reaches, and every one
// of those is a function; the declared count is the WIDEST of them (a wider definition elsewhere can only hide an
// extra argument, never invent one). What a call reaches is what runs where it runs: page code is seen by every page
// program, the verbs by every macro, a macro program's own definitions by it alone, a script's by itself alone (plus
// its imports) — a browser global, Node's, another program's same-named class or function is no candidate. A bare
// call reaches the BINDINGS of its lexical key (a script's top-level call: its own module's, or its import's; a
// global no module binds is Node's or, in a page.evaluate body, the page's — not judged). A `new X` or a constructor
// `super` reaches the constructor of the ONE class X names where it runs, up a chain the reader read to its end (none
// up the chain: Class.coffee's synthesized one, or a JS default, forwards to a base that takes none); `new
// @constructor` may build a subclass (not judged). A send is judged only when its receiver is ours — `via` 'this' or a
// `super` in a class whose whole chain is read (an `Array`, an `EventEmitter`, a computed or ambiguous parent above
// it would hold members no reader sees; a mixin's `@` is any class it augments: ours), or `X.m` of such a class — and
// some MEMBER or FIELD of its name exists (none: the target is assembled at run time); it then reaches the members,
// fields and FUNCTION-valued object keys of that name (a computed install, `X::[k] = v`, takes them from an object).
// A call matched by name alone to a receiver it cannot see would invent one — `Math.max a, b, c` against `Point::max`.
// EXTRA: the call passes more arguments than the widest (a written `undefined` counts: it is dead text). INTO
// OPTIONS: its definitions agree on an options slot and the argument there is of a kind the parse shows is no options
// object ('this', 'literal', 'array', 'function', 'new').

const fs = require('fs');
const path = require('path');
const { loadMetaCompiler } = require('./meta-compiler');
const { testsRepoFiles } = require('./tests-repo-code');
const { testMacroSourcesIn, verbMacroSourcesIn } = require('./macro-sources');
const { harvestDefs } = require('./name-definitions');
const { coffeeMask } = require('./coffee-mask');
const acorn = require('../../vendor/acorn/acorn.js');

const IS_CLASS = /^class +\w+/m;            // the tests build.py and check-coffee-syntax.js use
const IS_MIXIN = /^(\w+Mixin)\s*=/m;
const IDENT = /^[A-Za-z_$][\w$]*$/;
const THIS_ARG = new Set(['call', 'apply', 'bind']);

function walkFiles(dir, ext, acc = []) {
  if (!fs.existsSync(dir)) return acc;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name.startsWith('.') || e.name === 'node_modules') continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walkFiles(p, ext, acc); else if (e.name.endsWith(ext)) acc.push(p);
  }
  return acc.sort();
}

// ---- the 2.0.3 AST, read structurally ---------------------------------------------------------------------------
const kids = (n) => (n && typeof n === 'object' && Array.isArray(n.children)) ? n.children : null;
const shape = (n) => (kids(n) || []).join(',');
const isCall = (n) => shape(n) === 'variable,args';
const isValue = (n) => shape(n) === 'base,properties';
const isOp = (n) => shape(n) === 'first,second' && typeof n.operator === 'string';
const isLiteral = (n) => kids(n) && kids(n).length === 0 && typeof n.value === 'string';
const isAccess = (n) => shape(n) === 'name' && 'soak' in n;
const isIndex = (n) => shape(n) === 'index';
const isAssign = (n) => shape(n) === 'variable,value';
const isCode = (n) => shape(n) === 'params,body';
const isParam = (n) => shape(n) === 'name,value';
const isStringLit = (n) => isLiteral(n) && /^["']/.test(n.value);
const isSpreadArg = (n) => (shape(n) === 'name' && !('soak' in n)) || (kids(n) && kids(n).length === 0 && n.value === undefined);
const plainIdent = (v) => (isValue(v) && !v.properties.length && isLiteral(v.base) && IDENT.test(v.base.value) ? v.base.value : undefined);
const propName = (p) => {
  if (isAccess(p) && isLiteral(p.name)) return p.name.value;
  if (isIndex(p) && isValue(p.index) && !p.index.properties.length && isStringLit(p.index.base)) return p.index.base.value.slice(1, -1);
  return undefined;
};

const objectKey = (v) => {
  if (!isValue(v) || v.properties.length) return undefined;
  if (isLiteral(v.base) && IDENT.test(v.base.value)) return v.base.value;
  return isStringLit(v.base) ? v.base.value.slice(1, -1) : undefined;
};
const thisField = (v) => (isValue(v) && isLiteral(v.base) && v.base.value === 'this' && v.properties.length === 1 ? propName(v.properties[0]) : undefined);
// the names a binding target binds: `a`, a destructuring `[a, rest..., b]` / `{a, b: c, d = 1}`, nested
function patternNames(n, acc = []) {
  if (!n || !kids(n)) return acc;
  if (isLiteral(n)) { if (IDENT.test(n.value) && n.value !== 'this') acc.push(n.value); return acc; }
  const b = isValue(n) && !n.properties.length ? n.base : n;
  if (b !== n && isLiteral(b)) return patternNames(b, acc);
  if (shape(b) === 'objects') for (const o of b.objects) patternNames(o, acc);
  else if (shape(b) === 'properties') for (const p of b.properties) patternNames(isAssign(p) ? (p.context === 'object' ? p.value : p.variable) : p, acc);
  else if (shape(b) === 'name' && !('soak' in b)) patternNames(b.name, acc);     // a splat, `rest...`
  return acc;
}
// a function body reads `arguments` (a forwarding bare `super` does, through the rewrite) — a `->` inside has its own
function readsArguments(body) {
  let found = false;
  const look = (n) => {
    if (found || !n) return;
    if (Array.isArray(n)) { n.forEach(look); return; }
    if (!kids(n) || (isCode(n) && !n.bound) || isAccess(n)) return;
    if (isLiteral(n) && n.value === 'arguments') { found = true; return; }
    for (const c of n.children) look(n[c]);
  };
  look(body);
  return found;
}
// an OPTIONS parameter: one defaulting to an empty object literal, `opts = {}`
const isOptionsParam = (p) => isParam(p) && !!p.value && isValue(p.value) && !p.value.properties.length && shape(p.value.base) === 'properties' && !p.value.base.properties.length;
// what a value declares as a callee: a function's parameter count (Infinity when a splat, an expansion or `arguments`
// takes any number) and its options slot (-1: none); anything else is DATA, whose arity no reader can know
const DATA = Object.freeze({ fn: false });
const unwrapCode = (v) => (isCode(v) ? v : (isValue(v) && !v.properties.length && isCode(v.base) ? v.base : undefined));
function csSignature(v) {
  const code = unwrapCode(v);
  if (!code) return DATA;
  const unbounded = code.params.some((p) => !isParam(p) || p.splat) || readsArguments(code.body);
  return { fn: true, arity: unbounded ? Infinity : code.params.length, optsAt: code.params.findIndex(isOptionsParam) };
}
// an argument's STATIC kind, where the parse alone decides it: 'this', 'literal', 'array', 'function', 'new',
// 'object', 'absent' (`undefined`), 'spread'; anything else is an 'expression'
function csArgKind(a) {
  if (isSpreadArg(a)) return 'spread';
  if (isCode(a)) return 'function';
  if (isCall(a) && a.isNew) return 'new';
  if (isOp(a) && a.operator === 'new') return isValue(a.first) && isCall(a.first.base) && a.first.properties.length ? 'expression' : 'new';
  if (isOp(a) && (a.operator === '-' || a.operator === '+') && !a.second && isValue(a.first) && isLiteral(a.first.base) && /^\d/.test(a.first.base.value)) return 'literal';
  if (isOp(a) && a.operator === '+' && a.second && [a.first, a.second].some((o) => isValue(o) && isStringLit(o.base))) return 'literal';   // a string
  if (!isValue(a) || a.properties.length) return 'expression';
  const b = a.base;
  if (isLiteral(b)) {
    if (b.value === 'this') return 'this';
    if (b.value === 'undefined') return 'absent';
    return /^["'/\d]|^(true|false|null)$/.test(b.value) ? 'literal' : 'expression';
  }
  // parentheses, and an interpolated string (a `+` chain over its pieces): the one expression inside decides
  if (shape(b) === 'body') return b.body && b.body.expressions && b.body.expressions.length === 1 ? csArgKind(b.body.expressions[0]) : 'expression';
  if (shape(b) === 'objects') return 'array';
  if (shape(b) === 'properties') return 'object';
  return isCode(b) ? 'function' : 'expression';
}

// ---- the JS twins (acorn's ESTree) ----
const isJsFn = (n) => !!n && /Function/.test(n.type);
function jsPatternNames(p, acc = []) {
  if (!p) return acc;
  if (p.type === 'Identifier') acc.push(p.name);
  else if (p.type === 'AssignmentPattern') jsPatternNames(p.left, acc);
  else if (p.type === 'RestElement') jsPatternNames(p.argument, acc);
  else if (p.type === 'ArrayPattern') for (const e of p.elements) jsPatternNames(e, acc);
  else if (p.type === 'ObjectPattern') for (const q of p.properties) jsPatternNames(q.type === 'RestElement' ? q.argument : q.value, acc);
  return acc;
}
const isJsRequire = (n) => !!n && n.type === 'CallExpression' && n.callee.type === 'Identifier' && n.callee.name === 'require';
// the file a relative `require(spec)` from `file` loads, or undefined
const jsModuleFile = (file, spec) => ['', '.js', '/index.js'].map((ext) => path.resolve(path.dirname(file), spec + ext))
  .find((p) => fs.existsSync(p) && fs.statSync(p).isFile());
function jsReadsArguments(body) {
  let found = false;
  const look = (n) => {
    if (found || !n || typeof n !== 'object') return;
    if (Array.isArray(n)) { n.forEach(look); return; }
    if (typeof n.type !== 'string' || n.type === 'FunctionDeclaration' || n.type === 'FunctionExpression') return;
    if (n.type === 'Identifier' && n.name === 'arguments') { found = true; return; }
    for (const k of Object.keys(n)) {
      if (k === 'loc' || ((n.type === 'MemberExpression' && k === 'property') || (n.type === 'Property' && k === 'key')) && !n.computed) continue;
      look(n[k]);
    }
  };
  look(body);
  return found;
}
function jsSignature(v) {
  if (!isJsFn(v)) return DATA;
  const unbounded = v.params.some((p) => p.type === 'RestElement') || (v.type !== 'ArrowFunctionExpression' && jsReadsArguments(v.body));
  return { fn: true, arity: unbounded ? Infinity : v.params.length,
    optsAt: v.params.findIndex((p) => p.type === 'AssignmentPattern' && p.right.type === 'ObjectExpression' && !p.right.properties.length) };
}
function jsArgKind(a) {
  if (a.type === 'SpreadElement') return 'spread';
  if (a.type === 'Identifier' && a.name === 'undefined') return 'absent';
  if (a.type === 'ThisExpression') return 'this';
  if (a.type === 'Literal' || a.type === 'TemplateLiteral') return 'literal';
  if (a.type === 'UnaryExpression' && (a.operator === '-' || a.operator === '+') && a.argument.type === 'Literal') return 'literal';
  if (a.type === 'ArrayExpression') return 'array';
  if (a.type === 'ObjectExpression') return 'object';
  if (a.type === 'NewExpression') return 'new';
  return isJsFn(a) ? 'function' : 'expression';
}

function walkCS(n, fn, seen = new Set()) {
  if (Array.isArray(n)) { for (const x of n) walkCS(x, fn, seen); return; }
  if (!kids(n) || seen.has(n)) return;
  seen.add(n);
  fn(n);
  for (const c of n.children) walkCS(n[c], fn, seen);
}

// every call of a 2.0.3 AST, normalized: { isNew, variable, args, ld, node } (the three shapes, header)
function csCallsOf(ast) {
  const newVia = new Map();
  const out = [];
  walkCS(ast, (n) => {
    if (!isOp(n) || n.operator !== 'new') return;
    const f = n.first;
    if (isValue(f) && isCall(f.base) && !f.base.isNew && f.properties.length) newVia.set(f.base, n);
    else out.push({ isNew: true, variable: f, args: [], ld: n.locationData, node: n });
  });
  walkCS(ast, (n) => {
    if (!isCall(n) || n.do) return;
    const op = newVia.get(n);
    out.push({ isNew: !!n.isNew || !!op, variable: n.variable, args: n.args || [], ld: (op || n).locationData, node: op || n });
  });
  return out;
}

const short = (s, n = 46) => { s = String(s).replace(/\s+/g, ' ').trim(); return s.length > n ? s.slice(0, n - 3) + '...' : s; };
function textOf(lines, ld) {
  if (ld.first_line === ld.last_line) return (lines[ld.first_line] || '').slice(ld.first_column, ld.last_column + 1);
  const a = [(lines[ld.first_line] || '').slice(ld.first_column)];
  for (let k = ld.first_line + 1; k < ld.last_line; k++) a.push(lines[k] || '');
  a.push((lines[ld.last_line] || '').slice(0, ld.last_column + 1));
  return a.join('\n');
}

// ---- reading -----------------------------------------------------------------------------------------------------
// callSites({ srcDir, testsRepoDir }) -> { sites, unreadable: [{ file, line?, message }], counts, classes }
// `testsRepoDir` absent or not a tests repo ⇒ only src is read (counts.testsRepo = false).
function callSites({ srcDir, testsRepoDir } = {}) {
  const { CoffeeScript, Class, Mixin } = loadMetaCompiler({ srcDir, compileFGCode: () => '(function() {});' });
  const fragments = [];
  const realClassRewrite = Class.prototype._rewriteSuperCalls;
  Class.prototype._rewriteSuperCalls = function (member, text) {
    const out = realClassRewrite.apply(this, arguments);
    const isStatic = this.nonStaticPropertiesSources?.[member] !== text && this.staticPropertiesSources?.[member] === text;
    fragments.push({ member, isStatic, input: text, output: out });
    return out;
  };
  const realMixinRewrite = Mixin.prototype._rewriteSuperCalls;
  Mixin.prototype._rewriteSuperCalls = function (text) {
    const out = realMixinRewrite.apply(this, arguments);
    fragments.push({ input: text, output: out });
    return out;
  };

  const units = [];          // { file, where, lang, text, lineOf(k0) → file line, scope, cls?, memberAt? }
  const unreadable = [];
  const classes = new Map(); // name → { superName, hasCtor } — by NAME, the first definition read: the identity (D2(a))
  // EVERY class definition, with the HOME it runs in (below): the arity test resolves a class where its call runs
  const classDefs = new Map(); // name → [{ name, superName, hasCtor, home, file }]
  const defineClass = (name, superName, hasCtor, home, file) => {
    if (!name) return;
    if (!classes.has(name)) classes.set(name, { superName, hasCtor });
    if (!classDefs.has(name)) classDefs.set(name, []);
    classDefs.get(name).push({ name, superName, hasCtor, home, file });
  };
  const ours = new Set();
  // the names a CoffeeScript text defines join `ours`; a text the lexer refuses defines nothing here, since its parse
  // below reports it as unreadable
  const harvestDefsOf = (text, where) => {
    try { harvestDefs(coffeeMask(text, where), ours); } catch (e) { if (!/^COFFEE_MASK_UNLEXABLE /.test(e.message)) throw e; }
  };
  const counts = { src: 0, harness: 0, macro: 0, heredoc: 0, script: 0, fragments: 0, testsRepo: false };

  const readCoffeeFile = (file, where) => {
    const src = fs.readFileSync(file, 'utf8');
    const lines = src.split('\n');
    harvestDefsOf(src, file);
    const before = fragments.length;
    const silence = [console.log, console.info, console.warn];
    console.log = console.info = console.warn = () => {};
    let meta;
    try {
      if (IS_CLASS.test(src)) meta = { cls: new Class(src, true, false) };
      else if (IS_MIXIN.test(src)) meta = { mixin: new Mixin(src, true, false) };
    } catch (e) { unreadable.push({ file, message: 'the meta-compiler: ' + e.message }); return; }
    finally { [console.log, console.info, console.warn] = silence; }
    if (meta && meta.cls) {
      const c = meta.cls;
      defineClass(c.name, c.superClassName || undefined, Object.prototype.hasOwnProperty.call(c.nonStaticPropertiesSources, 'constructor'), 'page', file);
      for (const f of fragments.slice(before)) {
        counts.fragments++;
        // fragment line 0 is the rest of the `  name: …` header line, line k > 0 is header + k, verbatim
        const header = new RegExp('^  ' + (f.isStatic ? '@' : '') + f.member.replace(/\$/g, '\\$') + ' *: *(.*)$');
        const fl = f.input.split('\n');
        const at = [];
        for (let h = 0; h < lines.length; h++) {
          const m = header.exec(lines[h]);
          if (m && m[1] === fl[0] && fl.every((l, k) => k === 0 || lines[h + k] === l)) at.push(h);
        }
        if (at.length !== 1) { unreadable.push({ file, message: `member ${f.member}: its fragment maps to ${at.length} places in the file` }); continue; }
        const h = at[0];
        units.push({ file, where, lang: 'coffee', home: 'page', text: f.output, cls: c.name, lineOf: (k0) => h + k0 + 1,
          scope: file + '#' + (f.isStatic ? '@' : '') + f.member, member: f.member, isStatic: f.isStatic });
      }
    } else if (meta && meta.mixin) {
      for (const f of fragments.slice(before)) units.push({ file, where, lang: 'coffee', home: 'page', text: f.output, lineOf: (k0) => k0 + 1, scope: file, mixin: true });
    } else {
      units.push({ file, where, lang: 'coffee', home: 'page', text: src, lineOf: (k0) => k0 + 1, scope: file });
    }
  };

  const coffeeFiles = walkFiles(srcDir, '.coffee');
  for (const file of coffeeFiles) { counts.src++; readCoffeeFile(file, 'src'); }
  const repo = testsRepoDir && testsRepoFiles(testsRepoDir);
  // each macro command file's sources, through the one reader: parsed as CoffeeScript here, and skipped (by their spans)
  // when its JS shell is read with the scripts below
  const macroFilesRead = [];
  if (repo) {
    counts.testsRepo = true;
    for (const file of repo.harness) { counts.harness++; readCoffeeFile(file, 'harness'); coffeeFiles.push(file); }
    for (const file of repo.macro) {
      try { macroFilesRead.push({ file, sources: testMacroSourcesIn(fs.readFileSync(file, 'utf8'), file) }); }
      catch (e) { unreadable.push({ file, message: e.message }); }
    }
    for (const { file, sources } of macroFilesRead) {
      for (const s of sources) {
        counts.macro++;
        harvestDefsOf(s.text, `${file} (its macro source from line ${s.line})`);
        units.push({ file, where: 'macro', lang: 'coffee', home: 'macro:' + file, text: s.text, lineOf: (k0) => s.line + k0, scope: 'macros' });
      }
    }
  }
  Class.prototype._rewriteSuperCalls = realClassRewrite;
  Mixin.prototype._rewriteSuperCalls = realMixinRewrite;

  // parse every CoffeeScript unit
  const parsed = [];
  const parseCoffee = (u) => {
    try { parsed.push({ u, ast: CoffeeScript.nodes(u.text) }); return true; }
    catch (e) { unreadable.push({ file: u.file, line: e.location ? u.lineOf(e.location.first_line) : undefined, message: 'CoffeeScript: ' + e.message }); return false; }
  };
  for (const u of units) parseCoffee(u);
  // the verbs — every Macro.fromString literal of a CoffeeScript file read above, through the one reader
  // (lib/macro-sources.js): cooked, on its file lines
  for (const file of coffeeFiles) {
    let verbs;
    try { verbs = verbMacroSourcesIn(fs.readFileSync(file, 'utf8'), file); } catch (e) { unreadable.push({ file, message: e.message }); continue; }
    for (const v of verbs) {
      counts.heredoc++;
      harvestDefsOf(v.text, `${file} (its verb from line ${v.line})`);
      parseCoffee({ file, where: 'heredoc', lang: 'coffee', home: 'verbs', text: v.text, lineOf: (k0) => v.line + k0, scope: 'macros' });
    }
  }

  const sites = [];
  // DEFINITIONS (the arity test's other half): key → [{ file, line, home, form, fn, arity, optsAt }]
  const defs = new Map();
  const define = (key, d) => { if (!defs.has(key)) defs.set(key, []); defs.get(key).push(d); };
  for (const { u, ast } of parsed) {
    // a test's macro and every standard verb are linked into ONE program: a name it binds, at any depth, is a NAME of
    // that program (not a local), and a function it assigns one harvestDefs' line forms cannot see when indented
    const macros = u.scope === 'macros';
    const at = (n) => ({ file: u.file, line: u.lineOf(n.locationData.first_line), home: u.home });
    // FRAMES — CoffeeScript's scopes are its functions. A PARAMETER belongs to its own function (it shadows); a name
    // a function ASSIGNS (a destructured or loop variable included) to the OUTERMOST enclosing function that binds it,
    // for an assignment captures an outer variable — and to the unit's top level when that assigns it (a boot global,
    // called by name from other files too: one `name:` group, else a witness in another file would hide).
    const frameOf = new Map();                                            // node → its innermost enclosing frame
    const topAssigns = new Set();
    const bindsOf = (n) => (shape(n) === 'body,source,guard,step' ? [n.name, n.index].flatMap((t) => patternNames(t))
      : isAssign(n) && n.context !== 'object' && !(isValue(n.variable) && n.variable.properties.length) ? patternNames(n.variable) : []);
    const scan = (n, frame) => {
      if (Array.isArray(n)) { for (const x of n) scan(x, frame); return; }
      if (!kids(n)) return;
      frameOf.set(n, frame);
      for (const name of bindsOf(n)) (frame ? frame.assigns : topAssigns).add(name);
      let inner = frame;
      if (isCode(n)) {
        inner = { id: n.locationData.first_line + ':' + n.locationData.first_column, parent: frame, code: n,
          depth: frame ? frame.depth + 1 : 1, params: new Set(), assigns: new Set() };
        for (const p of n.params) if (isParam(p)) for (const name of patternNames(p.name)) inner.params.add(name);
      }
      for (const c of n.children) scan(n[c], inner);
    };
    scan(ast, undefined);
    const localKey = (frame, name) => 'local:' + u.scope + '#' + frame.id + '#' + name;
    const resolve = (name, frame) => {
      if (macros) return 'name:' + name;
      let outer;
      for (let f = frame; f; f = f.parent) {
        if (f.params.has(name)) return localKey(f, name);
        if (f.assigns.has(name)) outer = f;
      }
      return outer && !topAssigns.has(name) ? localKey(outer, name) : 'name:' + name;
    };
    u.resolve = resolve;
    u.frameOf = frameOf;
    if (u.member !== undefined) {
      // a class member: the fragment IS its value
      define(u.member === 'constructor' && !u.isStatic ? 'ctor:' + u.cls : 'name:' + u.member,
        { file: u.file, line: u.lineOf(0), home: u.home, form: 'member', ...csSignature(ast.expressions && ast.expressions[0]) });
    }
    // a MIXIN's members are the object keys at its member level, inside onceAddedClassProperties (one function deep)
    const mixinMember = (n) => u.mixin && frameOf.get(n) && frameOf.get(n).depth === 1;
    u.receivers = new Set();             // the functions whose `this` is the unit's own receiver (header, `via`)
    if (u.member !== undefined && unwrapCode(ast.expressions && ast.expressions[0])) u.receivers.add(unwrapCode(ast.expressions[0]));
    const walk = (n, cls) => {
      if (Array.isArray(n)) { for (const x of n) walk(x, cls); return; }
      if (!kids(n)) return;
      const frame = frameOf.get(n);
      if (shape(n) === 'variable,parent,body') {
        const name = plainIdent(n.variable);
        let hasCtor = false;
        walkCS(n.body, (m) => { if (isAssign(m) && m.context === 'object' && isCode(m.value) && objectKey(m.variable) === 'constructor') hasCtor = true; });
        defineClass(name, n.parent ? (plainIdent(n.parent) || '<computed>') : undefined, hasCtor, u.home, u.file);
        walk(n.body, name);
        return;
      }
      if (isCode(n)) for (const p of n.params) {
        if (!isParam(p)) continue;
        for (const name of patternNames(p.name)) define(macros ? 'name:' + name : localKey(frameOf.get(p), name), { ...at(p), form: 'binding', ...DATA });
        const field = thisField(p.name);                                 // `(@target) ->` assigns a field
        if (field) define('name:' + field, { ...at(p), form: 'field', ...DATA });
      }
      for (const name of shape(n) === 'body,source,guard,step' ? bindsOf(n) : []) define(resolve(name, frame), { ...at(n), form: 'binding', ...DATA });
      if (isAssign(n)) {
        const sig = csSignature(n.value);
        const v = n.variable;
        if (n.context === 'object') {
          const k = objectKey(v);
          const member = cls || mixinMember(n);
          if (member && u.mixin && unwrapCode(n.value)) u.receivers.add(unwrapCode(n.value));
          if (k !== undefined) define(cls && k === 'constructor' ? 'ctor:' + cls : 'name:' + k, { ...at(n), form: member ? 'member' : 'key', ...sig });
        } else if (plainIdent(v)) {
          const name = plainIdent(v);
          if (macros && sig.fn) ours.add(name);
          if (macros && !frame && unwrapCode(n.value)) u.receivers.add(unwrapCode(n.value));      // `m_Macro = ->`
          define(resolve(name, frame), { ...at(n), form: 'binding', ...sig });
        } else if (isValue(v) && v.properties.length) {
          const p = propName(v.properties[v.properties.length - 1]);
          if (p) define('name:' + p, { ...at(n), form: 'field', ...sig });
          if (p && v.properties.length === 1 && isLiteral(v.base) && v.base.value === 'window') define('name:' + p, { ...at(n), form: 'binding', ...sig });
        } else for (const name of patternNames(v)) define(resolve(name, frame), { ...at(n), form: 'binding', ...DATA });
      }
      for (const c of n.children) walk(n[c], isCode(n) ? undefined : cls);
    };
    walk(ast, undefined);
  }
  for (const { u, ast } of parsed) {
    const lines = u.text.split('\n');
    // a mixin's super resolves at run time through `arguments.callee.name`: the INNERMOST function-valued
    // property around the call is the member it supers
    const members = [];
    if (u.mixin) walkCS(ast, (n) => { if (isAssign(n) && n.context === 'object' && isCode(n.value) && isValue(n.variable) && isLiteral(n.variable.base))
      members.push({ name: n.variable.base.value, first: n.locationData.first_line, last: n.locationData.last_line }); });
    const memberAt = (k0) => members.filter((m) => m.first <= k0 && k0 <= m.last).sort((a, b) => b.first - a.first)[0]?.name;
    const arg = (a) => {
      const kind = csArgKind(a);
      return { text: short(textOf(lines, a.locationData)), spread: kind === 'spread', absent: kind === 'absent', kind };
    };
    // `@` is the unit's own receiver inside one of its RECEIVER functions (a class member; a macro or a verb; a
    // mixin's member), through any `=>` (it keeps `this`), never under a `->` (it rebinds it) nor at a unit's top
    // level (a boot file's `@` is `window`)
    const ownThis = (node) => {
      let f = u.frameOf.get(node);
      while (f && f.code.bound) f = f.parent;
      return !!f && u.receivers.has(f.code);
    };
    for (const c of csCallsOf(ast)) {
      const v = c.variable;
      const base = isValue(v) ? v.base : v;
      const props = isValue(v) ? v.properties : [];
      const baseName = isLiteral(base) ? base.value : undefined;
      const last = props.length ? propName(props[props.length - 1]) : undefined;
      const site = { file: u.file, line: u.lineOf(c.ld.first_line), where: u.where, lang: 'coffee', home: u.home, scope: u.scope, cls: u.cls };
      let args = c.args;
      if (c.isNew) {
        // `new @constructor …` in a class builds that class (or a subclass: grouping it with the class only adds
        // witnesses); `new a.b.X …` names X — judged when X is a class some code defines
        const own = baseName === 'this' && props.length === 1 && last === 'constructor' && u.cls;
        Object.assign(site, { kind: 'new', selfNew: !!own, name: own ? u.cls : props.length ? last : (IDENT.test(baseName || '') ? baseName : undefined) });
      } else if (props.length >= 2 && (last === 'call' || last === 'apply') && props.some((p) => propName(p) === '__super__')) {
        const member = u.cls ? (props.length === 3 ? propName(props[1]) : undefined) : (u.mixin ? memberAt(c.ld.first_line) : undefined);
        Object.assign(site, { kind: 'super', name: member, superOf: u.cls });
        if (last === 'apply') { site.forwarding = true; args = []; } else args = args.slice(1);
      } else if (!props.length) {
        Object.assign(site, { kind: 'bare', name: IDENT.test(baseName || '') && baseName !== 'this' ? baseName : undefined });
        if (site.name) site.binding = u.resolve(site.name, u.frameOf.get(c.node));
      } else {
        Object.assign(site, { kind: 'send', name: last, receiver: short((baseName === 'this' ? '@' : (baseName || '(…)')) + props.slice(0, -1).map((p) => '.' + (propName(p) || '[…]')).join(''), 40) });
        if (baseName === 'this' && props.length === 1) {
          site.receiver = '@';
          if (ownThis(c.node)) { site.via = 'this'; if (u.scope === 'macros') site.cls = 'MacroToolkit'; }
        } else if (props.length === 1 && IDENT.test(baseName || '')) site.via = 'name:' + baseName;
      }
      site.args = args.map(arg);
      sites.push(site);
    }
  }

  // JS: the tests repo's scripts and each macro file's shell (its macro sources are CoffeeScript, read above)
  const imports = new Map();     // script file → Map(imported name → the module file defining it)
  if (repo) {
    const jsDefs = new Set();
    const readJs = (file, where, skipRanges) => {
      const text = fs.readFileSync(file, 'utf8');
      let ast;
      for (const sourceType of ['script', 'module']) {
        try { ast = acorn.parse(text, { ecmaVersion: 'latest', sourceType, allowHashBang: true, allowReturnOutsideFunction: true, locations: true }); break; }
        catch (e) { if (sourceType === 'module') unreadable.push({ file, message: 'acorn: ' + e.message }); }
      }
      if (!ast) return;
      const inSkip = (n) => skipRanges.some(([s, e]) => s <= n.start && n.end <= e);
      const scope = file;
      const visit = (n, fn) => {
        if (Array.isArray(n)) { for (const x of n) visit(x, fn); return; }
        if (!n || typeof n.type !== 'string' || inSkip(n)) return;
        fn(n);
        for (const k of Object.keys(n)) if (k !== 'loc' && n[k] && typeof n[k] === 'object') visit(n[k], fn);
      };
      const home = where === 'script' ? 'node:' + file : 'page';      // a script runs in Node; a test file's JS shell in the page
      // FRAMES — a JS scope is its function (a block's `let` is read as its function's: an approximation that can only
      // keep a name local): a parameter, a declaration (destructured, loop and catch variables included), a nested
      // function's name. A name no function declares is the file's top level, a NAME — a module function may be
      // exported and called by name from another file (the CS rule).
      const frameOf = new Map();
      const topDeclared = new Set();
      const declsOf = (n) => (n.type === 'VariableDeclarator' ? jsPatternNames(n.id)
        : (n.type === 'FunctionDeclaration' || n.type === 'ClassDeclaration') && n.id ? [n.id.name]
        : n.type === 'CatchClause' && n.param ? jsPatternNames(n.param) : []);
      const scan = (n, frame) => {
        if (Array.isArray(n)) { for (const x of n) scan(x, frame); return; }
        if (!n || typeof n.type !== 'string' || inSkip(n)) return;
        frameOf.set(n, frame);
        for (const name of declsOf(n)) (frame ? frame.declared : topDeclared).add(name);
        let inner = frame;
        if (isJsFn(n)) {
          inner = { id: n.start, parent: frame, declared: new Set() };
          for (const p of n.params) for (const name of jsPatternNames(p)) inner.declared.add(name);
        }
        for (const k of Object.keys(n)) {
          if (k === 'loc' || !n[k] || typeof n[k] !== 'object') continue;
          // a function declaration's NAME is its enclosing scope's (declsOf, above); its params and body its own
          scan(n[k], isJsFn(n) && k === 'id' ? frame : inner);
        }
      };
      scan(ast, undefined);
      const resolve = (name, frame) => {
        for (let f = frame; f; f = f.parent) if (f.declared.has(name)) return 'local:' + file + '#' + f.id + '#' + name;
        return 'name:' + name;
      };
      // what the file defines (ours)
      const declJs = (n) => {
        if (Array.isArray(n)) { for (const x of n) declJs(x); return; }
        if (!n || typeof n.type !== 'string' || inSkip(n)) return;
        if (n.type === 'FunctionDeclaration' && n.id) jsDefs.add(n.id.name);
        if (n.type === 'VariableDeclarator' && n.id.type === 'Identifier' && n.init && isJsFn(n.init)) jsDefs.add(n.id.name);
        if (n.type === 'Property' && !n.computed && n.key.type === 'Identifier' && (n.method || /Function/.test(n.value.type))) jsDefs.add(n.key.name);
        if (n.type === 'MethodDefinition' && n.key.type === 'Identifier') jsDefs.add(n.key.name);
        if (n.type === 'PropertyDefinition' && !n.computed && n.key.type === 'Identifier' && isJsFn(n.value)) jsDefs.add(n.key.name);
        if (n.type === 'AssignmentExpression' && n.left.type === 'MemberExpression' && !n.left.computed && /Function/.test(n.right.type)) jsDefs.add(n.left.property.name);
        if ((n.type === 'ClassDeclaration' || n.type === 'ClassExpression') && n.id)
          defineClass(n.id.name, n.superClass ? (n.superClass.type === 'Identifier' ? n.superClass.name : '<computed>') : undefined,
            n.body.body.some((m) => m.kind === 'constructor'), home, file);
        for (const k of Object.keys(n)) if (k !== 'loc' && n[k] && typeof n[k] === 'object') declJs(n[k]);
      };
      declJs(ast);
      // its DEFINITIONS (the CoffeeScript forms' twins). A name a top-level `const { f } = require('./m')` destructures,
      // unrenamed, from a RELATIVE module is an IMPORT: it reaches that module's own `f` (`imports`) and defines nothing
      // itself; from any other module, or renamed, it is DATA — a definition no reader sees.
      const fileImports = new Map();
      const defineJs = (n, cls) => {
        if (Array.isArray(n)) { for (const x of n) defineJs(x, cls); return; }
        if (!n || typeof n.type !== 'string' || inSkip(n)) return;
        const frame = frameOf.get(n);
        const here = { file, line: n.loc.start.line, home };
        const bind = (key, sig) => define(key, { ...here, form: 'binding', ...sig });
        if (n.type === 'FunctionDeclaration' && n.id) bind(resolve(n.id.name, frame), jsSignature(n));
        if (n.type === 'VariableDeclarator') {
          if (n.id.type === 'Identifier') bind(resolve(n.id.name, frame), jsSignature(n.init));
          else {
            const spec = !frame && isJsRequire(n.init) && n.init.arguments[0] && n.init.arguments[0].type === 'Literal' ? n.init.arguments[0].value : undefined;
            const from = typeof spec === 'string' && /^\.\.?\//.test(spec) ? jsModuleFile(file, spec) : undefined;
            for (const q of n.id.type === 'ObjectPattern' ? n.id.properties : []) {
              const shorthand = q.type === 'Property' && !q.computed && q.key.type === 'Identifier' && q.value.type === 'Identifier' && q.key.name === q.value.name;
              if (from && shorthand) fileImports.set(q.key.name, from);
            }
            for (const id of jsPatternNames(n.id)) if (!fileImports.has(id) || frame) bind(resolve(id, frame), DATA);
          }
        }
        if (isJsFn(n)) for (const p of n.params) for (const id of jsPatternNames(p)) bind(resolve(id, frameOf.get(p.type === 'AssignmentPattern' ? p.left : p) || frameOf.get(n.body)), DATA);
        if (n.type === 'CatchClause' && n.param) for (const id of jsPatternNames(n.param)) bind(resolve(id, frame), DATA);
        if (n.type === 'AssignmentExpression' && n.left.type === 'Identifier') bind(resolve(n.left.name, frame), jsSignature(n.right));
        if (n.type === 'AssignmentExpression' && n.left.type === 'MemberExpression' && !n.left.computed) {
          const sig = jsSignature(n.right);
          define('name:' + n.left.property.name, { ...here, form: 'field', ...sig });
          if (n.left.object.type === 'Identifier' && /^(window|globalThis|self)$/.test(n.left.object.name)) bind('name:' + n.left.property.name, sig);
        }
        if (n.type === 'ObjectExpression') for (const p of n.properties) if (p.type === 'Property' && !p.computed && (p.key.type === 'Identifier' || p.key.type === 'Literal'))
          define('name:' + (p.key.type === 'Identifier' ? p.key.name : String(p.key.value)), { file, line: p.loc.start.line, home, form: 'key', ...jsSignature(p.value) });
        // a getter or a setter is not the callable: `this.h(1)` calls what the getter RETURNS — DATA
        if ((n.type === 'MethodDefinition' || n.type === 'PropertyDefinition') && !n.computed && n.key.type === 'Identifier' && (n.kind !== 'constructor' || cls))
          define(n.kind === 'constructor' ? 'ctor:' + cls : 'name:' + n.key.name, { ...here, form: 'member', ...(n.kind === 'get' || n.kind === 'set' ? DATA : jsSignature(n.value)) });
        const inner = n.type === 'ClassDeclaration' || n.type === 'ClassExpression' ? (n.id ? n.id.name : undefined) : cls;
        for (const k of Object.keys(n)) if (k !== 'loc' && n[k] && typeof n[k] === 'object') defineJs(n[k], isJsFn(n) ? undefined : inner);
      };
      defineJs(ast, undefined);
      if (fileImports.size) imports.set(file, fileImports);
      // `this` is a class's own receiver inside its methods and field initializers (an arrow keeps it, a `function`
      // rebinds it): the class it names, or none
      const thisClass = new Map();
      const thisWalk = (n, cls, inClass) => {
        if (Array.isArray(n)) { n.forEach((x) => thisWalk(x, cls, inClass)); return; }
        if (!n || typeof n.type !== 'string') return;
        thisClass.set(n, cls);
        const named = n.type === 'ClassDeclaration' || n.type === 'ClassExpression' ? (n.id ? n.id.name : '<anonymous>') : inClass;
        for (const k of Object.keys(n)) {
          if (k === 'loc' || !n[k] || typeof n[k] !== 'object') continue;
          const child = n[k];
          const own = (n.type === 'MethodDefinition' && k === 'value') || (n.type === 'PropertyDefinition' && k === 'value') ? named
            : (child.type === 'FunctionExpression' || child.type === 'FunctionDeclaration') ? undefined : cls;
          thisWalk(child, own, named);
        }
      };
      thisWalk(ast, undefined, undefined);
      visit(ast, (n) => {
        if (n.type !== 'CallExpression' && n.type !== 'NewExpression') return;
        const c = n.callee;
        const site = { file, line: n.loc.start.line, where, lang: 'js', home, scope: file };
        if (n.type === 'NewExpression') Object.assign(site, { kind: 'new', name: c.type === 'Identifier' ? c.name : (c.type === 'MemberExpression' && !c.computed ? c.property.name : undefined) });
        else if (c.type === 'Identifier') Object.assign(site, { kind: 'bare', name: c.name, binding: resolve(c.name, frameOf.get(n)) });
        else if (c.type === 'MemberExpression') {
          Object.assign(site, { kind: 'send', receiver: short(text.slice(c.object.start, c.object.end), 40),
            name: !c.computed ? c.property.name : (c.property.type === 'Literal' && typeof c.property.value === 'string' ? c.property.value : undefined) });
          if ((c.object.type === 'ThisExpression' || c.object.type === 'Super') && thisClass.get(n)) { site.via = 'this'; site.cls = thisClass.get(n); }
          else if (c.object.type === 'Identifier') site.via = 'name:' + c.object.name;
        } else Object.assign(site, { kind: 'bare', name: undefined });
        site.args = n.arguments.map((a) => { const kind = jsArgKind(a); return { text: short(text.slice(a.start, a.end)), spread: kind === 'spread', absent: kind === 'absent', kind }; });
        sites.push(site);
      });
    };
    for (const file of repo.script) { counts.script++; readJs(file, 'script', []); }
    for (const { file, sources } of macroFilesRead) readJs(file, 'macro', sources.map((s) => [s.start - 1, s.end + 1]));
    for (const x of jsDefs) ours.add(x);
  }

  // ---- identity (D2(a)) ----
  const chainOf = (name) => { const out = []; const seen = new Set(); let c = classes.get(name), n = name;
    while (c && !seen.has(n)) { seen.add(n); out.push(n); n = c.superName; c = classes.get(n); } return out; };
  const ctorOwner = (name) => { const ch = chainOf(name); return ch.find((n) => classes.get(n).hasCtor) || ch[ch.length - 1]; };
  for (const s of sites) {
    s.knownArity = !s.forwarding && !s.args.some((a) => a.spread);
    if (s.kind === 'new') {
      s.callee = !s.name ? { foreign: 'a dynamic new' } : classes.has(s.name) ? { key: 'ctor:' + ctorOwner(s.name) } : { foreign: 'new of a class no code defines' };
    } else if (s.kind === 'super') {
      if (s.name === 'constructor') s.callee = { key: 'ctor:' + ctorOwner(classes.get(s.superOf).superName) };
      else s.callee = s.name ? { key: 'name:' + s.name } : { unplaceable: true };
    } else if (!s.name) s.callee = { foreign: 'a dynamic callee' };
    else if (s.kind === 'send' && THIS_ARG.has(s.name)) s.callee = { excluded: '.call/.apply/.bind: the first argument is a this-arg' };
    else if (s.kind === 'bare' && s.binding && s.binding.startsWith('local:')) s.callee = { key: s.binding };
    else s.callee = ours.has(s.name) ? { key: 'name:' + s.name } : { foreign: 'a name no code in either repo defines' };
    let last = -1;
    s.args.forEach((a, i) => { if (!a.absent) last = i; });
    s.reach = last + 1;
    s.candidate = s.args.some((a, i) => a.absent && i < last);
  }
  for (const s of sites) if (s.callee.unplaceable) unreadable.push({ file: s.file, line: s.line, message: 'a super call no class chain places' });
  return { sites, unreadable, counts, classes, classDefs, defs, imports };
}

// THE CALLERS TEST over a site table -> { holes: [{ site, witness }], values: [{ site, sites }], foreign, excluded }
function callersTest(sites) {
  const byKey = new Map();
  for (const s of sites) if (s.callee.key) { if (!byKey.has(s.callee.key)) byKey.set(s.callee.key, []); byKey.get(s.callee.key).push(s); }
  const out = { holes: [], values: [], foreign: [], excluded: [] };
  for (const s of sites) {
    if (!s.candidate) continue;
    if (s.callee.excluded) { out.excluded.push({ site: s }); continue; }
    if (!s.callee.key) { out.foreign.push({ site: s }); continue; }
    const pool = byKey.get(s.callee.key);
    const witness = pool.find((t) => t !== s && t.knownArity && t.reach < s.reach);
    if (witness) out.holes.push({ site: s, witness }); else out.values.push({ site: s, sites: pool.length });
  }
  return out;
}

// THE ARITY TEST over a table (callSites' result) -> { extra: [{ site, widest }], intoOptions: [{ site, index, def }], judged }
// A call is judged only where the definitions it can reach are KNOWN (header, "THE ARITY TEST"); its declared count is
// the widest of them. EXTRA: it passes more arguments than that. INTO OPTIONS: its definitions agree on an options slot
// (`opts = {}`) and the argument there is of a kind the parse alone shows is no options object.
const NOT_OPTIONS = new Set(['this', 'literal', 'array', 'function', 'new']);
// a name Node itself defines as a global (Map, URL, fetch, …): what a script's bare `X` may mean when no code of its own
// binds it — asked of this very process, never listed
const isNodeGlobal = (name) => typeof globalThis[name] !== 'undefined';
function arityTest({ sites, defs, classDefs, imports }) {
  // may a definition made at `home` be what a call running at the site's home reaches? Page code (src, the harness)
  // is seen by every page program; the standard verbs by every macro; a macro program sees only its own; a script
  // only its own module (its imports are resolved by name, below)
  const sees = (site, home) => site.home === home || (!site.home.startsWith('node:')
    && (home === 'page' || (home === 'verbs' && (site.home === 'verbs' || site.home.startsWith('macro:')))));
  // the ONE class `name` names where `at` ({ home, file }) runs, or undefined (none, or more than one)
  const classAt = (name, at) => {
    const all = classDefs.get(name) || [];
    let vis = all.filter((c) => c.home === at.home);                      // a program's own class shadows the page's
    if (at.home.startsWith('node:')) {
      const from = imports.get(at.file)?.get(name);
      if (!vis.length && from) vis = all.filter((c) => c.home === 'node:' + from);
      if (!vis.length && !from && !isNodeGlobal(name)) vis = all.filter((c) => c.home === 'page');   // a page.evaluate body
    } else if (!vis.length) vis = all.filter((c) => sees(at, c.home));
    return vis.length === 1 ? vis[0] : undefined;
  };
  // c and its ancestors, or undefined when the chain leaves the code read (an `Array`, an `EventEmitter`, a computed
  // or ambiguous parent): an inherited member, or an inherited constructor, would be one no reader sees
  const chain = (c) => {
    const out = [];
    for (let k = c; k; k = k.superName ? classAt(k.superName, k) : undefined) {
      out.push(k);
      if (!k.superName) return out;
      if (out.length > 64) return undefined;
    }
    return undefined;
  };
  const ctorOf = (c) => {
    const ch = c && chain(c);
    if (!ch) return [];
    const owner = ch.find((k) => k.hasCtor);
    // no constructor anywhere up the chain: each synthesized one (Class.coffee; a JS default) forwards to a base that
    // takes none
    if (!owner) return [{ fn: true, arity: 0, optsAt: -1, implicit: c.name }];
    return (defs.get('ctor:' + owner.name) || []).filter((d) => d.home === owner.home && d.file === owner.file);
  };
  const reach = (s) => {
    if (s.kind === 'new') return s.selfNew ? [] : ctorOf(classAt(s.name, s));   // `new @constructor` may build a subclass
    const named = (s.callee.key && defs.get(s.callee.key)) || [];
    if (s.kind === 'super' && s.name === 'constructor') {
      const c = classAt(s.superOf, s);
      return c && c.superName ? ctorOf(classAt(c.superName, c)) : [];
    }
    if (s.kind === 'bare') {
      const bindings = named.filter((d) => d.form === 'binding');
      if (s.callee.key.startsWith('local:')) return bindings;                 // the function that binds it
      if (!s.home.startsWith('node:')) return bindings.filter((d) => sees(s, d.home));
      const own = bindings.filter((d) => d.home === s.home);
      const from = imports.get(s.file)?.get(s.name);
      // nothing in the module binds it: Node's global, or the page's in a page.evaluate body — no reader knows which
      return own.length ? own : from ? bindings.filter((d) => d.home === 'node:' + from) : [];
    }
    // a send: the receiver must be ours, its whole class chain read (a mixin's `@` is any class it augments: ours)
    if (s.kind === 'super') { const c = classAt(s.superOf, s); if (!c || !chain(c)) return []; }
    else if (s.via === 'this') { if (s.cls) { const c = classAt(s.cls, s); if (!c || !chain(c)) return []; } }
    else if (s.via && s.via.startsWith('name:')) { const c = classAt(s.via.slice('name:'.length), s); if (!c || !chain(c)) return []; }
    else return [];                                                           // a receiver no reader can see
    // a method is a MEMBER or a FIELD some code defines: none at all, and the call's target is assembled at run time
    // (not judged). Then a FUNCTION held under an object-literal key reaches it too — an `impl` object installed by a
    // computed key (`X::[k] = v`): widening can only hide an extra argument, never invent one
    const seen = named.filter((d) => (s.home.startsWith('node:') ? d.home.startsWith('node:') : sees(s, d.home)));
    if (!seen.some((d) => d.form === 'member' || d.form === 'field')) return [];
    return seen.filter((d) => d.form === 'member' || d.form === 'field' || (d.form === 'key' && d.fn));
  };
  const out = { extra: [], intoOptions: [], judged: 0 };
  for (const s of sites) {
    if (!s.callee.key || !s.knownArity) continue;
    const ds = reach(s);
    if (!ds.length || ds.some((d) => !d.fn)) continue;
    const widest = ds.reduce((a, d) => (d.arity > a.arity ? d : a));
    if (widest.arity === Infinity) continue;
    out.judged++;
    if (s.args.length > widest.arity) out.extra.push({ site: s, widest });
    const slots = new Set(ds.map((d) => d.optsAt));
    const i = slots.size === 1 ? [...slots][0] : -1;
    if (i >= 0 && i < s.args.length && NOT_OPTIONS.has(s.args[i].kind)) out.intoOptions.push({ site: s, index: i, def: ds.find((d) => d.optsAt === i) });
  }
  return out;
}

// how a site's callee reads in a report — the gate's and the census's one spelling
function describeCallee(s) {
  if (s.kind === 'new') return 'new ' + s.name;
  if (s.kind === 'super') return `super (${s.superOf}.${s.name})`;
  if (s.receiver === '@') return '@' + s.name;
  return (s.receiver ? s.receiver + '.' : '') + s.name;
}

module.exports = { callSites, callersTest, arityTest, csCallsOf, describeCallee };
