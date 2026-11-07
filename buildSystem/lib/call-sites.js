'use strict';
// call-sites.js — EVERY CALL SITE in both repos, read by real parsers, and the CALLERS TEST over them: the one reader
// behind check-argument-holes.js (the gate) and census-call-arity.js (the advisory queries), so the two can never
// disagree about what a call is or what a hole is.
//
// WHAT IS READ, AND HOW (each the way the code actually runs):
//   - Fizzygum/src and the tests repo's harness: every CLASS through the browser's own meta-compiler
//     (lib/meta-compiler.js) — each member fragment AFTER Class.coffee's super rewrite, so a `super` is an ordinary
//     call `<Cls>.__super__.<member>.call this, …` (a bare `super` forwards: `.apply(this, arguments)`); every MIXIN
//     as one source after Mixin.coffee's rewrite; every other file (boot) whole. Parsed with the bundled
//     CoffeeScript 2.0.3 `nodes()` — the browser's own grammar.
//   - every test's macro sources (lib/tests-repo-code.js macroSources: the COOKED text the page compiles), as
//     authored — before Macro.coffee rewrites verb calls into `yield from`.
//   - the `Macro.fromString "…"` HEREDOCS (MacroToolkit's standard verbs: CODE in a string): lifted and parsed, each
//     line mapped back to its file line.
//   - the tests repo's scripts and each macro file's JS shell: acorn (vendor/acorn), skipping the shell's macro
//     templates. The file set is tests-repo-code's testsRepoFiles.
// ⚠ The 2.0.3 bundle is MINIFIED, so node kinds are told STRUCTURALLY, by their `children` names. A call is one of
//   THREE shapes (found by cross-checking every call against CoffeeScript 2.7's `ast: true`, archive plan §9):
//   a Call {variable, args} (`isNew` for `new X(args)` / `new X args`); an ARGUMENT-LESS `new X`, which is NOT a
//   Call but `Op('new', X)`; and `new X(args).prop`, an `Op('new')` over a property chain around a NON-new Call.
//
// A SITE: { file, line (1-based, where the call STARTS), where ('src'|'harness'|'macro'|'heredoc'|'script'), lang,
//   kind ('new'|'super'|'bare'|'send'), name, receiver, args: [{ text, absent, spread }], forwarding, callee }.
//   `absent` = the argument is the bare identifier `undefined` — the codebase's ONE absence value (`null` is a value
//   by the house rule, `void 0` is spelled by no one). `callee` is the site's identity: `{ key }` — `ctor:<Owner>`
//   for a `new` or a constructor super (the nearest class up the chain that defines a constructor; the classes are
//   src's and the harness's, and those a script or a macro program defines; `new a.b.X` names X, `new @constructor`
//   the class it is written in), `name:<m>` for a send or a bare call of a name some code defines (BY NAME, whatever
//   the receiver — owner ruling D2(a): grouping more sites under one callee only adds witnesses, so it can invent a
//   hole, loudly, never hide one), `local:<scope>#<n>` ONLY for a bare call of a name nothing outside its unit can
//   reach — a parameter, or a function NESTED in another (a top-level function, a boot global or a JS module's, is
//   called from other files too: its calls are one `name:` group, else a witness in another file would hide) — or
//   `{ foreign }` (a name no code in either repo defines, a `new` of a class none defines or a computed one) or
//   `{ excluded }` (`.call`/`.apply`/`.bind`: their first argument is a foreign API's this-arg). A `Macro.fromString`
//   argument computed at run time (an interpolated heredoc) is UNREADABLE, never skipped. "Ours" is lib/name-definitions.js harvestDefs over every CoffeeScript text
//   read (one answer to "is this name ours?" across gates), plus the JS definitions, plus every function a macro
//   program assigns (indented, so beyond harvestDefs' line forms; a macro links with the verbs into one program,
//   so its helpers are names, not locals).
//
// THE CALLERS TEST (R3 of docs/architecture/constructor-and-parameter-conventions.md, mechanized): a site whose
// `undefined` comes BEFORE a present argument is a candidate; its REACH is 1 + the index of its last present
// argument (a spread counts as present). It is a HOLE iff another site of the same callee, of known arity, reaches
// LESS FAR — that site, the WITNESS, shows the tail is omittable, so this caller filled slots only to get past them.
// Otherwise it is a VALUE (every caller supplies the whole list: the `undefined` is the operand). Reach is the
// EFFECTIVE arity, so a trailing `undefined` written out is an omission like any other. A site whose arity is
// unknown (a spread, a forwarding super) is never a witness.

