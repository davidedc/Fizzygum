# Single-file save — the whole app (code + world) in ONE self-contained `.html`

**STATUS: AUTHORED 2026-07-10 — research complete, design approved by owner, NO code written yet.**
**REVISED 2026-07-30 against the post-build-and-packaging-program tree** (arcs 1–5 + the
teardown-shared-core arc all landed; head at revision `4daded29`+): every §2/§4 fact re-verified
against current code, corrections woven in place (the partial syncs the arcs themselves made are
retained). Anchor on quoted **method names** first; line numbers are hints.
⚠ Cold-executor caution: the `pre-compiled.js` stub comment (`auxiliary files/pre-compiled.js`) is
STALE (pre-program — it still describes a `--homepage` flag and a zip download); the image is now
harvested headlessly by `../Fizzygum-tests/scripts/generate-pre-compiled-headless.js`. Do not source
build facts from that comment: the present-tense build reference is
`docs/architecture/build-and-packaging.md`.

This plan is self-contained: it embeds the load-bearing findings of the 2026-07-10 research pass
(two codebase studies + six sourced web studies on TiddlyWiki/Decker/platform behavior), so it is
executable cold without the original session.

---

## 1. Goal

TiddlyWiki-style self-saving: Fizzygum can save **one `.html` file containing the entire framework
code AND the serialized world**, which — opened from disk over `file://` — boots straight into that
saved world. Every such page can save itself again (a quine: edits, new widgets, and in-system
source edits all survive into the next generation).

### Scope and owner decisions (all LOCKED-IN 2026-07-10)

| # | Decision | Choice |
|---|---|---|
| D1 | Rendering backends in the single file | **Native HTML5-Canvas only.** `[REVISED 2026-07-30 — the original premise dissolved; upgrade owner-sanctioned during the program]` The single file embeds the NATIVE bundle (`fizzygum-boot-native-min.js`, **18,386 B** — boot JS only: SourceVault + parts manifest + globalFunctions + extensions; no SWCanvas 2D engine, no det-trig, no fonts). There is nothing to "hard-disable": `?sw=1` no longer exists anywhere (arc 2 deleted it); the page simply presets `window.FIZZYGUM_USE_SWCANVAS = false` like every native entry page does. The fizzytiles 3D vendor payload (`vendor-parts/fizzytiles-3d.js`, 18,879 B) rides only when that part is embedded. |
| D2 | Code representation | **Compile-at-boot v1** (source strings + in-browser compiler, exactly like today's dev build; a few seconds behind the spinner). A precompiled image inside the single file (the `homepage` profile's `form: "precompiled"` shape) is a **later option**, not v1. |
| D3 | Source code in the file | **KEEP the sources.** They are only ~2.5 MB, they are what makes in-system live editing work in the saved artifact, and they are already in memory for free. (Owner had offered to drop them; research showed no need.) |
| D4 | Where "save as single page" is available | **Every build.** The build embeds the boot-bundle, compiler, helper and per-part vendor-payload texts as wrapped strings (`[REVISED 2026-07-30]` **~235 KB** extra — bundle 18 KB + compiler 209 KB + helpers ~8 KB, +19 KB per 3D-carrying part — §4.4), so the menu item works from the normal dev build too, not just from single-file pages. |
| D5 | Save mechanism v1 | **Blob + `<a download>`** via the existing `FileSaving.saveStringAsFile` (universal, works over `file://` in all engines, Safari `data:` fallback already implemented). |
| D6 | In-place overwrite (File System Access API) | **v2, owner-gated, Chromium-only** (§8.1). Verified to work even over `file://` — see §3.4. |
| D7 | Assembly implementation | **ONE implementation, in CoffeeScript, in-world.** The build produces the artifact by booting the page headless and invoking the same in-world assembler (precedent: `?generatePreCompiled` / `../Fizzygum-tests/scripts/generate-pre-compiled-headless.js`). The shipped file is *generation 0 of the quine* — produced by the very code path every later save uses. No parallel Python assembler. |
| D8 | Snapshot embedding format | **Inert JSON store block**, TiddlyWiki 5.2 style: `<script type="application/json" id="fizzygum-world-snapshot">` with `<` → `<` escaping; parsed with `JSON.parse` at boot (inert during HTML parse, cheaper than a JS literal, and structurally cannot execute). |
| D9 | Base code vs in-system edits | **Base code payload stays pristine**; user's in-system class/instance source edits ride inside the snapshot as `world.sourceEdits` deltas and are replayed by the proven `SourceEditsRegistry` path at load. ("Baking" edits into the payload = possible later feature, out of scope.) |
| D10 | Splash | Drop the fake-desktop splash PNG in single-file pages (it shows the *default* desktop, wrong before a custom world); keep the small spinner, inlined as a `data:` URI (~800 B). |

Non-goals (v1): tests inside the artifact; SWCanvas rendering; videos; precompiled startup; FSA.

---

## 2. Why this is feasible — codebase facts (verified 2026-07-10)

The built page is *already* 99% of a single-file app:

