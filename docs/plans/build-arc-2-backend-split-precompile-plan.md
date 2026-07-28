# Arc 2 · Backend split (SW-full vs native+3D-core bundles) + precompile-generation externalization

**STATUS: PLAN ONLY — AUTHORED 2026-07-28. Written to be executed COLD by an LLM/engineer with
ZERO prior context.** All facts below were verified against the working trees on 2026-07-28
(Fizzygum `master @ ae45e0ff`, suite = 268 SystemTests, SWCanvas repo `main`, dist commit
`468c5f7`, vendored pin `df0b64c9…`). Line numbers WILL drift — the quoted method/class names and
code snippets are authoritative; re-grep before trusting any `file:line`.

**MANDATE.** This arc *eliminates* two standing problems outright — it does not soften them:
1. The runtime `?sw=1` backend switch dies. The rendering backend becomes a **build-time property
   of the entry page**: an SW-everything page for testing, a native+3D-core page for product use.
   The 263 KB SWCanvas 2D/text engine and the 90 MB font assets stop riding along in artifacts
   that can never use them.
2. The in-page pre-compiled-bundle *generation* machinery (JSZip → `saveAs` → fish the zip out of
   the Downloads folder, driven by a **WSL-only** shell script that silently no-ops on macOS)
   is deleted and replaced by an external headless driver. Product pages carry zero generation
   code beyond two flag-gated accumulator lines.

---

## §0 Orientation

Fizzygum is a CoffeeScript GUI framework rendered on one HTML5 canvas; three sibling repos
(`Fizzygum` source, `Fizzygum-tests` suite, `Fizzygum-builds` output — build aborts if any
missing). Read the root `CLAUDE.md` and `Fizzygum/CLAUDE.md` first. Use the `fg` wrapper
(`/Users/davidedellacasa/code/Fizzygum-all/fg`) for every build/test invocation — absolute path,
never `./fg`.

**Why this plan exists now.** A 2026-07-27/28 owner discussion (recorded in memory
`mixin…`-era session; distilled entirely into this doc) examined the build/usage axes:
backend selection, dynamic loading, packaging profiles, single-file save. The owner locked
this arc: split the backend at build time and externalize precompile generation. It is ARC 2
of the program (arc 1, the test-serving link, runs first and is independent); later arcs
(harmonization, dynamic parts, packaging profiles) build on this one and are OUT OF SCOPE
here — see §10.

**Critical reframes — do not re-derive these, they are the plan's spine:**

- **R1: "Two builds" is a false dilemma.** The backend split point in `build_it_please.sh` sits
  *after* terser: the boot JS is minified first, then the SWCanvas vendor blobs are `cat`-ed in
  front of it. A second bundle flavour is one more concatenation (~1 s on an 18.4 s build), and
  both flavours share one build tree. Nobody runs the build twice.
- **R2: SWCanvas is already the test backend.** The headless runners hardcode `?sw=1`
  (`../Fizzygum-tests/scripts/run-all-headless.js:104`, `run-macro-test-headless.js:95`). Baking
  the flag into the harness page changes *selection mechanics only* — same engine, same flags,
  same pixels. **Expected reference-image churn: ZERO.** Any suite diff in Phase B is a
  regression, not churn.
- **R3: The 3D path needs ~23 KB of SWCanvas, not 263 KB.** `Triangle3DOps` writes raw typed
  arrays; its mentions of SpanOps/PolygonFiller/Context2D are comments only (verified). The full
  closure of what Fizzytiles' 3D uses is Validators + Color + Surface + DepthBuffer + Texture3D +
  Triangle3DOps (+ tiny Constants/Debug). Measured with terser: core ≈ 18,196 B min, sw3d.js ≈
  5,118 B min.
- **R4: Generation is packaging-time, not runtime.** A puppeteer driver can
  `page.evaluate(() => window.JSSourcesContainer.content)` and write `pre-compiled.js` from Node.
  The in-page zip/download dance exists only because a browser page can't write files. The
  current driver (`buildSystem/generate-pre-compiled-file-via-browser.sh`) only executes its body
  when `uname -r` contains `microsoft` — **on macOS, `--homepage` prints "generating…" and ships
  the `window.preCompiled = false` stub**, i.e. homepage's instant-boot precompile has been
  silently inoperative on this machine. Phase C makes it work again *and* deletes the machinery.
