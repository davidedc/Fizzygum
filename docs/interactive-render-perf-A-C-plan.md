# Interactive-render perf plan — A (SWCanvas full-cover canvas-wide fast path) + C (static-face back-buffering)

**Status**: Item **A LANDED 2026-07-09** (SWCanvas `60ba1a3..cf5eea8`, Fizzygum pin
bumped to `cf5eea8`). Item **C1 LANDED 2026-07-09** (§3.1 landed box — 6 refs recaptured,
owner-approved). Item **C2 NOT STARTED** — ⚠ scope it only AFTER the 2026-07-17 owner
direction "headers-as-widgets + cell-owned grid chrome" (spreadsheet follow-on F5) is
decided; F5 supersedes C2's shape — see §3.2. Self-contained / cold-runnable.
**Provenance**: the 2026-07-08 interactive-profiling investigation (see
`docs/profiling/prof-interactive.js` + `docs/profiling/README.md`; memory
`fizzygum-runtime-backend-swcanvas`). Follows the S3/W1/W2 wins in
`docs/runtime-performance-optimization-plan.md` (§8 ledger).

## 0. Orientation (read first)

- Fizzygum production world `index.html` uses the **native** canvas by default; **the owner
  runs `?sw=1` (SWCanvas)**, so SWCanvas runtime cost IS the owner's felt experience. Profile
  runtime with `?sw=1` (the interactive harness needs `--sw`).
- **SWCanvas is a SEPARATE repo** at `/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas`
  (branch `main`). Fizzygum pins it via `vendor/swcanvas.pin`. Current heads at authoring time:
  **SWCanvas `60ba1a3` (main), Fizzygum `c3140883` (master), pin=`60ba1a3`.**
- **Byte-identical gate for SWCanvas changes**: `./fg gauntlet` from the umbrella root
  (`/Users/davidedellacasa/code/Fizzygum-all`) — build + dpr1/dpr2/webkit full suites (196
  tests at authoring, 250 as of 2026-07-17 — counts grow) + apps + paint + gates (which since
  2026-07-17 include `fg revisits`, the EMPTY settle-re-visit baseline, and `fg census`,
  arrange idempotence) — MUST stay green with **zero reference churn**. Plus SWCanvas's own 218
  visual tests (`npm test` in the SWCanvas repo). NEVER recapture references for a perf item.
- **Re-vendor flow** (SWCanvas→Fizzygum): edit SWCanvas `src/` → `npm run build:prod` +
  `npm test` (218) → commit+push SWCanvas `main` → in Fizzygum
  `./scripts/vendor-swcanvas.sh --source "/Users/davidedellacasa/code/Unified SW Canvas/SWCanvas"`
  (bumps `vendor/swcanvas.pin`) → `./fg gauntlet` + `./fg homepage`. For a THROWAWAY
  pre-commit gauntlet add `--no-pin-update`. Push SWCanvas BEFORE the Fizzygum pin commit.
- **Owner prefs**: NEVER commit/push without explicit approval (present a summary + proposed
  `git commit -F <file>` messages — backticks in `-m` corrupt — and wait). Run straight
  through verifying; ONE end-of-arc review. Evidence before conclusions. When staging,
  EXCLUDE pre-existing not-mine files (SWCanvas `plans/clipping-optimization.md` + `AGENTS.md`;
  in Fizzygum check `git status` first — e.g. the in-flight uncommitted §3-F edits to
  `docs/dataflow-*`/`docs/specs/dataflow-*` as of 2026-07-17).

## 1. The measured problem

On a busy SWCanvas desktop (21 windows), dragging a window costs **~88 ms/frame median**
(~11 fps; p95 ~200 ms) — measured by `prof-interactive.js --sw`. The wallpaper is NO LONGER
the issue (W1/W2 made dots ≈ plain, +5.9 ms). A shadow-build V8 profile of the busy drag
(read %, not ms — shadow inflates ~3×) shows the cost spread across the rasterizer, with
one standout structural cluster:

| cost (self-time %) | what |
|---|---|
| `Rasterizer._performCanvasWideCompositing` 10.9% + `SourceMask.setPixel` 8.3% | **canvas-wide compositing** (~19% combined) |
| `_fillPolygonsDirect` + `_fillAxisAlignedRect` + `fill_AA_Opaq` + `_fillPixelSpan` | ~35% raw fill rasterization (spread) |
| `_drawImageInternal` 8.9% | back-buffer blits |
| `blendPixel` + `_evaluatePaintSource` ~10% | general per-pixel paint |