const fs = require('fs');
const path = require('path');
const { loadMetaCompiler } = require('./meta-compiler');
const { macroSources, testsRepoFiles } = require('./tests-repo-code');
const { maskJs } = require('./js-mask');
const { harvestDefs } = require('./name-definitions');
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

function walkCS(n, fn, seen = new Set()) {
  if (Array.isArray(n)) { for (const x of n) walkCS(x, fn, seen); return; }
  if (!kids(n) || seen.has(n)) return;
  seen.add(n);
  fn(n);
  for (const c of n.children) walkCS(n[c], fn, seen);
}

// every call of a 2.0.3 AST, normalized: { isNew, variable, args, ld } (the three shapes, header)
function csCallsOf(ast) {
  const newVia = new Map();
  const out = [];
  walkCS(ast, (n) => {
    if (!isOp(n) || n.operator !== 'new') return;
    const f = n.first;
    if (isValue(f) && isCall(f.base) && !f.base.isNew && f.properties.length) newVia.set(f.base, n);
    else out.push({ isNew: true, variable: f, args: [], ld: n.locationData });
  });
  walkCS(ast, (n) => {
    if (!isCall(n) || n.do) return;
    const op = newVia.get(n);
    out.push({ isNew: !!n.isNew || !!op, variable: n.variable, args: n.args || [], ld: (op || n).locationData });
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
  const realClassRewrite = Class.prototype._equivalentforSuper;
  Class.prototype._equivalentforSuper = function (member, text) {
    const out = realClassRewrite.apply(this, arguments);
    const isStatic = this.nonStaticPropertiesSources?.[member] !== text && this.staticPropertiesSources?.[member] === text;
    fragments.push({ member, isStatic, input: text, output: out });
    return out;
  };
  const realMixinRewrite = Mixin.prototype._equivalentforSuper;
  Mixin.prototype._equivalentforSuper = function (text) {
    const out = realMixinRewrite.apply(this, arguments);
    fragments.push({ input: text, output: out });
    return out;
  };

  const units = [];          // { file, where, lang, text, lineOf(k0) → file line, scope, cls?, memberAt? }
  const unreadable = [];
  const classes = new Map(); // name → { superName, hasCtor }
  const ours = new Set();
  const counts = { src: 0, harness: 0, macro: 0, heredoc: 0, script: 0, fragments: 0, testsRepo: false };

  const readCoffeeFile = (file, where) => {
    const src = fs.readFileSync(file, 'utf8');
    const lines = src.split('\n');
    harvestDefs(lines, ours);
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
      classes.set(c.name, { superName: c.superClassName, hasCtor: Object.prototype.hasOwnProperty.call(c.nonStaticPropertiesSources, 'constructor') });
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
        units.push({ file, where, lang: 'coffee', text: f.output, cls: c.name, lineOf: (k0) => h + k0 + 1,
          scope: file + '#' + (f.isStatic ? '@' : '') + f.member });
      }
    } else if (meta && meta.mixin) {
      for (const f of fragments.slice(before)) units.push({ file, where, lang: 'coffee', text: f.output, lineOf: (k0) => k0 + 1, scope: file, mixin: true });
    } else {
      units.push({ file, where, lang: 'coffee', text: src, lineOf: (k0) => k0 + 1, scope: file });
    }
  };

  for (const file of walkFiles(srcDir, '.coffee')) { counts.src++; readCoffeeFile(file, 'src'); }
  const repo = testsRepoDir && testsRepoFiles(testsRepoDir);
  if (repo) {
    counts.testsRepo = true;
    for (const file of repo.harness) { counts.harness++; readCoffeeFile(file, 'harness'); }
    for (const { file, sources } of macroSources(testsRepoDir)) {
      for (const s of sources) {
        counts.macro++;
        harvestDefs(s.text.split('\n'), ours);
        units.push({ file, where: 'macro', lang: 'coffee', text: s.text, lineOf: (k0) => s.line + k0, scope: 'macros' });
      }
    }
  }
  Class.prototype._equivalentforSuper = realClassRewrite;
  Mixin.prototype._equivalentforSuper = realMixinRewrite;

  // parse every CoffeeScript unit; lift the heredocs a parse finds
  const parsed = [];
  const parseCoffee = (u) => {
    try { parsed.push({ u, ast: CoffeeScript.nodes(u.text) }); return true; }
    catch (e) { unreadable.push({ file: u.file, line: e.location ? u.lineOf(e.location.first_line) : undefined, message: 'CoffeeScript: ' + e.message }); return false; }
  };
  for (const u of units) parseCoffee(u);
  for (const { u, ast } of parsed.slice()) {
    const fileLines = fs.readFileSync(u.file, 'utf8').split('\n');
    for (const c of csCallsOf(ast)) {
      const v = c.variable;
      if (c.isNew || !isValue(v) || !isLiteral(v.base) || v.base.value !== 'Macro' || v.properties.length !== 1 || propName(v.properties[0]) !== 'fromString') continue;
      if (c.args.length !== 1) continue;
      const a = c.args[0];
      // a REFERENCE (`eachSource`, `@mainMacroSource`) passes the macro sources themselves, read as macro units;
      // anything else computed — an interpolated heredoc — is code no reader can see
      const isReference = isValue(a) && isLiteral(a.base) && (a.base.value === 'this' || IDENT.test(a.base.value)) && a.properties.every(isAccess);
      if (isReference) continue;
      if (!isValue(a) || a.properties.length || !isStringLit(a.base)) {
        unreadable.push({ file: u.file, line: u.lineOf(c.ld.first_line), message: 'a Macro.fromString argument computed at run time (an interpolated heredoc?): its code cannot be read' });
        continue;
      }
      const open = u.lineOf(a.locationData.first_line);
      const text = new Function('return ' + a.base.value)();
      const off = text.split('\n').findIndex((l, k) => l.trim() && (fileLines[open + k] || '').trim() !== l.trim());
      if (off >= 0) { unreadable.push({ file: u.file, line: open, message: `heredoc line ${off} is not on file line ${open + 1 + off}` }); continue; }
      counts.heredoc++;
      harvestDefs(text.split('\n'), ours);
      const hd = { file: u.file, where: 'heredoc', lang: 'coffee', text, lineOf: (k0) => open + 1 + k0, scope: 'macros' };
      parseCoffee(hd);
    }
  }

  const sites = [];
  const locals = new Map();  // scope → Set(names declared there: assignments, parameters)
  const declare = (scope, name) => { if (!locals.has(scope)) locals.set(scope, new Set()); locals.get(scope).add(name); };
  // a class a macro program defines (`class Probe …`): `new Probe …` is ITS constructor
  const defineClass = (name, superName, hasCtor) => { if (name && !classes.has(name)) classes.set(name, { superName, hasCtor }); };
  for (const { u, ast } of parsed) {
    if (u.scope === 'macros') {
      // a test's macro and every standard verb are linked into ONE program: a function it assigns, at any depth,
      // is a NAME of that program (not a local), and one harvestDefs' line forms cannot see when it is indented
      walkCS(ast, (n) => {
        if (isAssign(n) && n.context !== 'object' && isCode(n.value)) { const id = plainIdent(n.variable); if (id) ours.add(id); }
        if (shape(n) === 'variable,parent,body') {
          let hasCtor = false;
          walkCS(n.body, (m) => { if (isAssign(m) && m.context === 'object' && isCode(m.value) && isValue(m.variable) && isLiteral(m.variable.base) && m.variable.base.value === 'constructor') hasCtor = true; });
          defineClass(plainIdent(n.variable), n.parent ? plainIdent(n.parent) : undefined, hasCtor);
        }
      });
      continue;
    }
    // a name is LOCAL only where nothing outside its unit can reach it: a parameter, or an assignment NESTED in a
    // function. A unit's top-level assignment (a boot global) is called by name from other files too, so its calls
    // group by NAME with every other call of it — a split would hide a witness.
    const declareIn = (n, inFn) => {
      if (Array.isArray(n)) { for (const x of n) declareIn(x, inFn); return; }
      if (!kids(n)) return;
      if (isParam(n) && isLiteral(n.name) && IDENT.test(n.name.value)) declare(u.scope, n.name.value);
      if (inFn && isAssign(n) && n.context !== 'object') { const id = plainIdent(n.variable); if (id) declare(u.scope, id); }
      for (const c of n.children) declareIn(n[c], inFn || isCode(n));
    };
    declareIn(ast, false);
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
      if (isSpreadArg(a)) return { text: short(textOf(lines, a.locationData)), spread: true, absent: false };
      const absent = isValue(a) && !a.properties.length && isLiteral(a.base) && a.base.value === 'undefined';
      return { text: short(textOf(lines, a.locationData)), spread: false, absent };
    };
    for (const c of csCallsOf(ast)) {
      const v = c.variable;
      const base = isValue(v) ? v.base : v;
      const props = isValue(v) ? v.properties : [];
      const baseName = isLiteral(base) ? base.value : undefined;
      const last = props.length ? propName(props[props.length - 1]) : undefined;
      const site = { file: u.file, line: u.lineOf(c.ld.first_line), where: u.where, lang: 'coffee', scope: u.scope, cls: u.cls };
      let args = c.args;
      if (c.isNew) {
        // `new @constructor …` in a class builds that class (or a subclass: grouping it with the class only adds
        // witnesses); `new a.b.X …` names X — judged when X is a class some code defines
        const own = baseName === 'this' && props.length === 1 && last === 'constructor' && u.cls;
        Object.assign(site, { kind: 'new', name: own ? u.cls : props.length ? last : (IDENT.test(baseName || '') ? baseName : undefined) });
      } else if (props.length >= 2 && (last === 'call' || last === 'apply') && props.some((p) => propName(p) === '__super__')) {
        const member = u.cls ? (props.length === 3 ? propName(props[1]) : undefined) : (u.mixin ? memberAt(c.ld.first_line) : undefined);
        Object.assign(site, { kind: 'super', name: member, superOf: u.cls });
        if (last === 'apply') { site.forwarding = true; args = []; } else args = args.slice(1);
      } else if (!props.length) {
        Object.assign(site, { kind: 'bare', name: IDENT.test(baseName || '') && baseName !== 'this' ? baseName : undefined });
      } else {
        Object.assign(site, { kind: 'send', name: last, receiver: short((baseName === 'this' ? '@' : (baseName || '(…)')) + props.slice(0, -1).map((p) => '.' + (propName(p) || '[…]')).join(''), 40) });
        if (baseName === 'this' && props.length === 1) site.receiver = '@';
      }
      site.args = args.map(arg);
      sites.push(site);
    }
  }

  // JS: the tests repo's scripts and each macro file's shell (its macro templates are CoffeeScript, read above)
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
      // what the file defines (ours), and its LOCALS — a parameter, a catch parameter, or a declaration NESTED in a
      // function; a top-level function or variable may be exported and called by name from another file (the CS rule)
      const declJs = (n, inFn) => {
        if (Array.isArray(n)) { for (const x of n) declJs(x, inFn); return; }
        if (!n || typeof n.type !== 'string' || inSkip(n)) return;
        const fnLike = /Function/.test(n.type);
        if (n.type === 'FunctionDeclaration' && n.id) { if (inFn) declare(scope, n.id.name); jsDefs.add(n.id.name); }
        if (n.type === 'VariableDeclarator' && n.id.type === 'Identifier') { if (inFn) declare(scope, n.id.name); if (n.init && /Function/.test(n.init.type)) jsDefs.add(n.id.name); }
        if (fnLike) for (const p of n.params) { const id = p.type === 'Identifier' ? p : (p.type === 'AssignmentPattern' && p.left.type === 'Identifier' ? p.left : undefined); if (id) declare(scope, id.name); }
        if (n.type === 'CatchClause' && n.param && n.param.type === 'Identifier') declare(scope, n.param.name);
        if (n.type === 'Property' && !n.computed && n.key.type === 'Identifier' && (n.method || /Function/.test(n.value.type))) jsDefs.add(n.key.name);
        if (n.type === 'MethodDefinition' && n.key.type === 'Identifier') jsDefs.add(n.key.name);
        if (n.type === 'AssignmentExpression' && n.left.type === 'MemberExpression' && !n.left.computed && /Function/.test(n.right.type)) jsDefs.add(n.left.property.name);
        if ((n.type === 'ClassDeclaration' || n.type === 'ClassExpression') && n.id)
          defineClass(n.id.name, n.superClass && n.superClass.type === 'Identifier' ? n.superClass.name : undefined, n.body.body.some((m) => m.kind === 'constructor'));
        for (const k of Object.keys(n)) if (k !== 'loc' && n[k] && typeof n[k] === 'object') declJs(n[k], inFn || fnLike);
      };
      declJs(ast, false);
      visit(ast, (n) => {
        if (n.type !== 'CallExpression' && n.type !== 'NewExpression') return;
        const c = n.callee;
        const site = { file, line: n.loc.start.line, where, lang: 'js', scope };
        if (n.type === 'NewExpression') Object.assign(site, { kind: 'new', name: c.type === 'Identifier' ? c.name : (c.type === 'MemberExpression' && !c.computed ? c.property.name : undefined) });
        else if (c.type === 'Identifier') Object.assign(site, { kind: 'bare', name: c.name });
        else if (c.type === 'MemberExpression') Object.assign(site, { kind: 'send', receiver: short(text.slice(c.object.start, c.object.end), 40),
          name: !c.computed ? c.property.name : (c.property.type === 'Literal' && typeof c.property.value === 'string' ? c.property.value : undefined) });
        else Object.assign(site, { kind: 'bare', name: undefined });
        site.args = n.arguments.map((a) => ({ text: short(text.slice(a.start, a.end)), spread: a.type === 'SpreadElement', absent: a.type === 'Identifier' && a.name === 'undefined' }));
        sites.push(site);
      });
    };
    for (const file of repo.script) { counts.script++; readJs(file, 'script', []); }
    for (const file of repo.macro) {
      let tpl = [];
      try { tpl = maskJs(fs.readFileSync(file, 'utf8'), file).templates.filter((t) => t.depth === 0).map((t) => [t.start - 1, t.end + 1]); }
      catch (e) { unreadable.push({ file, message: e.message }); continue; }
      readJs(file, 'macro', tpl);
    }
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
    else if (s.kind === 'bare' && locals.get(s.scope)?.has(s.name)) s.callee = { key: 'local:' + s.scope + '#' + s.name };
    else s.callee = ours.has(s.name) ? { key: 'name:' + s.name } : { foreign: 'a name no code in either repo defines' };
    let last = -1;
    s.args.forEach((a, i) => { if (!a.absent) last = i; });
    s.reach = last + 1;
    s.candidate = s.args.some((a, i) => a.absent && i < last);
  }
  for (const s of sites) if (s.callee.unplaceable) unreadable.push({ file: s.file, line: s.line, message: 'a super call no class chain places' });
  return { sites, unreadable, counts, classes };
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

// how a site's callee reads in a report — the gate's and the census's one spelling
function describeCallee(s) {
  if (s.kind === 'new') return 'new ' + s.name;
  if (s.kind === 'super') return `super (${s.superOf}.${s.name})`;
  if (s.receiver === '@') return '@' + s.name;
  return (s.receiver ? s.receiver + '.' : '') + s.name;
}

module.exports = { callSites, callersTest, csCallsOf, describeCallee };