- **`Fizzygum-builds/latest/index.html` is tiny** (`[REVISED 2026-07-30]` — measured, 2,718 B):
  `<title>` + one `<style>` block, splash + spinner `<img>`s, a positioning div, one
  `<canvas id="world">`, then TWO generated script tags (from `buildSystem/build.py`'s
  `generateEntryPage`, replacing the `<!--FIZZYGUM_BOOT_SCRIPTS-->` placeholder at
  `src/index.html`): an inline preset line
  `window.FIZZYGUM_USE_SWCANVAS = false; window.FIZZYGUM_EAGER_ALL_PARTS = false;` and
  `<script src="js/fizzygum-boot-native-min.js">` (**18,386 B** — boot JS only; the SWCanvas 3D
  core + SW3D moved OUT of the bundle in arc 4, into the fizzytiles part's vendor payload
  `js/vendor-parts/fizzytiles-3d.js`, 18,879 B, fetched with the part), plus an inline
  `window.onload → boot()`. **No stylesheet, no fonts, no favicon, and NO charset meta — the
  encoding currently rides on a UTF-8 BOM** at the top of both `src/index.html` and every built
  page (see risk R2). The SWCanvas bundle (`fizzygum-boot-sw-min.js`, 319,331 B) belongs to
  `index-sw.html`/the test harness and is never what a single-file save embeds.
- **Nothing anywhere uses `fetch`/XHR.** All runtime loading is `<script>` injection
  (`loadJSFilePromise`, `src/boot/globalFunctions.coffee:42-64`) or `new Image()` — because the
  page must run over `file://`. Inlining is therefore a *natural fit*, not a retrofit.
- **Total native-canvas no-tests payload ≈ 3.0 MB** (`[REVISED 2026-07-30]` — measured on a dev
  tree, ALL parts): boot bundle 18,386 B + CoffeeScript compiler
  (`js/libs/fizzygum-coffeescript-min.js`, 208,604 B) + `js/coffeescript-sources/` (23 files,
  2,778,000 B total: 21 per-part batch files `sources_batch_<n>` / `sources_batch_<part>_<n>` =
  2,741,288 B, plus `Class-source.js` 24,250 + `Mixin-source.js` 12,462) + three boot helpers
  (~7.8 KB: `loading-and-compiling…-min` 4,062, `dependencies-finding-min` 2,824,
  `logging-div-min` 905) + `pre-compiled.js` stub (257 B). A homepage-scope subset
  (core + meta-tools only) is smaller still.