**Root-cause of the ~19% canvas-wide cluster** (instrumented with `--sw --cwc`): **12,807
`source-in` composites in a 100-frame drag (128/frame)**, all triggered by `fillRect` under
`globalCompositeOperation='source-in'` through the shadow pipeline. Fizzygum sets NO composite
op itself — the `source-in` comes from the **vendored BitmapText engine's colored-glyph
tinting**: `#createColoredGlyph` (SWCanvas dist `swcanvas.js:5677`, batched at `:5647`) draws a
glyph's alpha to a scratch canvas then `globalCompositeOperation='source-in'; fillRect(0,0,fullScratch)`
to stamp the text colour through it. (Source: `vendor/bitmaptext/runtime/BitmapText.js` in the
SWCanvas repo; concatenated into the dist.)

Instrumented with `--sw --text`: regular labels back-buffer FINE — `TextWdgt` back-buffer =
**29,887 hits / 357 rebuilds** (99.9% reused). The re-rendered colored text is **the SpreadsheetWdgt
row-number headers "1".."12"** (`src/spreadsheet/SpreadsheetWdgt.coffee:217`
`aContext.fillText ("" + (row + 1)), 4, y`) + column letters (`:212`) + `CellWdgt` scalar text —
drawn DIRECTLY in the sheet's paint, NOT back-buffered, so every repaint over the open sheet
re-renders them. The AnalogClockWdgt on the desktop is a SEPARATE instance of the same class of
waste: `AnalogClockWdgt.paintIntoAreaOrBlitFromBackBuffer` (`src/apps/AnalogClockWdgt.coffee:60`)
→ `renderingHelper` (`:119`) re-draws the STATIC face (12 hour ticks `:143`, 60 minute ticks
`:156`, outer arc `:178`) with stroke ops on EVERY repaint — only the hands (`:170-172`) move.

So there are two independent, complementary fixes:

- **A — make the tint cheap (SWCanvas, broad, byte-identical).** A full-cover `source-in`
  fillRect can skip the two-pass source-mask machinery. Speeds EVERY colored-glyph tint (and
  any full-cover canvas-wide op) everywhere, forever. Symptom-level but wide and low-risk.
- **C — stop re-rendering static content (Fizzygum, targeted).** Widgets that animate or are
  repainted often but redraw a STATIC sub-part every time should back-buffer that sub-part.
  Two concrete instances: C1 = AnalogClockWdgt static face; C2 = SpreadsheetWdgt static grid +
  headers. Root-cause-level; matches the framework's existing back-buffer design (BackBufferMixin,
  `world.cacheForImmutableBackBuffers`).

Do A first (cheap, broad, byte-identical). C is a larger, higher-ceiling follow-up.

---

## 2. Item A — full-cover canvas-wide composite fast path (SWCanvas)

> **✅ LANDED 2026-07-09** — SWCanvas `cf5eea8` (`perf(rasterizer): full-cover
> canvas-wide composite fast path`), Fizzygum pin bumped `60ba1a3→cf5eea8`.
> `_fillRectInternal` detects the safe case (no clip, axis-aligned transform, device
> rect ⊇ `[0,W]×[0,H]`) and runs a single `blendPixel` pass (`_fillFullCoverCanvasWide`);
> the SourceMask is now lazily allocated (`_ensureSourceMask`) so the fast path allocates
> nothing. Byte-identical: SWCanvas **218/218** + a 36-scene old-vs-new A/B (every op ×
> full-cover/oversized/scaled-cover + gradient + back-to-back tints fire the fast path;
> partial / scaled-miss-corner / rect-clip / rotated / `fill(path)` / source-over fall
> back — all identical hashes); full `fg gauntlet` (dpr1/dpr2/webkit 196/196 + apps +
> paint + gates) **and** `fg homepage` green, **zero reference churn** (built
> `js/fizzygum-boot-min.js` confirmed to ship the fast path). Tint micro-bench
> **1.55–1.71× faster**; busy-drag re-measure (`--sw --cwc`) shows canvas-wide
> compositing calls **12,807 → 0**. See §8 ledger in
> `docs/runtime-performance-optimization-plan.md`. **No tests-repo change.**

