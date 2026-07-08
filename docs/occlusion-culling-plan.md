# Occlusion culling in the broken-rectangles repaint — feasibility + plan

**Status**: AUTHORED 2026-07-08 (feasibility established), NOT STARTED. Self-contained.
**Idea (owner, 2026-07-08)**: when a broken rectangle is repainted back-to-front, if some widget
in the paint stack draws a SOLID OPAQUE rect that fully covers the broken rect, everything
painted BENEATH it is wasted — detect that and skip painting what's underneath.
**Provenance**: interactive profiling (2026-07-08) showed ~35% of a busy-drag frame is raw fill
rasterization (`_fillPolygonsDirect`/`_fillAxisAlignedRect`/`fill_AA_Opaq`/`_fillPixelSpan`) —
much of it overdraw of widgets hidden behind opaque windows. Orthogonal to items A/C in
`docs/interactive-render-perf-A-C-plan.md` (which make the painting that DOES happen cheaper;
this AVOIDS painting occluded widgets at all).

## 0. Orientation
Fizzygum framework (CoffeeScript), `src/**/*.coffee`. Owner runs `?sw=1` (SWCanvas) — see memory
`fizzygum-runtime-backend-swcanvas`. Verify with `./fg gauntlet` (dpr1/dpr2/webkit 196/196 + apps
+ paint + gates) + `./fg homepage`, **zero reference churn**. Owner prefs: ask before commit/push;
evidence before conclusions; one end-of-arc review. Measure with
`docs/profiling/prof-interactive.js --sw` (busy-desktop drag; see `docs/profiling/README.md`).

## 1. Key facts (verified 2026-07-08, cited)

**The architecture already anticipates this.** The exact optimization is a documented TODO citing
GitHub issue #149 at `src/mixins/ClippingAtRectangularBoundsMixin.coffee:152-159`, and an
opacity-driven child-skip ALREADY ships in the SHADOW path there (`:204-209`: an opaque panel
skips painting all children in its shadow). There is currently NO such skip for CONTENT painting.

**Paint recursion is back-to-front (confirmed):**
- `WorldWdgt.doOneCycle` (`src/WorldWdgt.coffee:1454`) → `@updateBroken()` (`:1514`).
- `WorldWdgt.updateBroken` (`:1085`) drives `@broken.forEach (rect) => @fullPaintIntoAreaOrBlitFromBackBuffer @worldCanvasContext, rect` (`:1119-1124`).
- `WorldWdgt.fullPaintIntoAreaOrBlitFromBackBuffer` (`:688`) → `super` (Widget impl) → paints `@hand`/cursor LAST, on top (`:702`).
- `Widget.fullPaintIntoAreaOrBlitFromBackBuffer` (`src/basic-widgets/Widget.coffee:1964`) → shadow first if `@shadowInfo?` (`:1975`) → `fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow` (`:2012`): **self paints, THEN children in array order** (`children[0..n]`, later = on top).
- Top-level widgets (windows, icons) are direct `world.children`; siblings are a flat ordered list per parent, front-to-back = array order. So the z-order a pre-scan needs is directly available.

**Existing pruning (none is content occlusion):** `PanelWdgt` narrows the dirty rect to its box
+ stops recursion on children outside it (`ClippingAtRectangularBoundsMixin.coffee:119,169-171`);
`preliminaryCheckNothingToDraw` (`Widget.coffee:1905`) is a pure visibility gate (invisible / empty
clip / orphan) with no opacity notion. No `isOpaque`/`covers`/`occlus` flag exists in `src/`.

**Opacity must be DERIVED (no flag).** A widget paints a solid opaque rect fully covering its
bounds only when ALL of: appearance is `RectangularAppearance` (NOT `BoxyAppearance`/rounded —
rounded corners are transparent, `BoxyAppearance.coffee:19-40`; NOT a `BackBufferMixin` blit —
per-pixel opacity unknown); `@alpha == 1` (`Widget.coffee:78`); `@color._a == 1` (Color emits
`rgb(` not `rgba(` only then, `Color.coffee:203-208`); all four paddings 0 so
`boundingBoxTight()` == `boundingBox()` (the fill clips to the TIGHT box,
`RectangularAppearance.coffee:82,88`); no translucent `backgroundColor`. Clean candidates:
`RectangleWdgt` (`RectangleWdgt.coffee:12-18`) and an INTERNAL (nested) `WindowWdgt` body (a free
desktop window uses rounded `BoxyAppearance`, `WindowWdgt.coffee:431-435` — NOT a full-cover rect).

