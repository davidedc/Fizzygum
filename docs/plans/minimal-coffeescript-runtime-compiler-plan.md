# Minimal Fizzygum-only CoffeeScript runtime compiler — PLAN

> **PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
> Everything needed is embedded inline or one named-doc hop away. Do not assume the
> executing session shares any prior conversation. Line numbers drift — the quoted
> code / method name / filename is authoritative; **grep it fresh** before trusting a
> number.

---

## §0 Orientation — what this is and why it exists now

**Fizzygum** is a CoffeeScript GUI framework rendered on one HTML5 `<canvas>` (a
"web OS": windows, desktop, drag-drop, live in-system editing). Its ~470 class/mixin
sources are **not compiled at build time**. Instead the build wraps each class's
CoffeeScript source into an escaped JS string (`window.Foo_coffeSource = "…"`) and the
**browser compiles them at boot** using a **CoffeeScript compiler bundled into every
build**. (See root `CLAUDE.md` → "Source-as-text + in-browser compilation".) That
bundled compiler is the subject of this plan.

**Immediately-prior arc (the session that produced this plan):** we established that
the long-frozen runtime compiler — a vendored **CoffeeScript 2.0.3** browser bundle,
untouched for ~10 years — can be replaced by **stock CoffeeScript 2.7.0** with **zero
behavioral change**. Evidence gathered (all reproducible, see §7):
- All 487 shipped sources compile under 2.7.0 via the real fragmented meta-compiler path — **0 errors** (identical to 2.0.3).
- Diffing the *emitted JS* of every fragment, 2.0.3 vs 2.7.0, the only differences are **cosmetic and semantically identical** (`new X`→`new X()`, comment reindent, `for`-condition parens, multi-line string constants as template literals vs `\n` escapes — same string *value*).
- The built world **boots clean** (native + SWCanvas, zero console errors) with 2.7.0 as the runtime compiler.
- The **full 13-leg gauntlet passed** built on 2.7.0: 265 tests × dpr1/dpr2/webkit, apps, paint audit, tiernaming/settle/capstone/revisits gates, refs, census, **serialization + file round-trip**, storage — all green, 4m44s. The pixel-exact screenshot gates prove byte-identical rendering; the serialization/file-roundtrip legs prove the saved-to-disk format is unchanged.

**Why this plan now:** the stock runtime compiler is enormous relative to what Fizzygum
actually uses. The Fizzygum runtime calls **exactly one** compiler function:
`CoffeeScript.compile(source, {bare:true})` (see §2 for the grep proof — 2 call sites,
nothing else). Everything else CoffeeScript ships — the CLI, `cake`, the REPL, the
Node `require` hook, browser `<script type=text/coffeescript>` auto-compilation + XHR
loading, source-map generation + base64/VLQ, Literate CoffeeScript, JSX/CSX, the
`import`/`export` module system, shebang handling, `Error.prepareStackTrace` rewriting,
`btoa`, `CoffeeScript.load/run/eval/runScripts` — is **dead weight** shipped in every
build and re-parsed on every boot. The owner has wanted this trimmed since **2017**
(the note in §5 is verbatim from Evernote, dated 2017-12-13).

### ⚠ CRITICAL REFRAME — the thing to internalize before touching anything
The runtime's CoffeeScript API surface is **ONE function**: `compile(source, {bare})`.
The minimal fork's ONLY job is to preserve that one function's *output* byte-for-byte.
Every strip is validated two ways: (a) a fast **byte-identity diff** — compile all 487
sources with the candidate vs stock 2.7.0 and assert ZERO emitted-JS differences; then
(b) the **full gauntlet** (pixel-exact + serialization). If both stay green, the strip
is safe *by construction* — you are not reasoning about whether a feature "matters,"
you are proving the compiled output is unchanged. This makes an otherwise-scary "hack
the compiler" task mechanically safe.

---

## §1 Mandate

**Complete elimination**, not documentation-of-what's-unused. Produce a **minimal,
owned, vendored CoffeeScript-2.7.0-derived compiler** that (a) exposes exactly
`window.CoffeeScript = { compile, VERSION }`, (b) emits byte-identical `bare` JS to
stock 2.7.0 for the whole Fizzygum corpus, (c) passes the full gauntlet, and (d) is
materially smaller than both the 2.0.3 (~257 KB) and stock-2.7.0-legacy (~529 KB)
bundles. Ship it as Fizzygum's runtime compiler. Success is measured in **bytes removed
while the gauntlet stays green**, with a defined stop condition (§6 Phase 4).

---

## §2 Current state / mechanism (grep-verified this session; re-verify before trusting line numbers)

**The vendored runtime compiler:**
- File: `Fizzygum/auxiliary files/CoffeeScript/coffee-script_2.0.3.js` — a UMD browser
  bundle (already minified), **~257 KB**, that sets a global `CoffeeScript` (its tail
  does `CoffeeScript = …`; it is `require()`-able in Node too, which the syntax gate
  relies on). **This filename is git-tracked**; restore any experiment with
  `git -C Fizzygum checkout -- "auxiliary files/CoffeeScript/coffee-script_2.0.3.js"`.

**THREE places reference the vendored file** ⚠ (this plan originally said "two — and only
two" and BOTH earlier §12 entries + the memory note repeated it — they MISSED the runtime
boot loader, ref 3 below. Corrected 2026-07-23 during vendoring, caught by a fresh
`grep -rn` across the whole repo. Lesson: grep the WHOLE tree, not just build scripts.):
1. `Fizzygum/build_it_please.sh` (~line 733):
   `cp auxiliary\ files/CoffeeScript/<vendored>.js $BUILD_PATH/js/libs/`
   → copies it into the build output the browser loads via `<script>`.
