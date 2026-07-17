# Occlusion culling — purpose and mechanism

**Status**: reference (feature LANDED — Avenue A, top-level, stateless). This documents what
ships and why. For the feasibility study, the correctness derivation, the measurement
methodology, and the deferred follow-on phases (Avenue B, descend, drag-case), see
[`docs/plans/occlusion-culling-plan.md`](occlusion-culling-plan.md). This feature is orthogonal to and
composes with [`docs/archive/interactive-render-perf-A-C-plan.md`](interactive-render-perf-A-C-plan.md):
that one makes the painting that DOES happen cheaper; this one avoids painting occluded widgets
at all.

## TL;DR

- The canvas repaints dirty regions ("broken rectangles") **back-to-front**. If some widget in
  the paint stack draws a **solid opaque fill that fully covers** the broken rect, everything
  painted *beneath* it in that rect is wasted overdraw (profiling: ~35% of a busy-drag frame was
  raw fill rasterization, much of it hidden behind opaque windows).
- **The fix**: before painting a broken rect, find the frontmost widget that provably paints an
  opaque fill covering the whole rect, and **start painting from there** — skipping the desktop
  fill and every widget behind it, within that rect.
- **Correctness is a one-way trap**: a wrong "it's covered" silently drops pixels (caught only by
  the byte-exact SystemTests). So the coverage test is **conservative by construction** — any
  uncertainty yields "not covered", making every error a false *negative* (a redundant repaint),
  never a dropped pixel.
- **Measured**: on a busy 21-window desktop (SWCanvas, plain wallpaper), same-build A/B shows
  window-drag ~3.0×, pen-draw ~2.1×, and a clock-behind-window "covered" scene ~4.3× cheaper per
  frame; the coverage scan itself is not a profile hotspot.

## 1. The problem it solves

Painting is a recursive, **back-to-front** walk driven by the damage system
(`WorldWdgt.updateBroken` → `fullPaintIntoAreaOrBlitFromBackBuffer` per broken rect). For each
broken rect the world paints its own desktop fill, then every top-level widget from rearmost to
frontmost (`world.children` is a back-to-front array), each painting its whole subtree; later =
on top. When an opaque window sits in front of that rect, the desktop fill and every rearward
widget are painted and then **completely overpainted** — pure overdraw.