### 2.1 Current mechanism (why it's wasteful)

A canvas-wide composite op (`CANVAS_WIDE_COMPOSITE_OPS = {'destination-atop','destination-in',
'source-in','source-out','copy'}`, `src/core/Rasterizer.js:11`) is handled in TWO passes
(`Rasterizer._fillInternal`, `src/core/Rasterizer.js:417`, canvas-wide branch at `:425`):

1. **Pass 1 — build the SourceMask.** `PolygonFiller.fillPolygons(..., sourceMask, ...)` walks
   the fill and records coverage into a fresh full-surface `SourceMask` via `SourceMask.setPixel`
   (in `_fillPixelSpan`: `if (sourceMask) { sourceMask.setPixel(x,y,true); continue; }`) — it
   does NOT draw to the surface, only records coverage. (Allocation + per-pixel writes.)
2. **Pass 2 — composite.** `_performCanvasWideCompositing` (`:324`) gets
   `bounds = sourceMask.getIterationBounds(clipMask, true)` (**true = canvas-wide ⇒ FULL surface /
   clip bounds**) and, for EVERY pixel in bounds, reads `Sa = sourceMask.getPixel(x,y)`, evaluates
   the paint where covered (else transparent), and `CompositeOperations.blendPixel(composite, ...)`.

The point of "canvas-wide" is that these ops also modify pixels the source does NOT cover
(e.g. `source-in` erases the destination outside the source). That's why they scan the whole
surface. BUT in the dominant case — a `fillRect` covering the ENTIRE surface (the glyph-tint
`fillRect(0,0,fullScratch)`) — the source covers every pixel, so:
- Pass 1's mask is all-`true`; building + reading it is pure waste.
- Pass 2 sees `Sa === 1` for every pixel ⇒ it is exactly `blendPixel(composite, evalPaint, dst)`
  per pixel with no coverage branch.

### 2.2 The fast path (byte-identical)

When a fill under a canvas-wide op **covers the full iteration region** (source coverage is
total over `bounds`), skip the SourceMask entirely and do a SINGLE pass:
```
for each pixel in bounds (respecting clip):
    src = _evaluatePaintSource(paint, x, y, transform, globalAlpha, subPixelOpacity)
    dst = surface pixel
    write CompositeOperations.blendPixel(composite, src.rgba, dst.rgba)
```
This is provably identical to the current two passes because full coverage ⇒ `Sa===1` for
every pixel, which is exactly the `Sa>0` arm of Pass 2 — with no allocation, no Pass-1 build,
and one iteration instead of two.

**Detection (scope to the safe, dominant case):** a `fillRect` whose device rectangle ⊇ the
iteration bounds (full surface, or the full clip region). Concretely, gate in
`Context2D.fillRect` / `Rasterizer._fillRectInternal` (`src/core/Rasterizer.js:172`, the gate
that currently reroutes rect fills to `_fillInternal` when a clip/canvas-wide op is present):
when `composite ∈ CANVAS_WIDE_COMPOSITE_OPS` AND the transformed fill rect covers the surface
(and the clip, if any, is a rect ⊆ the fill), route to the new single-pass composite over the
clip-or-surface bounds instead of the two-pass path. Do NOT attempt full-cover detection for
arbitrary polygons in v1 (harder; not the hot case). Everything not detected as full-cover
keeps the existing two-pass path untouched.

Reuse the S3 `_clipRect` when present to bound the single pass (the tint fillRect on the small
scratch canvas has no clip; but bounding to `_clipRect` when there is one is both correct and
faster). The tint scratch canvas is tiny, so the win here is the eliminated SourceMask
allocation + Pass-1 build + second iteration per glyph, ×128/frame.

### 2.3 Verification (A)

1. In SWCanvas: `npm run build` + `npm test` → **All 218 tests passed** (they include
   `tests/visual/101-130-*` clipping×every-composite-op and canvas-wide-op tests — the
   regression surface for this change).
2. **A/B harness** (recreate in scratchpad, mirror `validate-pattern-ab.js`): render a battery
   of canvas-wide scenes on the OLD dist vs the NEW — full-cover `source-in` fillRect (the tint
   case), plus `destination-in`/`source-out`/`copy`/`destination-atop` full-cover, plus
   PARTIAL-cover (a small fillRect under `source-in`, which must FALL BACK to the two-pass path)
   and under-a-rect-clip — assert identical surface hashes across all. The partial-cover +
   fallback cases prove the detection doesn't misfire.