- **The booted page retains everything needed to regenerate its own code, in memory:**
  - every class/mixin source in the **`SourceVault`** (`window.SourceVault`,
    `src/boot/source-vault.coffee`) — the registry every generated `sources_batch_*.js` file stores
    into, keyed by class name and tagged with the PART the class belongs to. Never emptied.
    `SourceVault.names()` enumerates, `SourceVault.get name` reads one
    (`src/boot/dependencies-finding.coffee` is its first consumer).
    ⚠ Build arc 4 replaced the old per-class `window.<Name>_coffeSource` globals and the
    `Object.keys(window)` suffix-scan with this registry, and a build gate
    (`buildSystem/check-source-vault.js`) keeps them dead — so the assembler enumerates the VAULT.
    Do not reintroduce a window scan. (Nothing else changed for this plan: the sources are still
    resident, still complete, still text.)
  - the `CoffeeScript` compiler global (kept resident — the paint tool needs it);
  - bonus: under `?generatePreCompiled`, `window.JSSourcesContainer.content` accumulates every
    class's compiled JS (the guarded appends in `src/meta/Class.coffee` / `Mixin.coffee`) — this
    is what the headless packaging driver reads back out and writes to disk, **proving
    in-browser self-reconstruction already works.** (⚠ Build arc 2 GATED that accumulation on
    the `?generatePreCompiled` mode: an ordinary boot no longer builds the string, so a
    single-file assembler running in a normal session must not assume it is populated —
    it can request the mode, or re-derive from the vault's sources.)
- **Load order is computed in-browser at boot** (`findLoadOrder()`, regex-scan + topological DFS,
  `dependencies-finding.coffee`) — no build-time manifest to carry.
- **The source-string wrapper** (`build.py`, `STRING_BLOCK`):
  `SourceVault.store("%s", "%s", "%s");` (name, escaped text, part)
  — the escaping is still `"`→`＂`, `\`→`⧹`, newline→`⤶`, but the DECODE now lives once inside
  `SourceVault.store` (`src/boot/source-vault.coffee`) instead of being appended to every emitted
  line. An assembler re-emitting sources must apply the same three replacements and emit
  `SourceVault.store` calls. (JSON was rejected historically because `file://` blocks JSON fetch.)
- **The serialization arc is the complete data half:**
  - `WorldWdgt::serializeWorldSnapshot(opts)` (`src/WorldWdgt.coffee:2228`) →
    `Serializer.serializeWorld` → versioned JSON envelope
    `{format:"fizzygum", formatVersion:1, kind:"world", objects:[…], world:{…}}`;
    the `world` section carries `children/desktopColor/alpha/wallpaperPatternName/appSlots/`
    `bin/shelf/preferences/idCounters/sourceEdits/…` (`src/serialization/Serializer.coffee:118-153`).
    `savedAt` is stamped **only if `opts.savedAt` is passed** — keep it OFF for deterministic
    generation-comparison tests.
  - In-system source edits ARE captured (`world.sourceEdits`, `SourceEditsRegistry`) and replayed
    through the in-browser compiler on load — class edits via `replayClassEdits()` *before*
    deserialization (`WorldWdgt.coffee:2277-2278`), instance edits via `{"$src"}` records.
  - `WorldWdgt::loadWorldSnapshot(envelopeOrString, opts)` (`WorldWdgt.coffee:2353`,
    `[REVISED 2026-07-30]`) is the restore orchestrator, and it now ALREADY handles the two
    availability concerns a single-file boot needs:
    **step 0** (`:2371-2378`) pre-scans the envelope's class names for missing LAZY parts and
    re-enters itself after `@parts.ensureAllLoaded` (positioned BEFORE any mutation — the in-code
    comment calls that placement "the whole correctness argument");
    **step 0b** (`:2386-2388`) does the same for the reflective layer when the snapshot carries
    class/mixin-level `sourceEdits` (`_snapshotNeedsTheReflectiveLayer`, `:2346`). Then:
    structural teardown via the SHARED shipping core (`@_settleLayoutsAfter =>
    @_teardownWorldStructureNoSettle()`, `:2392` — the same core the test teardown calls),
    id-counter restore, mixin-then-class edit replay, `Deserializer.deserialize`, app-slot/bin/
    shelf re-bind, one-settle child attach, colour/wallpaper, repaint + **`result.whenReady`**
    second repaint once async `$Image`/`$Canvas` data-URLs have decoded (`:2464`).
    **It `window.confirm`s unless `opts.skipConfirm`** (`:2358-2360`) — the boot path must pass
    `skipConfirm: true`. On a single-file page steps 0/0b are structurally no-ops: every embedded
    part is present and eager, and the sources are inline.
  - Round-trip is PROVEN pixel-identical cross-session at dpr 1 and 2
    (`../Fizzygum-tests/scripts/serialization-roundtrip-headless.js`), including source edits.
  - `FileSaving.saveStringAsFile(string, suggestedName, mimeType = "application/json")`
    (`src/serialization/FileSaving.coffee:12`) already does Blob → objectURL → `<a download>` →
    deferred revoke, with a Safari `data:`-URL fallback. Ships in all builds.
- **The boot seam** for "boot into a snapshot" is exactly
  `src/boot/globalFunctions.coffee:470-471` (`[REVISED 2026-07-30]` — same shape, new home):
  `if world.isIndexPage` → `world.createDesktop()` inside `createWorldAndStartStepping.startWorld`.
  Two nearby facts a cold executor needs: the harness `*TestSupport.installOnto` grafts run just
  before `new WorldWdgt` (`:429-433`) — verify they are existence-guarded, since those classes are
  absent from a single-file page; and `world.parts = new PartsRegistry` is created unguarded in the
  `WorldWdgt` constructor (`WorldWdgt.coffee:460`), seeding its state from the page-global
  `window.FIZZYGUM_PARTS` manifest — so the single-file page MUST carry a manifest block (§4.1/§4.3).
- **What does NOT exist today** (= the whole feature): a boot-time snapshot load path (loading is
  strictly in-session via menu/file dialog, `FileLoading`), and any HTML bundling/export
  (`FileSaving` is the only Blob user in `src/`, and it emits JSON).

---

## 3. External research distillation (sourced; full reports were session-scratchpad, ephemeral)

### 3.1 TiddlyWiki 5 — the pattern to copy

- **TW never snapshots the DOM.** `saveWiki` re-renders the whole file from wikitext templates
  (`core/modules/saver-handler.js`: `text = wiki.renderTiddler(downloadType, "$:/core/save/all")`);
  the HTML shell, `boot.js`, and the core plugin all live **as tiddlers in the store**, so every
  save regenerates the file from canonical data. Nothing depends on keeping the original file bytes.
- **Store block** (v5.2.0+): `<script class="tiddlywiki-tiddler-store" type="application/json">`
  with one JSON object per tiddler per line. The **entire** anti-breakout defense is in the
  `$jsontiddler` widget (`core/modules/widgets/jsontiddler.js`):

  ```javascript
  var json = JSON.stringify(fields);
  if(this.attEscapeUnsafeScriptChars) {
      json = json.replace(/</g,"\\u003C");
  }
  ```

  Since `<` can only occur inside JSON string values, `<` round-trips losslessly through
  `JSON.parse`, and `</script>` / `<!--` can never appear as literal bytes in the payload.
- **Saver hierarchy**: 15 savers, priority-sorted, first-capable wins. On a plain `file://` wiki in
  a modern browser everything above the **download saver** (Blob + `<a download>`, priority 100)
  disqualifies itself. In-place saving historically relied on privileged per-browser hacks that all
  died (TiddlyFox killed by Firefox 57, ActiveX, Java applet…) — the download saver is the only
  thing that survived every platform rug-pull. Lesson: **download is the baseline; anything
  fancier is an optional enhancement.**
- **Sizes**: empty TW5 = 2,552,335 B (v5.4.1), ~94% of it core JS. Community practical limits:
  comfortable < 10–20 MB, "rough going" ~30 MB, OOM territory ~70 MB. What degrades first is UI
  list rendering and import RAM, not hard browser ceilings (V8 max string ≈ 512 MB; Chromium
  in-memory Blob cap 2 GB on 64-bit desktop).

### 3.2 Decker — closest prior art (canvas-rendered single-file quine)

Deck data sits in a `<script language="decker">` block at the top of `<body>`; the whole UI is
canvas-drawn (multiple canvases + a hidden input — same DOM shape as Fizzygum). Save
(`js/decker.js`) splices fresh deck text into that block, re-serializes `body.innerHTML`, downloads
via Blob + hidden `<a download>` (revoked after 200 ms). Its format doc states the invariant
normatively: *"The PAYLOAD must never contain the literal sequence of characters `</script`"* —
enforced by format-level escaping. Feather Wiki (58 KB wiki quine) regenerates from a template
literal instead, reading its own running code from its `<script id=a>` DOM node.
**We take TW/Feather's template reassembly, not Decker's live-DOM serialization** — Fizzygum's DOM
accumulates runtime mutations (hidden IME `<input>` from `WorldWdgt.coffee:~1773`, canvas
width/height/style, boot-injected `<script>` tags in the multi-file case) that must not leak into
the artifact.

### 3.3 Platform facts (✓/✗, verified 2026-07-10)

- ✓ Blob + `<a download>` works from `file://` pages in Chrome/Firefox/Safari (same-origin blob;
  TW's universal saver). Repeated saves uniquify: `world (1).html` (Chromium-documented).
- ✓ Downloads are byte-exact; Chrome does NOT flag `.html` as a dangerous file type
  (`download_file_types.asciipb`: html has no `danger_level`); Safari's webarchive mangling applies
  only to File→Save As, never to programmatic downloads; Safari does not auto-open HTML.
- ✗ A `file://` page cannot `fetch`/XHR its **own bytes** in any default config (Chrome opaque
  origin; Firefox 68+ unique origin per file, CVE-2019-11730; Safari local-file restrictions).
  ⇒ self-save MUST come from memory/DOM, never from re-reading the file. (Reading own inline
  `script.textContent` from the DOM is unrestricted, no size cap that matters.)
- ✓ **`showSaveFilePicker` (File System Access API) WORKS from `file://` in Chromium** — the
  common "file:// isn't a secure context" claim is FALSE: Chromium's
  `is_potentially_trustworthy.cc` explicitly returns potentially-trustworthy for the file scheme,
  the picker path has NO scheme gate (verified in `window_file_system_access.idl`,
  `global_file_system_access.cc`, `file_system_access_manager_impl.cc`,
  `chrome_file_system_access_permission_context.cc`, Chromium main 2026-07), and TW community
  reports confirm first-hand ("From both a file: url and a localhost url I was able to save and
  reload"). Requires a user gesture; Chrome 122+ has persistent "Allow on every visit" permissions.
- ✗ Safari and Firefox have NO FSA pickers in any version (OPFS only); both formally oppose the
  API (WebKit standards-positions #28 "oppose", Mozilla #154 "harmful"). Brave disables FSA
  wholesale. ⇒ FSA = Chromium-only enhancement (v2), download = baseline.
- ✓ Inert `<script type="application/json">` + `JSON.parse` beats an equivalent JS literal at
  parse/boot (V8 "cost of JavaScript" guidance) and is inert during HTML parse.

---

## 4. Design

### 4.1 The artifact — block layout (document order = execution order)

```html
<!DOCTYPE html>
<html><head>
  <meta charset="UTF-8">                             <!-- MANDATORY, FIRST (risk R2) -->
  <title>Fizzygum</title>
  <style> …spinner keyframes (copied from src/index.html)… </style>
</head>
<body …same user-select/position:fixed styles…>
  <img id="spinner" src="data:image/svg+xml;…">      <!-- inlined spinner; NO fake-desktop splash (D10) -->
  <canvas id="world" tabindex="1" …></canvas>
  <script> window.FIZZYGUM_SINGLE_FILE = true;
           window.FIZZYGUM_USE_SWCANVAS = false;      /* the presets every native entry page carries */
           window.FIZZYGUM_EAGER_ALL_PARTS = true;    /* everything in the file is present ⇒ eager */ </script>
  <script> /* NATIVE boot bundle text (18 KB: SourceVault first, parts-manifest slot, boot JS —
              so the store blocks below have somewhere to go). No SWCanvas 2D, no det-trig. */ </script>
  <script> window.FIZZYGUM_PARTS = {…};  /* manifest REGENERATED from the saving session: the
              embedded parts only, batches irrelevant (inline), eager (§4.3) */ </script>
  <script> window.preCompiled = false;  /* the pre-compiled.js stub, inlined */ </script>
  <script> /* CoffeeScript compiler (2.0.3-based minimal build) */ </script>
  <script> /* vendor payloads of embedded 3D-carrying parts (e.g. fizzytiles-3d, 19 KB) */ </script>
  <script> /* the Class + Mixin sources (SourceVault.store blocks) + the 3 boot helpers
              (loading-and-compiling…, logging-div, dependencies-finding) */ </script>
  <script> /* source batches — SourceVault.store("<Name>", "…", "<part>") blocks, re-encoded (§4.5) */ </script>
  <script type="application/json" id="fizzygum-world-snapshot">
    /* serializeWorldSnapshot() envelope, "<" escaped to < (§4.5) */
  </script>
  <script> window.onload = function () { …canvas 1×1 sizing…; boot(); }; </script>
</body></html>
```

Notes:
- Inline blocks execute synchronously in document order ⇒ **no loader is needed at all**; by the
  time `boot()` runs, every global the multi-file loader would have injected already exists.
- The JSON store block is inert; boot reads it with
  `JSON.parse(document.getElementById("fizzygum-world-snapshot").textContent)`.
- The snapshot block is **replaced wholesale on every save** — never carried forward — so there is
  no staleness bug class.

### 4.2 Boot changes (`src/boot/globalFunctions.coffee`)

`[REVISED 2026-07-30 — re-derived against the current boot chain; the change SHRANK]`
Two small, surgical branches on `window.FIZZYGUM_SINGLE_FILE`:

1. **Short-circuit the loader at its ONE choke point.** Every script the boot chain fetches —
   `pre-compiled.js`, the compiler lib, the `BUILDFLAG_LOAD_TESTS` block
   (`globalFunctions.coffee:326-330`), the two always-loaded helpers (`:351-354`), and everything
   `loadReflectiveLayerPromise()` (`:130-170`) fetches (Class/Mixin sources,
   `dependencies-finding-min`, the batch files) — goes through `loadJSFilePromise` (`:67`). On a
   single-file page ALL of that content is already inline, executed in document order, so the
   branch is: `loadJSFilePromise` returns an immediately-resolved Promise under
   `FIZZYGUM_SINGLE_FILE`. One branch, one function; the rest of the chain — including the
   compile-at-boot arm of `loadReflectiveLayerPromise` (ingest+compile from the vault,
   `createWorldAndStartStepping()` at `:168`) — runs **unchanged** against the inline-populated
   vault. The old per-site `maybeLoad` substitution and the per-site test-assets guard are
   OBSOLETE: with the loader itself inert, no 404 is possible (old risk R4 dissolves
   structurally). Verify only that `testsManifest` staying `undefined` is tolerated —
   `runPostBootActionsOnce` (`:199-207`) is `Automator?`-guarded, and the `*TestSupport.installOnto`
   grafts (`:429-433`) must be existence-guarded (they are expected to be; check).
2. **Boot into the snapshot instead of the default desktop.** In `startWorld`
   (`globalFunctions.coffee:470-471`), replace
   `if world.isIndexPage then world.createDesktop()` with: if a `#fizzygum-world-snapshot` block
   exists → parse it and `world.loadWorldSnapshot envelope, {skipConfirm: true}`; else
   `world.createDesktop()` as today.
   - `loadWorldSnapshot` on the *empty* just-constructed world: the shared-core teardown
     (`_teardownWorldStructureNoSettle`) is designed to be safe on any world state, and
     `binWdgt`/`shelfWdgt` exist by then (created at `:467-468`, before this seam).
     **Verify this explicitly in Phase 2** (expected-safe, not yet demonstrated).
     Its steps 0/0b (parts + reflective-layer pre-scans) are no-ops here by construction.
   - Spinner UX: `removeSpinnerAndFakeDesktop()` currently runs before this seam (`:465`); in
     single-file mode prefer removing the spinner after `result.whenReady` resolves (images/canvas
     data-URLs decode async) — cosmetic, decide at implementation.
3. **Presets, not overrides.** The single-file shell carries the same preset line every native
   entry page carries (`window.FIZZYGUM_USE_SWCANVAS = false; window.FIZZYGUM_EAGER_ALL_PARTS =
   true;` — §4.1); `boot()` console.errors if the SW preset is missing (`:257-259`), so the shell
   must include it. There is no `?sw=1` to defend against — it no longer exists.

### 4.3 The assembler — `src/serialization/SingleFilePageAssembler.coffee` (new class)

One class, one job: return the full HTML string of §4.1 from live memory. All parts are canonical,
none read from the DOM:

- **Shell template**: a literal in the class (the single-file shell is intentionally distinct from
  `src/index.html`; it is THE canonical shell for saved pages).
- **Boot bundle + compiler texts**: from the wrapped strings the build embeds (§4.4) —
  `window.fizzygumBootBundle_source`, `window.coffeeScriptCompiler_source` (decoded with the same
  replacement table `SourceVault.store` applies — four characters once Phase 1 lands).
- **Boot helpers** (loading-and-compiling / logging-div / dependencies-finding minified JS): also
  embedded as wrapped strings by the build (§4.4) — they are small (~8 KB total).
- **Source batches**: regenerated from the in-memory registry — **enumerate the `SourceVault`**
  (`SourceVault.names()`, reading each text with `SourceVault.get name`; the same enumeration
  `dependencies-finding.coffee` uses), re-encode each with the escape spec (§4.5), and emit
  `SourceVault.store("<Name>", "…", "<part>")` blocks — carrying each source's PART through, so a
  saved page reproduces the partition rather than flattening it. The `Class` and `Mixin` sources are
  emitted in their own earlier block (they must compile before the batches — mirror the boot chain
  order) and deduped out of the batch set. The shell must therefore include
  `src/boot/source-vault.coffee`'s compiled output before any batch block, exactly as the boot
  bundle does.
  ⚠ Arc 4 note, concretized `[REVISED 2026-07-30]`: a saved page embeds **core + the parts that
  were actually loaded** in the saving session (that is what the vault holds). A part never loaded
  is simply not in the saved page — correct semantics for a single-file artifact. Concretely the
  assembler must ALSO emit: (a) a **`window.FIZZYGUM_PARTS` manifest block** regenerated from the
  live `window.FIZZYGUM_PARTS` filtered to the embedded parts — `PartsRegistry` seeds from it in
  the `WorldWdgt` constructor and `_partOf`/the snapshot pre-scan read it (the vault deliberately
  has no `partOf`); with `FIZZYGUM_EAGER_ALL_PARTS = true` preset, per-part eagerness and `batches`
  entries are irrelevant on the saved page; and (b) the **vendor payload text of each embedded
  3D-carrying part** (e.g. `fizzytiles-3d`, 19 KB) as an inline block before the batches — a loaded
  part's vendor JS has EXECUTED but its text is not in the vault, so the build must embed those
  payloads as wrapped strings alongside the bundle/compiler (§4.4(1)).
- **Snapshot block**: `serializeWorldSnapshot()` (no `savedAt` unless the user-facing save wants
  it), then `.replace(/</g, "\\u003C")` — the TW trick, verbatim (§3.1).
- **The `FIZZYGUM_SINGLE_FILE` flag block** and the `onload → boot()` tail.

World menu (in `WorldWdgt::buildContextMenu`, next to "save world snapshot…" at
`WorldWdgt.coffee:2347`): **"save world as single page…"** →
`saveWorldAsSinglePageToFile` → assembler →
`FileSaving.saveStringAsFile html, "fizzygum-world.html", "text/html"` (the mimeType param already
exists). Wrap in the same `SerializationError → world.inform` try/catch shape as
`saveWorldSnapshotToFile` (:2239-2248).

⚠ Dead-method gate: `saveWorldAsSinglePageToFile` / the assembler's public entry must be referenced
by a test before the gate passes (known gotcha: new public API trips the symmetry-aware dead-methods
gate until a test references it) — Phase 5's harness provides that reference.

### 4.4 Build changes (`buildSystem/build.py` + `build_it_please.sh`)

1. **Embed shell parts as wrapped strings in every build** (D4): after the boot bundle and
   compiler are finalized, wrap their file contents with the same STRING_BLOCK machinery into e.g.
   `js/coffeescript-sources/BootBundle_jsSource.js` (`window.fizzygumBootBundle_source`),
   `…Compiler_jsSource.js`, the three helper texts, **and each part's vendor-payload text**
   (`[REVISED 2026-07-30]` — needed so a saved page can embed a loaded part's vendor JS, §4.3);
   load them in the boot chain alongside the batches (multi-file builds only — the single-file
   page embeds their content directly AND the wrapped strings, since a saved page must be able to
   save itself again). Cost: **~235 KB** per build tree (+~19 KB per 3D-carrying part). NOTE the
   wrapped boot-bundle string must be generated AFTER the bundle is assembled+minified (ordering
   inside `build_it_please.sh` — the NATIVE bundle is finalized at `:898`, after the one terser
   pass at `:827`; the SW-flavour assembly at `:871-880` is irrelevant here).
2. **`--singleFile` flag**: after the normal build, boot the built page headless and invoke the
   assembler, writing `../Fizzygum-builds/latest/fizzygum-single.html` (D7). Precedent and
   mechanics: `../Fizzygum-tests/scripts/generate-pre-compiled-headless.js` (headless puppeteer +
   `?generatePreCompiled`, `page.evaluate` the string out, write it from Node) — build arc 2
   already did exactly this shape, so model the new script on it and put it in the same
   directory (Node resolves `require('puppeteer')` from the SCRIPT's directory).
   Prerequisite: Puppeteer from `../Fizzygum-tests` (`npm i` there), same as `build_and_smoke.sh`.
3. **Exotic-char guard**: `[REVISED 2026-07-30]` the guard half-exists — `build.py:368-370`
   already FAILS LOUDLY on `＂ ⧹ ⤶` in any source. This plan extends the table AND the guard with
   `＜` (fourth character), in the same place.

### 4.5 Escaping spec (the load-bearing correctness section)

Two independent payloads, two escapes:

| Payload | Escape | Decode | Why |
|---|---|---|---|
| Code payload (every `SourceVault.store` block, boot-bundle/compiler/helper strings) | build.py STRING_BLOCK substitution, **extended**: `"`→`＂`, `\`→`⧹`, `\n`→`⤶`, **NEW `<`→`＜`** (fullwidth less-than U+FF1C) | **`SourceVault.store`'s decode chain gains `.replace(/＜/g,"<")`** (`src/boot/source-vault.coffee`) — arc 4 moved the decode out of the emitted line and into the vault, so this extension is a ONE-LINE change in ONE place instead of a change to the emitted template | a literal `</script` (or `<!--`) in ANY source comment/string would truncate the inline block and corrupt the whole file. Today this cannot bite (sources ship as external `.js`); inline it is fatal. Escaping ALL `<` kills `</script>` AND `<!--` parser edge cases at once. |
| Snapshot JSON block | `json.replace(/</g,"\\u003C")` — TW-exact | none needed — `JSON.parse` restores it | `<` only occurs inside JSON strings ⇒ lossless; `</script>` can never appear as literal bytes. |

Rules:
- The runtime (CoffeeScript) encoder in the assembler and the build-time (Python) encoder never
  process the same string — each output is decoded by the same single `SourceVault.store` chain —
  but BOTH must implement the same 4-char ENCODE table, and both rely on the §4.4(3) guard.
  ⚠ Since arc 4 there is exactly ONE decoder (the vault). Extending the table means editing the
  Python encoder, the CoffeeScript encoder, and that one decoder — no longer N emitted chains.
- `<meta charset="UTF-8">` must be the FIRST element in `<head>`: the substitution characters are
  non-ASCII, and a saved file re-opened with a mis-sniffed encoding corrupts every source string.
  (Both Decker and Feather Wiki hard-code exactly this, for exactly this reason.)
  ⚠ `[REVISED 2026-07-30]` `src/index.html` still declares NO charset, but is NOT naked: both it
  and every built page start with a **UTF-8 BOM** (`ef bb bf`), which is what carries the encoding
  today. The single-file shell should use the explicit `<meta charset>` (belt) and MAY also emit
  the BOM (suspenders) — the assembler must decide once and the quine test then keeps it stable;
  add the meta to `src/index.html` too (Phase 1) so the two shells agree.
- User text content typed into widgets lives in the JSON snapshot (JSON escaping), NOT under the
  exotic-char substitution — a user typing `⤶` or `</script>` in a note is handled correctly by
  construction. Only *source code* rides the substitution, and the §4.4(3) guard polices sources.

### 4.6 Size budget (v1)

`[REVISED 2026-07-30 — measured on the current dev tree]`

| Component | Bytes |
|---|---:|
| NATIVE boot bundle (no SWCanvas 2D, no det-trig — D1) | 18.4 KB |
| CoffeeScript compiler (minimal 2.0.3-based build) | 208.6 KB |
| Sources: 21 per-part batches + Class/Mixin (re-encoded) | ~2.78 MB (all parts; core+meta-tools subset less) |
| Boot helpers ×3 | ~7.8 KB |
| Parts manifest + presets + spinner data-URI + shell | ~3 KB |
| Vendor payloads of embedded 3D parts (only if loaded) | +18.9 KB each |
| **Code total** | **~3.0 MB** (all parts) |
| Snapshot | tens of KB (default desktop) → grows with content; dominated by base64 `$Canvas`/`$Image` records |

Reference points: empty TiddlyWiki 2.55 MB; community comfort zone <10–20 MB ⇒ ~5× headroom for
world content before entering "large wiki" territory.

---

## 5. Phases

Run each phase's gates green before continuing (standard arc discipline; `fg gauntlet` is the
13-leg behavioural gate — but remember it never builds a production tree, so packaging-visible
changes ALSO need `fg homepage`, the only standing gate that boots one and round-trips a snapshot
on it).

### Phase 0 — spikes (NO repo changes; scratch scripts + the EXISTING build only)

- **S1 — FizzyPaint round-trip (UNVERIFIED, must-know):** `$Canvas` own-props serialize as base64
  PNG (`Serializer.coffee:287-294`), but `backBuffer`-family fields are transients
  (`Widget.coffee:37-49`), and paint content may live in a buffer-style field
  (`StretchableCanvasWdgt.coffee:115-129`, `@behindTheScenesBackBufferContext`). Headless: paint
  strokes → `serializeWorldSnapshot` → fresh page → `loadWorldSnapshot` → pixel-compare.
  Outcome A: survives ⇒ note and move on. Outcome B: lost ⇒ file a serialization fix as a
  prerequisite work item (likely: the painted canvas must be an own serialized prop, not a
  transient) — decide with owner whether it gates v1 or ships as a known limitation.
- **S2 — hand-built prototype:** a scratch node script that concatenates the CURRENT build's
  artifacts (boot bundle, stub, compiler, Class/Mixin, helpers, batches) into one HTML per §4.1
  (manually `<`-escaping for the prototype), plus a snapshot captured from a live session; open it
  headless; assert clean boot + pixel-match. Proves block ordering, charset, and escaping BEFORE
  any source is touched. (S2 needs a temporary hack for the §4.2 boot branches — e.g. a small
  patch script over the concatenated bundle text — acceptable in a scratch spike.)

### Phase 1 — escaping + charset groundwork (`build.py`, `src/index.html`)

- Extend the STRING_BLOCK encode (`build.py:372-374`), the one decoder
  (`source-vault.coffee:45-48`) and the existing guard (`build.py:368-370`) with `＜`; add
  `<meta charset="UTF-8">` to `src/index.html` (currently BOM-only — §4.5).
- Runtime behavior must be identical (decode restores bytes). Gate: `fg gauntlet` + `fg homepage`.

### Phase 2 — boot branches (`src/boot/globalFunctions.coffee`)

- `[REVISED 2026-07-30]` The central `loadJSFilePromise` short-circuit (§4.2.1 — replaces the old
  per-site `maybeLoad` plan and the per-site tests guard), the snapshot-block-or-createDesktop
  seam at `:470-471` (with `skipConfirm: true`), spinner timing. Verify: the
  loadWorldSnapshot-on-empty-world expectation (§4.2.2), `testsManifest`-undefined tolerance, and
  that the `*TestSupport.installOnto` grafts (`:429-433`) are existence-guarded.
- Testable NOW via the S2 prototype re-generated from this build. Gate: gauntlet (multi-file
  behavior must be byte-identical — every branch is `FIZZYGUM_SINGLE_FILE`-gated) + S2 boots.

### Phase 3 — the assembler + menu item

- `src/serialization/SingleFilePageAssembler.coffee` (§4.3), `WorldWdgt::saveWorldAsSinglePageToFile`,
  menu wiring. Needs Phase 4's embedded strings to work from a multi-file page — until then it can
  be exercised from an S2-style page (where the DOM fallback isn't needed since the wrapped strings
  are embedded there by hand). Doc rule: fold the durable format spec into
  `docs/architecture/serialization-duplication-reference.md` (new §: single-file page) — CLAUDE.md stays
  link-only.

### Phase 4 — build integration

- §4.4(1) embedded shell-part strings in every build; §4.4(2) `--singleFile` headless generation
  (new `buildSystem/generate-single-file-via-browser.sh` + hook in `build_it_please.sh`); consider
  an `fg singlefile` wrapper. ⚠ Use `git -C` (not `cd` chains) around any repo-crossing commands —
  the guard hook blocks wrong-cwd chains.

### Phase 5 — verification gate (tests repo)

- New headless node-script leg (modeled on `scripts/serialization-roundtrip-headless.js`; NOT a
  macro — same classification rationale as the capstone catch-test: needs `page.evaluate`,
  cross-page orchestration, file I/O):
  1. **Gen-0**: `--singleFile` artifact boots clean (console-error-free, native canvas) and
     pixel-matches the multi-file default desktop (clock masked, as in the existing harness).
  2. **Round-trip**: populate a world (window + moved icon + recolor + wallpaper + a source edit —
     the proven roundtrip recipe) → save single page (invoke the assembler via `page.evaluate`,
     write the string from node) → open gen-1 → pixel-identical.
  3. **Quine stability**: gen-1 → gen-2; assert the CODE payload is byte-identical across
     generations (snapshot section may differ only if `savedAt`/user content differs; omit
     `savedAt` in the harness).
  4. dpr 1 + dpr 2; wire into `fg gauntlet` as a new leg.
- This harness is also what satisfies the dead-method gate for the new public API (§4.3 ⚠).

### Phase 6 (v2, owner-gated) — FSA in-place save (§8.1)

---

## 6. Risks & mitigations

| # | Risk | Mitigation |
|---|---|---|
| R1 | `</script` truncation via source comments/strings | §4.5 `＜` substitution (code) + `<` (JSON); §4.4(3) build guard |
| R2 | Charset mis-sniffing corrupts substitution chars | `<meta charset="UTF-8">` first in head, both shells (Phase 1) |
| R3 | FizzyPaint pixels may be serialization-transient | Phase 0 S1 spike BEFORE building anything |
| R4 | Dev-build boot bundle carries `BUILDFLAG_LOAD_TESTS=true` into saved pages → 404 loads | `[REVISED 2026-07-30]` dissolved structurally: the central `loadJSFilePromise` short-circuit (§4.2.1) makes ALL loads inert; residual check = `testsManifest` stays undefined and `runPostBootActionsOnce` tolerates it (`Automator?`-guarded) |
| R5 | DOM snapshot temptation (outerHTML) captures runtime mutations | template reassembly only; assembler reads NOTHING from the DOM |
| R6 | `savedAt`/`build` envelope fields break generation-comparison | harness omits `savedAt`; compare code payload separately from snapshot |
| R7 | Stale-copy UX (download model): user edits gen-N after saving, reopens gen-N-1 | inherent to the download model (TW lives with it); v2 FSA in-place save is the real fix; consider a `beforeunload` dirty-guard as a small independent follow-up |
| R8 | Assembler encode drifts from build.py encode | same 4-char table, §4.4(3) guard, Phase 5 quine-stability test catches drift |
| R9 | New public API trips dead-method gate | Phase 5 harness references it |
| R10 | iOS Safari blob quirks | existing `FileSaving` data:-fallback covers; iOS is not a target |

## 7. Open items (banked, not v1)

- **7.1** Precompiled single file (instant boot; +~2 MB and a second code representation) — D2 later
  option. **`[ARC 5, 2026-07-30]` The build side of this is now DATA, not work:** a profile is
  `{parts, form, sources, entries}` (`buildSystem/profiles/*.json`, read by
  `buildSystem/buildProfile.py`), so "precompiled" is `form: "precompiled"` and the "+~2 MB second
  representation" this line worries about is `sources`, which now has three settings —
  `background` (ship it and load it behind the world), `lazy` (ship it, load it only when something
  reflects; what `homepage` uses) and `none` (do not ship it at all; what `lean` uses, 10 files /
  1.3 MB). ⇒ a precompiled single file that carries NO second representation is
  `{form: "precompiled", sources: "none"}` and needs no new build mechanism, only an assembler that
  reads the profile it is packaging. See `docs/architecture/build-and-packaging.md`.
- **7.2** Strip SWCanvas/SW3D from a single-file boot-bundle variant (−285 KB) — D1 later option.
  **`[ARC 5]`** Also data now: the SW bundle and the ~90 MB of font assets are derived from whether
  any shipped `entries` page renders through SWCanvas, so a native-only single file is
  `entries: ["index.html"]`.
- **7.3** "Bake" in-system source edits into the payload (vs. replay-deltas) — deliberate future feature.
- **7.4** `beforeunload` dirty guard (R7).
- **7.5** Snapshot-block compression (LZ-string-style) — unnecessary at current sizes.

## 8. v2 — in-place save (File System Access API, Chromium-only)

Feature-detect `window.showSaveFilePicker`; on first "save in place…" (user gesture) show the
picker, keep the handle for the session, `createWritable → write(blob) → close()` on subsequent
saves; Chrome 122+ "Allow on every visit" makes re-grants rare. Verified working over `file://`
(§3.4 — the "not a secure context" folklore is refuted from Chromium source). Fallback remains the
download saver. Caveats: Safari/Firefox never (hide the item), Brave disables FSA, persisted
handles in IndexedDB on `file://` share one origin across all local pages (prefer session-scoped
handle in v1 of v2).

## 9. Provenance

Authored 2026-07-10 from: two Explore studies of this repo + the build output; six sourced web
studies (TW5 store/escaping/saver internals quoted from Jermolene/TiddlyWiki5 master; Decker from
JohnEarnest/Decker `js/decker.js` + `docs/format.md`; Feather Wiki from Alamantus/FeatherWiki;
platform matrix from WHATWG/MDN/Chromium source/caniuse/vendor standards-positions; FSA-on-file://
verdict from Chromium `is_potentially_trustworthy.cc` + picker-path sources + TW community
first-hand reports). Full reports lived in the session scratchpad (ephemeral); every load-bearing
fact is embedded above.