2. `Fizzygum/buildSystem/check-coffee-syntax.js` (~line 63):
   `const COMPILER = path.join(__dirname, '..', 'auxiliary files', 'CoffeeScript', '<vendored>.js');`
   → the build-time syntax gate `require()`s it and drives every source through the
   **real** `src/meta/Class.coffee`/`Mixin.coffee` fragmenting compiler, exactly as the
   browser does. **Reuse this file as a test harness** (see §7) — it is the faithful
   "does the whole corpus compile + what JS does it emit" oracle.
3. `Fizzygum/src/boot/globalFunctions.coffee` (~line 219):
   `loadJSFilePromise "js/libs/<vendored>.js"` → the RUNTIME boot loader that actually
   pulls the compiler into the running world. Miss this and the built world can't compile
   its sources at boot.

(As of 2026-07-23 the vendored file was renamed `coffee-script_2.0.3.js` →
`fizzygum-coffeescript-min.js` and all three refs repointed.)

**How the runtime uses it (the whole contract):**
- `Fizzygum/src/boot/loading-and-compiling-coffeescript-sources.coffee` (~line 88):
  ```coffee
  compileFGCode = (codeSource, bare) ->
    ...
    compiled = CoffeeScript.compile codeSource, {"bare": bare}
  ```
- Every runtime compile goes through `compileFGCode` with `bare:true`: the meta
  `Class.coffee`/`Mixin.coffee` fragment each class and **rewrite bare `super`** via
  `_equivalentforSuper` *before* calling compile (grep `_equivalentforSuper` in
  `src/meta/`); `globalFunctions.coffee` boots `Class`/`Mixin` themselves this way; and
  `src/meta/ConsoleWdgt.coffee` compiles live-typed code the same way.
- **API-surface proof** (grep `CoffeeScript\.` under `Fizzygum/src`): the only match is
  `CoffeeScript.compile` (2 sites). **Nothing** uses `.nodes / .tokens / .run / .load /
  .eval / .register / runScripts`. Re-run this grep at the start of execution to confirm
  it still holds:
  `grep -rhoE "CoffeeScript\.[A-Za-z_]+" Fizzygum/src | sort | uniq -c`

**The stock 2.7.0 package on disk** (`Fizzygum/node_modules/coffeescript`, version 2.7.0):
- Ships **compiled** modules only — `lib/coffeescript/*.js`. **No `src/*.coffee`, no
  `Cakefile`.** Modules: `browser.js  cake.js  coffeescript.js  command.js  grammar.js
  helpers.js  index.js  lexer.js  nodes.js  optparse.js  parser.js  register.js  repl.js
  rewriter.js  scope.js  sourcemap.js`.
- Two prebuilt browser bundles:
  - `lib/coffeescript-browser-compiler-legacy/coffeescript.js` — **UMD, sets a global,
    Babel-transpiled to ES5, ~529 KB.** This is the drop-in we validated this session
    (boots + full gauntlet). It is `require()`-able in Node (exposes `.compile`, `.VERSION`).
  - `lib/coffeescript-browser-compiler-modern/coffeescript.js` — **ES module
    (`export default CoffeeScript`).** ⚠ **Unusable as the vendored file** — a plain
    `<script src>` will not create the `CoffeeScript` global from an ESM. (Do-not-reattempt, §9.)
- `node_modules/coffeescript/package.json` `main: ./lib/coffeescript/index`. `test`
  script runs `bin/cake test` (needs the repo, not present).

**Tooling on this machine:** `terser` 5.39.1 (global — for minification). `coffee` CLI
2.7.0 (global). Node 22. Puppeteer + Playwright/WebKit in `Fizzygum-tests` (for headless
boot + coverage + the gauntlet).

**Verification harness:**
- `Fizzygum-all/fg gauntlet` — 13-leg parallel full gate, ~5 min. Legs: dpr1, dpr2,
  webkit (265 tests each), apps, paint, tiernaming, settle, capstone, refs, revisits,
  census, serialization, storage. Verdict at `/tmp/fg-gauntlet.verdict`.
- `fg build` — rebuild only. `fg presuite` — faster inner loop (build + dpr1 suite ∥
  paint audit, ~3.5 min). Boot-smoke: `( cd Fizzygum-tests && node scripts/smoke-boot-headless.js )`
  (boots native + SWCanvas headless, fails on any console/page error, ~15 s).
- Long ops: launch with the Bash tool's `run_in_background: true`, redirect to a log,
  wait for the completion notification. **Do not foreground-poll** (a guard hook blocks it).

---

## §3 Why it's shaped this way (history)

The 2.0.3 bundle was vendored ~2015–2017 and **frozen**, not for any technical
constraint but because (a) Fizzygum builds are **saved-to-disk-and-served** — the bundle
is copied into each build and shipped as-is, so "it works, don't touch it" held for a
decade — and (b) it was never necessary to update it. It is the **full stock browser
distribution** of CoffeeScript, which bundles everything for CLI + browser-script-tag +
source-maps use-cases, **none** of which Fizzygum's compile-only runtime exercises. The
owner identified the redundant parts in 2017 (§5) but the trim was never done. This
session removed the last excuse by proving the 2.7.0 base is behavior-identical, so the
minimal fork is built on 2.7.0 (modern, maintained-era output) rather than the ancient 2.0.3.

---

## §4 The distilled argument

1. **Surface is one function.** Runtime = `compile(src, {bare})`. Proven by grep (§2).
2. **The payload is ~2× necessary.** The parser (jison-generated `parser.js`), lexer,
   rewriter, nodes, scope, helpers, and the `compile` entry are the irreducible core.
   Everything else (`cake`, `command`, `optparse`, `repl`, `register`, `browser`,
   `sourcemap`, + Literate/JSX/module-system/shebang/base64/prepareStackTrace inside the
   core modules) is dead in this environment.
