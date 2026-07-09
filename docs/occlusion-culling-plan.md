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

## 2. Design — two avenues

The recursion is top-down back-to-front, so when a subtree starts you don't yet know a LATER
sibling covers it. Both avenues fix this by, before painting a broken rect, finding the frontmost
widget that fully+opaquely covers it and beginning actual painting from THERE (skipping everything
behind it, within that rect). They differ in HOW they find that widget — a stateless per-rect scan
vs a maintained coverage list. They are complementary and can coexist (start with Avenue A; Avenue
B is the scaling/generalising follow-up).

Both need a **coverage notion** derived per Q3 (no `isOpaque` flag exists). Two shapes of it:
- `Widget::paintsOpaqueFillCovering(rect)` → boolean (does this widget paint a solid opaque fill
  that contains `rect`?). Used by Avenue A.
- `Widget::opaqueCoveredRect()` → the maximal axis-aligned rectangle this widget paints FULLY
  OPAQUE (or `nil`). Used by Avenue B. See the covered-rect note below.
A false positive in either silently drops pixels (only the pixel-exact SystemTests catch it), so
both must be CONSERVATIVE — err to `false` / a smaller rect.

### Avenue A — stateless front-to-back pre-scan per broken rect
Before painting each broken rect, walk the overlapping widgets front-to-back and start from the
frontmost `paintsOpaqueFillCovering(rect)`.
- **Insertion point**: the `@broken.forEach` driver (`WorldWdgt.updateBroken:1119`) /
  `WorldWdgt.fullPaintIntoAreaOrBlitFromBackBuffer` (`:688`): walk `world.children` front-to-back
  (and their panel-clipped descendants overlapping `rect`), find the frontmost coverer, paint from it.
- **Start simple: top-level only** — if the frontmost `world.children` widget overlapping the rect
  is opaque-covering, skip all world.children behind it (+ the desktop). Captures the dominant
  "small rect fully inside an opaque window with windows behind it" case with minimal risk, before
  attempting nested/descendant occluders.
