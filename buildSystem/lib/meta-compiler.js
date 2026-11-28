'use strict';
// meta-compiler.js — the browser's OWN meta-compiler, loaded into Node: the bundled CoffeeScript 2.0.3 and the real
// src/meta/Class.coffee, so a build tool sees every class exactly as the browser compiles it.
//
// WHY THE REAL ONE. The browser never compiles a whole class file: Class.coffee splits each class into FRAGMENTS
// (constructor + every member, each the rest of its `  name: …` header line plus its body lines verbatim), rewrites
// every `super` into a plain `__super__` call (`_rewriteSuperCalls`, read from the lexer's tokens), and compiles
// each fragment with {bare: true}. Re-porting that transform would drift, so this loads and runs it. Readers:
// check-coffee-syntax.js (compiles every fragment: the syntax gate), lib/call-sites.js (taps `_rewriteSuperCalls`
// for the fragments it parses), compile-fragment.js (the real super rewrite) and check-method-categories.js (reads
// each class's members, comments and categories off the parse). The two that place a member on its file's lines
// share one rule for it, placesOfMember.
//
// THE SHIM. Class touches a few globals at construction time; they are supplied as closed-over factory parameters
// plus a `window` Proxy:
//   - CoffeeScript               -> the bundled compiler (the super rewrite and every constructor's ending read its
//                                    lexer, `CoffeeScript.tokens`)
//   - compileFGCode(src, bare, …) -> the caller's (default: CoffeeScript.compile — the real wrapper's one-liner,
//                                    loading-and-compiling-coffeescript-sources.coffee). A reader that only needs
//                                    the fragments passes a stub; Class's later steps accept `'(function() {});'`.
//   - JSSourcesContainer         -> { content: '' }
//   - window (Proxy)             -> seeded { classDefinitionAsJS: [], srcLoadCompileDebugWrites: false } (Class reads
//                                    the flag WITH the `window.` prefix; it must be falsy or debug paths run); every
//                                    other key answers a stub, so a superclass reads as loaded and
//                                    `window[@name].class = @` does not throw.
// Drive a source with `new Class(src, true, false)` — generate-precompiled mode: every fragment goes through
// compileFGCode exactly as in the browser, and no object is built (the `eval` is gated behind the 3rd argument).
// Because the real meta-compiler runs, a change to it is tracked automatically.
//
// SAFE FAILURE DIRECTION: a real syntax error is thrown by compileFGCode inside the reused meta-compiler whatever
// the shim does, so a shim gap cannot mask one — at worst it is a loud META_COMPILER_UNAVAILABLE, fixed once.

const fs = require('fs');
const path = require('path');

const COMPILER = path.join(__dirname, '..', '..', 'vendor', 'coffeescript', 'fizzygum-coffeescript-min.js');

// The bundled CoffeeScript 2.0.3 — the compiler the browser runs (not the 2.7 CLI).
function bundledCoffeeScript() {
  let CoffeeScript;
  try {
    const mod = require(COMPILER);
    CoffeeScript = (mod && mod.CoffeeScript) || mod;
  } catch (e) {
    throw new Error('META_COMPILER_UNAVAILABLE: could not load bundled compiler at "' + COMPILER + '": ' + e.message);
  }
  if (!CoffeeScript || typeof CoffeeScript.compile !== 'function') {
    throw new Error('META_COMPILER_UNAVAILABLE: bundled compiler did not expose a compile() function');
  }
  return CoffeeScript;
}

// -> { CoffeeScript, Class } from `srcDir`'s meta/Class.coffee (a plain class that extends nothing and uses no bare
// super, so it compiles whole — which is also how boot bootstraps it).
function loadMetaCompiler({ srcDir, compileFGCode } = {}) {
  const CoffeeScript = bundledCoffeeScript();
  const compile = compileFGCode || ((src, bare) => CoffeeScript.compile(src, { bare }));
  let Class;
  try {
    const classJS = CoffeeScript.compile(fs.readFileSync(path.join(srcDir, 'meta', 'Class.coffee'), 'utf8'), { bare: true });
    const STUB = { prototype: {} };
    const windowProxy = new Proxy({ classDefinitionAsJS: [], srcLoadCompileDebugWrites: false }, {
      get(t, k) { return (k in t) ? t[k] : STUB; },
      set(t, k, v) { t[k] = v; return true; },
    });
    const factory = new Function(
      'window', 'CoffeeScript', 'compileFGCode', 'JSSourcesContainer',
      classJS + '\n;\nreturn { Class: Class };'
    );
    ({ Class } = factory(windowProxy, CoffeeScript, compile, { content: '' }));
  } catch (e) {
    throw new Error('META_COMPILER_UNAVAILABLE: the meta-compiler (Class.coffee) itself failed to load: ' + e.message);
  }
  if (typeof Class !== 'function') {
    throw new Error('META_COMPILER_UNAVAILABLE: failed to capture the Class constructor from the meta-compiler');
  }
  return { CoffeeScript, Class };
}

// The text a member's source becomes before it is compiled: Class.coffee's own super rewrite, run on `src` as the
// member `memberName` of class `className` (the same text, line for line — the rewrite is same-line).
// A receiver backed by Class's own prototype, so whatever the rewrite asks of `this` beyond the name is Class's.
function rewriteSuper(Class, className, memberName, src) {
  return Class.prototype._rewriteSuperCalls.call(Object.assign(Object.create(Class.prototype), { name: className }), memberName, src);
}

// Where a member's recorded SOURCE stands in its class file's `lines`: the index (from 0) of every line whose member
// header — `  name: rest`, `  @name: rest` for a class-side member — has the source's first line as its rest, the
// source's other lines following it verbatim. The parse cuts a member's source out of its file exactly so (the rest of
// its header line, then its body's lines), so the source read back lands where it was cut. A member found once is
// placed; what any other count means is the reader's to say (lib/call-sites.js refuses it; check-method-categories.js
// keeps the last, as the parse keeps a member's last writing).
function placesOfMember(lines, memberName, isStatic, source) {
  const header = new RegExp('^  ' + (isStatic ? '@' : '') + memberName.replace(/\$/g, '\\$') + ' *: *(.*)$');
  const sourceLines = source.split('\n');
  const at = [];
  for (let h = 0; h < lines.length; h++) {
    const m = header.exec(lines[h]);
    if (m && m[1] === sourceLines[0] && sourceLines.every((l, k) => k === 0 || lines[h + k] === l)) at.push(h);
  }
  return at;
}

module.exports = { bundledCoffeeScript, loadMetaCompiler, rewriteSuper, placesOfMember, COMPILER };