The architecture already anticipated this: it is a documented TODO (GitHub issue #149) at
`ClippingAtRectangularBoundsMixin.coffee`, and an opacity-driven child-skip already ships in the
*shadow* path there. This feature adds the equivalent skip for **content** painting.

## 2. The mechanism (Avenue A — stateless per-rect pre-scan)

Two pieces, both in the framework source:

### 2a. `Widget::opaqueCoveredRect()` — the coverage predicate

Returns the axis-aligned rectangle this widget **provably paints fully opaque**, in logical px
world coordinates, or `nil`. It is the single geometry the whole feature rests on. Gates, ALL
evaluated at runtime (never baked per class — appearances are swapped live, e.g. a re-parented
window flips Rectangular↔Boxy):

1. **Plain appearance-delegation paint route** —
   `@paintIntoAreaOrBlitFromBackBuffer is Widget::paintIntoAreaOrBlitFromBackBuffer`. Nine widget
   classes override paint to draw arbitrary pixels (`HandleWdgt`, `LayoutChromeWdgt`,
   `LabelButtonWdgt`, `PenWdgt`, `CellWdgt`, `SpreadsheetWdgt`, `AnalogClockWdgt`,
   `Example3DPlotWdgt`, `GraphsPlotsChartsWdgt`), and `BackBufferMixin` blits an offscreen buffer
   of unknown per-pixel opacity. This one prototype-identity check excludes them all.
2. **Not ephemeral** (`not @isEphemeral()`) — highlights / drag affordances are translucent
   screen-toppers, never coverers.
3. **Opaque** — `@alpha == 1` and `@color._a == 1` (a translucent colour makes `fillStyle` emit
   `rgba(…)`).
4. **Exact-class appearance dispatch** (a subclass may add arbitrary drawing, so it must NOT
   inherit a coverage claim):
   - `RectangularAppearance` → the **tight box** (bounds minus the four paddings — the main fill
     clips there), or the **full bounds** if there is an opaque `backgroundColor` (which fills the
     whole clipped bounds, padding ring included);
   - `BoxyAppearance` (rounded windows) → the **inscribed box**: bounds inset by
     `cornerRadius + 1` on every side (the straight edges fill crisply; only the corner arcs
     anti-alias, so +1 is conservative);
   - anything else (gradients, `DesktopAppearance`, unknown subclasses) → `nil`.

Padding ≠ 0 and a *translucent* `backgroundColor` are **not** exclusions — the tight-box result
already accounts for both.

### 2b. `WorldWdgt::_paintedFromFrontmostCoverer(aContext, aRect)` — the per-rect skip

Called from the world's `fullPaintIntoAreaOrBlitFromBackBuffer` **before** the normal `super()`
pass; if it returns `true` (it did the painting), `super()` is skipped and only the hand/cursor is
painted on top as before. It:

1. bails if `WorldWdgt.occlusionCullingEnabled` is off, or the context is not the live screen
   (scratch / back-buffer contexts and their bookkeeping are left untouched);
2. narrows the rect to the desktop: `dirtyPart = aRect ∩ boundingBox()`; bails if empty;
3. **reverse-scans `world.children`** (back-to-front array ⇒ reverse = front-to-back): the first
   child whose `opaqueCoveredRect()` contains `dirtyPart` (with a **+1px** margin for logical-grid
   rounding) **and** whose `clippedThroughBounds()` contains `dirtyPart` (so an ancestor clip
   hasn't cut the fill) is the coverer;
4. if found: preserves the world's own paint-record bookkeeping
   (`recordDrawnAreaForNextBrokenRects` — the world can itself be a broken widget, e.g. on a
   wallpaper change), then paints the coverer **and everything in front of it** (`children[k..]`)
   narrowed to `dirtyPart`, replicates the trailing panel stroke, and returns `true`;
5. else returns `false` → the caller paints the normal full-depth way.

## 3. Why it is safe

When a coverer is found, its opaque fill covers every pixel of the broken rect, so anything
skipped beneath it would have been overpainted anyway — the final pixels are identical to the
full-depth pass. This holds even for the coverer's own drop shadow: all painting is clipped to
`dirtyPart`, and the coverer's fill (which contains `dirtyPart + 1px`) overpaints its own
pre-content shadow. The only way to be wrong is to *over-claim* a covered rect, and every gate in
§2a guards against that by yielding `nil` / a smaller rect on any doubt. The byte-exact SystemTest
suite (196 tests × dpr1/dpr2/WebKit) is the proof; it also empirically covers the paint-record
skip.

## 4. The control flag

`WorldWdgt.occlusionCullingEnabled` (default `true`) is a **class-level** property, so it is
invisible to world-snapshot serialization. It exists to:

- drive the `prof-interactive.js --cull=on|off|both` **same-build A/B** measurement, and
- serve as the `DETERMINISM.md` **"disable the mechanism"** first move — if a suspect SystemTest
  still fails with it `false`, the failure is not this feature.

Setting it `false` restores the exact untouched `super()` paint path.

## 5. Measured impact

Same-build A/B via `docs/profiling/prof-interactive.js --sw --wallpaper=plain --cull=both --occl`
(busy ~21-window desktop, dpr1, 2 reps), cull off → on:

| phase | median off → on | speedup | fire-rate |
|---|---|---|---|
| window drag | 84 → 28 ms | ~3.0× | ~72% |
| pen draw | 86 → 40 ms | ~2.1× | ~68% |
| clock behind a window (`covered`) | 58 → 13 ms | ~4.3× | ~99% |

The coverage scan is not a hotspot (the per-frame median *drops*, not rises; ~25k cheap
rect-tests over a whole run). Instruments: `--occl` adds per-phase {rects seen, culled fires,
fire-rate} counters + a scan-call count; the `covered` phase parks a large window over the desktop
`AnalogClockWdgt` and holds input-free frames (the clock keeps animating under it).

## 6. Scope and future work

What ships is **top-level, whole-rect** culling: it skips a broken rect's overdraw only when a
single **top-level** `world.children` widget covers the **entire** rect. Deferred (owner-gated,
detailed in the plan):

- **Avenue B (P4)** — a maintained, incrementally-invalidated list of the sizable opaque widgets +
  their covered rects, replacing the per-rect scan with an O(short-list) lookup. Same
  `opaqueCoveredRect()` geometry, just cached; its defining risk is **staleness** (a missed
  invalidation drops pixels), which is why the stateless Avenue A shipped first.
- **Descend / per-widget (P5)** — test *each* widget's clipped redraw against the opaque set, so a
  rect that no single widget covers can still skip its individually-occluded widgets (needs a
  tree-wide z-order; partial coverage needs fringe clipping, P5c). This is where the residual
  ~30% of overdraw — the rects Avenue A can't fire on — lives.
- **Hand-carried coverer (P5b)** — treat the floatDragged window (which rides the hand, painted
  last) as a coverer for the drag case.

## 7. Verifying / debugging

- Correctness gate: `./fg gauntlet` (dpr1 + dpr2 + WebKit, all byte-exact) + `./fg homepage`. A
  dropped pixel fails loudly; **fix the predicate, never recapture references** to hide it.
- A suspect SystemTest: flip `WorldWdgt.occlusionCullingEnabled = false` and re-run — if it still
  fails, it is not this feature.
- Measure: `node docs/profiling/prof-interactive.js --sw --cull=both --occl` (always `--sw`; the
  software backend is the felt runtime). Read the fire-rate before judging ms deltas.
