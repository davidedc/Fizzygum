# Open items whose arc has no plan file — their detail, moved from docs/BACKLOG.md

> The twin of `archive/backlog-closed-items-ledger.md`: when an arc that left open items behind never had a plan
> file, its items' full text lives here (docs/README.md filing rule 5) and `docs/BACKLOG.md` keeps a one-line
> entry pointing at its heading. An item that closes moves to the closed-items ledger.

## BACKLOG detail (open items, moved from docs/BACKLOG.md)

### Pointer hit-test rework 2026-08-21 — the backlog's note

`isTransparentAt` + the `noticesTransparentClick` flag retired for three single-meaning members —
`Appearance.shapeContainsPoint` (outline) / `Widget.catchesPointerAt` (does my surface stop the
pointer) / `Widget.isPointerTargetAt` (the whole question) — and `opaqueCoveredRect`'s exact-class
switch dissolved onto the appearances. Living truth: `architecture/widget-authoring-guidelines.md` §5
and `architecture/occlusion-culling.md` §2a. What it deliberately did not take on:

### `BubblyAppearance.shapeContainsPoint` OVER-CLAIMS its tail strip

- [ ] **`BubblyAppearance.shapeContainsPoint` OVER-CLAIMS its tail strip** (named in the class, not
      silent). A bubble's rounded body occupies only the top `h - h/5`; the bottom fifth is empty
      except for the spike. It inherits `BoxyAppearance`'s rounded-box test, so a click in the empty
      corner beside the spike stops on the bubble instead of falling through. Harmless today (a speech
      bubble is not a thing you click past; the tooltip is a plain rounded plate since W2), and correcting it needs an analytic body+spike
      point test — a BEHAVIOUR change with hover-pixel churn, not a rename. ⭐ Its `opaqueCoveredRect`
      twin was NOT harmless and is already refused: `BoxyAppearance`'s `insetBy cornerRadius + 1`
      reaches BELOW the fill for any bubble taller than ~5×(cornerRadius+1), and a `ToolTipWdgt` is a
      direct child of the world, so the culler asks it and would have dropped real pixels.

### SliderTrackClickMovesButton side-problems arc 2026-10-15 — the backlog's note

- The three measured residue items (the list verb's thin-geometry drag, the pixel-short move, the ~1 px bars
  in short viewports) are CLOSED: `archive/backlog-closed-items-ledger.md` § "Residue arc 2026-10-16".
  Its follow-ups are filed under "Residue arc 2026-10-16 — follow-ups" below.

### The gauntlet's refs leg hits its leg alarm in-wave on a loaded machine