3. Re-vendor (throwaway `--no-pin-update`) → `./fg gauntlet` + `./fg homepage` green, zero churn.
4. **Re-measure**: `prof-interactive.js --sw --cwc --wallpaper=plain` — the `_performCanvasWideCompositing`
   + `SourceMask.setPixel` share should drop sharply (target: the ~19% cluster roughly halved,
   since the SourceMask build + second pass are gone; the single composite pass remains).
5. Present for commit approval; on go: commit SWCanvas (`src/core/Rasterizer.js` [+ maybe
   `Context2D.js`] + `dist/`, EXCLUDE `plans/`+`AGENTS.md`) → push → re-vendor with pin bump →
   Fizzygum commit (pin + this doc/§8-ledger update) → push. Update memory.

---

## 3. Item C — static-face back-buffering (Fizzygum)

**Principle**: a widget that (a) animates (`@fps>0`, self-`changed()` per tick) OR is frequently
repainted by others dragging over it, AND (b) redraws a STATIC sub-part directly each paint,
wastes that sub-part's render every frame. Fizzygum already has the machinery: `BackBufferMixin`
(`src/mixins/BackBufferMixin.coffee`) + `world.cacheForImmutableBackBuffers` +
`_createRefreshOrGetBackBuffer` (see `TextWdgt.coffee` ~459, which caches at 99.9%). The fix is to
render the static sub-part into a cached back buffer once and blit it, drawing only the dynamic
part on top.

### 3.1 C1 — AnalogClockWdgt static face

> **✅ LANDED 2026-07-09 (Fizzygum-only; NOT byte-identical — 6 refs recaptured).**
> `src/apps/AnalogClockWdgt.coffee`: the 12 hour + 48 minute tick marks (the static face) are
> pre-rendered once per size into an immutable back buffer (`_getFaceBuffer` +
> `_renderStaticFace`, cached in `world.cacheForImmutableBackBuffers` keyed by device size) and
> blitted in `paintIntoAreaOrBlitFromBackBuffer` **in device space**, integer-aligned to the same
> `al/at/sl/st` as the background rect; the hands and the centre dot + outer arc stay drawn live
> (z-order: ticks < hands < dot < arc). **NOT byte-identical — but the mechanism is NOT what the
> determinism note below guessed** (it is not a fractional transform). Measured ground truth: the
> clock's `@bounds` are integer (`Widget.__commitExtent` rounds the extent, positions round in the
> move path) AND the context transform at the blit is **identity** (`a1 b0 c0 d1 e0 f0` — logged in
> the scroll test). The ≤1px tick divergence is **floating-point non-associativity** in tick-endpoint
> rasterisation: drawing the ticks DIRECTLY bakes the widget position into the float CTM, so an
> endpoint rasterises as `floor(a·squareDim + position + w/2)`; drawing them into an origin buffer +
> integer-offset blit rasterises as `floor(a·squareDim + w/2) + position`. Equal in exact arithmetic,
> but IEEE-754 addition is **not associative**, so they differ by ≤1px (more at large size/dpr) when
> the endpoint sits near a pixel boundary. Confirmed by isolated reproduction (`scratchpad/clock-*.js`)
> that matches the suite exactly: byte-exact for 70/130 px clocks at dpr1, **diverges for 130 px at
> dpr2 (867/900 positions) and 200 px at both dprs** — precisely why the resize/nested-window clock
> tests (130 px) pass at dpr1 but fail at dpr2. It is **not gate-able by an integer-position check**
> (positions ARE already integer; the divergence is in the internal float rasterisation of the
> rotated ticks). Owner decision: **ship + recapture**. Six SystemTests were
> recaptured (owner-approved): four with the tick-shift artifact — `macroDocumentScrollsMixedTextAndClocks`
> (scroll), `macroClosingInnerWindowKeepsOuter` (window close), `macroClockInWindowKeepsSquareOnResize`
> (resize, dpr2), `macroWindowWithAClockInAWindowConstructionTwo` (nested, dpr2) — plus two BENIGN
> inspector member-list shifts from the two new methods (`macroAnalogClockInspectEdit`,
> `macroNakedInspectorRendersResizesAndEdits`). 32 frames recaptured (11 dpr1 + 21 dpr2). Full
> `fg gauntlet` (dpr1/dpr2/webkit 196/196 + apps + paint + gates) + `fg homepage` green over the new
> refs. ⚠ **Lesson for C2 and any future back-buffer conversion of a directly-drawn widget: a back
> buffer is byte-identical to a direct draw ONLY at integer device transforms; under a fractional
> ancestor transform (scroll/animation) it shifts non-AA pixels.** See §8 ledger.

