#!/usr/bin/env node
'use strict';
/*
 * check-coffee-syntax.js — build-time CoffeeScript syntax gate.
 *
 * WHY THIS EXISTS
 * Fizzygum ships its ~470 class/mixin sources as escaped TEXT and compiles them
 * in-browser at boot (see CLAUDE.md). The build only runs `coffee` over src/boot/*,
 * so a green build has NEVER checked the syntax of the class/mixin files — a typo
 * surfaces only when a human opens the build in a browser. This gate closes that gap.
 *
 * WHY IT DOES NOT JUST `CoffeeScript.compile(wholeFile)`
 * The browser NEVER compiles a whole class file. src/meta/Class.coffee splits each
 * class into fragments (constructor + every field) and compiles them SEPARATELY with
 * {bare:true}, AFTER stripping `@augmentWith` lines and rewriting every `super` form
 * (Fizzygum legally uses `@field=` before super() and bare `super`, both of which
 * vanilla CoffeeScript class syntax rejects). Compiling whole files therefore
 * false-fails on ~300 of ~500 files. DO NOT "simplify" this to a whole-file compile.
 *
 * HOW IT AVOIDS DUPLICATING THAT TRANSFORM
 * Instead of re-porting Class.coffee's fragmenting logic (which would drift), this
 * gate LOADS AND RUNS THE REAL src/meta/Class.coffee and src/meta/Mixin.coffee in
 * Node and drives each source through `new Class(src, true, false)` /
 * `new Mixin(src, true, false)` — i.e. generate-precompiled mode, which compiles
 * every fragment exactly as the browser will, but builds no objects (the `eval` at
 * Class.coffee:419 / Mixin.coffee:99 is gated behind the 3rd "create" arg, which we
 * pass as false). Because the real meta-compiler runs, any future change to it is
 * tracked automatically.
 *
 * THE SHIM (only new logic). Class/Mixin touch a few globals at construction time;
 * we provide minimal stand-ins as closed-over factory params + a `window` Proxy:
 *   - compileFGCode(src,bare)  -> CoffeeScript.compile (faithful 1-liner of the real
 *                                 wrapper, loading-and-compiling-...coffee:88-103)
 *   - nil                      -> undefined  (Fizzygum's undefined alias)
 *   - srcLoadCompileDebugWrites-> false       (Mixin.coffee:63 reads it BARE; must be
 *                                 falsy or debug paths run)
 *   - JSSourcesContainer       -> {content:''}(Class.coffee:414, Mixin.coffee:96)
 *   - window (Proxy): seeded {classDefinitionAsJS:[], srcLoadCompileDebugWrites:false}
 *                     (Class.coffee reads window.srcLoadCompileDebugWrites WITH the
 *                     window. prefix); every other key returns a truthy stub so
 *                     `window[superClassName].class` (:118) and
 *                     `window[@name].class = @` (:430) don't throw. Mode 2 never
 *                     reads these as real objects, so a stub is enough.
 *
 * SAFE FAILURE DIRECTION: real syntax errors are thrown by CoffeeScript.compile
 * INSIDE the reused meta-compiler regardless of the shim, so a shim gap can never
 * silently MASK a real error — at worst it causes a loud operational error (exit 2),
 * which is fixed once. Exit codes: 0 = clean, 1 = syntax error(s), 2 = operational.
 *
 * FILE SET: obtained from `python3 buildSystem/build.py --list-shippable <args>` — the
 * single source of truth for what the build ships, so this gate can't drift from it.
 * All args we receive are forwarded so the set matches the build's flags.
 *
 * Run from the Fizzygum/ repo root (build_it_please.sh does this):
 *   node ./buildSystem/check-coffee-syntax.js [build flags...]
 */

const path = require('path');
const fs = require('fs');
const { execFileSync } = require('child_process');

const REPO = process.cwd(); // build_it_please.sh runs us from Fizzygum/
const COMPILER = path.join(__dirname, '..', 'auxiliary files', 'CoffeeScript', 'fizzygum-coffeescript-min.js');

function fail(msg) { console.error('check-coffee-syntax: ' + msg); process.exit(2); }

// ---- 1. load the SAME compiler the browser uses (2.0.3, not the 2.7.0 CLI) ----
let CoffeeScript;
try {
  const mod = require(COMPILER);
  CoffeeScript = (mod && mod.CoffeeScript) || mod;
} catch (e) {
  fail('could not load bundled compiler at "' + COMPILER + '": ' + e.message);
}
if (!CoffeeScript || typeof CoffeeScript.compile !== 'function') {
  fail('bundled compiler did not expose a compile() function');
}

