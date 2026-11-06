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
 *   - MixedClassKeywords       -> the real 3-entry list (Mixin's static parse pass
 *                                 filters the DSL hooks out of the 2-space keys)
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
 * which is fixed once.
 *
 * THE SECOND CHECK: A CLASS MEMBER MUST NOT LOSE A NAME TO THE HELPER STRIP. The compiler
 * declares the helpers a construct needs in a `var` statement at the head of what it
 * compiles (`%%` wants `modulo`, a range assignment `a[i..j] = b` wants `splice`, …), and
 * Class._removeHelperFunctions cuts that whole head out of every member fragment, leaving
 * the body to reach its helpers as FREE identifiers. Boot provides exactly three of them
 * as globals (hasProp / indexOf / slice); any other name declared in that head is gone.
 * A helper the body CALLS is then a ReferenceError at runtime; a compiler temporary the
 * body ASSIGNS first (`ref`, which the compiler hoists to that head out of a parameter
 * default such as `(c = @color ? @fallback()) ->`) silently becomes a page-wide global in
 * the sloppy-mode eval. Both parse, so both would pass the syntax check above. So this gate
 * taps the real strip (it sees exactly the text the meta-system cuts) and FAILS a fragment
 * whose head declares a name outside the provided set, naming the class, the member and
 * the name(s). The compiler's output is
 * the authority on which helpers exist; the only list here is the PROVIDED one, read from
 * Class._memberNamesThatMustStayAnonymous (the meta-system's own statement of the helper
 * globals) and held against the `window.<name> = [].<m>` / `{}.<m>` assignments in
 * src/boot that actually provide them: if the two disagree, the gate stops.
 * A MIXIN is not checked: it compiles as a whole source and keeps its helper declarations
 * (Mixin's strip, used only by live member edits, removes the three provided ones by name
 * and leaves the rest declared), so no helper is lost there.
 *
 * Exit codes: 0 = clean, 1 = syntax error(s) or a member losing a helper,
 * 2 = operational (including: the PROVIDED set cannot be established, or the tap on the
 * strip saw no fragment — a check that sees nothing must not pass).
 *
 * FILE SET: obtained from `python3 buildSystem/build.py --list-shippable <args>` — the
 * single source of truth for what the build ships, so this gate can't drift from it.
 * All args we receive are forwarded so the set matches the build's flags.
 *
 * Run from the Fizzygum/ repo root (build_it_please.sh does this):
 *   node ./buildSystem/check-coffee-syntax.js [build flags...]
 * TESTING HOOK — check given files instead of the shippable set (everything after the flag
 * is a path, relative to the repo root or absolute; build flags before it are ignored):
 *   node ./buildSystem/check-coffee-syntax.js --files <a.coffee> [<b.coffee> ...]
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
    'window', 'nil', 'compileFGCode', 'JSSourcesContainer', 'srcLoadCompileDebugWrites', 'MixedClassKeywords',
    classJS + '\n;\n' + mixinJS + '\n;\nreturn { Class: Class, Mixin: Mixin };'
  );
  ({ Class, Mixin } = factory(windowProxy, undefined, compileFGCode, JSSourcesContainer, false,
    ['onceAddedClassProperties', 'included', 'consumerClassNames']));
  if (typeof Class !== 'function' || typeof Mixin !== 'function') {
    fail('failed to capture Class/Mixin constructors from the meta-compiler');
  }
} catch (e) {
  fail('the meta-compiler (Class.coffee/Mixin.coffee) itself failed to load: ' + e.message);
}

// ---- 2b. the PROVIDED helper globals (header: THE SECOND CHECK) ----
//   Read from the meta-system's own declaration, and held against what boot actually assigns.
const declared = Class._memberNamesThatMustStayAnonymous;
if (!Array.isArray(declared) || !declared.length || !declared.every(n => typeof n === 'string')) {
  fail('Class._memberNamesThatMustStayAnonymous is not a non-empty list of names — the helper globals boot provides cannot be established');
}
const PROVIDED = new Set(declared);
{
  const bootDir = path.join(REPO, 'src', 'boot');
  const BOOT_HELPER = /^\s*window\.([A-Za-z_$][\w$]*)\s*=\s*(?:\[\]|\{\})\.[A-Za-z_$][\w$]*\s*$/;
  const assigned = new Set();
  const walk = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith('.coffee')) for (const line of fs.readFileSync(p, 'utf8').split('\n')) { const m = line.match(BOOT_HELPER); if (m) assigned.add(m[1]); }
  } };
  try { walk(bootDir); } catch (e) { fail('could not read ' + bootDir + ' to establish the helper globals: ' + e.message); }
  const onlyDeclared = [...PROVIDED].filter(n => !assigned.has(n));
  const onlyAssigned = [...assigned].filter(n => !PROVIDED.has(n));
  if (onlyDeclared.length || onlyAssigned.length) {
    fail('the helper globals disagree — Class._memberNamesThatMustStayAnonymous says [' + [...PROVIDED].join(', ')
      + '], src/boot assigns window.<helper> for [' + [...assigned].join(', ') + ']'
      + (onlyDeclared.length ? '; declared but never provided: ' + onlyDeclared.join(', ') : '')
      + (onlyAssigned.length ? '; provided but not declared: ' + onlyAssigned.join(', ') : '')
      + ' — make the two say the same thing');
  }
}