- **R5: The compiler is NOT part of this arc.** A 2026-07-28 inventory proved the in-browser
  CoffeeScript compiler is product-critical (FizzyPaint tools are CS source strings, spreadsheet
  formulas are CS, `$src` snapshot records, Fizzytiles LCL). Nothing here touches
  `js/libs/fizzygum-coffeescript-min.js`.

---

## §0.5 Cold-execution protocol

1. Run `/Users/davidedellacasa/code/Fizzygum-all/fg status` — confirm clean trees, note the
   suite count.
2. Read this doc fully. Re-grep every quoted symbol you are about to touch (`grep -n` the method
   name, not the line number).
3. Execute phases IN ORDER (A → B → C). Each phase ends with its gate green (§8) before the next
   begins. A and C are independent of each other; B depends on A's vendored artifacts.
4. Phase A works in the SWCanvas repo at `/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas`
   — **the path contains spaces**: quote it everywhere; `git -C "<path>"` for every git command.
5. Owner gates: ratify the D-decisions marked RATIFY (§1) at kickoff if the owner is present;
   otherwise proceed with the recommended choice and list them in the end-of-arc review.
   **Never commit or push without explicit owner approval** (standing rule). Cross-repo commit
   order at the end: SWCanvas first (dist is committed there), then Fizzygum (pin bump + build
   changes), then Fizzygum-tests (script adaptations).
6. If a suite leg fails: remember `[shard N] did not start within 90s` /
   `ReferenceError: CoffeeScript is not defined` is the boot-storm infra flake, not a code bug.
   Real pixel diffs in Phase B violate R2 — stop and diagnose, do not recapture.

---

## §1 Goal and decisions

One 18-ish-second build pass produces ONE build tree containing TWO boot bundles and (up to)
three entry pages; the runtime `?sw=1` switch is removed; precompile generation becomes an
external cross-platform driver.

| # | Decision | Choice | Status |
|---|---|---|---|
| D1 | Backend selection | Build-time, per entry page. `worldWithSystemTestHarness.html` (+ `index-sw.html`) preset `window.FIZZYGUM_USE_SWCANVAS = true` and load the SW-full bundle; `index.html` presets `false` and loads the native+3D-core bundle. | LOCKED (owner, 2026-07-27) |
| D2 | Precompile generation | Externalized: drain deleted from src, accumulator flag-gated, WSL script replaced by a puppeteer driver living in `Fizzygum-tests/scripts/`. | LOCKED (owner, 2026-07-28) |
| D3 | det-trig in the native bundle | **Drop it** (it exists solely for SW cross-engine determinism; native pixels are not suite-gated). Consequence: native-entry trig differs from platform-Math by ≤1 ULP vs today, and Fizzytiles' cube renders ~1 ULP differently between the two entries. Keep the shim in the SW bundle unchanged. | RECOMMENDED — RATIFY |
| D4 | Interactive SW entry | Ship `index-sw.html` (SW bundle, no test harness) — replaces the owner's `?sw=1`-on-index habit and gives the smoke script a clean SW page. | RECOMMENDED — RATIFY |
| D5 | Homepage flavour | Native-only: no SW bundle, no `index-sw.html`, no `font-assets/` copy in `--homepage` trees (it already `rm`s the harness page). Saves 90 MB deploy + 263 KB boot payload. | RECOMMENDED — RATIFY |
| D6 | The `?sw=1` query param | Delete the URL-param fallback (`globalFunctions.coffee` — the `bootQueryParams.get("sw")` branch) in the same arc; the preset is the only mechanism. Keep `?dpr=` (still needed for HiDPI test forcing). Update the three tests-repo scripts that pass `?sw=1` (harmless-but-dead once pages preset). | RECOMMENDED — RATIFY |

Non-goals: dynamic/lazy part loading; packaging profiles; anything touching the compiler; the
single-file-save arc (separate locked plan — this arc *upgrades* its §7.2/D1 option, see §10).

---

## §2 Exact current state (verified 2026-07-28)

### 2.1 Sizes and timings (measured this session)