- **Cost**: stateless (no bookkeeping, never stale) but pays a per-rect traversal of the overlap
  set (`PanelWdgt` clipping already prunes most of it; there's no maintained global `fullBounds`
  index — issue #150).

### Avenue B — maintained "covered-rect" list of sizable opaque widgets
Keep a persistent, incrementally-maintained list of the SIZABLE opaque widgets, each paired with
the **rectangle it completely covers** (`opaqueCoveredRect()`, in world/device space, already
intersected with its `clippedThroughBounds()` so an ancestor clip can't over-claim) plus a z-order
key. Then repainting a broken rect is a fast scan of this SHORT list: find the frontmost entry
whose covered-rect `containsRectangle(brokenRect)`, start painting from that widget, and paint
only the widgets IN FRONT of it. This is the "top-n biggest opaque widgets" idea the TODO already
suggests (`ClippingAtRectangularBoundsMixin.coffee:156`), made precise.
- **The covered-rect is the key refinement** — track the rectangle a widget *completely* covers,
  NOT its bounds, so **non-rectangular opaque shapes still participate** via their INSCRIBED opaque
  rectangle, and every check stays a cheap rectangle-containment test:
  - Plain opaque `RectangleWdgt` / flat `RectangularAppearance` with zero padding → the tight box.
  - Rounded / `BoxyAppearance` (a large `CircleBox`, an external rounded `WindowWdgt`) → the largest
    axis-aligned rectangle strictly inside the opaque region, i.e. bounds inset by ~the corner
    radius on each side (`BoxyAppearance.cornerRadius`, transparent-at-corner test
    `BoxyAppearance.coffee:19-40`). Conservative: inset a touch more than the exact radius so the
    covered-rect never includes an anti-aliased corner pixel.
  - Anything without a provably-opaque interior (back-buffer blits, `@alpha<1`, `@color._a<1`,
    translucent `backgroundColor`, gradient/pattern fills) → `nil` (not tracked).
- **"Sizable"** = covered-rect area above a threshold (small widgets aren't worth tracking; the win
  is big background rects/windows). Keeps the list short → O(list) per broken rect.
- **Maintenance / invalidation** (the cost of this avenue): the list entry for a widget is
  (re)computed only when something that affects its coverage changes — add/remove, move/resize,
  alpha/color/backgroundColor/cornerRadius/padding change, re-parenting (which changes
  `clippedThroughBounds` and z-order), and show/hide. Hook these off the existing `changed()` /
  layout / add-remove paths rather than rebuilding per frame. Z-order key: for top-level widgets
  it's the `world.children` index; nested coverers need the ancestor chain's order (defer to a
  later phase — start with top-level coverers only, same as Avenue A's simple start).
- **Cost**: O(short-list) rectangle checks per broken rect (no traversal), at the price of
  maintenance + a staleness surface (a missed invalidation → dropped pixels). Favoured when there
  are many broken rects per frame and few large opaque widgets — exactly the busy-desktop drag.

**Recommendation**: implement Avenue A first (stateless, no staleness surface, easiest to prove
correct against the pixel-exact suite). Then add Avenue B as the scaling path once the predicate +
covered-rect geometry are trusted — B reuses A's coverage logic, just caches it and generalises to
inscribed rects. A can even validate B (run both, assert B's chosen start-widget ⊆ A's) during
bring-up.

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
4. **No maintained global `fullBounds` index** (issue #150, `Widget.coffee:1938-1941`) — Avenue A's
   overlap scan costs a traversal; `PanelWdgt` clipping already prunes most of it. Measure that the
   scan doesn't eat the savings — if it does, that's the argument for Avenue B.
5. **Avenue B staleness (its defining risk)** — the covered-rect list is correct only if EVERY
   change that affects a tracked widget's coverage, geometry, opacity, z-order, or parentage
   invalidates/updates its entry. A missed invalidation → silently-dropped pixels. Enumerate the
   invalidation triggers exhaustively (add/remove, move/resize, alpha/color/backgroundColor/
   cornerRadius/padding, re-parent, show/hide) and prefer over-invalidation (drop the entry on any
   doubt → falls back to painting, never to dropping). The inscribed covered-rect for rounded/Boxy
   shapes must be inset conservatively (never include an anti-aliased corner pixel).

## 4. Phased plan
1. **P1 — coverage predicate/geometry.** Add `Widget::paintsOpaqueFillCovering(rect)` (default
   false) — Avenue A — and `Widget::opaqueCoveredRect()` (default nil) — Avenue B — with true/rect
   impls for `RectangleWdgt`, flat internal `WindowWdgt` bodies, and (for `opaqueCoveredRect`) the
   inscribed-rect case for `BoxyAppearance`/rounded widgets. Full conservative gate; unit-reason
   each condition; no behaviour change yet (unused).
2. **P2 — Avenue A, top-level skip.** In the broken-rect driver, before painting each rect, find
   the frontmost opaque-covering `world.child` and start painting from it (skip the desktop +
   windows behind, within that rect only). Gate behind a flag for A/B. Stateless — easiest to prove.
3. **P3 — verify A.** Full `./fg gauntlet` (dpr1/dpr2/webkit 196/196) + `./fg homepage`, **zero
   reference churn** (the pixel-exact suite is the correctness proof — any dropped pixel fails
   loudly). Re-measure `prof-interactive.js --sw` busy drag: the fill-rasterization cluster (~35%)
   should drop by the occluded fraction; confirm the scan cost is < the savings.
4. **P4 — Avenue B, maintained covered-rect list.** Build the persistent list of sizable opaque
   top-level widgets + their `opaqueCoveredRect()` + z-index, with the full invalidation wiring
   (P-risk 5). Replace the per-rect traversal with the O(list) rectangle scan. Bring-up safety: run
   BOTH avenues and assert B's chosen start-widget matches A's, then drop A. Re-verify gauntlet +
   re-measure (expect the scan cost to fall vs P2, especially with many broken rects/frame).
5. **P5 — (optional) descend.** Extend either avenue to nested opaque panels (needs the ancestor
   z-order chain) if the top-level win justifies the added complexity.

Fizzygum-only (no SWCanvas change ⇒ no re-vendor). Record in
`docs/runtime-performance-optimization-plan.md` §8 ledger + memory. This is the higher-ceiling
structural win (avoids overdraw entirely) vs A/C (cheaper per-pixel/per-widget work); they compose.