3. **Stripping is provably safe here.** None of the dead features affect the emitted
   `bare` JS. So every strip is gated by (a) a **zero-diff** emitted-JS check over all
   487 sources and (b) the **pixel-exact + serialization gauntlet**. A bad strip fails
   loudly and instantly; you never ship on a hunch.
4. **Why now:** the 2.7.0 base is de-risked, and a 5-minute full-behavior harness exists
   to gate each step. The cost of being wrong is one `git checkout` + rebuild.
5. **Bonus:** target **modern JS** (Fizzygum runs only on current Chrome/WebKit — proven
   this session on native + webkit), so we avoid the legacy bundle's Babel-ES5 shim bloat
   for free — that alone is a large fraction of the 529 KB.

---

## §5 The redundant-parts inventory — owner's 2017 note, mapped to 2.7.0 modules

> **Owner's Evernote note, verbatim** (tags: #fizzygumBoot #fizzygumCoffeeScript2; created
> 2017-12-13, modified 2019-01-10). "I took a look at the coffeescript compiler source
> from around version 2.1.0 and found out the following keywords point to pieces of code
> that are not needed for the coffeescript use we make in Fizzygum:"
> *XHR loading · cake · Literate · Runscripts · Sourcemap / Linemap · Base64 encode ·
> Checkshebangline · Module declaration · CSX / JSX · Basefilename ·
> Error.preparestacktrace · Btoa · Coffeescript.load.*
> "Also note there is a very useful tool in Chrome dev tools that gives you the code
> coverage for any particular source — it can tell you all the parts of a source not used
> in a particular run, so you can take a look and potentially take those out!"

Mapping to CoffeeScript 2.7.0 `lib/coffeescript/*.js` (verify each by grepping the module
before editing — the exact function/branch names may differ slightly from 2.1.0):

