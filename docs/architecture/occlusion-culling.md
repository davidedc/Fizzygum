# Occlusion culling — purpose and mechanism

**Status**: reference (feature LANDED — Avenue A, top-level, stateless). This documents what
ships and why. For the feasibility study, the correctness derivation, the measurement
methodology, and the deferred follow-on phases (Avenue B, descend, drag-case), see
[`docs/plans/occlusion-culling-plan.md`](occlusion-culling-plan.md). This feature is orthogonal to and
composes with [`docs/archive/interactive-render-perf-A-C-plan.md`](interactive-render-perf-A-C-plan.md):
that one makes the painting that DOES happen cheaper; this one avoids painting occluded widgets
at all.

## TL;DR

- The canvas repaints damage regions ("damage rectangles") **back-to-front**. If some widget in
  the paint stack draws a **solid opaque fill that fully covers** the damage rect, everything
  painted *beneath* it in that rect is wasted overdraw (profiling: ~35% of a busy-drag frame was
  raw fill rasterization, much of it hidden behind opaque windows).
- **The fix**: before painting a damage rect, find the frontmost widget that provably paints an
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
(`WorldWdgt._repaintDamagedRects` → `fullPaintIntoAreaOrBlitFromBackBuffer` per damage rect). For each
damage rect the world paints its own desktop fill, then every top-level widget from rearmost to
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
world coordinates, or `undefined`. It is the single geometry the whole feature rests on, and it is
answered at **two layers**: the widget decides whether its paint is *modulated* out of a claim, and
the **appearance** supplies the claim's *geometry*, beside the paint that creates it. Everything is
evaluated at runtime (never baked per class — appearances are swapped live, e.g. a re-parented
window flips Rectangular↔Boxy).

**`Widget::opaqueCoveredRect()` — the widget-side gates**, then `@appearance?.opaqueCoveredRect()`:

1. **Not ephemeral** (`not @isEphemeral()`) — highlights / drag affordances are translucent
   screen-toppers, never coverers.
2. **Opaque** — `@alpha == 1` and `@color._a == 1` (a translucent colour makes `fillStyle` emit
   `rgba(…)`).

**`Appearance::opaqueCoveredRect()` — the shape-side geometry.** The base answers `undefined`: a
shape makes no coverage claim unless it states one. Two state one:

- `RectangularAppearance` → the **tight box** (bounds minus the four paddings — the main fill clips
  there), or the **full bounds** if there is an opaque `backgroundColor` (which fills the whole
  clipped bounds, padding ring included);
- `BoxyAppearance` (rounded windows) → the **inscribed box**: bounds inset by `cornerRadius + 1` on
  every side (the straight edges fill crisply; only the corner arcs anti-alias, so +1 is
  conservative).

⚠⚠ **A claim is inherited, and a subclass that changes the OUTLINE must therefore refuse it.**
`BubblyAppearance` does: its rounded body occupies only the top `h - h/5` of the box (the rest is
the tail strip), so `BoxyAppearance`'s inscribed box reaches below the fill for any bubble taller
than about `5×(cornerRadius+1)` — and a `ToolTipWdgt` is a direct child of the world, so it *is*
asked. It overrides back to `undefined`. `DesktopAppearance` and `SimpleDropletAppearance` inherit
the rectangular claim correctly (a wallpaper tile and a plus-sign glyph both sit *on* the full
fill), as `MenuAppearance` does the boxy one.

ⓘ The `BackBufferMixin` consumers (`StringWdgt`, `CanvasWdgt`, `PaletteWdgt` and their subclasses)
blit an offscreen buffer of unknown per-pixel opacity: the mixin answers `undefined` for itself, so
nothing at the widget layer has to test how a widget's paint is routed. Every other class that
draws arbitrary pixels — `HandleWdgt`, `LayoutChromeWdgt`, `LabelButtonWdgt`, `PenWdgt`,
`CellWdgt`, `SheetHeaderCellWdgt`, `AnalogClockWdgt`, `Example3DPlotWdgt`,
`GraphsPlotsChartsWdgt` — does so through its own `*Appearance` subclass, which takes the base's
`undefined`.

ⓘ The scan runs over `world.children`, so only **desktop-level** widgets are ever asked; the world
itself never is.

Padding ≠ 0 and a *translucent* `backgroundColor` are **not** exclusions — the tight-box result
already accounts for both.

**Its sibling predicate is [`shapeContainsPoint`](widget-authoring-guidelines.md#5-appearance)**,
the pointer's shape question, which shares no code with this one on purpose: this one is about how
much a widget *paints* (and so consults `@alpha` and colour opacity, and must be conservative in
the direction of claiming less), while that one is about where a widget *is* (and so consults
neither, and is exact).

### 2b. `WorldWdgt::_paintedFromFrontmostCoverer(aContext, aRect)` — the per-rect skip

Called from the world's `fullPaintIntoAreaOrBlitFromBackBuffer` **before** the normal `super()`
pass; if it returns `true` (it did the painting), `super()` is skipped and only the hand/cursor is
painted on top as before. It:

1. bails if `WorldWdgt.occlusionCullingEnabled` is off, or the context is not the live screen
   (scratch / back-buffer contexts and their bookkeeping are left untouched);
2. narrows the rect to the desktop: `damagedPart = aRect ∩ boundingBox()`; bails if empty;
3. **reverse-scans `world.children`** (back-to-front array ⇒ reverse = front-to-back): the first
   child whose `opaqueCoveredRect()` contains `damagedPart` (with a **+1px** margin for
   logical-grid rounding) **and** whose `clippedThroughBounds()` contains `damagedPart` (so an
   ancestor clip hasn't cut the fill) is the coverer;
4. if found: preserves the world's own paint-record bookkeeping
   (`_recordDrawnAreaForNextDamageRects` — the world can itself be a damagedWidget, e.g. on a
   wallpaper change), then paints the coverer **and everything in front of it** (`children[k..]`)
   narrowed to `damagedPart`, replicates the trailing panel stroke, and returns `true`;
5. else returns `false` → the caller paints the normal full-depth way.

## 3. Why it is safe

When a coverer is found, its opaque fill covers every pixel of the damage rect, so anything
skipped beneath it would have been overpainted anyway — the final pixels are identical to the
full-depth pass. This holds even for the coverer's own drop shadow: all painting is clipped to
`damagedPart`, and the coverer's fill (which contains `damagedPart + 1px`) overpaints its own
pre-content shadow. The only way to be wrong is to *over-claim* a covered rect, and every gate in
§2a guards against that by yielding `undefined` / a smaller rect on any doubt. The byte-exact
SystemTest suite (300+ tests × dpr1/dpr2/WebKit — `fg status` prints the live count) is the proof;
it also empirically covers the paint-record skip.

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

What ships is **top-level, whole-rect** culling: it skips a damage rect's overdraw only when a
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