// ---- 2. compile + capture the REAL Class.coffee / Mixin.coffee ----
//   They are plain classes that extend nothing and use no bare-super, so they
//   compile as whole files (this is also how boot bootstraps them).
let Class, Mixin;
try {
  const classJS = CoffeeScript.compile(fs.readFileSync(path.join(REPO, 'src', 'meta', 'Class.coffee'), 'utf8'), { bare: true });
  const mixinJS = CoffeeScript.compile(fs.readFileSync(path.join(REPO, 'src', 'meta', 'Mixin.coffee'), 'utf8'), { bare: true });

  // The shim globals are passed as factory PARAMETERS so the defined Class/Mixin
  // methods close over them (no global pollution). `window` is a Proxy; see header.
  const STUB = { class: null, prototype: {} };
  const windowProxy = new Proxy({ classDefinitionAsJS: [], srcLoadCompileDebugWrites: false }, {
    get(t, k) { return (k in t) ? t[k] : STUB; },
    set(t, k, v) { t[k] = v; return true; }
  });
  const JSSourcesContainer = { content: '' };
  const compileFGCode = (src, bare) => CoffeeScript.compile(src, { bare: bare });

  const factory = new Function(
    'window', 'nil', 'compileFGCode', 'JSSourcesContainer', 'srcLoadCompileDebugWrites',
    classJS + '\n;\n' + mixinJS + '\n;\nreturn { Class: Class, Mixin: Mixin };'
  );
  ({ Class, Mixin } = factory(windowProxy, undefined, compileFGCode, JSSourcesContainer, false));
  if (typeof Class !== 'function' || typeof Mixin !== 'function') {
    fail('failed to capture Class/Mixin constructors from the meta-compiler');
  }
} catch (e) {
  fail('the meta-compiler (Class.coffee/Mixin.coffee) itself failed to load: ' + e.message);
}

// ---- 3. get the shipped-source file list (single source of truth = build.py) ----
let files;
try {
  const out = execFileSync('python3', ['buildSystem/build.py', '--list-shippable', ...process.argv.slice(2)],
    { cwd: REPO, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
  files = out.split('\n').map(s => s.trim()).filter(Boolean);
} catch (e) {
  fail('could not get the shippable file list from build.py: ' + e.message);
}
if (!files.length) fail('build.py --list-shippable returned no files');

// ---- 4. drive each source through the real meta-compiler ----
const IS_CLASS = /^class +\w+/m;            // same test build.py uses (build.py:48)
const IS_MIXIN = /^(\w+Mixin)\s*=/m;        // same test build.py uses (build.py:49)

// Silence the meta-compiler's own console noise (debug logs + the pre-existing
// "code contains a helper var" warning from _removeHelperFunctions) while we drive
// it; real syntax errors THROW and are caught below, they are not logged.
const realLog = console.log, realInfo = console.info, realWarn = console.warn;
const failures = [];
let nClass = 0, nMixin = 0, nSkip = 0;

console.log = console.info = console.warn = function () {};
try {
  for (const rel of files) {
    let src;
    try {
      src = fs.readFileSync(path.resolve(REPO, rel), 'utf8');
    } catch (e) {
      failures.push({ rel, message: 'could not read file: ' + e.message });
      continue;
    }
    const isClass = IS_CLASS.test(src);
    const isMixin = IS_MIXIN.test(src);
    try {
      if (isClass) { nClass++; new Class(src, true, false); }
      else if (isMixin) { nMixin++; new Mixin(src, true, false); }
      else { nSkip++; }  // not a class/mixin file: the build wraps none of these as text
    } catch (e) {
      failures.push({ rel, message: (e && e.message) || String(e), location: e && e.location });
    }
  }
} finally {
  console.log = realLog; console.info = realInfo; console.warn = realWarn;
}

// ---- 5. report + exit ----
for (const f of failures) {
  const loc = f.location ? ` (${f.location.first_line + 1}:${f.location.first_column + 1})` : '';
  console.error('FAIL ' + f.rel + loc);
  console.error('    ' + String(f.message).replace(/\n/g, '\n    '));
}
const checked = nClass + nMixin;
console.log(`syntax check: ${checked} files (${nClass} classes, ${nMixin} mixins, ${nSkip} skipped) — ${failures.length} error(s)`);
process.exit(failures.length ? 1 : 0);
