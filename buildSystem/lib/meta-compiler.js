'use strict';
// meta-compiler.js — the browser's OWN meta-compiler, loaded into Node: the bundled CoffeeScript 2.0.3 and the real
// src/meta/Class.coffee + Mixin.coffee, so a build tool sees every class exactly as the browser compiles it.
//
// WHY THE REAL ONE. The browser never compiles a whole class file: Class.coffee splits each class into FRAGMENTS
// (constructor + every member, each the rest of its `  name: …` header line plus its body lines verbatim), rewrites
// every `super` into a plain `__super__` call (`_rewriteSuperCalls`, read from the lexer's tokens), and compiles
// each fragment with {bare: true}; Mixin.coffee rewrites and compiles a mixin as one source. Re-porting that transform
// would drift, so this loads and runs it. Readers: check-coffee-syntax.js (compiles every fragment: the syntax gate),
// lib/call-sites.js (taps `_rewriteSuperCalls` for the fragments it parses) and compile-fragment.js (the real super
// rewrite).
//
// THE SHIM. Class/Mixin touch a few globals at construction time; they are supplied as closed-over factory
// parameters plus a `window` Proxy:
//   - CoffeeScript               -> the bundled compiler (the super rewrite and every constructor's ending read its
//                                    lexer, `CoffeeScript.tokens`)
//   - compileFGCode(src, bare, …) -> the caller's (default: CoffeeScript.compile — the real wrapper's one-liner,
//                                    loading-and-compiling-coffeescript-sources.coffee). A reader that only needs
//                                    the fragments passes a stub; Class's later steps accept `'(function() {});'`.
//   - srcLoadCompileDebugWrites  -> false (Mixin.coffee reads it BARE; it must be falsy or debug paths run)
//   - JSSourcesContainer         -> { content: '' }
//   - window (Proxy)             -> seeded { classDefinitionAsJS: [], srcLoadCompileDebugWrites: false } (Class reads
//                                    the flag WITH the `window.` prefix); every other key answers a stub, so a
//                                    superclass reads as loaded and `window[@name].class = @` does not throw.
// Drive a source with `new Class(src, true, false)` / `new Mixin(src, true, false)` — generate-precompiled mode:
// every fragment goes through compileFGCode exactly as in the browser, and no object is built (the `eval` is gated
// behind the 3rd argument). Because the real meta-compiler runs, a change to it is tracked automatically.
//
// SAFE FAILURE DIRECTION: a real syntax error is thrown by compileFGCode inside the reused meta-compiler whatever
// the shim does, so a shim gap cannot mask one — at worst it is a loud META_COMPILER_UNAVAILABLE, fixed once.

const fs = require('fs');
const path = require('path');

const COMPILER = path.join(__dirname, '..', '..', 'auxiliary files', 'CoffeeScript', 'fizzygum-coffeescript-min.js');

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

// -> { CoffeeScript, Class, Mixin } from `srcDir`'s meta/Class.coffee + meta/Mixin.coffee (both plain classes that
// extend nothing and use no bare super, so they compile whole — which is also how boot bootstraps them).
function loadMetaCompiler({ srcDir, compileFGCode } = {}) {
  const CoffeeScript = bundledCoffeeScript();
  const compile = compileFGCode || ((src, bare) => CoffeeScript.compile(src, { bare }));
  let Class, Mixin;
  try {
    const classJS = CoffeeScript.compile(fs.readFileSync(path.join(srcDir, 'meta', 'Class.coffee'), 'utf8'), { bare: true });
    const mixinJS = CoffeeScript.compile(fs.readFileSync(path.join(srcDir, 'meta', 'Mixin.coffee'), 'utf8'), { bare: true });
    const STUB = { prototype: {} };
    const windowProxy = new Proxy({ classDefinitionAsJS: [], srcLoadCompileDebugWrites: false }, {
      get(t, k) { return (k in t) ? t[k] : STUB; },
      set(t, k, v) { t[k] = v; return true; },
    });
    const factory = new Function(
      'window', 'CoffeeScript', 'compileFGCode', 'JSSourcesContainer', 'srcLoadCompileDebugWrites',
      classJS + '\n;\n' + mixinJS + '\n;\nreturn { Class: Class, Mixin: Mixin };'
    );
    ({ Class, Mixin } = factory(windowProxy, CoffeeScript, compile, { content: '' }, false));
  } catch (e) {
    throw new Error('META_COMPILER_UNAVAILABLE: the meta-compiler (Class.coffee/Mixin.coffee) itself failed to load: ' + e.message);
  }
  if (typeof Class !== 'function' || typeof Mixin !== 'function') {
    throw new Error('META_COMPILER_UNAVAILABLE: failed to capture Class/Mixin constructors from the meta-compiler');
  }
  return { CoffeeScript, Class, Mixin };
}

// The text a member's source becomes before it is compiled: Class.coffee's own super rewrite, run on `src` as the
// member `memberName` of class `className` (the same text, line for line — the rewrite is same-line).
// A receiver backed by Class's own prototype, so whatever the rewrite asks of `this` beyond the name is Class's.
function rewriteSuper(Class, className, memberName, src) {
  return Class.prototype._rewriteSuperCalls.call(Object.assign(Object.create(Class.prototype), { name: className }), memberName, src);
}

module.exports = { bundledCoffeeScript, loadMetaCompiler, rewriteSuper, COMPILER };