**Coverage test** (logical px, +1px safety margin since the fill rounds at device res): a widget
occludes the broken rect iff `@boundingBoxTight().containsRectangle(brokenRect)` AND
`@clippedThroughBounds().containsRectangle(brokenRect)` (`Widget.coffee:1196` — bounds after the
ancestor clip chain, so an ancestor clip hasn't cut the fill) AND the opacity conditions above.

**Broken rects are small/tight** (per-widget dirty regions; only per-widget src+dst merging,
`WorldWdgt.coffee:740-750`; no global consolidation). **So a single opaque widget covering an
ENTIRE broken rect is COMMON when the change originates inside an opaque widget** (e.g. a button
repaint inside an opaque window body → everything behind that window in that small rect is pure
overdraw). It's LESS likely for big drag/move rects. This is exactly the busy-desktop case:
many small rects each fully inside an opaque window.

## 2. Design — front-to-back pre-scan per broken rect

The recursion is top-down back-to-front, so when a subtree starts you don't yet know a LATER
sibling covers it. Fix: before painting a broken rect, **pre-scan the overlapping widgets
front-to-back, find the frontmost one that `paintsOpaqueFillCovering(rect)`, and begin actual
painting from THERE** (skip everything behind it).

- **Predicate** `Widget::paintsOpaqueFillCovering(rect)` — new method returning true only under
  the conservative Q3/coverage conditions above. Default `false` on `Widget`; true only for the
  clean rectangular-opaque cases. A false positive silently drops pixels, so err to `false`.
- **Insertion point** (two options):
  - (a) In the `@broken.forEach` driver (`WorldWdgt.updateBroken:1119`) / `WorldWdgt.fullPaintIntoAreaOrBlitFromBackBuffer` (`:688`): walk `world.children` front-to-back (and their panel-clipped descendants that overlap `rect`), find the frontmost covering widget, and start the paint from it.
  - (b) The cheaper approximation the TODO suggests (`ClippingAtRectangularBoundsMixin.coffee:156`): maintain a short list of the top-N largest opaque widgets (windows, big rectangles) and test only those against each broken rect — avoids a full traversal.
- Start simple: **top-level only** — before painting a broken rect, if the frontmost `world.children`
  window/rectangle overlapping it is opaque-covering, skip all world.children behind it (and the
  desktop). This captures the dominant "small rect fully inside an opaque window with windows
  behind it" case with minimal risk, before attempting nested/descendant occluders.

## 3. Risks / caveats (must handle)

1. **Correctness is a one-way trap** — a false "covers" drops pixels invisibly (only caught by the
   pixel-exact SystemTests). The predicate must conservatively exclude: padding≠0, Boxy/rounded,
   back-buffer blits, `@alpha<1`, `@color._a<1`, translucent `backgroundColor`, ancestor-clipped
   fills. Prefer false negatives.
2. **Shadows paint OUTSIDE bounds** (`Widget.coffee:1975`, subtree re-painted offset/faint behind
   itself). Skipping occluded subtrees is safe STRICTLY inside the fully-covered rect (the opaque
   coverer hides both the widget behind and its shadow within that rect); but the coverer's OWN
   shadow extends beyond it and must never be treated as coverage. Keep the skip inside the covered
   rect only.
3. **Ephemeral overlays** (highlights, drag affordances) are injected every cycle right before
   paint (`doOneCycle:1508-1511`) and are translucent (highlight alpha 50, `Widget.coffee:1851`) —
   must ALWAYS paint, never count as occluders and never be skipped. The **hand/cursor** paints
   unconditionally last (`WorldWdgt.coffee:702`) — outside the skip; fine.
4. **No maintained global `fullBounds` index** (issue #150, `Widget.coffee:1938-1941`) — the overlap
   scan costs a traversal; `PanelWdgt` clipping already prunes most of it, and the top-N-opaque
   heuristic (option b) bounds it. Measure that the scan doesn't eat the savings.

## 4. Phased plan
1. **P1 — predicate.** Add `Widget::paintsOpaqueFillCovering(rect)` (default false) + true impls for
   `RectangleWdgt` and internal `WindowWdgt` bodies, with the full conservative gate. Unit-reason
   each condition; no behaviour change yet (unused).
2. **P2 — top-level skip.** In the broken-rect driver, before painting each rect, find the frontmost
   opaque-covering `world.child` and start painting from it (skip the desktop + windows behind,
   within that rect only). Gate behind a flag for A/B.
3. **P3 — verify.** Full `./fg gauntlet` (dpr1/dpr2/webkit 196/196) + `./fg homepage`, **zero
   reference churn** (the pixel-exact suite is the correctness proof — any dropped pixel fails
   loudly). Re-measure `prof-interactive.js --sw` busy drag: the fill-rasterization cluster (~35%)
   should drop by the occluded fraction; confirm the scan cost is < the savings.
4. **P4 — (optional) descend.** Extend to nested opaque panels / the top-N-opaque heuristic if P2's
   win justifies the added complexity.

Fizzygum-only (no SWCanvas change ⇒ no re-vendor). Record in
`docs/runtime-performance-optimization-plan.md` §8 ledger + memory. This is the higher-ceiling
structural win (avoids overdraw entirely) vs A/C (cheaper per-pixel/per-widget work); they compose.