// The names a compiled fragment's LEADING `var` statement declares — the head the strip cuts — or []
// when the fragment opens with anything else. A helper's initializer can hold `;` and `,` inside its
// own body (`modulo = function(a, b) { return …; }`), so declarators are split at depth 0 only.
function leadingVarNames(js) {
  if (!/^var\b/.test(js)) return [];
  const names = [];
  let depth = 0, quote = null, expectName = true;
  for (let i = 3; i < js.length; i++) {
    const c = js[i];
    if (quote) { if (c === '\\') i++; else if (c === quote) quote = null; continue; }
    if (expectName) {
      const m = /^\s*([A-Za-z_$][\w$]*)/.exec(js.slice(i));
      if (m) { names.push(m[1]); i += m[0].length - 1; expectName = false; continue; }
    }
    if (c === '"' || c === "'" || c === '`') quote = c;
    else if ('([{'.includes(c)) depth++;
    else if (')]}'.includes(c)) depth--;
    else if (depth === 0 && c === ',') expectName = true;
    else if (depth === 0 && c === ';') break;
  }
  return names;
}

// THE TAP: observe the real strip without changing it. `_equivalentforSuper` is the step every
// member's source passes through just before it is compiled and handed to the strip, so it says
// WHICH member the next stripped fragment belongs to (a class-side one is reported as `@name`).
const helperLosses = [];   // [{ rel, cls, member, names }]
let tapRel = null, tapMember = null, strippedFragments = 0;
for (const m of ['_equivalentforSuper', '_removeHelperFunctions']) {
  if (typeof Class.prototype[m] !== 'function') fail('Class.prototype.' + m + ' is gone — the helper check cannot tap the meta-system\'s strip; re-read THE SECOND CHECK against src/meta/Class.coffee');
}
const realEquivalentForSuper = Class.prototype._equivalentforSuper;
Class.prototype._equivalentforSuper = function (fieldName, aString) {
  const isStatic = this.nonStaticPropertiesSources?.[fieldName] !== aString && this.staticPropertiesSources?.[fieldName] === aString;
  tapMember = (isStatic ? '@' : '') + fieldName;
  return realEquivalentForSuper.apply(this, arguments);
};
const realRemoveHelperFunctions = Class.prototype._removeHelperFunctions;
Class.prototype._removeHelperFunctions = function (compiled) {
  strippedFragments++;
  const lost = leadingVarNames(compiled).filter(n => !PROVIDED.has(n));
  if (lost.length) helperLosses.push({ rel: tapRel, cls: this.name, member: tapMember, names: lost });
  return realRemoveHelperFunctions.apply(this, arguments);
};

// ---- 3. get the shipped-source file list (single source of truth = build.py) ----
//   …or, with the --files testing hook, exactly the files named after it.
let files;
const filesFlag = process.argv.indexOf('--files');
if (filesFlag >= 0) {
  files = process.argv.slice(filesFlag + 1);
  if (!files.length) fail('--files names no file');
} else {
  try {
    const out = execFileSync('python3', ['-B', 'buildSystem/build.py', '--list-shippable', ...process.argv.slice(2)],
      { cwd: REPO, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 });
    files = out.split('\n').map(s => s.trim()).filter(Boolean);
  } catch (e) {
    fail('could not get the shippable file list from build.py: ' + e.message);
  }
  if (!files.length) fail('build.py --list-shippable returned no files');
}

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
    tapRel = rel; tapMember = null;
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
for (const h of helperLosses) {
  console.error(`FAIL ${h.rel}  ${h.cls}.${h.member}: its compiled form declares ${h.names.map(n => '`' + n + '`').join(', ')} in the leading \`var\` head that`
    + ` Class._removeHelperFunctions cuts out, and boot provides only ${[...PROVIDED].join(' / ')} as globals — so the body's use of`
    + ` ${h.names.length === 1 ? 'it' : 'them'} has no declaration: a call to a helper throws ReferenceError at runtime, and an assigned compiler`
    + ` temporary becomes a page-wide global. Rewrite the construct the compiler declares ${h.names.length === 1 ? 'it' : 'them'} for`
    + ` (a helper is named for its construct; a temporary comes from a parameter default — move the default's logic into the body,`
    + ` or spell it so it needs no temporary).`);
}
// a tap that saw nothing checked nothing: with classes compiled, the strip must have run
if (nClass > 0 && strippedFragments === 0) {
  fail(`the helper tap saw no stripped fragment across ${nClass} classes — Class no longer routes members through _removeHelperFunctions, so the helper check is vacuous; re-read THE SECOND CHECK against src/meta/Class.coffee`);
}
const checked = nClass + nMixin;
console.log(`syntax check: ${checked} files (${nClass} classes, ${nMixin} mixins, ${nSkip} skipped) — ${failures.length} error(s); `
  + `${strippedFragments} class-member fragments checked against the provided helpers [${[...PROVIDED].join(', ')}] — ${helperLosses.length} losing a helper`);
process.exit(failures.length || helperLosses.length ? 1 : 0);