| Owner keyword | Lives in | Action |
|---|---|---|
| XHR loading, Runscripts, Coffeescript.load/run, Btoa, Error.preparestacktrace | `browser.js` | **Exclude module entirely** — Fizzygum never uses `<script type=text/coffeescript>`, never XHR-loads `.coffee`, loads its sources itself. |
| cake | `cake.js` | **Exclude module.** |
| CLI, Basefilename, Checkshebangline, optparse | `command.js`, `optparse.js`; shebang/basename helpers in `coffeescript.js`/`helpers.js` | **Exclude `command.js`+`optparse.js`; strip shebang/basename from the core.** |
| repl, Node require hook | `repl.js`, `register.js` | **Exclude both modules.** |
| Sourcemap / Linemap / Base64 encode | `sourcemap.js` + sourcemap wiring in `coffeescript.js` and `nodes.js` (SourceMap emission) | **Exclude module; strip the wiring** so `compile` never builds a map (Fizzygum passes no `sourceMap` option). |
| Literate | literate handling in `coffeescript.js`/`helpers.js` (`.litcoffee`) | **Strip.** |
| CSX / JSX | JSX lexing/parsing in `lexer.js`, `grammar.js`, `nodes.js` | **Strip** (Fizzygum uses no JSX; verify with `grep -rn "</" src/**/*.coffee` = none meaningful). |
| Module declaration (`import`/`export`) | `grammar.js`, `nodes.js` | **Strip only if** Fizzygum sources contain no `import`/`export` (grep to confirm; class sources don't) AND it doesn't perturb class/function codegen. Lower priority — verify byte-diff stays zero. |

**Irreducible core (DO NOT touch codegen of):** `parser.js` (generated), `lexer.js`,
`rewriter.js`, `nodes.js` (the emit logic), `scope.js`, `helpers.js` (minus the
strippable helpers), and `coffeescript.js` `compile()` itself.

The owner's coverage tip is upgraded to an **automated empirical dead-code map** in
Phase 2 (Puppeteer JS coverage), which both *guides* stripping and *confirms* the
keyword list against a real Fizzygum run.

---

## §6 Approach + phases

**Primary build approach — bundle-the-lib-subset (self-contained, modern-JS, recommended).**
Because the npm package ships compiled `lib/coffeescript/*.js` (CommonJS, modern JS,
already the from-coffee output) and NO `src`/`Cakefile`, the fastest faithful path is to
**bundle a subset of those lib modules into a single UMD that sets `window.CoffeeScript`,
then minify with terser** — rather than cloning the coffeescript repo and running its
self-hosting `cake build:browser`. This also naturally avoids the legacy bundle's
Babel-ES5 transpilation (pure size win). Stripping happens by (i) excluding whole
modules from the bundle and (ii) editing the retained `lib/*.js` modules (or, if cleaner,
patching the bundled output) to remove in-module dead branches.

> **Alternative "true fork" approach (optional, for §Phase 0 learning or deeper strips):**
> clone `jashkenas/coffeescript` at the tag matching 2.7.0, read its **Cakefile**
> `build` and `build:browser` targets to learn exactly how the stock bundle is produced
> (self-hosting: the prebuilt `lib/` compiles `src/*.coffee`; the browser target bundles
> the lib via a browserify-style require-registry and minifies). Edit `src/*.coffee`,
> `cake build`, `cake build:browser`, minify. Use this only if source-level edits prove
> cleaner than editing compiled lib. Keep the RESULT identical in contract (UMD, global,
> `{compile, VERSION}`).

### Phase 0 — LEARN the build + establish a passing from-scratch baseline
Goal: before removing anything, prove you can *produce* a working bundle from the lib
modules and that it passes the gauntlet. This de-risks the pipeline.
1. In a scratch dir (`Fizzygum-tests/.scratch/mincoffee/` — gitignored; Node resolves
   `require` from the script's dir, so keep probes there), write an **entry** that
   re-exports the compile surface:
   ```js
   // entry.js
   const CoffeeScript = require('coffeescript/lib/coffeescript/coffeescript');
   module.exports = { compile: CoffeeScript.compile, VERSION: CoffeeScript.VERSION };
   ```
2. Bundle it to a **UMD that sets the `CoffeeScript` global**. Options (pick one, install
   as a scratch devDep): `esbuild --bundle --format=iife --global-name=CoffeeScript`
   (fast, tree-shakes, minifies with `--minify`), or `browserify -s CoffeeScript`, or a
   hand-rolled require-registry. **Do not Babel-transpile to ES5.** Then `terser` the
   result if the bundler didn't minify.
3. Sanity: `node -e "const C=require('./bundle.js'); console.log(C.VERSION, typeof C.compile)"`
   and `console.log(C.compile('x = 1', {bare:true}))`.
4. **Swap-and-gauntlet:** copy the bundle over the vendored slot (keep the *filename* the
   build references, or repoint both refs to a new filename — see Phase 4), then
   `git -C Fizzygum checkout` to restore afterward. Run `fg gauntlet`. **Must be green.**
   Record baseline size (expect it already < 529 KB legacy, since no Babel-ES5).
5. **Byte-identity oracle:** reuse this session's technique — a patched copy of
   `check-coffee-syntax.js` whose `COMPILER` is env-overridable and which captures every
   `compileFGCode` fragment output to a file (see §7). Dump fragment output for
   **stock 2.7.0** and for **your baseline bundle**; `diff` must be **empty**. This is
   your fast pre-gauntlet gate for every subsequent phase.

### Phase 1 — Exclude whole dead modules
Rebuild the bundle excluding `cake.js`, `command.js`, `optparse.js`, `repl.js`,
`register.js`, `browser.js`, `sourcemap.js` (and ensure `coffeescript.js` doesn't hard-
`require` them on the compile path — stub/guard as needed). Re-bundle, minify.
Gate: **byte-diff empty** → **`fg gauntlet` green**. Record size delta.

### Phase 2 — Empirical dead-code coverage map (automate the owner's DevTools tip)
Using Puppeteer (in `Fizzygum-tests`), boot a build whose `js/libs/` compiler is the
*unminified* full-lib bundle, with **`page.coverage.startJSCoverage()`** active, then
exercise a representative slice (boot + open the app battery / a few macro tests). Dump
per-range coverage for the compiler file → a used/unused **line map**. Cross-reference
with §5. This (a) confirms the keyword list against a real run, (b) surfaces anything the
list missed, (c) tells you which in-module branches are safe to strip in Phase 3.
Keep the coverage script under `.scratch/` and document what it found in this plan's
progress log.

### Phase 3 — Strip in-module dead features (one category per commit-point, gated)
For each category — sourcemap wiring, Literate, JSX/CSX, shebang, basename,
module-declaration, btoa/base64, `Error.prepareStackTrace` — do ONE at a time:
edit the retained lib module(s), re-bundle, re-minify, then **byte-diff empty → full
gauntlet green**. Keep only if both pass; revert immediately if either fails and record
*why* in the progress log (falsification evidence for future readers). Measure size after
each. Prioritize by coverage (Phase 2) × size.

### Phase 4 — Finalize + vendor
Stop when: gauntlet green **and** either the size target is met **or** remaining strips
are high-risk/low-yield (diminishing returns — the parser dominates and is irreducible).
Suggested target: **materially below the 2.0.3 baseline (~257 KB)**; treat < ~150 KB
minified as a strong result, but let the byte-diff+gauntlet — not the number — decide.
Then:
1. Name and vendor the artifact, e.g.
   `Fizzygum/auxiliary files/CoffeeScript/fizzygum-coffeescript-2.7.0-min.js`, plus keep
   the **unminified** source + the **build recipe/script** (`build-min-coffee.sh` or a
   `buildSystem/` node script) checked in, so the fork is reproducible, not a mystery blob.
2. Repoint the **two** references (§2): `build_it_please.sh` `cp` line and
   `check-coffee-syntax.js` `COMPILER`. (Grep `coffee-script_2.0.3` to be sure those are
   the only two.) Optionally keep the old filename to minimize churn, but a descriptive
   name is better documentation.
3. Final gate: `fg build` → boot-smoke → **`fg gauntlet`** (all 13 legs incl. webkit +
   serialization + file-roundtrip). Byte-diff vs stock 2.7.0 still empty.
4. Document: add a `docs/architecture/` note (or extend the runtime-backend note) on the
   fork — what was removed, the reproducible build recipe, the API contract, and the
   "re-derive from a newer CoffeeScript by re-running the recipe" procedure. Move this
   plan to `docs/archive/` with a status stamp + `archive/INDEX.md` line. Add a memory note.

---

## §7 Verification protocol (concrete)

- **Byte-identity oracle (fast, run first every phase).** Copy `buildSystem/check-coffee-syntax.js`
  to a scratch variant patched so: (i) `const COMPILER = process.env.CC_COMPILER;`
  (ii) `compileFGCode` pushes each `CoffeeScript.compile(src,bare)` result into a global
  array; (iii) before `process.exit`, if `process.env.CC_OUT` is set, write the array
  joined by a separator to that file. Run it from the `Fizzygum/` repo root with
  `CC_COMPILER=<abs path to bundle>` `CC_OUT=<file>`. Do it for stock-2.7.0 and the
  candidate; `cmp`/`diff` the two output files → **must be identical**. (This session's
  working patch: replace the `COMPILER` line via
  `s.replace(/const COMPILER = .*;/, 'const COMPILER = process.env.CC_COMPILER;')`,
  the `compileFGCode` line to capture into `global.__OUT`, and inject the dump before
  `process.exit`.) A green here means codegen is unchanged; only then spend gauntlet time.
- **Boot-smoke (fast).** Swap the candidate into the current build's
  `Fizzygum-builds/latest/js/libs/coffee-script_2.0.3.js` (keep filename), then
  `( cd Fizzygum-tests && node scripts/smoke-boot-headless.js )`. Restore afterward:
  `cp "Fizzygum/auxiliary files/CoffeeScript/coffee-script_2.0.3.js" Fizzygum-builds/latest/js/libs/`.
- **Full gate (per phase / commit-point).** Put the candidate in the **vendored slot**,
  `fg build` (its syntax gate will `require()` the candidate — so the candidate must be
  Node-`require`-able AND browser-global-setting, i.e. UMD), then `fg gauntlet`
  (background; wait for the notification; read `/tmp/fg-gauntlet.verdict`). All 13 legs green.
- **Rollback (always).** Vendored file is git-tracked:
  `git -C Fizzygum checkout -- "auxiliary files/CoffeeScript/coffee-script_2.0.3.js"`.
  Build output is disposable: `fg build` regenerates. **Always restore the vendored file
  after any swap**, and leave a clean `git status` before ending a session.

---

## §8 Central risks

- **A strip silently changes emitted JS.** → Caught by the byte-diff oracle (run it
  first, every phase) and the pixel-exact gauntlet.
- **Compile path hard-depends on a "dead" module** (e.g. `coffeescript.js` `require`s
  `sourcemap` unconditionally). → Guard/stub the require; boot-smoke fails loudly if wrong.
- **Minifier changes behavior.** → Always gauntlet the **minified** artifact, not just
  the unminified one. terser defaults are safe for this code, but verify, don't assume.
- **Candidate not Node-`require`-able** → the build's syntax gate (`check-coffee-syntax.js`)
  throws an operational error and the build aborts. Ensure UMD (works in Node *and*
  browser), like the stock legacy bundle. (Or, if you deliberately keep the gate on stock
  2.7.0, that's a design choice to document — but simplest is one artifact for both.)
- **Chasing the parser.** `parser.js` (jison table) dominates size and is irreducible —
  don't sink time trying to shrink it. The wins are the peripheral modules + Babel-ES5 removal.

---

## §9 Rejected / do-not-reattempt

- **Do NOT use the `modern` ESM bundle as the vendored file.** It is `export default
  CoffeeScript` — a plain `<script src>` will not create the global; the boot expects the
  `CoffeeScript` global. Use a **UMD** (the legacy bundle's shape) or your own UMD.
- **Do NOT keep Babel-ES5 transpilation "to be safe."** Fizzygum runs only on modern
  Chrome/WebKit (proven this session on native + webkit legs). ES5 shims roughly double
  the bundle for zero runtime benefit. Target modern JS.
- **Do NOT strip on the keyword list alone.** Every removal must pass the byte-diff oracle
  AND the gauntlet. The list guides; the gates decide.
- **Do NOT try to shrink `parser.js`.** Generated + irreducible.
- **Do NOT edit `Fizzygum-builds/**` as the source of truth** — it is regenerated every
  build. The vendored `auxiliary files/CoffeeScript/…` file is the source; edits go there
  (or to the build recipe that produces it).

---

## §10 Cold-execution protocol (how a fresh session runs this)

1. Read this whole doc. Run `Fizzygum-all/fg status` (repos/build/tests re-orientation).
2. **Re-verify the load-bearing facts** (they may have drifted): grep
   `CoffeeScript\.[A-Za-z_]+` under `Fizzygum/src` (expect only `.compile`); grep
   `coffee-script_2.0.3` under `Fizzygum/` (expect the 2 refs in §2); confirm
   `node_modules/coffeescript` is still 2.7.0 and still ships the two browser bundles.
3. (Optional, ~10 min) Reproduce this session's **drop-in proof** to build confidence:
   swap the stock legacy 2.7.0 bundle into the vendored slot, `fg gauntlet`, restore.
   Skip if short on time — it's already documented in §0.
4. Set up `Fizzygum-tests/.scratch/mincoffee/` and do **Phase 0** (baseline bundle +
   byte-diff oracle + one green gauntlet). Do not proceed until the baseline is green.
5. Phases 1 → 2 → 3 in order, each gated by **byte-diff empty → gauntlet green**, one
   change per gate, size measured each step, falsifications logged in this doc.
6. **Phase 4** only after a clean full gauntlet. Vendoring + repointing the two refs +
   final gauntlet + docs + archive this plan + memory note. Present a commit for owner
   approval (owner preference: never commit without an explicit OK; see the memory index).
7. This is a **fresh-session-worthy** arc (compiler internals + long gauntlet loops) —
   start it in its own session, not tacked onto other work.

---

## §11 References

- Root `CLAUDE.md` → "Source-as-text + in-browser compilation"; `Fizzygum/CLAUDE.md`
  (build/test/gauntlet, the syntax gate).
- `buildSystem/check-coffee-syntax.js` — the faithful fragmented-compile oracle; reuse it.
- `src/boot/loading-and-compiling-coffeescript-sources.coffee` (`compileFGCode`),
  `src/meta/Class.coffee` / `Mixin.coffee` (`_equivalentforSuper`, fragmenting).
- Memory index (`MEMORY.md`): the adjacent CoffeeScript-tooling note
  (`coffeescript-cognitive-complexity-tool.md`) records the 2.0.3-vs-2.7.0-vs-1.12.7
  version landscape and the bare-`super` shim gotcha. **Add a new memory note for this arc.**
- Owner's 2017 Evernote note — embedded verbatim in §5.
- The prior arc's raw evidence (this session): fragmented syntax gate under 2.7.0 = 0
  errors; emitted-JS diff = cosmetic only; boot-smoke green; full gauntlet green (verdict
  string recorded: `dpr1:PASS dpr2:PASS webkit:PASS apps:PASS paint:PASS tiernaming:PASS
  settle:PASS capstone:PASS refs:PASS revisits:PASS census:PASS serialization:PASS
  storage:PASS`).

---

## Ready-to-paste start prompt (run this plan cold in a fresh session)

> Read `Fizzygum/docs/plans/minimal-coffeescript-runtime-compiler-plan.md` in full — it
> is self-contained. Goal: build a minimal Fizzygum-only fork of the CoffeeScript **2.7.0**
> in-browser runtime compiler that exposes only `window.CoffeeScript.compile(src,{bare})`,
> emits byte-identical `bare` JS to stock 2.7.0 for all ~487 Fizzygum sources, passes the
> full `fg gauntlet`, and is materially smaller than the current ~257 KB 2.0.3 bundle.
> First run `fg status` and re-verify the plan's load-bearing facts (§2/§10 step 2:
> `grep -rhoE "CoffeeScript\.[A-Za-z_]+" Fizzygum/src` should show only `.compile`;
> `grep -rn coffee-script_2.0.3 Fizzygum` should show only the two references). Then do
> **Phase 0** exactly (scratch bundle from `node_modules/coffeescript/lib/coffeescript/*`,
> UMD/global, no Babel-ES5, minified with terser; stand up the byte-identity oracle by
> patching a copy of `buildSystem/check-coffee-syntax.js` per §7; get ONE green
> `fg gauntlet` on the un-stripped baseline) before removing anything. Gate every strip
> with **byte-diff-empty → gauntlet-green**, one change at a time, logging size deltas and
> any falsifications back into the plan. Always restore the git-tracked vendored file
> (`git -C Fizzygum checkout -- "auxiliary files/CoffeeScript/coffee-script_2.0.3.js"`)
> after a swap and leave a clean `git status`. Do NOT commit without explicit owner
> approval. Do NOT use the modern ESM bundle, do NOT keep Babel-ES5, do NOT strip on the
> keyword list without the gates (§9).

---

## §12 Progress log (append-only; newest first)

### 2026-07-23 (latest) — productionized as its own package `fizzygum-coffeescript-min`

Owner chose: **own repo + own npm package** (mirroring `coffeescript-cognitive-complexity`),
NOT a CoffeeScript git-branch. Reasoning: our cuts are on the *compiled* lib (a real branch
needs the harder src+jison route for ~no benefit); we're deliberately frozen on 2.0.3 for
byte-identity to the gauntlet refs (tracking upstream is an anti-goal); a branch is heavyweight
for shipping one bundle. Separation: the **package** is the versioned recipe + pre-built artifact;
**Fizzygum keeps vendoring** the built output (respects its no-runtime-npm, saved-to-disk build).

Created `Fizzygum-all/fizzygum-coffeescript-min/` (umbrella sibling; `git init`, 16 files staged,
NOT committed): `build.js` (recipe — reads `coffeescript@2.0.3` devDep lib, applies `patched/`,
bundles UMD via terser API, no global tools), `patched/{coffeescript,nodes,lexer,helpers}.js`
(the cut4 modules, each documents its cut), `verify.js` (fork ≡ stock 2.0.3 over `test/corpus/`),
`dist/coffeescript.js` (208,604 b = cut4 + ~50 b license banner) + `dist/coffeescript.full.js`,
README (cut manifest + provenance), MIT LICENSE (CoffeeScript derivative attribution). Scripts:
`build`/`verify`/`test`/`prepublishOnly`. `main` = dist min; `files` ships dist+patched+recipe.

**Verified:** `npm run build` + `npm run verify` OK; **authoritative Fizzygum-corpus byte-diff of
`dist/coffeescript.js` = IDENTICAL over all 4901 fragments**; **full gauntlet on the exact dist
artifact CLEAN GREEN (4m35s).** (Package dist min differs from scratch cut4 only by terser-version
drift + banner — the corpus byte-diff is the authority, and it's empty.)

**Outward steps (owner-approved, executed 2026-07-23):**
1. ✅ initial commit `fizzygum-coffeescript-min` @ `482ee03`.
2. ✅ GitHub repo live + pushed: https://github.com/davidedc/fizzygum-coffeescript-min (main @ 482ee03).
3. ✅ publish PREPPED — `npm publish --dry-run` green (prepublishOnly = build+verify; 14-file tarball,
   221 KB). **Owner runs the real `npm publish` (2FA), as with the CC tool.**
4. ✅ Fizzygum vendoring — vendored file **renamed** `coffee-script_2.0.3.js` →
   `fizzygum-coffeescript-min.js`; **3 refs repointed** (see §2 — build cp, syntax-gate COMPILER,
   AND the boot loader the plan had missed); provenance `README.md` added next to it; two tangential
   doc mentions updated. `fg build` OK; full gauntlet running/GREEN. Fizzygum commit pending owner OK.


### 2026-07-23 (later) — OWNER PIVOT: re-base the fork on 2.0.3 and cut THAT

**Owner decision** (after the reframe below): since sub-257 KB is infeasible on a 2.7.0
base, **re-base the minimal fork on CoffeeScript 2.0.3** — the currently-shipping vendored
compiler — and cut *it* down. 2.0.3 has a much smaller core (`nodes.js` 215 KB vs 2.7.0's
327 KB; `parser.js` 115 KB vs 192 KB) and, crucially, **byte-identity to 2.0.3 = zero
behavioral change against the existing gauntlet references** (which were captured under
2.0.3). So the byte-diff reference for this arc is the **stock vendored 2.0.3 blob**
(`/tmp/frags-vend203.txt` = its fragment output over all 487 sources).

**2.0.3 source:** `npm i coffeescript@2.0.3` into scratch `cs203/` (gitignored). Its lib
layout + compile-path require graph are structurally identical to 2.7.0 (same 8 modules),
so the same bundler applies (`--lib` points at the 2.0.3 lib). The vendored blob is the
stock **full browser bundle, Babel-ES5** (has `_typeof`/`_get` helpers, `text/coffeescript`,
`btoa`, `sourceMap`, `define.amd`).

**Bundler now takes** `--lib <dir>` `--pkg <file>` `--patch <dir>` (per-module edited
copies; stock modules stay pristine) `--drop <names>` (exclude a module entirely). Patched
modules live in scratch `patched/`.

**Results (all byte-identical to stock 2.0.3 over 4901 fragments; minified bytes):**
| step | bytes | Δ vs shipping 257,123 | what |
|---|---|---|---|
| shipping vendored 2.0.3 (full, Babel-ES5) | 257,123 | — | baseline to beat |
| **baseline** (compile-path only, modern JS) | 220,639 | **−14.2%** | drops Babel-ES5 + all CLI/browser/repl/register/cake/command/optparse modules. **Full gauntlet GREEN (4m34s).** |
| **cut1** — sourcemap family | 216,359 | −16.0% | `patched/coffeescript.js` (removed `require('./sourcemap')`, base64encode, sources/sourceMaps, map-building in `compile()`, inlineMap/sourceMap/transpile return branches, getSourceMap, formatSourcePosition, `Error.prepareStackTrace`) + `--drop sourcemap`. None affect emitted `js`. |
| **cut2** — + module-declaration | 212,311 | **−17.4%** | `patched/nodes.js` excises the contiguous `//### Import and Export` block (ModuleDeclaration/Import*/Export*, ~245 lines) — only referenced by import/export grammar reductions, which never fire for Fizzygum. **Full gauntlet GREEN (4m29s).** |
| **cut3** — + JSX (lexer) | 210,711 | −18.0% | `patched/lexer.js` removes `csxToken()` (the ~94-line CSX tokenizer) from the consume chain + its 3 exclusive regexes (`CSX_IDENTIFIER`/`INSIDE_CSX`/`CSX_INTERPOLATION`). `csxToken` only fires on `<` beginning a CSX tag; Fizzygum's `<` (comparison) always fell through to the operator path, so removal is a no-op for its output. **Full gauntlet GREEN (serial-retry clean; warn was a self-induced CPU-contention flake).** |
| **cut4** — + coverage-driven exotica | 208,554 | **−18.9%** | Bucket A (see below): CSX codegen (`compileCSX`/`compileCSXAttributes` in `patched/nodes.js`), Literate (`invertLiterate`/`isLiterate`), `baseFileName`, `checkShebangLine` (in `patched/helpers.js` + `patched/coffeescript.js`). **Full gauntlet CLEAN GREEN (4m35s, no flakes).** ← current best, awaiting owner vendor/commit. |

### Phase 2 — empirical dead-code coverage (the owner's 2017 DevTools tip, automated)
Ran **V8 coverage** (`NODE_V8_COVERAGE`) over the whole-corpus compile (dump-fragments,
unminified cut3, all 487 sources → 4901 fragments), analyzed with `analyze-coverage.js`:
**560 compiler functions, 105 DEAD (count 0), ~42.7 KB unmin.** Triaged into 3 buckets —
DEAD ≠ safe-to-cut:
- **A — exotic / not-Fizzygum's-use-case (CUT in cut4):** CSX codegen, Literate, baseFileName,
  shebang. Unambiguous non-language tooling. ~2.2 KB min.
- **B — ESSENTIAL, keep (dead only because the corpus compiles cleanly):** `syntaxErrorToString`
  (1481b), `updateSyntaxError`, `throwSyntaxError`, `parser.yy.parseError`,
  `nameWhitespaceCharacter`, the `error()` methods. These fire on ANY syntax error (live console
  editing, a future typo). Cutting them makes errors crash cryptically. **DO NOT CUT.**
- **C — real language features, unused-in-corpus but USABLE (owner decision; NOT cut):**
  `compileDestructuring` (6906b) + `compileObjectDestruct` (4976b) [destructuring assignment],
  `compileSplice`, `compilePower`/`compileModulo`/`compileSpecialMath` (`**`/`%%`), `generateDo`
  (`do ->`), unicode-codepoint escapes, `_extends`/`objectWithoutKeys` utility emitters. ~15 KB min
  potential, but removing them strips language capability — a future Fizzygum source using them
  would miscompile/crash confusingly (the byte-diff gate only protects the CURRENT corpus).
  **Recommend KEEP** unless the owner wants a hard-frozen dialect.

Tooling: `analyze-coverage.js <covDir> <unmin-bundle>` ranks dead functions by size.

Recipe for cut4 (the complete cut):
`node build-min-coffee.js --lib cs203/.../lib/coffeescript --patch patched --drop sourcemap --out out/fizzygum-cs203-cut4`
`patched/` = edited copies of `coffeescript.js` (sourcemap+shebang), `nodes.js` (module-decl+CSX),
`lexer.js` (CSX tokenizer), `helpers.js` (literate+baseFileName).

**Owner's 2017 list — coverage:** ✅ XHR/Runscripts/load/run/Btoa/prepareStackTrace
(browser excluded + base64/prepareStackTrace removed) · ✅ cake · ✅ CLI/Basefilename
(command/optparse excluded) · ✅ repl/register · ✅ Sourcemap/Linemap/Base64 · ✅ Module
declaration · ✅ **CSX/JSX** (csxToken removed — the safe bulk) · ⚠ Checkshebangline (still in
compile, trivial ~0.4 KB) · ⚠ Literate (invertLiterate/isLiterate still in helpers/lexer, tiny).

**Net at cut4: 257,123 → 208,554 = −48,569 bytes (−18.9%), byte-identical to stock 2.0.3 over
all 4901 fragments.** `parser.js` (~95 KB min) + `nodes.js` core (~80 KB min) dominate the
remaining floor; the only further material lever is Bucket C (language features, ~15 KB min) —
NOT recommended — and anything past that needs jison regen. **Status after cut4: awaiting the
final gauntlet, then owner decision to vendor+commit** (name the artifact, repoint the 2 refs
in `build_it_please.sh`+`check-coffee-syntax.js`, check in the `build-min-coffee.js` recipe +
`patched/` + `cs203` provenance, archive this plan). Tree left clean after each gauntlet
(vendored 2.0.3 restored via `git checkout`).

### 2026-07-23 — Phase 0 DONE (green), + a mandate-reframing size finding

**Scratch tooling** (all under `Fizzygum-tests/.scratch/mincoffee/`, gitignored):
- `build-min-coffee.js` — the reproducible bundler. Assembles the compile-path lib
  modules into a self-contained **UMD** (sets `window.CoffeeScript`, also Node-`require`-
  able) via a ~30-line require-registry, then `terser --compress --mangle --ecma 2020`.
  **No external bundler, no Babel-ES5.** `--out <base>` picks the output basename.
- `dump-fragments.js` — the **byte-identity oracle** (patched `check-coffee-syntax.js`;
  env `CC_COMPILER`/`CC_REPO`/`CC_OUT`, captures every `compileFGCode` fragment).

**Structural finding — the compile path is only 8 modules.** `coffeescript.js` (the entry;
`index.js` is bypassed — it's the Node wrapper that pulls `fs`/`vm`/`path`/`@babel`)
requires only `{lexer, parser, helpers, sourcemap, nodes}`; `lexer→{rewriter,helpers}`,
`nodes→{scope,lexer,helpers}`, `rewriter→helpers`, plus `package.json` (VERSION). **Zero
node built-ins on the compile path; the only external dep — `jison` — is in `grammar.js`,
which is BUILD-TIME (generates `parser.js`) and never loaded at runtime.** ⇒ **The plan's
Phase 1 "exclude whole dead modules" (cake/command/optparse/repl/register/browser) is
already banked** — those modules are never required by the compile path, so they were
never in the bundle. The only compile-path module whose *functionality* is dead under
`{bare:true}` is `sourcemap.js` (still `require`d by `coffeescript.js`; a Phase-3 in-module
strip, ~1.7 KB min).

**Phase 0 gates — ALL GREEN:**
- Byte-identity oracle: stock-2.7.0-lib vs my FULL bundle vs my MIN bundle → **all three
  emit byte-for-byte identical JS** across 487 files / **4901 fragments** / 0 errors
  (67,519-line dumps, empty `diff`). Terser perturbed nothing (full==min).
- Build with the bundle vendored: **OK** (syntax gate `require`d it, compiled all sources +
  530 test files, 0 errors, all build gates pass).
- **Full 13-leg `fg gauntlet`: GREEN, 4m37s** — `dpr1 dpr2 webkit apps paint tiernaming
  settle capstone refs revisits census serialization storage` all PASS.

**Sizes (minified, terser --ecma 2020):**
| bundle | bytes | note |
|---|---|---|
| stock 2.7.0 legacy (Babel-ES5) | 530,111 | what stock ships |
| **my baseline min (8 modules, modern JS)** | **342,886** | byte-identical, gauntlet-green |
| vendored 2.0.3 (the old target to beat) | 257,123 | a much older, smaller language |
| per-module: `parser.js` | 155,750 | generated jison table — data, minifies poorly |
| per-module: `nodes.js` | 129,351 | AST codegen — needed for features Fizzygum uses |
| **parser + nodes = irreducible floor** | **285,101** | **already > the whole 2.0.3 bundle** |

**⚠ MANDATE REFRAME (decision for the owner).** The §1 target "materially below the 2.0.3
~257 KB" is **infeasible on a 2.7.0 base**: `parser.js`+`nodes.js` alone minify to **278 KB
> 257 KB**. 2.0.3 is smaller only because it's a fundamentally older/smaller language
(pre-JSX/import feature growth). The Babel-ES5 removal + whole-module exclusion wins are
already banked in the 335 KB baseline (exactly as §8 predicted). To go materially lower
needs the **"true fork"** (§6 alt): clone `jashkenas/coffeescript@2.7.0`, strip
JSX/import/literate from `src/grammar.coffee`+`src/lexer.coffee`+`src/nodes.coffee`,
**regenerate `parser.js` via jison**, rebuild — high effort, real byte-diff risk, bounded/
uncertain payoff (the JSX+import share of the 278 KB floor). **PAUSED here for owner
direction: (A) ship the gated ~335 KB modern bundle as-is [recommended], (B) do the
small sourcemap strip only (~3 KB), or (C) attempt the true-fork to chase sub-257 KB.**
Tree restored to clean (vendored 2.0.3 back); baseline bundle + tooling live in scratch.
