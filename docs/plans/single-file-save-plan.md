# Single-file save — the whole app (code + world) in ONE self-contained `.html`

**STATUS: AUTHORED 2026-07-10 — research complete, design approved by owner, NO code written yet.**
File/line references were verified against the Fizzygum working tree on 2026-07-10 (head ~`805490e6`,
while the affine-transforms arc was still moving); anchor on the quoted **method names** first and
treat line numbers as hints if they have drifted.

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
| D1 | Rendering backends in the single file | **Native HTML5-Canvas only.** BitmapText font assets (90 MB, `?sw=1`-only) are NEVER included. The SWCanvas *engine* (~285 KB, already inside the boot bundle) is **kept but hard-disabled** — `?sw=1` is ignored in single-file pages (stripping it would need a boot-bundle build variant; not worth it in v1). |
| D2 | Code representation | **Compile-at-boot v1** (source strings + in-browser compiler, exactly like today's dev build; a few seconds behind the spinner). A `--homepage`-style precompiled image inside the single file is a **later option**, not v1. |
| D3 | Source code in the file | **KEEP the sources.** They are only ~2.5 MB, they are what makes in-system live editing work in the saved artifact, and they are already in memory for free. (Owner had offered to drop them; research showed no need.) |
| D4 | Where "save as single page" is available | **Every build.** The build embeds the boot-bundle and compiler texts as wrapped strings (~575 KB extra, §4.4), so the menu item works from the normal dev build too, not just from single-file pages. |
| D5 | Save mechanism v1 | **Blob + `<a download>`** via the existing `FileSaving.saveStringAsFile` (universal, works over `file://` in all engines, Safari `data:` fallback already implemented). |
| D6 | In-place overwrite (File System Access API) | **v2, owner-gated, Chromium-only** (§8.1). Verified to work even over `file://` — see §3.4. |
| D7 | Assembly implementation | **ONE implementation, in CoffeeScript, in-world.** The build produces the artifact by booting the page headless and invoking the same in-world assembler (precedent: `?generatePreCompiled` / `buildSystem/generate-pre-compiled-file-via-browser.sh`). The shipped file is *generation 0 of the quine* — produced by the very code path every later save uses. No parallel Python assembler. |
| D8 | Snapshot embedding format | **Inert JSON store block**, TiddlyWiki 5.2 style: `<script type="application/json" id="fizzygum-world-snapshot">` with `<` → `<` escaping; parsed with `JSON.parse` at boot (inert during HTML parse, cheaper than a JS literal, and structurally cannot execute). |
| D9 | Base code vs in-system edits | **Base code payload stays pristine**; user's in-system class/instance source edits ride inside the snapshot as `world.sourceEdits` deltas and are replayed by the proven `SourceEditsRegistry` path at load. ("Baking" edits into the payload = possible later feature, out of scope.) |
| D10 | Splash | Drop the fake-desktop splash PNG in single-file pages (it shows the *default* desktop, wrong before a custom world); keep the small spinner, inlined as a `data:` URI (~800 B). |

Non-goals (v1): tests inside the artifact; SWCanvas rendering; videos; precompiled startup; FSA.

---

## 2. Why this is feasible — codebase facts (verified 2026-07-10)

The built page is *already* 99% of a single-file app:

- **`Fizzygum-builds/latest/index.html` is tiny**: one `<canvas id="world">`, two `<img>`s
  (splash + spinner), an empty positioning div, ONE `<script src="js/fizzygum-boot-min.js">`
  (316,251 B — of which ~285 KB is SWCanvas+SW3D+det-trig, ~15 KB actual boot JS), and an inline
  `window.onload → boot()`. **No stylesheet, no fonts, no favicon, no charset meta** (see risk R2).
- **Nothing anywhere uses `fetch`/XHR.** All runtime loading is `<script>` injection
  (`loadJSFilePromise`, `src/boot/globalFunctions.coffee:42-64`) or `new Image()` — because the
  page must run over `file://`. Inlining is therefore a *natural fit*, not a retrofit.
- **Total native-canvas no-tests payload ≈ 3.07 MB**: boot bundle 316 KB + CoffeeScript compiler
  (`js/libs/fizzygum-coffeescript-min.js`, 208,604 B) + source batches (`sources_batch_0..13.js`,
  2,489,628 B) + `Class_coffeSource.js`/`Mixin_coffeSource.js` (28,621 B) + three small boot
  helpers (~8 KB) + `pre-compiled.js` stub (257 B).
- **The booted page retains everything needed to regenerate its own code, in memory:**
  - every class/mixin source as `window.<Name>_coffeSource` (never deleted; enumerated by
    suffix-scanning `Object.keys(window)` — `src/boot/dependencies-finding.coffee:64-66` and
    `src/meta/SourceVault.coffee:49-57`);
  - the `CoffeeScript` compiler global (kept resident — the paint tool needs it);
  - bonus: `window.JSSourcesContainer.content` accumulates every class's compiled JS
    (`src/meta/Class.coffee:412`, `Mixin.coffee:112`) — this is what `?generatePreCompiled`
    zips up (`src/boot/loading-and-compiling-coffeescript-sources.coffee:151-155`), **proving
    in-browser self-reconstruction already works.**
- **Load order is computed in-browser at boot** (`findLoadOrder()`, regex-scan + topological DFS,
  `dependencies-finding.coffee`) — no build-time manifest to carry.
- **The source-string wrapper** (build.py:273):
  `window.%s = "%s".replace(/＂/g,"\"").replace(/⧹/g,"\\").replace(/⤶/g,"\n");`
  — i.e. `"`→`＂`, `\`→`⧹`, newline→`⤶`, undone at load. (JSON was rejected historically because
  `file://` blocks JSON fetch — build.py:266-272.)
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
  - `WorldWdgt::loadWorldSnapshot(envelopeOrString, opts)` (`WorldWdgt.coffee:2256`) is the
    restore orchestrator: product-safe teardown (`_teardownForSnapshotLoadNoSettle`, :2335 — built
    from primitives that SHIP in `--homepage`, unlike `resetWorld`), id-counter restore, class-edit
    replay, `Deserializer.deserialize`, app-slot/bin/shelf re-bind, one-settle child attach,
    colour/wallpaper, repaint + **`result.whenReady`** second repaint once async `$Image`/`$Canvas`
    data-URLs have decoded (:2326). **It `window.confirm`s unless `opts.skipConfirm`** (:2261-2263)
    — the boot path must pass `skipConfirm: true`.
  - Round-trip is PROVEN pixel-identical cross-session at dpr 1 and 2
    (`../Fizzygum-tests/scripts/serialization-roundtrip-headless.js`), including source edits.
  - `FileSaving.saveStringAsFile(string, suggestedName, mimeType = "application/json")`
    (`src/serialization/FileSaving.coffee:12`) already does Blob → objectURL → `<a download>` →
    deferred revoke, with a Safari `data:`-URL fallback. Ships in all builds.
- **The boot seam** for "boot into a snapshot" is exactly
  `src/boot/globalFunctions.coffee:427-428`:
  `if world.isIndexPage` → `world.createDesktop()` inside `createWorldAndStartStepping.startWorld`.
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
  <script> window.FIZZYGUM_SINGLE_FILE = true; </script>
  <script> /* boot bundle text (det-trig + SWCanvas + SW3D + boot JS) */ </script>
  <script> window.preCompiled = false;  /* the pre-compiled.js stub, inlined */ </script>
  <script> /* CoffeeScript compiler 2.0.3 */ </script>
  <script> /* Class_coffeSource + Mixin_coffeSource + the 3 boot helpers
              (loading-and-compiling…, logging-div, dependencies-finding) */ </script>
  <script> /* source batches — window.<Name>_coffeSource blocks, re-encoded (§4.5) */ </script>
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

Two small, surgical branches on `window.FIZZYGUM_SINGLE_FILE`:

1. **Skip the script-injection chain.** Minimal-diff shape: one helper
   `maybeLoad = (path) -> if window.FIZZYGUM_SINGLE_FILE then Promise.resolve() else loadJSFilePromise path`
   and substitute it through the boot chain (`globalFunctions.coffee:275-350`). The rest of the
   chain (compile Mixin/Class via `compileFGCode` at :312-313, then
   `storeSourcesAndPotentiallyCompileThemAndExecuteThem false` at :338, then
   `createWorldAndStartStepping()` at :346) runs **unchanged** — everything it needs is already
   defined by the inline blocks.
   ⚠ The test-assets block at :283-287 must be skipped in single-file mode **even though the
   embedded boot bundle may carry `BUILDFLAG_LOAD_TESTS = true`** (it is the dev build's bundle;
   guard it with `and not window.FIZZYGUM_SINGLE_FILE`) — otherwise the saved page 404s on
   `js/tests/…`. `if Automator?` code paths are naturally inert (Automator classes never load).
2. **Boot into the snapshot instead of the default desktop.** In `startWorld`
   (`globalFunctions.coffee:427-428`), replace
   `if world.isIndexPage then world.createDesktop()` with: if a `#fizzygum-world-snapshot` block
   exists → parse it and `world.loadWorldSnapshot envelope, {skipConfirm: true}`; else
   `world.createDesktop()` as today.
   - `loadWorldSnapshot` on the *empty* just-constructed world: its teardown
     (`fullDestroyChildren` + `binWdgt?.empty()` + `shelfWdgt?.empty()` + slot nils) is safe on an empty world —
     `binWdgt` / `shelfWdgt` exist by then (created at `globalFunctions.coffee:361-362`, before this seam).
     **Verify this explicitly in Phase 2** (it is expected-safe, not yet demonstrated).
   - Spinner UX: `removeSpinnerAndFakeDesktop()` currently runs before this seam (:420); in
     single-file mode prefer removing the spinner after `result.whenReady` resolves (images/canvas
     data-URLs decode async) — cosmetic, decide at implementation.
3. **Hard-disable SWCanvas routing** in single-file mode: force
   `window.FIZZYGUM_USE_SWCANVAS = false` regardless of `?sw=1` (no BitmapText assets exist in the
   file; placeholder-box text would be a broken half-mode).

### 4.3 The assembler — `src/serialization/SingleFilePageAssembler.coffee` (new class)

One class, one job: return the full HTML string of §4.1 from live memory. All parts are canonical,
none read from the DOM:

- **Shell template**: a literal in the class (the single-file shell is intentionally distinct from
  `src/index.html`; it is THE canonical shell for saved pages).
- **Boot bundle + compiler texts**: from the wrapped strings the build embeds (§4.4) —
  `window.fizzygumBootBundle_source`, `window.coffeeScriptCompiler_source` (decoded the same way
  `_coffeSource` strings are).
- **Boot helpers** (loading-and-compiling / logging-div / dependencies-finding minified JS): also
  embedded as wrapped strings by the build (§4.4) — they are small (~8 KB total).
- **Source batches**: regenerated from the in-memory registry — enumerate `Object.keys(window)`
  for the `_coffeSource` suffix (same enumeration as `dependencies-finding.coffee:64-66` /
  `SourceVault.coffee:55-57`), re-encode each with the escape spec (§4.5), emit
  `window.<Name>_coffeSource = "…"` blocks. `Class_coffeSource`/`Mixin_coffeSource` are emitted in
  their own earlier block (they must compile before the batches — mirror the boot chain order) and
  deduped out of the batch set.
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
   `…Compiler_jsSource.js`, and the three helper texts; load them in the boot chain alongside the
   batches (multi-file builds only — the single-file page embeds their content directly AND the
   wrapped strings, since a saved page must be able to save itself again).
   Cost: ~575 KB per build tree. NOTE the wrapped boot-bundle string must be generated AFTER the
   bundle is assembled+minified (ordering inside `build_it_please.sh` — bundle assembly is at
   :535-564).
2. **`--singleFile` flag**: after the normal build, boot the built page headless and invoke the
   assembler, writing `../Fizzygum-builds/latest/fizzygum-single.html` (D7). Precedent and
   mechanics: `buildSystem/generate-pre-compiled-file-via-browser.sh` (headless Chrome +
   `?generatePreCompiled`); implement as a sibling script driving a URL param or a
   `page.evaluate`-invoked call, capturing the HTML string (do NOT go through the download path
   headless — evaluate the assembler and write the string from node).
   Prerequisite: Puppeteer from `../Fizzygum-tests` (`npm i` there), same as `build_and_smoke.sh`.
3. **Exotic-char guard**: build.py must FAIL LOUDLY if any source file contains any of the four
   substitution characters `＂ ⧹ ⤶ ＜` (both encoders assume they never occur in sources; today
   this is an unchecked assumption).

### 4.5 Escaping spec (the load-bearing correctness section)

Two independent payloads, two escapes:

| Payload | Escape | Decode | Why |
|---|---|---|---|
| Code payload (every `_coffeSource` block, boot-bundle/compiler/helper strings) | build.py STRING_BLOCK substitution, **extended**: `"`→`＂`, `\`→`⧹`, `\n`→`⤶`, **NEW `<`→`＜`** (fullwidth less-than U+FF1C) | the emitted `.replace` chain gains `.replace(/＜/g,"<")` | a literal `</script` (or `<!--`) in ANY source comment/string would truncate the inline block and corrupt the whole file. Today this cannot bite (sources ship as external `.js`); inline it is fatal. Escaping ALL `<` kills `</script>` AND `<!--` parser edge cases at once. |
| Snapshot JSON block | `json.replace(/</g,"\\u003C")` — TW-exact | none needed — `JSON.parse` restores it | `<` only occurs inside JSON strings ⇒ lossless; `</script>` can never appear as literal bytes. |

Rules:
- The runtime (CoffeeScript) encoder in the assembler and the build-time (Python) encoder never
  process the same string — each output is decoded only by its own emitted chain — but BOTH must
  implement the same 4-char table, and both rely on the §4.4(3) guard.
- `<meta charset="UTF-8">` must be the FIRST element in `<head>`: the substitution characters are
  non-ASCII, and a saved file re-opened with a mis-sniffed encoding corrupts every source string.
  (Both Decker and Feather Wiki hard-code exactly this, for exactly this reason.)
  ⚠ `src/index.html` itself currently declares NO charset — add it there too (Phase 1); external
  `.js` files made this survivable until now.
- User text content typed into widgets lives in the JSON snapshot (JSON escaping), NOT under the
  exotic-char substitution — a user typing `⤶` or `</script>` in a note is handled correctly by
  construction. Only *source code* rides the substitution, and the §4.4(3) guard polices sources.

### 4.6 Size budget (v1)

| Component | Bytes |
|---|---:|
| Boot bundle (incl. SWCanvas/SW3D, kept per D1) | 316 KB |
| CoffeeScript compiler | 257 KB |
| Source batches + Class/Mixin (re-encoded) | ~2.52 MB |
| Boot helpers | ~8 KB |
| Spinner data-URI + shell | ~2 KB |
| **Code total** | **~3.15 MB** |
| Snapshot | tens of KB (default desktop) → grows with content; dominated by base64 `$Canvas`/`$Image` records |

Reference points: empty TiddlyWiki 2.55 MB; community comfort zone <10–20 MB ⇒ ~5× headroom for
world content before entering "large wiki" territory.

---

## 5. Phases

Run each phase's gates green before continuing (standard arc discipline; `fg gauntlet` = build +
suite dpr1 + dpr2 + webkit + apps legs).

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

- Extend STRING_BLOCK encode/decode with `＜`; add the §4.4(3) exotic-char guard; add
  `<meta charset="UTF-8">` to `src/index.html`.
- Runtime behavior must be identical (decode restores bytes). Gate: `fg gauntlet` + homepage.

### Phase 2 — boot branches (`src/boot/globalFunctions.coffee`)

- `maybeLoad` substitution, the `BUILDFLAG_LOAD_TESTS and not FIZZYGUM_SINGLE_FILE` guard, the
  snapshot-block-or-createDesktop seam (with `skipConfirm: true`), SWCanvas hard-disable, spinner
  timing. Verify the loadWorldSnapshot-on-empty-world expectation (§4.2.2).
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
| R4 | Dev-build boot bundle carries `BUILDFLAG_LOAD_TESTS=true` into saved pages → 404 loads | explicit `not FIZZYGUM_SINGLE_FILE` guard (§4.2.1) |
| R5 | DOM snapshot temptation (outerHTML) captures runtime mutations | template reassembly only; assembler reads NOTHING from the DOM |
| R6 | `savedAt`/`build` envelope fields break generation-comparison | harness omits `savedAt`; compare code payload separately from snapshot |
| R7 | Stale-copy UX (download model): user edits gen-N after saving, reopens gen-N-1 | inherent to the download model (TW lives with it); v2 FSA in-place save is the real fix; consider a `beforeunload` dirty-guard as a small independent follow-up |
| R8 | Assembler encode drifts from build.py encode | same 4-char table, §4.4(3) guard, Phase 5 quine-stability test catches drift |
| R9 | New public API trips dead-method gate | Phase 5 harness references it |
| R10 | iOS Safari blob quirks | existing `FileSaving` data:-fallback covers; iOS is not a target |

## 7. Open items (banked, not v1)

- **7.1** Precompiled single file (instant boot; +~2 MB and a second code representation) — D2 later option.
- **7.2** Strip SWCanvas/SW3D from a single-file boot-bundle variant (−285 KB) — D1 later option.
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