- [ ] (optional, owner to decide) the gauntlet's `refs` leg hits fg's own leg alarm in-wave on a loaded machine
      (twice on 2026-10-15; the second time wave B's legs ran ~280 s each) — a budget question, not a reference
      problem. ⚠ The log line `Alarm clock: 14` names SIGALRM by its signal NUMBER: the budget is the alarm
      `buildSystem/legs.js` gives `check-refs.js --pixels`, not 14 s.

### Residue arc 2026-10-16 — the backlog's note

- Six of its follow-ups are CLOSED: `archive/backlog-closed-items-ledger.md` § "Residue arc 2026-10-16 — its six
  follow-ups".

### The corner-occupancy protocol does not see the temporary resize/move halo

- [ ] **The corner-occupancy protocol does not see the temporary resize/move halo** (2026-10-16). A halo's
      bottom-right handle is not a declared occupant, so a bar runs under it while the halo is up (its side
      handles already sat on the bars). Related, pre-existing: `Widget._setLayoutSpec` updates the
      visibility of only its FIRST handle child, so a halo handle that precedes a frame's resizer would
      keep the resizer's visibility, and its corner reserve, stale.

### The sw3d work is not vendored

- [ ] **The sw3d work is not vendored**: SWCanvas branch `sw3d-game` (6 commits, `examples/` only) forked from `main` before the pinned font-symbols commit and its `dist/sw3d.min.js` was never rebuilt; bring it in as its own pin bump, from a branch rebased onto `main` with a rebuilt dist, with its own whole-suite check (it reaches Fizzytiles).

### census-widget-conformance.js facet 1: lookahead defeated

- [ ] `census-widget-conformance.js` facet 1 (`declarationsOf`): its `(?!\(|->|=>)` lookahead is defeated by backtracking, so every class-level key counts as a declaration — and that is LOAD-BEARING (a naive fix makes the ratcheted gate report `FridgeMagnets3DCanvasWdgt`'s function-valued fields).

### A demo `PointerWdgt` holds its `target` only through a field

- [ ] **A demo `PointerWdgt` holds its `target` only through a field** (demos part): the world inventory reads the target as ESCAPED the moment a pointer is made (`RectangleWdgt#1@world.children.[0].target`) and after the pointers die; a single-widget save of a pointer is refused (`→ .target`) and a world snapshot CAPTURES the target as an off-tree record (`Fizzygum-tests/.scratch/arc-r3/R12/q2-pointer.js`). Same shape as the placeholder this arc dissolved: an owned widget kept off the tree.

### The overflow menu's miniature of a text tool races the glyph atlas

- [ ] **The overflow (») menu's miniature of a text-bearing tool races the glyph atlas on SWCanvas pages**: `OverflowChevronButtonWdgt._miniatureOf` pictures each hidden tool ONCE; the Slides toolbar's "Fizzygum logo with text" icon (`FizzygumLogoWithTextIconAppearance` types with `fillText`, no live-picture escape) shot while text is still loading keeps 36 px of placeholder boxes until the menu's next opening (`.scratch/arc-r3/R3b/logs/overflow-*.log`). The same one-shot picture of a plain `StringWdgt` in an `InertIconHolderWdgt` keeps them for good. Native pages are unaffected; no test opens an overflow holding a text tool.

### SWCanvas drawImage of a file:// image throws SecurityError

- [ ] **On `index-sw.html` in an ordinary browser, SWCanvas's `drawImage` of an image loaded over `file://` throws `SecurityError`** (it reads the image's pixels; the harness runs with `--allow-file-access-from-files`), so an image widget cannot paint on the SW page outside the harness. Nothing shipped draws an `HTMLImageElement` today (`.scratch/arc-r3/R34/logs/i4-noflag-sw.log`).

### Ellipses are flattened by their MINOR radius

- [ ] **Ellipses are flattened by their MINOR radius** (`Context2D._bakeEllipse`, `PathFlattener._flattenEllipse`): uniform-angle chords miss the major-axis ends by up to (a/b)×0.25 px — worst 0.52 px filled and 0.50 px stroked, against the 0.25 px tolerance. Fix, prototyped in `R-B2/v-chords`: size the count by the device semi-major radius (0.21 / 0.18 px). Fizzygum draws no ellipse.

### Path2D curves are flattened with a USER-space tolerance

- [ ] **Path2D curves are flattened with a USER-space tolerance** (`PathFlattener.flattenPath` takes no transform), so the device error grows with the scale: at scale 4 a Path2D arc misses by 0.92 px and an ellipse by 1.53 px (a device tolerance through the CTM's largest singular value gives 0.25 / 0.22). Béziers too (`R-A2/logs/bezier-scale-tolerance.log`). Fizzygum uses no Path2D.

### Arc segment counts read the CTM's largest column length

- [ ] **Arc segment counts read the CTM's largest COLUMN length, not its largest singular value** (`Context2D`'s `max(scaleX, scaleY)`): under scale-then-rotate they under-count. It moves 2 SWCanvas PNGs (51 px); no assertion catches it at test sizes (worst 0.125 px).

### Two `arcTo` flatteners disagree

- [ ] **Two `arcTo` flatteners disagree**: `Context2D._bakeArcTo` (a device-space count) and `PathFlattener._handleArcTo` (a user-space count, which also skips t1 within 0.01 and ends at cos/sin(end) rather than exactly at t2). `fillStadium` (a Path2D) differs from the path `roundRect` in 84 of 5376 cases, and from a `roundRect` clip in 42 (ties, scales 1 and 2). Fix: one sampler and one count (then 0 and 0). An in-page Fizzygum sample did not change.

### Open thick strokes end square to the last CHORD, not to the curve

- [ ] **Open thick strokes end square to the last CHORD, not to the curve** (`StrokeGenerator._generateCaps` takes the first and last segments' tangents): the error is ≈ halfWidth·sin(chord angle / 2), 0.76 / 1.51 / 2.31 px at lw 20 / 40 / 60 on r 60 open arcs (0.25 with the curve's own tangents). Closed rings are fine.

### fillArc and friends drop sub-0.5 px segments near the apex

- [ ] **`fillArc` / `outerStrokeArc` / `fillStrokeOuter` drop sub-0.5 px segments near the apex** (`ArcOps`'s `segRight - segLeft < MIN_EDGE_LENGTH`, six sites): `fillArc` misses 24 pixel centres (worst 0.39 px) and `outerStrokeArc` 23 (worst 0.31); and the pie keeps the half-open rule on the circle where `fillCircle` contracts by `FILL_EPSILON`. Fizzygum calls none of them.

### Path curves are inscribed chords

- [ ] **Path curves are inscribed chords**: a filled curve misses pixel centres up to 0.25 px inside the true curve (arc fills: 1075 px; `fillStadium` ≤ 0.023 px). Exact crossings are prototyped (`R-B/swc`, "EC9"; a start on the active-edge filler in `R-B2/v-exact/swc`, its curve layer not begun); they want the curve-tag layer two items down.

### Stroke flattening ignores the line width

- [ ] **Stroke flattening ignores the line width, and a curve's vertices are stroked as user joins**: arcs flatten for their radius alone, Béziers at 0.25 USER units, and every flattened vertex takes the stroke's `lineJoin` (miter spikes, bevel facets). Design in `R-A2/NOTES.md`: ONE curve-tag layer feeding the exact fills above, a sweep join at a vertex inside one curve, and flattening for max(r, halfWidth) device px. On 54 arc cases the stroke misses 5169–9544 px today and 1244 with all three. Test draft `R-A2/tests-draft/0NN-thick-curve-stroke-is-its-sweep.js`.

### A FILL's pixel at an exact tie can depend on where the fill is drawn

- [ ] **A FILL's pixel at an exact tie can depend on where the fill is drawn** (strokes are anchored since the follow-ons: SWCanvas §9 entry 32). Fills, clips and `isPointInPath` keep absolute device arithmetic, so an integer-vertex fill decides a pixel centre exactly on its edge by rounding at its own magnitude (10 of 836 renders differ between positions, 1 px each; 34 of 3576 integer-edge tie crossings). A device frame for fills was built and REFUSED (`Fizzygum-tests/.scratch/arc-sw/U17/NOTES.md`): a caller that computes its vertices at the device position (`FolderIconAppearance`'s slant, before it drew from its own box) is re-rounded consistently by absolute arithmetic, and the frame made such fills depend on position. It wants the path stored translation-free first: the default path is kept in DEVICE space and mapped back through the inverse, which is inexact at non-dyadic scales (0.75, 1.5, 3), so two spellings of one shape disagree on ties there (fill 232 / clip 116 of 5376 cases at scale 3). The rotated `strokeRect` (`RectOpsRot`) is not framed either. Fizzygum runs at dpr 1 and 2 only.

### A semi-transparent rotated `strokeRect` blends some pixels twice

- [ ] **A semi-transparent rotated `strokeRect` blends some pixels twice** (`RectOpsRot._stroke_Rot_Alpha`: the two opposite edges of a pair share a role, so where they overlap they blend twice): 48 of 648 cases, 1171 px, every one a rect with min(w, h) < lineWidth. The axis-aligned direct `strokeRect` does the same on tiny rects (lw 6 on a 4×4 rect paints alpha 193 for a 0.5 colour).

### `Color` stores premultiplied 8-bit components

- [ ] **`Color` stores premultiplied 8-bit components**, so a translucent colour's straight components drift: up to 127 levels at alpha 1–15, 7 at 16–63, 1 at ≥ 128 (rgba(200,100,50,1/255) reads back (255,0,0,1)). Fix prototyped in `R-C2/N2c-keep/` (exact straight storage, and `copy` of a transparent colour gives 0,0,0,0; faster; a core test draft): over opaque destinations it then matches Chrome (0 of 1270 samples differ, main 526 at 1 level). Fizzygum: ±1 level, INFERRED ~30–40 tests per density to recapture (from a 62-test sample).

### `putImageData` of (255,0,0,0) keeps its RGB

- [ ] **`putImageData` of (255,0,0,0) keeps its RGB**, where Chrome reads back 0,0,0,0. Invisible (alpha 0).

### `xor` is binary on partial alpha

- [ ] **`xor` is binary on partial alpha** (it gives 0,0,0,0; off by up to 127–178 levels), and **`lighter` and the blend modes fall back to source-over** (off by up to 220). Fizzygum uses only source-over, source-in and destination-out.

### `PaletteAppearance`'s rings sit at a radius ± 0.5 about a pixel centre

- [ ] (Fizzygum) **`PaletteAppearance`'s rings sit at a radius ± 0.5 about a pixel centre** (~:45-46), which puts both ring edges ON pixel centres, so the 3.5 ring is asymmetric at dpr 1. An integer radius 3 is symmetric at dpr 1 and 2 under every variant (`R-B2/logs/ring-symmetry.log`). Cosmetic; a fix moves the palette's pixels (a recapture).

### A screenshot whose reference never LOADED reports as a pixel mismatch.

- [ ] **A screenshot whose reference never LOADED reports as a pixel mismatch.** `AutomatorPlayer.compareScreenshots`
      falls through to "FAIL - no screenshots like this one" when `candidates` is EMPTY, the same words as a real
      mismatch. Seen at the arc's closing gauntlet (machine at load 54, battery 7%): the `settle` leg's parallel run
      failed `SystemTest_macroLockedCompositeWidgetPreventsDrag` image_1, and the picture the leg kept
      (`FIZZYGUM_FAILURE_IMAGES_DIR`) is pixel-identical to the committed reference (its hash `a329fa14…` IS the
      reference's) — so no reference was there to match, on a shard that had needed a boot-storm reload. Fix: an empty
      candidate set gets its own failure line ("no reference loaded for X — its pixels were not compared"), still a
      failure, so the next one classifies itself as infra at a glance; then ask why a reference record can go missing
      mid-run (the loader proceeds on the reference scripts' onload — does an onerror go unreported?).

### visual-review-sample.txt names a test that no longer exists

- [ ] (no plan; found 2026-11-12 by the mixin-removal loop's U10 docs sweep) `docs/tooling/visual-review-sample.txt` (~:14) names `SystemTest_macroEditModeTogglePencilEyeGlyph`, which has no test directory, so `fg diffpage` refuses the sample as given — drop the name or replace it with the test that now covers the edit-mode toggle's glyph.

### A StretchableWidgetContainerWdgt keeps a stale @contents

- [ ] (no plan; found 2026-11-12 by the mixin-removal loop's U7 review, `Fizzygum-tests/.scratch/mixin-removal-loop/u7-relay/` LEDGER) A `StretchableWidgetContainerWdgt` keeps a stale `@contents` once its page leaves it — "Pick up", "Delete" or "Attach" on the page of a slide, a dashboard, a generic panel or a patch-programming window — and nothing clears it: each re-lay of the container moves the departed page back to its box (`_reLayout` through `_reLayoutWithOwnContents`, no parent check), drops in its margin go to that page, `add` and "Attach" forward to it, and the window's edit toggle writes its flag (the state U7 found Phase 6's early bar call still needed for). Medium, by reading (the edit-toggle half measured: `u7-relay/probe-a1.js`). Fix shape: the container hears its child leave and lets it go; what the emptied window then shows is a product decision.