| Fact | Value |
|---|---|
| Full `fg build` wall time | **18.35 s** (`/usr/bin/time`, this machine) |
| `js/fizzygum-boot-min.js` | 314,357 B = det-trig + `;try { DetTrig.install(Math) }…` + swcanvas.min.js + sw3d.js + ~15 KB minified boot JS |
| `vendor/swcanvas/swcanvas.min.js` | 262,997 B (includes BitmapText + text bridge ≈ 26% of the unminified bundle) |
| `vendor/swcanvas/sw3d.js` | 21,910 B unminified |
| 3D-core subset, terser-minified probe | **18,196 B** (SWCanvasConstants, core/Debug, utils/Validators, core/Color, core/Surface, core/DepthBuffer, core/Texture3D, renderers/Triangle3DOps) |
| `examples/sw3d.js` terser-minified | **5,118 B** |
| `runtime-prelude/deterministic-trig.js` | 15,984 B unminified |
| `font-assets/` (repo AND copied into every build) | **90 MB** |
| CoffeeScript compiler `js/libs/fizzygum-coffeescript-min.js` | 208,604 B (untouched by this arc) |

### 2.2 Bundle assembly (`Fizzygum/build_it_please.sh`)

- `:142-152` — vendor auto-fetch gate (`vendor/swcanvas/` from `vendor/swcanvas.pin` via
  `scripts/vendor-swcanvas.sh`; checks for `swcanvas.min.js`, `sw3d.js`, `VERSION`).
- `:645-660` — homepage-only sed that turns `if Automator?…` checks into `if (false)` before
  terser (dead-code elimination).
- `:660` — terser minifies `fizzygum-boot.js` → `fizzygum-boot-min.js` (SWCanvas NOT included at
  this point).
- `:672-698` — **the prepend** (the seam R1 exploits): writes `deterministic-trig.js`, the
  `DetTrig.install(Math)` line, `swcanvas.min.js`, `sw3d.js`, then the minified boot JS into a
  tmp file, `mv`s it over `fizzygum-boot-min.js`. `\n;\n` separators defend against ASI (the
  vendor min file ends with a sourceMappingURL comment and no newline — keep that defense).
- `:705-709` — unconditional `font-assets/*` copy into the build.
- `:591/:593` — `BUILDFLAG_LOAD_TESTS = false/true` stamped into the boot source per flavour.
- `:713` — `cp src/index.html $BUILD_PATH/` (the only entry-page copy).
- `:811-850` — homepage tail: `rm worldWithSystemTestHarness.html`, dev icons, unminified boot,
  per-class source files (keeps `sources_batch_*` + Class/Mixin sources), then
  `. ./buildSystem/generate-pre-compiled-file-via-browser.sh`, then `rm FileSaver.min.js`,
  `jszip.min.js`, the three `js/src/` helpers' unminified twins.

### 2.3 Entry pages