`src/apps/AnalogClockWdgt.coffee`: `@fps = 1` (`:11`), `step` → `@changed()` (`:99-101`), and
`renderingHelper` (`:119`) re-strokes the STATIC face every paint: 12 hour ticks (`:143-149`),
60 minute ticks (`:156-163`), centre dot + outer `#325FA2` arc (`:175-178`). Only the 3 hands
(`drawHoursHand`/`drawMinutesHand`/`drawSecondsHand`, `:170-172`) + the moment-in-time depend on
the clock.

**Change**: split `renderingHelper` into `_renderFace(context)` (ticks + arc + dot base — static;
depends only on the clock's size) and `_renderHands(context)` (the three hands + centre dot).
Cache the face in a back buffer keyed by device size (a per-size immutable face; reuse
`world.cacheForImmutableBackBuffers` or a local `@_faceBackBuffer` invalidated on resize). In
`paintIntoAreaOrBlitFromBackBuffer`, blit the cached face then draw the hands live. Keep the
existing clip + logical-pixel + translate/scale scaffolding (`:70-90`).

**Determinism note (as-authored — see the LANDED box above for the CORRECTION)**: the hands'
angles derive from `@dateLastTicked`, which under the Automator is pinned
(`AnalogClockWdgt.coffee:105-108` sets a fixed date when `Automator.animationsPacingControl`). The
face has no *time* dependence — but "no time dependence" does NOT imply "no pixel change": as the
landed box records, moving the tick draw into an origin buffer changes a few tick-endpoint pixels via
**floating-point non-associativity** (position baked into the float CTM vs added as an integer blit
offset — equal in exact math, ≤1px apart in IEEE-754 near pixel boundaries; size/dpr-dependent). This
required recapturing 6 SystemTests (4 clock-tick + 2 benign inspector member-list). The original "MUST
stay pixel-identical" expectation was wrong, and — note — it is **NOT** fixable by keeping positions
integer (they already are); the divergence is in the internal rasterisation of the rotated ticks.

### 3.2 C2 — SpreadsheetWdgt static grid + headers

`src/spreadsheet/SpreadsheetWdgt.coffee`: `_paintGrid` draws the header strips (`:172`), column
letters (`:212` `fillText @model.colToLetters(col)`), row numbers (`:217`
`fillText ("" + (row + 1))`), and gridlines directly every paint; `CellWdgt` (`src/spreadsheet/CellWdgt.coffee`)
paints scalar cell text directly (branch 3, `:11`). None is back-buffered, so a repaint over the
open sheet re-renders the whole visible grid + all headers + all scalar cells — the measured
"1".."12" ×428 and much of the `source-in` traffic.

**Change (scoped)**: back-buffer the STATIC grid chrome — the header strips, column letters, row
numbers, and gridlines — keyed by (visible range, scroll offset, cell size, dpr). Blit it, then
paint only the CELL CONTENTS (which change with data/edit/selection) on top. Cell scalar text
(`CellWdgt`) is a larger question (it changes with data); a cheaper interim is to give `CellWdgt`
the same immutable-back-buffer cache `TextWdgt` uses (keyed by text+font+size), since most cells'
text is stable frame-to-frame. **Verify against the `macroSpreadsheet*` / `macroDataflow*`
SystemTests** (Fizzygum-tests) — they MUST stay pixel-identical.

⚠ C2 is materially more involved than C1 (scroll/selection/edit interactions, the dataflow
reconcile that rebuilds cells — see `src/spreadsheet/CLAUDE.md`). Land C1 first as the pattern,
then scope C2 carefully. Item A independently reduces C2's per-glyph cost meanwhile.

⚠⚠ **Owner direction 2026-07-17 reshapes C2 — decide it BEFORE scoping** (recorded as
follow-on **F5** in `docs/dataflow-engine-implementation-plan.md` §3-F): anything
selectable/clickable should be a widget — the header cells become widgets (toward future
column/row selection), and the gridline chrome migrates into the cell widgets, leaving the
sheet's own paint ~empty (owner refinement, same day: the cells attach into a dedicated
container SUBCLASS that draws the two residual bottom/right outer lines itself, LIVE). Under
F5 there is NO sheet-drawn static layer left for this item to back-buffer, and per the owner
the gridline STROKES stay live everywhere — axis-aligned 1px strokes are cheap, buffering
them costs memory and re-imports the C1 FP-CTM risk. Caching is reserved for TEXT: header
widgets cache the way `TextWdgt`/`StringWdgt` already do (the 99.9%-hit
`world.cacheForImmutableBackBuffers`); `CellWdgt` scalar text stays a later,
measurement-driven option. That structurally delivers this item's win, since the measured
hot spot IS the header-text re-render (§1). So: if F5 is
scheduled, C2-as-specced is SUPERSEDED (fold the §3.3 verification into F5); only if F5 is
declined/deferred does the sheet-level chrome buffer above remain the plan. (Independently,
the "keyed by (visible range, scroll offset, …)" cache key above already anticipates
spreadsheet follow-on F1's scroll — under F1-without-F5, keep that key.)

### 3.3 Verification (C)

- Full `./fg gauntlet` (all three engine legs, full suite + the standing gates incl.
  `fg revisits`/`fg census`) + `./fg homepage` green, **zero reference
  churn** — the clock + spreadsheet SystemTests prove pixel-identity. If a legitimately-benign
  inspector member-list recapture is needed for a refactor, that's allowed per owner pref
  `byte-identical-not-sacred-for-benign-inspector-recapture` — but face/grid pixels must not move.
- Re-measure with `prof-interactive.js --sw --text`: `BitmapText.drawTextFromAtlas` call count +
  the "1".."12" repeat counts should drop toward the number of DISTINCT static renders (≈ once
  per cache key), not per-frame.
- No SWCanvas change ⇒ no re-vendor; Fizzygum-only commit (+ possibly the clock/sheet
  SystemTests if a new macro is added, per `fizzygum-macro-test-system`).

---

## 4. Sequencing & ledger

1. **A** (SWCanvas full-cover canvas-wide fast path) — ✅ **DONE 2026-07-09** (SWCanvas `cf5eea8`).
2. **C1** (clock face back-buffer) — ✅ **DONE 2026-07-09** (Fizzygum-only; NOT byte-identical —
   6 SystemTests recaptured, owner-approved; see §3.1 landed box). Established the pattern AND the
   sharp lesson below.
3. **C2** (spreadsheet grid back-buffer) — larger; scope after C1. ⚠ **FIRST reconcile with
   the 2026-07-17 owner direction** (spreadsheet follow-on F5, headers-as-widgets +
   cell-owned chrome — §3.2 ⚠⚠ box): F5 supersedes the sheet-level buffer if scheduled.
   ⚠ **Heed the C1 lesson**:
   back-buffering a directly-drawn widget is NOT automatically byte-identical, even at integer
   positions. Relocating a draw into an origin buffer changes the float CTM (position no longer baked
   in), so any content whose rasterisation is FP-sensitive near pixel boundaries — rotated/scaled
   strokes especially — can shift ≤1px (size/dpr-dependent; see the C1 landed box). The spreadsheet
   grid is mostly axis-aligned rects + text at integer positions, which is FP-robust, so C2 is likely
   safer than C1 — but VERIFY with the gauntlet and expect that any FP-sensitive sub-content may still
   force a recapture. Integer positions are necessary but NOT sufficient for back-buffer byte-identity.

Record each landing in `docs/runtime-performance-optimization-plan.md` §8 ledger (date, item,
SWCanvas range + pin bump for A, byte-identity evidence, before/after `prof-interactive` numbers).
Update memory `runtime-performance-optimization-plan` + `fizzygum-runtime-backend-swcanvas`.

## 5. Related (separate) investigation — occlusion culling

A DISTINCT idea (bigger, structural, being investigated separately 2026-07-08): in a broken
rectangle painted back-to-front, if some widget in the stack draws a SOLID OPAQUE rect covering
the whole broken rect, everything painted BENEATH it is wasted. See the occlusion-culling
findings/plan (separate doc) — it targets the ~35% fill-rasterization cluster by NOT painting
occluded widgets at all, orthogonal to A/C (which make the painting that DOES happen cheaper).