- `src/index.html` is the ONLY page source; `:47` loads `js/fizzygum-boot-min.js`. No charset
  meta (known; the single-file plan's Phase 1 adds it — don't collide, just don't regress it).
- `worldWithSystemTestHarness.html` is **generated by `buildSystem/build.py`** from
  `src/index.html` (`INPUT_HTML_FILE` `build.py:41`, `OUTPUT_HTML_FILE_FOR_TESTS_RUNNING`
  `build.py:42`, written around `build.py:390`). This generator is the natural place for
  per-page bundle-src substitution and the flag-preset inline script.

### 2.4 Backend selection at runtime (`src/boot/globalFunctions.coffee`)

- `:127-128` — `unless window.FIZZYGUM_USE_SWCANVAS?` then read `?sw=1`. **A preset wins and the
  param is then never parsed** — the preset mechanism this plan relies on already exists.
- `:166-167` — `if window.FIZZYGUM_USE_SWCANVAS and window.SWCanvas?` → `installSWCanvasExtensions()`.
- `:342-349` — world creation defers behind `bootstrapSWCanvasFontsThen` only under the flag.
- **Guard audit (done 2026-07-28, load-bearing for D1):** every consumer of the full-bundle
  surface (`SWCanvas.createCanvas`, `SWCanvas.fonts._raw`, compat contexts) is either gated on
  `FIZZYGUM_USE_SWCANVAS` or only ever installed/called by code that is
  (`installSWCanvasExtensions` `SWCanvasElement-extensions.coffee:144-197`;
  `swCanvasEnsureAtlasForFont` `:100-136` reachable only via the wrapped `fillText` that
  `installSWCanvasExtensions` installs; `bootstrapSWCanvasFontsThen` `globalFunctions.coffee:267`
  called only from the flag-gated branch; `HTMLCanvasElement-extensions.coffee:23-24` flag-gated;
  `WorldWdgt.coffee:515` flag-gated). Therefore a **Core-only** `window.SWCanvas` on the native
  page trips nothing. The only unconditional touch is `window.SWCANVAS_MAX_FONT_SIZE = 96`
  (`SWCanvasElement-extensions.coffee:33`) — a plain number, harmless.
- 3D consumers use only the Core subset: `FridgeMagnets3DCanvasWdgt.coffee:115-120` —
  `window.SWCanvas.Core.Surface physW, physH` (FACTORY, no `new`),
  `new window.SWCanvas.Core.DepthBuffer`, `window.SW3D.makeEngine window.SWCanvas, {…}`; sw3d.js
  itself reads only `SWCanvas.Core.Triangle3DOps` (lazily, inside `makeEngine`).

### 2.5 SWCanvas repo (`/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas` — SPACES IN PATH)

- `build.sh` concatenates ~60 sources into `dist/swcanvas.js` inside one IIFE; BitmapText is a
  *vendored sub-dependency* (auto-fetched from `vendor/bitmaptext.pin` — the gate at build.sh
  ~`:97-105` aborts the FULL build if the fetch fails; a core-only target must NOT trigger it).
- The footer (build.sh `~:320-395`) builds `window.SWCanvas = { createCanvas, createImageData,
  fonts, Core: {...} }` — note `Core.Surface` is exposed as `CoreSurfaceFactory` (a factory
  wrapping `new Surface`), and a Node `module.exports` mirror follows.
- `dist/` IS committed (`git ls-files dist/` → swcanvas.js, swcanvas.min.js, build-info, map) —
  so new dist artifacts propagate through Fizzygum's from-pin vendoring.
- Dependency closure for the core target (verified by grep of the actual sources):
  `Surface.js` uses Color + Validators; `DepthBuffer.js`/`Texture3D.js`/`Triangle3DOps.js` use
  nothing further (their SpanOps/ClipMask/Context2D mentions are comments). Include
  `SWCanvasConstants.js` + `core/Debug.js` because the footer exports `IS_DEBUG`/`assertDebug`
  and they cost ~2 KB.
- `Fizzygum/scripts/vendor-swcanvas.sh` copies exactly `dist/swcanvas.js`, `dist/swcanvas.min.js`,
  `examples/sw3d.js` (both modes: from-pin tarball and `--source <checkout>`); validates their
  presence; writes `VERSION` last as completion sentinel.

### 2.6 Precompile generation machinery

- **Accumulator:** `JSSourcesContainer.content += JS_string_definitions + "\n"` at
  `src/meta/Class.coffee:434` and `src/meta/Mixin.coffee:220`, inside the
  `if generatePreCompiledJS or createClass/createMixin` compile branch (`Class.coffee:301`,
  `Mixin.coffee:218`). Constructor signatures: `(source, generatePreCompiledJS, createClass)`
  (`Class.coffee:275`), `(source, generatePreCompiledJS, createMixin)` (`Mixin.coffee:166`).
  The boot loader passes `true, true` for a normal compile boot and `false, false` for a
  pre-compiled ingest boot (`loading-and-compiling-coffeescript-sources.coffee:174-186`) — so
  **every dev boot accumulates ~2.5 MB of compiled-JS string it never uses**.
- **Drain:** `loading-and-compiling-coffeescript-sources.coffee:150-155` — if URL contains
  `generatePreCompiled`: `new JSZip` → zip `pre-compiled.js` =
  `"window.preCompiled = true;\n\n" + window.JSSourcesContainer.content` → `saveAs`.
  This is the ONLY src consumer of JSZip/`saveAs` (`FileSaving.coffee:6` is deliberately
  independent; the other users are `Automator.coffee`/`AutomatorPlayer.coffee` in the tests
  harness).
- **Load gating:** `globalFunctions.coffee:191` loads FileSaver + jszip + the two tests manifests
  `if BUILDFLAG_LOAD_TESTS or (window.location.href.includes "generatePreCompiled")`.
- **Driver:** `buildSystem/generate-pre-compiled-file-via-browser.sh` — entire body inside
  `if [[ "$(uname -r)" == *microsoft* ]]`; launches real Chrome, `sleep 12`, unzips from the
  Downloads directory. On Darwin: no-op (R4).
- **Stub:** `auxiliary files/pre-compiled.js` (`window.preCompiled = false;`) copied into every
  non-generated build (`build_it_please.sh:735-737`).
- The tests repo has a boot-wait helper to reuse: `scripts/lib/headless-boot.js` —
  `resolveBuiltIndexUrl`, `inPageWaitReady`.

---

## §3 Why it is shaped this way (history)

- `?sw=1` was added when SWCanvas was an experimental alternate backend; runtime switching let
  one artifact serve both. SWCanvas then became the deterministic test substrate (byte-exact
  SHA-256 reference matching, DetTrig shim), while production stayed native — but the bundle was
  never split, so every artifact ships both engines.
- SW3D landed 2026-07-08 (Fizzytiles port, `docs/archive/fizzytiles-sw3d-port-plan.md`), making
  the native entry *depend* on a sliver of SWCanvas Core even with the flag off — which is what
  makes the naive "drop SWCanvas from the native page" impossible and the core-subset target
  necessary.
- The zip/download generation flow predates headless tooling in this workspace (driver commit
  era: WSL2 daily machine). The machine changed; the script's guard never did. Puppeteer has
  since become a standing dependency (`build_and_smoke.sh`, the whole headless suite), removing
  the original reason for the browser-download hop.

---

## §4 The distilled argument

The backend axis and the generation axis share one root cause: **capabilities that are
per-artifact properties are currently selected at runtime inside a single maximal artifact.**
Splitting at the existing post-terser concatenation seam costs ~1 s and zero test churn (R1+R2);
the 3D subset is already architecturally clean inside SWCanvas (R3); generation already proved
the page can rebuild its own code (`?generatePreCompiled`), so the only in-page requirement is
the accumulator — everything else is Node's job (R4). No prior attempt at any of this exists to
learn from; the risk register (§7) is therefore about seams, not scar tissue.

---

## §5 Design (fix shape)

### Phase A — SWCanvas repo: `swcanvas-3d-core` dist target + sw3d dist artifact

1. New build script `build-scripts/build-3d-core.sh` (called at the END of `build.sh`, after the
   full dist — and runnable standalone). It must NOT pass through the BitmapText vendor gate.
   Concatenate, inside one IIFE (mirror the main build's header/footer style):
   `src/SWCanvasConstants.js`, `src/core/Debug.js`, `src/utils/Validators.js`,
   `src/core/Color.js`, `src/core/Surface.js`, `src/core/DepthBuffer.js`,
   `src/core/Texture3D.js`, `src/renderers/Triangle3DOps.js`, then a footer:

   ```javascript
   function CoreSurfaceFactory(width, height) { return new Surface(width, height); }
   var api = { Core: { Surface: CoreSurfaceFactory, Color: Color, Validators: Validators,
       DepthBuffer: DepthBuffer, Texture3D: Texture3D, Triangle3DOps: Triangle3DOps,
       IS_DEBUG: IS_DEBUG, assertDebug: assertDebug, debugLog: debugLog, debugWarn: debugWarn } };
   if (typeof window !== 'undefined') { window.SWCanvas = api; }
   else if (typeof module !== 'undefined' && module.exports) { module.exports = api; }
   ```

   Output `dist/swcanvas-3d-core.js`; minify → `dist/swcanvas-3d-core.min.js` with the SAME
   terser invocation `minify.sh` uses (read it, mirror it). Also minify `examples/sw3d.js` →
   `dist/sw3d.min.js`. Wire all three into `npm run build:prod`.
2. Node witness (new `examples/3d-core-node.js`, modeled on `examples/3d-meshes-node.js`):
   `require` ONLY `dist/swcanvas-3d-core.js` + `examples/sw3d.js`, render a lit box mesh to a
   Surface, assert non-empty pixels + a couple of exact spot-checks. Add to the test entry point
   if the harness supports it; otherwise leave as a runnable witness invoked by the build script
   (fail loudly on error).
3. Gate: SWCanvas `npm test` fully green (218+ tests at last count — trust the current runner's
   own count) + the witness passes + `dist/swcanvas.min.js` byte-identical to before (the full
   target must be untouched).
4. `Fizzygum/scripts/vendor-swcanvas.sh`: add the three new artifacts to BOTH modes' copy list
   and the presence validation. `build_it_please.sh:144` vendor check: also require
   `swcanvas-3d-core.min.js` (so stale vendors re-fetch).

### Phase B — Fizzygum: two bundles, three pages, no runtime switch

1. **Bundles** (edit the `:672-698` prepend section): from the SAME `fizzygum-boot-min.js`
   terser output produce
   - `js/fizzygum-boot-sw-min.js` = det-trig + `DetTrig.install` + `swcanvas.min.js` + `sw3d.js`
     + boot (byte-wise today's recipe, renamed);
   - `js/fizzygum-boot-native-min.js` = `swcanvas-3d-core.min.js` + `sw3d.min.js` + boot
     (no det-trig per D3; keep the `\n;\n` separators).
   Drop the old `fizzygum-boot-min.js` name entirely; grep the whole workspace for the literal
   (expect: `src/index.html`, `build.py`, docs, the single-file plan) and update — the
   single-file plan's §4.4/§2 references get a one-line "now `fizzygum-boot-native-min.js`" edit.
2. **Pages** (in `build.py`'s HTML generation, `build.py:41-42` + the writer near `:390`): from
   `src/index.html` emit
   - `index.html` — inline `<script>window.FIZZYGUM_USE_SWCANVAS = false;</script>` immediately
     before the bundle tag; bundle src = native;
   - `worldWithSystemTestHarness.html` — preset `true`; bundle src = SW; harness additions as
     today;
   - `index-sw.html` (D4) — preset `true`; bundle src = SW; NO harness additions.
   Implementation freedom: the substitution can live in build.py (preferred — it already writes
   the harness page) with `src/index.html` gaining a placeholder token; keep `src/index.html`
   the single page source.
3. **Boot cleanup** (D6): in `globalFunctions.coffee` delete the `?sw=1` fallback branch
   (`:127-128` becomes nothing — the preset is always present; add a loud
   `console.error` if the flag is undefined, as a page-authoring tripwire). Keep `?dpr`, `?speed`,
   `?intro` parsing untouched.
4. **font-assets** (`:705-709`): skip the copy when `$homepage` (D5). Homepage tail additionally
   removes `index-sw.html` and `fizzygum-boot-sw-min.js` (it already rm's the harness page).
5. **Tests repo adaptations** (same arc, separate commit):
   - `scripts/run-all-headless.js:104`, `run-macro-test-headless.js:95`, and the `?sw=1` uses in
     `macro-page-lib.js` / capture / serialization / torture scripts: drop the now-dead `sw=1`
     param (pages preset it). Grep `sw=1` across `scripts/` — 10+ hits, mechanical.
   - `scripts/smoke-boot-headless.js`: native leg boots `index.html`, SW leg boots
     `index-sw.html` (today both boot index with/without `?sw=1` — `:130`).
   - `swcanvas-hidpi-headless-check.js` and any script that boots index-with-sw: point at
     `index-sw.html`.
6. **Docs**: root + Fizzygum + tests `CLAUDE.md` sections that describe `?sw=1` and the single
   bundle; `docs/architecture/` mentions if any (grep `sw=1` in docs/). Present-tense, no
   changelog prose.

### Phase C — precompile-generation externalization

1. **Gate the accumulator**: wrap the two append lines in their own guard —
   `Class.coffee:434` and `Mixin.coffee:220` become `if generatePreCompiledJS then
   JSSourcesContainer.content += …`. Then make the boot loader pass the real mode:
   in `loading-and-compiling-coffeescript-sources.coffee:180/:186` replace the hardcoded first
   `true` with `window.location.href.includes "generatePreCompiled"` (hoist to a const). Also
   grep `new Class ` / `new Mixin ` across src/ to confirm no OTHER constructor call sites pass
   `generatePreCompiledJS = true` (expected: none — inspector edits go through
   `applyMemberEdit`, not the constructor; verify).
2. **Delete the drain**: remove `loading-and-compiling-coffeescript-sources.coffee:150-155`
   (the JSZip/saveAs block) — nothing else may change in that promise chain.
3. **Demote FileSaver/jszip**: `globalFunctions.coffee:191` condition becomes plain
   `if BUILDFLAG_LOAD_TESTS` (the manifests and libs are test-machinery-only now). The build
   still copies both libs (`build_it_please.sh:716-717`) for the test harness; homepage already
   deletes them.
4. **New driver** `../Fizzygum-tests/scripts/generate-pre-compiled-headless.js` (it lives in the
   tests repo so `require("puppeteer")` resolves — Node resolves from the SCRIPT's directory;
   this is the standing MODULE_NOT_FOUND trap). Model on `smoke-boot-headless.js` +
   `lib/headless-boot.js`: launch headless, goto
   `file://…/latest/index.html?generatePreCompiled`, wait for source compilation to finish (the
   page signal `stillLoadingSources == false`, or reuse `inPageWaitReady`), fail on any console
   error, then `page.evaluate(() => window.JSSourcesContainer.content)` and write
   `"window.preCompiled = true;\n\n" + content` to `<buildPath>/js/pre-compiled.js`. Assert the
   result is > 1 MB (sanity floor) and starts with the expected preamble.
5. **Wire it**: `build_it_please.sh` homepage section (`:825-830` area) replaces
   `. ./buildSystem/generate-pre-compiled-file-via-browser.sh` with an invocation `( cd
   ../Fizzygum-tests && node scripts/generate-pre-compiled-headless.js )` (explicit cd inside a
   subshell, mirroring `build_and_smoke.sh`; the guard hook allows correctly-cd'd chains).
   Delete `buildSystem/generate-pre-compiled-file-via-browser.sh`. NOTE the ordering trap: the
   driver must run BEFORE the homepage tail deletes dev files it needs, and the freshly built
   tree boots in compile-at-boot mode (stub `false`) — which is exactly what generation needs.
6. **Prove precompile is live**: extend the homepage boot check (`fg homepage` leg) to assert
   `window.preCompiled === true` in the booted page and that boot reached the desktop without
   the compile-at-boot log div. (Until now the leg could pass on the stub — that's how R4 went
   unnoticed.)

---

## §6 Phases and gates summary

| Phase | Repo(s) | Gate before proceeding |
|---|---|---|
| A | SWCanvas, then Fizzygum vendor script + pin | SWCanvas `npm test` green; core witness renders; full dist byte-identical; `fg build` green after re-vendor |
| B | Fizzygum + Fizzygum-tests scripts | `fg gauntlet` — **zero reference churn expected (R2)**; `fg homepage`; smoke boots all shipped pages; manual: open `index.html`, drag a Fizzytiles box tile, see the lit cube (native 3D proof) |
| C | Fizzygum + Fizzygum-tests | `fg gauntlet` green; `fg homepage` green WITH the new `preCompiled === true` assertion (first time this passes on macOS); dev-build boot unchanged (open `index.html`, world boots, inspectors work) |

---

## §7 Risks & mitigations

| # | Risk | Mitigation |
|---|---|---|
| R-1 | Core-only `window.SWCanvas` trips a full-bundle consumer on the native page | Guard audit already done (§2.4) — every consumer is flag-gated. Phase B smoke boots every page headless and fails on any console error, catching regressions of this invariant. |
| R-2 | The 3D-core concat misses a hidden dependency (something Surface/Triangle3DOps reads that only the full bundle defines) | The Node witness (§5.A.2) requires ONLY the core dist — a missing symbol throws there, not in Fizzygum. |
| R-3 | Suite pixels shift in Phase B despite R2 | Treat as regression, never recapture. Likeliest causes: page preset ordering (flag must be set BEFORE the bundle script executes), or det-trig accidentally dropped from the SW bundle. |
| R-4 | Gating `generatePreCompiledJS` changes normal-boot semantics (the `or createClass` branch also compiles/evals) | Only the two append LINES get the new guard — the compile/eval flow is untouched. The gauntlet plus a manual dev boot (inspector opens, class edit works) covers it. |
| R-5 | Generation driver races the boot (evaluates before all sources compiled) | Wait on the page's own completion signal (`stillLoadingSources` false / promise chain end), not a sleep; assert content size floor. |
| R-6 | Homepage tree still ships SW leftovers (bundle, index-sw, fonts) after D5 | Add an explicit homepage-tree assertion to the homepage check: forbidden files absent. |
| R-7 | Stale vendor: Fizzygum builds against a pin that predates the core target | `build_it_please.sh:144` presence check extended to the new artifact forces a re-fetch. |
| R-8 | Single-file-save plan drift (it embeds the boot bundle BY NAME and banks §7.2) | One-line edits in that plan doc (§5.B.1); its D1 upgrade (embed native bundle) is a NOTE there, executed by that arc, not this one. |

---

## §8 Verification protocol (concrete commands)

```
/Users/davidedellacasa/code/Fizzygum-all/fg status                  # orientation, every phase
# Phase A (SWCanvas repo — QUOTE THE PATH):
cd "/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas" && npm run build:prod && npm test
node examples/3d-core-node.js
# re-vendor into Fizzygum (from local checkout, updates pin):
cd /Users/davidedellacasa/code/Fizzygum-all/Fizzygum && ./scripts/vendor-swcanvas.sh --source "/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas"
# Phases B/C inner loop:
/Users/davidedellacasa/code/Fizzygum-all/fg presuite
# phase close (run in background, redirect to log; wait for the task notification):
/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet
/Users/davidedellacasa/code/Fizzygum-all/fg homepage
```

Long-run discipline: background + log + verdict files (`/tmp/fg-*.verdict`); never foreground-poll;
never pipe an fg call through a filter when its exit code gates a decision.

---

## §9 Rejected alternatives (do NOT re-attempt)

1. **BitmapText-optional flag on the FULL SWCanvas build** ("swcanvas minus text"): requires
   stubbing `fillText`/`strokeText`/`measureText` in Context2D and yields a dist matrix with no
   consumer — the SW world-backend inherently needs text (the world is mostly text), and the 3D
   path needs no Context2D at all. The subtractive core target is the correct seam.
2. **SW3D (or the 3D primitives) in a separate repo**: 22 KB, one consumer, and the primitives
   share Surface/conventions/tests with SWCanvas Core. A fourth repo in the vendoring chain
   (BitmapText → SWCanvas → Fizzygum) adds a cross-repo API-compatibility axis for zero
   isolation gain. Promotion to `dist/` gives the layering without the split.
3. **Two full build passes** for the two flavours: pointless — the split point is post-terser
   concatenation (R1); everything else in the tree is shared bytes.
4. **Making generation a lazily-loaded runtime part**: relocates code the product never needs at
   runtime; the external driver *removes* it instead (R4).
5. **Keeping the `?sw=1` runtime fallback "just in case"**: owner explicitly wants the runtime
   switch gone; a dead switch in boot code is exactly the species this codebase eliminates
   (proper-layouts-elimination standing direction).

---

## §10 References & downstream arcs

- `docs/plans/single-file-save-plan.md` — LOCKED sibling plan. This arc upgrades its D1/§7.2
  (the native bundle IS the "stripped SWCanvas variant" it banked). Its `SourceVault.coffee`
  citations are STALE (no such class exists; the enumeration lives in
  `src/boot/dependencies-finding.coffee:63-74` + the Class/Mixin source maps) — fix during its
  own revision pass.
- `docs/archive/fizzytiles-sw3d-port-plan.md` — how SW3D got here; determinism conventions.
- `Fizzygum/CLAUDE.md` §Architecture (source-as-text, boot, SW3D bullet) — must be updated in
  Phase B/C (docs step).
- **This is ARC 2 of the build-and-packaging program.** Sibling plans (authored 2026-07-28,
  filenames numbered by execution order): arc 1 `archive/build-arc-1-test-serving-link-plan.md` (DONE 2026-07-28)
  (replaces the per-build tests copy with a symlink; runs BEFORE this arc; shares
  `build_it_please.sh`, disjoint sections), arc 3 `build-arc-3-world-harmonization-plan.md`
  (one world design; retires the `»>>` region markers), arc 4
  `build-arc-4-dynamic-parts-plan.md` (SourceVault, partition, lazy loading; retires the
  `_coffeSource` globals and the whole-file exclusion markers), arc 5
  `build-arc-5-packaging-profiles-plan.md` (manifests; retires the `--homepage` conditional
  thicket). The program table and the owner-mandated **completion doctrine** (a retirement,
  once started, completes inside its arc — ratchet gates from day one, zero-count at close,
  machinery deleted in-arc) live in `build-arc-4-dynamic-parts-plan.md` §0.1/§0.2 and bind
  this arc too (this plan already conforms: D6, Phase C deletions). Compiler stays in ALL interactive
  profiles (2026-07-28 inventory: FizzyPaint tools, spreadsheet formulas, `$src` records,
  ScriptWdgt/console, Fizzytiles LCL all compile CoffeeScript at runtime).

## §11 Provenance

Authored 2026-07-28 from a live investigation session: measured build timing/sizes; read
`build_it_please.sh`, `build.py`, `globalFunctions.coffee`, the boot loader, `Class`/`Mixin`
append sites, `SWCanvasElement-extensions.coffee` (guard audit), SWCanvas `build.sh`/footer/
vendor scripts; terser probes for the core subset; an Explore-agent inventory of every runtime
compiler/source-string consumer. Owner locked D1/D2 in-session 2026-07-27/28.
