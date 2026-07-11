# Affine transforms for widgets (rotated / scaled windows) — design + phased execution plan

**STATUS (updated 2026-07-10): Phases 0–3 COMPLETE + COMMITTED (not pushed); Phase 4 IN
PROGRESS — 4A-1 (click-position mapping), 4C (property sugar), 4B (halo rotation), 4A-2
(drag-delta mapping), and 4B-universal (rotate ANY widget from its halo) COMPLETE + COMMITTED;
rough edges R1 (mouseMove-pointer mapping / paint-in-rotated-window), R3 (resize-after-rotate
clip, via the TrackingTransformFrameWdgt subclass), R2 (ephemeral-overlay rotation, via in-plane
highlight parenting + a resetWorld teardown fix), and R4 (slider + palette nonFloatDragging pointer
plane-mapping) COMPLETE + COMMITTED; 4D-1 (drop-IN, the smaller half of pick/drop) COMPLETE +
COMMITTED; 4D-2a (pick-OUT to desktop) COMPLETE + COMMITTED; 4D-2b (drop-back-INTO + unwrap-on-match),
4E (close-out) REMAINING. See the per-phase §6 banners for hashes + gate results
(they are the authority on status). Owner-gated; a standing
grant to "commit + continue while all gates pass" is in force as of 2026-07-10. Original design
was AUTHORED 2026-07-09 and hardened same day by an adversarial fresh-eyes pass (§10 facet
dossier; three correctness fixes folded into §4: composite damage-clip §4.2, plane-purity/two-
faces §4.11, flesh-out mapping order §4.5; SWCanvas drawImage is nearest-neighbor → Phase 0f).**

This document is self-contained: it embeds the history, the architectural facts it depends on
(with `file:line` anchors), the design decisions with their rationale, the rejected
alternatives (do NOT re-attempt those without new evidence), and a phased execution plan with
verification gates. It is written to be executable "cold" by an agent with no prior context.

> **Line-number convention.** All `file:line` anchors were verified on 2026-07-09 against the
> `Fizzygum` repo master (and the vendored `vendor/swcanvas/swcanvas.js` at pin
> `468c5f76d05540ff2e1325d24d516b808a8b1072`). Line numbers drift; every anchor is paired with
> a symbol name — if the line doesn't match, `grep -n "<symbol>" <file>` and trust the symbol.
> Never grep from the workspace root (`Fizzygum-builds/` is ~1.3 GB); scope to `src/`, `docs/`,
> or `vendor/`.

---

## §0 What we are building, in one paragraph

Widgets (and whole widget subtrees, e.g. windows) become rotatable and scalable, Squeak-style:
a **similitude** transform (translate + rotate + uniform scale, around an anchor point) can be
applied to any widget. The implementation is **NOT** the Lively/scene-graph "matrix on every
widget, local coordinates everywhere" architecture. It is the Squeak/CSS-compositor
architecture: the untransformed world keeps today's absolute-integer-rectangle machinery
untouched, and a transformed subtree is wrapped in a **`TransformFrameWdgt`** ("island") that
rasterizes its content un-rotated into a buffer and composites that buffer through the matrix
(one transformed `drawImage`). Transforms are **paint-only with respect to layout by default**
(CSS semantics), with two opt-in coupling modes. When no island exists in the world, no new
code runs on any hot path — gate: the full test suite must stay green and (for the
identity-transform case) screenshots must be verified pixel-identical.

---

## §1 History and provenance (why these decisions were made)

### 1.1 The 2015 "Zombie Kernel" notes (owner's private vault)

The owner drafted affine-transform designs in 2015–2017 (Evernote/vault notes tagged
`#fizzygumAffineTransforms`, chiefly `Affine-Transformations-in-Zombie-Kernel.md`). Their key
content, embedded here so the vault is not needed:

- Each morph gets a matrix + an **anchor point** ("rotating around an arbitrary anchor point"
  matters — clock hands rotate around an extremity, not the center; composite morphs rotate
  around the composite's center, not each child's own).
- **Damage strategy ranking** — of four candidate damage-area computations, the chosen winner
  was: *the screen-aligned rectangle containing the bounding box of the transformed damaged
  area, intersected with the clip*. (Exact clipped paths were rejected as too expensive;
  bare AABB-of-AABB intersection was rejected as too sloppy alone.)
- **Hit-test rejection ladder**: test the cheap screen-aligned AABB first; only on a hit,
  inverse-transform the *pointer* into the morph's coordinates and reuse the existing
  untransformed shape test unchanged. Transform the point, never the shape.
- **Migration ladder**: 1) make absolute screen position always fetched via a method;
  2) re-derive it via a chain of parent-local coordinates; 3) switch the chain to matrices;
  4) extend to rotation/scale.
- **"IDEALLY you'd like a system that does the simple steps if no-one in the world has used
  transformations."**
- A companion note warns that a *thin widget rotated 45°* has a pathologically large AABB
  (collision/damage efficiency worry) — still true, addressed in §4.7 and banked work §7.3.

Status of that plan against 2026 reality: step 1 is already true in today's code (`left()`,
`top()`, `position()` are thin accessors over `@bounds`); steps 2–3 (the
"switch-to-local-co-ordinates" conversion) are **rejected** by this plan (§5.1); the anchor
insight, damage ranking, and hit-test ladder are adopted essentially unchanged.

### 1.2 The 2026-07-09 brainstorm conclusions (owner + Claude)

1. **Island (wrapper) architecture chosen over per-widget local coordinates.** Decisive
   arguments: (a) every subsystem of Fizzygum is rectangle-native end-to-end (§3); (b) even a
   full matrix conversion would still need buffer-warp islands for text, because SWCanvas
   bitmap text cannot rasterize under a rotation (§3.7) — so islands are a strict subset of
   the Lively path, not an alternative; (c) systems that own their rasterizer (Squeak, Self,
   Morphic.js) all chose wrappers-or-nothing, while systems with per-node matrix APIs
   (CSS/WPF/Flash) *implement* them as islands (compositor layers) anyway.
2. **Transform tree and layer tree are orthogonal.** "Who has a matrix" (cheap scalars,
   eventually on any widget) is separate from "where cached rasters live" (a policy). The
   in-tree proof is `AnalogClockWdgt`: cached raster face (`src/apps/AnalogClockWdgt.coffee:98`,
   `drawImage faceBuffer`) + per-tick vector hands (`:254-279`, `context.rotate`). End-state
   abstraction ≈ Core Animation: a layer = content + mode (cached-raster | vector-replay) +
   rasterization scale + composite matrix. Phases 1–4 build the minimal shape (wrapper always
   buffers); the general policy engine is banked (§7.1).
3. **Scalars are canonical, matrices are derived.** Store `rotationDegrees`, `scale`, `anchor`
   as exact numbers; build the matrix on demand. Never extract angle/scale back out of a
   matrix (Lively's `Similitude.getRotation/getScale` needed epsilon-hacks precisely because
   the matrix was the source of truth and float error accumulated in the *model*). Fizzygum's
   model stays exact; floats appear only transiently at composite time.
4. **Transforms are paint-only for layout by default**, with opt-in coupling (§4.9). This is
   the single decision that separates working systems (CSS `transform` does not affect layout;
   Flutter's `Transform` is applied "during painting, not layout"; Core Animation constrains
   untransformed geometry) from the broken LivelyKernel demos (transformed bounds fed back
   into the layout solver → oscillation, drift, "crawling" morphs).
5. **SWCanvas already proves the core primitive.** Its own text renderer handles transforms by
   rendering glyphs un-rotated into an intermediate surface and blitting through the CTM
   (§3.7). The island does per-subtree what SWCanvas text already does per-string.
6. **Rotated text is accepted "Squeak-soft"** (bilinear resample of straight-rasterized text).
   Crisp-rotated-text on the native backend is banked (§7.5) and can never be matched
   pixel-for-pixel by SWCanvas, so it would be excluded from pixel tests.

---

## §2 How to build and test (verbatim operational facts)

- Preferred wrappers, runnable from any cwd (defined in the umbrella workspace, see the
  workspace root `CLAUDE.md`): `fg build` · `fg suite [--dpr=2|--browser=webkit]` ·
  `fg gauntlet` (build + dpr1 + dpr2 + webkit + apps) · `fg test <name>` ·
  `fg recapture <name>` · `fg apps` · `fg homepage`.
- Standard inner-loop verification: `cd Fizzygum && ./build_and_test.sh` (full build + all
  SystemTests headless, sharded, `speed=fastest`, dpr 1, ~1 min).
- The headless suite runs the world with **`?sw=1`** — the SWCanvas software backend — plus
  `&dpr=` and `&speed=` (`Fizzygum-tests/scripts/run-all-headless.js:112`). That is why one
  set of screenshot references is shared across Chrome and WebKit: SWCanvas is deterministic.
  Production default is the native canvas backend; the owner profiles under `?sw=1`.
- Macro SystemTests are the ONLY test style; author them with the `/author-macro-test` skill
  (in Claude Code). Gotchas in §8.
- Never hand-edit `Fizzygum-builds/`; one class per file, filename == class name; `nil` means
  `undefined`.

---

## §3 Current-architecture facts this plan depends on (verified 2026-07-09)

Each fact below is load-bearing; if an executor finds one no longer true, STOP and re-assess
the affected section before proceeding.

### 3.1 Coordinates: absolute, integer, axis-aligned; no local frames

- Geometry is one `Rectangle` per widget in **absolute world/screen logical pixels**:
  `src/basic-widgets/Widget.coffee:59` (`bounds: nil`), init at `:344`. Accessors are thin
  wrappers (`left/top/right/bottom/center` at `:669-694`, `position: -> @bounds.origin`
  at `:913`).
- Parent→child is a translation baked into each child's absolute bounds: `_applyMoveByBase`
  (`Widget.coffee:1271`) translates `@bounds` and recurses `child.__commitMoveBy delta`
  (`:1287`) into every descendant.
- `Point::toLocalCoordinatesOf` is plain subtraction, no matrix
  (`src/basic-data-structures/Point.coffee:122`).
- Placement is integer: `_moveToNoSettle` rounds and clamps (`Widget.coffee:1361`); see
  `docs/integer-pixel-placement-and-sizing.md` for the whole invariant. Fractional *desired*
  geometry lives separately (`desiredExtent`/`desiredPosition`, `Widget.coffee:74-75`).

### 3.2 Paint: broken-rect repaint; rect-intersection clipping; back buffers blitted axis-aligned

- Damage: `changed()` (`Widget.coffee:2369`) / `fullChanged()` (`:2414`) queue the widget on
  `world.widgetsWithMaybeChangedPaintBounds` / `...FullPaintBounds`; rects are computed later
  as `clippedThroughBounds()` (`:1196`) / `fullClippedBounds()` (`:1160`), both intersected
  with `clipThrough()` (`:1223`) which walks up to `firstParentClippingAtBounds`, else world.
- The world merges axis-aligned damage rects: `broken` (`src/WorldWdgt.coffee:215`),
  `pushBrokenRect` (`:772`), `mergeBrokenRectsIfCloseOrPushBoth` (`:790`),
  `fleshOutBroken` (`:863`), `fleshOutFullBroken` (`:914`), consumed in `updateBroken`
  (`:1135`, paint call at `:1174`).
- Recursive paint is back-to-front: `fullPaintIntoAreaOrBlitFromBackBuffer`
  (`Widget.coffee:2003`, content recursion at `:2051`), leaf paint via
  `paintIntoAreaOrBlitFromBackBuffer` (`:401`) → the widget's `Appearance`.
- **No ctx transforms are used for compositing.** Physical pixels come from manual
  `* ceilPixelRatio` multiplication + `Math.round` (`calculateKeyValues`,
  `Widget.coffee:1815`; `paintRectangle` `:1877`). The only `translate/scale/rotate` calls in
  `src/` draw a widget's OWN buffer content (icons `src/icons/IconAppearance.coffee:99-101`,
  `src/StretchableCanvasWdgt.coffee:62,126`, clock hands `src/apps/AnalogClockWdgt.coffee`).
- Scroll-frame clipping is **rectangle intersection of paint areas**, not `ctx.clip()`:
  `src/mixins/ClippingAtRectangularBoundsMixin.coffee:169` narrows `dirtyPartOfFrame` and
  passes it down. (`clipsAtRectangularBounds: true` at `:9`.)
- Back-buffered widgets (`src/mixins/BackBufferMixin.coffee`) blit equal-extent, integer,
  axis-aligned: `paintIntoAreaOrBlitFromBackBuffer` (`:98`), the `drawImage` at `:116`.
- The one existing "drawImage rides a context translate" precedent (needed by §4.4):
  `src/apps/AnalogClockWdgt.coffee:95-98`.

### 3.3 DPR: one global integer scale, hand-threaded

`window.ceilPixelRatio = Math.ceil(devicePixelRatio)` (`src/boot/globalFunctions.coffee:190`;
forcing via `?dpr=` at `:183-188`). Applied by manual multiplication in ~25 files and by
`useLogicalPixelsUntilRestore` (= `@scale ceilPixelRatio, ceilPixelRatio`,
`src/boot/extensions/CanvasRenderingContext2D-extensions.coffee:5-6`) for buffers. There is no
per-widget or world zoom anywhere.

### 3.4 Hit testing: AABB containment + per-pixel alpha, both translation-only

- Entry: `topWdgtUnderPointer` (`src/ActivePointerWdgt.coffee:96`) — predicate is
  `m.clippedThroughBounds().containsPoint(@position()) and ... (not m.isTransparentAt(@position()))`.
  A second predicate-descent use exists at `src/basic-widgets/Widget.coffee:323`.
- The descent itself: `TreeNode::topWdgtSuchThat` (`src/basic-data-structures/TreeNode.coffee:546`)
  — depth-first, children tested top (last in array) to bottom, then self. The *predicate*
  closes over the screen point; the descent does not thread a point. (This shapes the fix:
  change what point the predicate tests, not the descent — §4.6.)
- Per-pixel alpha: `BackBufferMixin.isTransparentAt` (`:75`) → `getPixelColor` (`:85`) maps via
  `toLocalCoordinatesOf` (subtraction) and reads `getImageData(point * ceilPixelRatio, ...)`.

### 3.5 Occlusion culling: axis-aligned containment (landed 2026-07-09)

`WorldWdgt.occlusionCullingEnabled` (`src/WorldWdgt.coffee:213`);
`_paintedFromFrontmostCoverer` (`:724-752`) scans world children front-to-back testing
`child.opaqueCoveredRect().containsRectangle(dirtyPart.expandBy 1)` — all AABBs.
`Widget.opaqueCoveredRect` (`Widget.coffee:1937`) already returns `nil` for every
BackBufferMixin widget and all custom painters (`:1944`), for alpha < 1, and for
non-rectangular appearances. See `docs/occlusion-culling.md`.
**Consequence: a buffered island automatically returns nil — occlusion stays correct with
zero changes, at the cost of no culling behind transformed widgets (banked recovery §7.3).**

### 3.6 Text: whole-string `fillText` into an axis-aligned back buffer

`src/basic-widgets/StringWdgt.coffee:734-781` and `src/basic-widgets/TextWdgt.coffee:506,547`:
`backBufferContext.font = @buildCanvasFontProperty()`, one `fillText` per string/line, then
the buffer is blitted axis-aligned via BackBufferMixin. No glyph-atlas of Fizzygum's own on
the native path; measurement is cached via `world.canvasContextForTextMeasurements`
(`StringWdgt.coffee:571-580`).

### 3.7 SWCanvas backend: full AA canvas-2D incl. transforms and path clip; text via intermediate-blit

- Vendored at `vendor/swcanvas/swcanvas.js` (pin file `vendor/swcanvas.pin`); selected by
  `?sw=1` → `window.FIZZYGUM_USE_SWCANVAS` (`globalFunctions.coffee:181`); single factory
  choke point `HTMLCanvasElement.createOfPhysicalDimensions`
  (`src/boot/extensions/HTMLCanvasElement-extensions.coffee:35,45-49`); prototype extensions
  copied over by `installSWCanvasExtensions`
  (`src/boot/extensions/SWCanvasElement-extensions.coffee:142`).
- Full affine machinery: `class Transform2D` (`swcanvas.js:1088`); context `rotate`/`transform`/
  `setTransform`/`scale`/`translate`/`resetTransform`; scanline `PolygonFiller` with
  nonzero/evenodd and a 1-bit `ClipMask` stencil (`swcanvas.js:18607,18617`); anti-aliased
  sub-pixel coverage for rotated fills.
- **Raw `BitmapText.drawTextFromAtlas` ignores ALL context transforms** (comment at
  `swcanvas.js:4820`, transform reset at `:4922`). BUT the context-level
  `TextRenderer.fillText` (`swcanvas.js:23559`) handles this: fast path when the CTM is
  axis-aligned uniform scale == atlas density with integer translate
  (`_isDirectBlitEligible`); **slow path for rotation/skew/scale≠density**: compute exact ink
  box (`BitmapText.computeInkBoundingBox`, `swcanvas.js:~4718`), render un-rotated into an
  intermediate surface, then `drawImage` through the CTM — "rotation/scale are honoured".
  This is the same render-straight-then-warp primitive the island uses, already exercised
  in-tree.
- Atlases ship only Arial/Times/Courier in a limited size range with size snapping
  (`SWCanvasElement-extensions.coffee:13-23,179-189`) — relevant to zoom crispness (§7.4).
- Deterministic trig: cross-engine trig differs by ~1 ULP. The fdlibm-based shim is a **Fizzygum-
  side global, `DetTrig`** (`{sin, cos, ...}`, ~345 lines, +−×÷/sqrt only; see §0-R 0b), which the
  boot sequence **installs over `Math.*` BEFORE SWCanvas renders** — it is NOT "carried by" or
  internal to SWCanvas (that earlier wording was wrong; corrected per §0-R). **Any Fizzygum-side
  matrix construction MUST call `DetTrig.cos/sin` explicitly** (`TransformSpec.coffee:98`) — relying
  on `Math.*` being patched is fragile — or rotated references will differ across engines. (Past
  campaign: memory note "SWCanvas deterministic trig".)

### 3.8 Existing matrix code (for reference, NOT for reuse as-is)

`src/fizzytiles/LCLTransforms.coffee` is a 4×4 column-major 3D matrix stack owned by the
Fizzytiles SW3D widget. Do not reuse it for 2D similitudes (wrong shape, wrong ownership;
it is also a candidate for deletion in `docs/accidental-complexity-reduction-plan.md`). The
2D math needed here is ~40 lines and is fully specified in §4.3.

---

## §4 The design

### 4.1 Two structures, one new class

- **Transform spec** (`TransformSpec`, new small class): scalars `rotationDegrees` (float,
  canonical), `scale` (float > 0), `anchor` (default: center of the slot box; else a `Point`
  in slot coordinates), `claimsSpace` (`'slot' | 'footprint' | 'sweep'`, default `'slot'`).
  Matrix is derived, never stored as truth (§1.2 D3).
- **`TransformFrameWdgt`** (the island): a widget that owns exactly one content subtree and a
  `TransformSpec`. Its own `bounds` (integer, axis-aligned, absolute — unchanged Fizzygum
  geometry) is the **slot box**: the untransformed footprint, and what layout sees in `'slot'`
  mode. It declares `clipsAtRectangularBounds: true` so `clipThrough()` terminates inner
  damage at it (fact 3.2), and it clips content to the slot box by construction (the buffer
  edge is the clip).
- **Virtual plane**: the content subtree keeps ordinary absolute Fizzygum coordinates *as if
  the island were untransformed* — i.e. the virtual plane coincides with the screen plane
  exactly when the transform is identity. Children of the island are laid out, settled,
  serialized, and hit-tested with completely unchanged machinery inside this plane.

### 4.2 Compositing

Per repaint of a screen damage rect that intersects the island's **outer AABB** (§4.3):

1. Refresh the island buffer: replay any accumulated virtual-plane dirty rects by painting the
   content subtree into the island's back buffer (children's normal
   `fullPaintIntoAreaOrBlitFromBackBuffer` with the buffer context pre-translated by
   `(-slotLeft * ceilPixelRatio, -slotTop * ceilPixelRatio)`; the clock precedent (fact 3.2,
   last bullet) shows blits ride a context translate).
2. Composite — the exact sequence is load-bearing (see facet dossier §10.2):
   `ctx.save()`; `ctx.clipToRectangle(damageRect ∩ screenFootprint)` (path clip — MANDATORY,
   see below); `ctx.setTransform(...)` to (device matrix) × (island matrix);
   `drawImage(buffer, srcSubRect → dstSubRect)`; `ctx.restore()`.
   - **Why the clip is mandatory (correctness, not hygiene):** the repaint contract is that
     painting a broken rect never touches pixels OUTSIDE it — widgets in front are only
     repainted inside the rect, so any spill paints the island OVER front content that isn't
     being repainted this cycle (z-order corruption). Axis-aligned widgets satisfy this via
     rect-intersected `drawImage`/`fillRect` (`calculateKeyValues`); a transformed `drawImage`
     cannot express it with src/dst rects, so a real `clip()` is required. Both backends
     support it (`clipToRectangle`,
     `src/boot/extensions/CanvasRenderingContext2D-extensions.coffee:17-25`; SWCanvas
     `ClipMask` stencil, `swcanvas.js:18617`).
   - **Sub-rect optimization:** inverse-map the damage rect into the virtual plane, take the
     AABB (+1px pad), and composite only that buffer sub-rect — avoids warping the whole
     buffer for a small damage.
   - **Identity fast path**: if `spec.isIdentity()`, skip setTransform/clip entirely and use
     the exact BackBufferMixin-style equal-extent integer blit. GATE (Phase 1): a world
     containing an identity island must produce screenshots pixel-identical to the same world
     without the island (to be verified, not assumed).
   - **Scale-only fast path** (Phase 1): pure uniform scale needs no `setTransform` — a
     `drawImage` with unequal src/dst rects suffices, every mapped rect stays axis-aligned,
     and the damage clip is expressible as plain rect intersection of the dst rect.
   - **Shadow pass:** when called with `appliedShadow` (the unified shadow mechanism repaints
     content through a context translate with a shadow alpha —
     `fullPaintIntoAreaOrBlitFromBackBufferJustShadow`, `Widget.coffee:2035`), the island runs
     the SAME composite with `globalAlpha = appliedShadow.alpha * @alpha` (the BackBufferMixin
     contract, `BackBufferMixin.coffee:113`). A warped faint copy at the shadow offset IS the
     correctly rotated shadow — no quad-silhouette special case needed (supersedes earlier
     drafts of §4.8).
3. Seam rule (why subtrees must buffer): compositing children individually under a rotated CTM
   anti-aliases each child's edges independently → hairline cracks where children abut.
   Rasterize-straight-then-warp is seam-free. Vector-replay under the matrix is only safe for
   *overlay* content (clock hands) — banked policy work, §7.1.

### 4.3 The matrix math (complete spec — do not improvise)

Canvas 2D convention: matrix `(a, b, c, d, e, f)` maps `x' = a·x + c·y + e`,
`y' = b·x + d·y + f`.

Given slot box `B` (integers), anchor `A` (defaults to `B.center()`), angle `θ` (radians,
from `rotationDegrees`), scale `s`:

```
forward:  p' = A + s · Rot(θ) · (p − A)
  a =  s·cos θ     c = −s·sin θ     e = A.x − s·(cos θ · A.x − sin θ · A.y)
  b =  s·sin θ     d =  s·cos θ     f = A.y − s·(sin θ · A.x + cos θ · A.y)

inverse:  p = A + (1/s) · Rot(−θ) · (p' − A)      (same closed form with s→1/s, θ→−θ)
```

- `cos/sin` MUST come from the deterministic (fdlibm) implementation shared with SWCanvas
  (Phase 0 task 0b).
- **Rect mapping (damage, footprint):** transform the 4 corners of the rect, take
  `minX/minY/maxX/maxY`, then `Math.floor` the mins, `Math.ceil` the maxes, then
  `expandBy 1` (AA coverage bleeds < 1px past the geometric edge). Result is an integer
  axis-aligned `Rectangle` — safe to feed into the existing broken-rect machinery unchanged.
- **Identity test:** `rotationDegrees % 360 == 0 and scale == 1` (exact comparison on the
  canonical scalars — this is why scalars, not matrices, are the source of truth).
- **Sweep bound (for `claimsSpace:'sweep'`):** radius `r = max over corners c of |c − A|`;
  the claimed box is the square of side `ceil(2r)` centered on `A`, intersected with nothing
  (it may exceed the slot box). For `A = center`, `2r = ceil(sqrt(w² + h²))` (the diagonal).

### 4.4 Buffer management

Model on `BackBufferMixin` (fact 3.2) but with a custom composite step (§4.2): buffer of
physical size `slotExtent × ceilPixelRatio` (Phase 1; rasterization-scale folding for crisp
zoom is §7.4), a validity checker keyed on slot extent + content version, and a list of
virtual-plane dirty rects accumulated between composites. Drop the buffer when the island
returns to identity AND memory matters (v1: keep it; eviction policy is banked §7.1).

### 4.5 Damage routing (the one world-side hook)

Inner widgets damage themselves exactly as today; because the island
`clipsAtRectangularBounds`, their computed damage rects are already intersected down to the
island's slot box (fact 3.2; and ONLY the slot box — see the plane-purity rule, §4.11). The
single new step: **when the world fleshes out a damage rect whose widget's parent chain
crosses one or more islands, map the rect to screen space through each island's forward
matrix (corner-map, §4.3) before pushing it into `world.broken`**, and also record the
pre-mapping virtual rect on each crossed island as a buffer-dirty region.

Implementation shape and ordering (verified against the flesh-out code, fresh-eyes pass
2026-07-09 — see §10.2):

- Add `Widget::mapRectToScreen(r)` — walks `@parent` chain; for each `TransformFrameWdgt`
  with non-identity spec, `r = island.spec.mapRect(r)`; after the outermost island, intersect
  with that island's ancestor screen clips (§4.11). Identity chain returns `r` unchanged
  (fast path: a cached "am I inside any non-identity island" flag, invalidated on
  reparent/spec change).
- Both flesh-out lanes need it: `fleshOutBroken` (`src/WorldWdgt.coffee:863`, uses
  `clippedBoundsWhenLastPainted` + `clippedThroughBounds()`) and `fleshOutFullBroken`
  (`:914`, uses `fullClippedBoundsWhenLastPainted` + `fullClippedBounds()`). Both the
  *source* (last-painted snapshot) and *destination* (current) rects are per-widget and
  virtual for island descendants — map BOTH.
- **Map BEFORE any merge/dedupe.** `mergeBrokenRectsIfCloseOrPushBoth` (`:790`) and the
  hierarchy dedupe (`checkARectWithHierarchy` `:803` /
  `rectAlreadyIncludedInParentBrokenWidget`) must only ever see post-mapping screen rects;
  mixing planes in the merge logic silently drops or bloats damage.
- Shadow accounting is already handled: both lanes do `.expandBy(1).growBy @maxShadowSize`
  (`:879,896,927,938`) — apply that AFTER mapping (the shadow offset is a screen-space
  phenomenon).
- Clean invariant (document in code): **buffer content depends only on virtual content; the
  matrix affects only compositing.** A transform change therefore damages the SCREEN
  (`oldFootprint ∪ newFootprint`) but never dirties the buffer; a content change dirties the
  buffer region AND (via mapping) the screen. A slot-box RESIZE dirties both (the buffer is
  reallocated).
- **⚠ HOW `oldFootprint ∪ newFootprint` is achieved (do NOT "fix" this):** the implementation does
  NOT push two explicit rects. `_transformChangedNoSettle` (`TransformFrameWdgt.coffee`) queues a single
  `fullChanged()`; the OLD footprint rides the **last-painted-snapshot lane**
  (`fullClippedBoundsWhenLastPainted`, frozen in screen coords at paint time by
  `recordDrawnAreaForNextBrokenRects`) as the flesh-out SOURCE rect, and the NEW footprint is the current
  bounds as the DESTINATION rect. This equivalence is now **trace-proven** (2026-07-10, §7.5 Bug C forensics),
  including the hard **destroy-in-same-batch** case (de-tilt → dematerialize → `_destroyNoSettle` all in one
  NoSettle batch): the instrumented `fleshOutFullBroken` showed both the island and its content push the
  correct rotated source rect. So a future reader who notices the "deviation" from an explicit `old ∪ new`
  push must NOT add redundant damage to this proven path.

### 4.6 Hit testing and pointer events

The descent (`TreeNode::topWdgtSuchThat`, fact 3.4) is untouched. The *predicates* change:
everywhere a predicate tests a widget's bounds/pixels against the raw screen pointer
(`src/ActivePointerWdgt.coffee:96-101`, `src/basic-widgets/Widget.coffee:323`), test instead
against `w.screenPointToMyPlane(screenPoint)`:

- `Widget::screenPointToMyPlane(p)` — walk own parent chain root-ward, apply each crossed
  island's **inverse** matrix (outermost first); identity chain returns `p` (same cached flag
  as §4.5). The 2015 rejection ladder emerges naturally: a widget inside an island is only
  reached after the descent enters the island's subtree, and the island itself is tested on
  its outer AABB first.
- **Exactness is free in virtual space** (fresh-eyes finding, §10.4): the predicate
  `m.clippedThroughBounds().containsPoint(m.screenPointToMyPlane(p))` is an EXACT quad test —
  in the virtual plane everything is axis-aligned, so no polygon/point-in-quad code exists
  anywhere in the system. Corner fall-through (click inside the outer AABB but outside the
  rotated quad reaches the widget behind) emerges automatically, including for
  `noticesTransparentClick` widgets whose stage-1 rect test is their only test.
- `TransformFrameWdgt` refines its own containment the same way: outer-AABB pre-filter →
  inverse-map → point in slot box. Per-pixel transparency of the island comes for free: its
  buffer is sampled at the inverse-mapped point.
- **Per-event memoization:** a descent tests many widgets; cache each island's inverse-mapped
  pointer keyed on a pointer-event stamp so chains aren't recomputed per candidate. (Matrix
  mutations happen in the step/input phase, before repaint — hit tests within one world cycle
  see one consistent matrix; see §10.9 ordering note.)
- `isTransparentAt`/`getPixelColor` (fact 3.4) work unchanged *provided* the point handed to
  them is plane-mapped — audit the call chain from the changed predicates. Inverse-mapped
  points are floats: `Math.floor` before `getImageData` (`BackBufferMixin.coffee:88`
  multiplies by `ceilPixelRatio` — floor AFTER the multiply).
- Everything that converts a plane point back to screen (opening a menu at a widget, caret
  screen position if ever needed) uses the forward mapping `localPointToScreen`.
- **Halo / handle model (DESIGN DECISION — inside-attachment survives intact, and the island
  architecture rewards it):** resize/move handles attach INSIDE their target (corner-internal
  children, `HandleWdgt.defaultLayoutSpecWhenAddedTo` — the owner's pre-transform 2015 decision so
  handles "belong to" the widget, move with it, and clip with it). Under islands that config is the
  free one: a handle is **in-plane content** → painted into the island buffer → composited through
  the matrix, so it lands at the widget's TRANSFORMED corner on screen automatically (the
  Figma/PowerPoint selection frame that follows a rotated shape — no new code). Hit-testing is free
  too (it is a virtual-plane widget; the Phase-1 inverse-mapped predicate tests it exactly), and it
  clips with its widget (the buffer edge is the clip). The Squeak-style **world-overlay halo is
  REJECTED** here: it would need explicit re-positioning on every transform change and float
  un-clipped over frames — re-introducing exactly what inside-attachment avoids. Two visual
  side-effects to consciously ACCEPT for v1 (both Squeak-consistent, both compensable later WITHOUT
  changing the attachment model): (1) handles **scale with the island** (double-size at scale 2, tiny
  at 0.5) — the design-tool "screen-constant handle" compensation is local (a handle sizes its own
  extent by the inverse accumulated ancestor scale) and is BANKED (§7.9), not built now; (2) handle
  glyphs rotate and are nearest-neighbor-chunky on SW (fine under the 0f verdict). The one genuinely
  missing piece is **4A-2**: `nonFloatDragging` computes `pos − startOffset` in screen space and
  writes it into `@target`'s virtual-plane bounds — deltas are VECTORS, so they map through the
  inverse of the LINEAR PART ONLY of the accumulated matrix. That is exactly why Phase 1 guards
  handles OFF inside non-identity islands (`Widget.coffee` ~:3145); when 4A-2 lands the mapping AND
  lifts the guard, inside-attachment works end-to-end (drag the bottom-right handle of a widget in a
  30° island → the visually-correct edge moves along the rotated axes).
- **Cross-plane actors** (widgets that read/write ANOTHER widget's geometry — §10.1): `HandleWdgt`
  (above); `CaretWdgt` does geometry math against `@parent`/`@target`
  (`src/basic-widgets/CaretWdgt.coffee:223-274`) — expected in-plane (it is parented next to
  its target), VERIFY in the Phase 1 audit. Menus/prompts open at the hand position (screen
  plane — fine); audit any open-at-widget paths. There is NO visual line-connector widget in
  the codebase ("Connector" is the dataflow method-lane naming, e.g.
  `_<action>Connector` — `src/dataflow/DataflowEngine.coffee:27`), so no line-endpoint
  mapping problem exists.
- **Phase 1 scope cut:** islands refuse to be drop targets (reject in the
  `dropTargetFor`/drag-embed resolution path, entry near `src/ActivePointerWdgt.coffee:164,180`)
  so pick/drop coordinate rewriting can wait until Phase 4. Dragging the island itself works
  (it is an ordinary widget with ordinary slot bounds).

### 4.7 Known accepted inefficiencies (v1)

- Rotated damage AABBs over-approximate (worst: thin widget at 45° — the 2014 note's case).
  Correctness is unaffected; repaint area grows. Quad-aware rejection is banked (§7.3).
- No occlusion culling behind non-identity islands (fact 3.5). Regions topped by a rotated
  widget repaint as the whole world did before 2026-07-09's occlusion arc.
- SW-backend warp cost: a transformed `drawImage` is per-pixel inverse-map + bilinear sample —
  it cannot use the `data32.fill` opaque-span fast path. Estimate (UNMEASURED — verify per
  §9): 3–10× per painted pixel vs. axis blit. Native backend composites on GPU.

### 4.8 Shadows — the unified mechanism already produces rotated shadows

(Rewritten after the fresh-eyes code pass.) Fizzygum has ONE unified drop-shadow mechanism
(standing rule: never reintroduce per-part shadows), and it works by REPAINTING the widget's
content through a context translate with `appliedShadow` set
(`fullPaintIntoAreaOrBlitFromBackBufferJustShadow`, `Widget.coffee:2035-2043`; back-buffered
widgets then blit with `globalAlpha = appliedShadow.alpha * @alpha`,
`BackBufferMixin.coffee:113`). The island simply honors `appliedShadow` in its composite
(§4.2 shadow pass): the result is a warped, faint copy at the shadow offset — i.e. a
**correctly rotated shadow, for free, inside the unified mechanism**. Damage accounting
already grows all broken rects by `world.maxShadowSize` (§4.5). No quad-silhouette special
case, no suppression fallback. Phase 2 adds a macro that shows a rotated island's shadow.

### 4.9 Layout coupling — `claimsSpace` (the Lively-breakage firewall)

The mode answers ONE question the layout engine already asks every child: *what extent do you
claim?* — plus one invalidation rule. The transform machinery is identical across modes.

| mode | extent reported to parent layout | layout dirtied on transform change? | intended use |
|---|---|---|---|
| `'slot'` (default) | untransformed slot box | **never** (damage only) | animation, decoration — CSS semantics; the document under a spinning title stays rock-still |
| `'footprint'` | corner-mapped integer AABB of the slot box (§4.3) | yes — like a resize, one settle per change | statically rotated figures the text should flow around; exact & stable at 90° multiples (Flutter `RotatedBox` equivalent) |
| `'sweep'` | anchor-aware circumscribed square (§4.3) | once, on entering the mode / changing anchor·extent | continuous spinners inside layouts — reserve the swept circle, then never reflow |

- The knob is **per-widget**, a field of `TransformSpec` — it must travel and serialize with
  the widget (drag a rotated plot to another document ⇒ same behavior). Containers never
  choose a child's mode (an optional container-level "freeze: treat all as slot" veto is
  banked; a global exists only as the feature kill-switch, §4.12).
- **FORBIDDEN, permanently:** deriving the untransformed extent FROM a transformed constraint
  (e.g. solving `w·cosθ + h·sinθ = W` for `w`). It is a cyclic constraint (shrinking `w`
  rewraps text, changing `h`, changing the AABB) with no convergence guarantee — this is the
  documented root cause of the LivelyKernel layout breakage. The width constraint always
  binds the untransformed content width in every mode; modes only change how much *space* is
  claimed from siblings.
- **Claimed-box = extent AND offset** (fresh-eyes finding, §10.8 — a weaker executor WILL
  botch this if unspecified): for `'footprint'`/`'sweep'`, the value handed to layout is not
  just an extent but a pair `{claimedExtent, slotOffsetWithinClaimedBox}` where
  `slotOffset = slotOrigin − claimedBoxOrigin` (both computable from slot EXTENT + θ + s +
  anchor alone — the similitude AABB is translation-invariant, so there is NO
  position→extent feedback). When layout places the claimed box at `P`, the slot box is
  committed to `P + slotOffset` (integer-rounded). Reporting extent alone produces visually
  offset widgets.
- **Stretch semantics:** stretch constraints ALWAYS bind the slot extent (untransformed
  content width/height). `'footprint'`/`'sweep'` children are measured-not-stretched with
  respect to their claimed box — if a stack stretches children to container width, the SLOT
  width stretches and the claimed AABB is whatever it then is (possibly wider than the
  container → overflow/clipping per the container's semantics). Never invert (see FORBIDDEN
  below).
- Anti-drift rule: layout owns the slot box position; the anchor is defined relative to the
  slot box; rotation never feeds back into position. (Storing the transformed AABB's origin
  as "the position" is the classic crawling-widget bug — never do it.)
- Wire-up point: the extent-negotiation path parents already use (the
  `preferredExtentForWidth` family — see `docs/` pure-measure and layout-rename docs; layout
  method family names: `_reLayout`, `_reLayoutSelf`, `_reLayoutChildren`). `'footprint'`
  transform changes must invalidate layout through the SAME entry a resize uses — find it by
  reading what `_applyOwnArrangedWidth/Height` / resize handles call; do not invent a new
  invalidation path.

### 4.10 Serialization / duplication

Serialize the scalars (`rotationDegrees`, `scale`, `anchor`, `claimsSpace`) — never the
matrix, never the buffer. Any cached matrix/buffer on `TransformSpec`/`TransformFrameWdgt`
must be registered as a derived value for deepCopy (**the Fizzytiles lesson: deepCopy needs
the `rebuildDerivedValue` stamp — `@serializationTransients` alone is NOT sufficient**; grep
`rebuildDerivedValue` in `src/` for the pattern). Content subtree serializes unchanged (it is
ordinary widgets in ordinary coordinates). Follow
`docs/serialization-duplication-reference.md` for where ser/deser details are documented.

### 4.11 Plane purity: the island's two faces (fresh-eyes CORRECTNESS finding — read before Phase 1)

Clip chains do not commute with transforms. Stock semantics build every widget's
`clipThrough()` as own-box ∩ the whole ancestor clip chain in ONE plane
(`Widget.coffee:1223-1240`). With an island on the chain, an ancestor's SCREEN clip rect
corresponds to a rotated quad in the island's VIRTUAL plane — numerically intersecting it
into a descendant's virtual clip rect can wrongly cut virtual damage that actually maps into
visible screen area (missed repaints: a correctness bug, not an inefficiency). Therefore the
island presents **two faces**:

- **To its descendants** (`clipThrough()` as consumed by children via
  `firstParentClippingAtBounds`): return the **slot box ONLY** — a plane-pure clip terminal.
  Ancestor screen clips are deliberately NOT intersected in.
- **To the outer world** (`clippedThroughBounds()` / `fullClippedBounds()` — what its parent
  merges, what flesh-out uses when the island itself is queued, what the hit-test AABB
  pre-filter sees): return the **screen footprint** — `mapRect(slot box)` (resp. the mapped
  AABB of the subtree's merged virtual full bounds) ∩ the ancestor screen clip chain. This is
  larger than the slot box when rotated (a rotated rect's corners overhang its own slot —
  "ink overflow"); ancestors only ever consult the island's overrides, never grandchildren
  directly (`fullClippedBounds` merges through the recursion, `Widget.coffee:1160-1186`), so
  overriding at the island is sufficient.
- Ancestor screen clips are applied to inner damage AFTER mapping, inside
  `mapRectToScreen` (§4.5) — clipping in the correct plane.

⚠ **SLOW-oracle twins.** The clip/bounds caches have de-circularized SLOW mirrors
(`SLOWclipThrough`, `SLOWclippedThroughBounds`, `SLOWfullClippedBounds`,
`Widget.coffee:1059-1083`) compared against the cached results whenever
`world.doubleCheckCachedMethodsResults` is on — the bounds-cache campaign's standing lesson
is that SLOW twins must be overridden IN LOCKSTEP. Every island override above MUST override
its SLOW twin identically or the coherence gate will alert/`debugger` at first use.

Identity islands keep stock single-plane behavior bit-for-bit (virtual ≡ screen), preserving
the identity-bypass gate.

### 4.12 Feature flag

`WorldWdgt.affineTransformsEnabled` (default: true once Phase 2 lands; style precedent:
`occlusionCullingEnabled`, `src/WorldWdgt.coffee:213`). When false, `TransformSpec` setters
clamp to identity. This is a kill-switch, not a semantics switch.

---

## §5 Rejected alternatives — do NOT re-attempt without new evidence

1. **Full Lively conversion (parent-relative coordinates + matrix on every widget).**
   Rejected 2026-07-09 by cost/risk analysis: it changes the meaning of `bounds` across ~470
   files and forces re-derivation of the settle engine, `geometryVersion` caches, broken-rect
   merging, occlusion culling, per-pixel hit sampling, and serialization — and it STILL needs
   buffer-warp for text (fact 3.7), so it is a superset of this plan, not an alternative.
   The islands built here do not foreclose it; they would become its compositor layer if it
   were ever revisited. The vault stub `switch-to-local-co-ordinates` is superseded by this
   decision.
2. **Render-through rotation for composite subtrees** (apply the CTM and let children
   composite individually). Rejected for correctness: independent per-child AA edges under a
   rotated CTM produce hairline seams at abutting edges; also re-rasterizes content every
   frame during rotation animation. Acceptable only for overlay content under the banked
   policy engine (§7.1).
3. **Matrix as the canonical stored transform.** Rejected: accumulating float error in the
   model (see Lively `Similitude` epsilon extraction); breaks exact identity tests and
   deterministic serialization. Scalars are canonical (§1.2 D3).
4. **Layout constraints binding transformed bounds** (solving untransformed extent from a
   transformed constraint). Rejected as ill-posed — see §4.9 FORBIDDEN.
5. **Per-string/per-glyph shadow or text special-casing under rotation.** The unified shadow
   rule stands (§4.8); text rotates as part of the island buffer, period (native
   crisp-rotated-text is banked §7.5 and pixel-test-excluded).

---

## §6 Phased execution plan

General rules for every phase: work in `Fizzygum/src/**` (+ tests in `Fizzygum-tests/`);
gates are `fg gauntlet` (196+ tests × dpr1/dpr2/webkit, all green, zero offenders) and
`fg homepage`; new behavior gets macro tests authored via `/author-macro-test`; do not
commit/push — present a summary and wait for the owner (standing rule). Phase order is
mandatory; each phase is independently shippable and ends at a resting point.

### Phase 0 — evidence spike (no product code; results appended to this doc as §0-R)

- **0a. Transformed-drawImage determinism + edge behavior.** Scratch harness (use the session
  scratchpad, not the repos): with the vendored `swcanvas.js`, draw a deterministic pattern
  into a surface, `setTransform` to rotations {15°, 30°, 45°, 90°} (+ one uniform scale
  1.7×), `drawImage` **inside a `clip()`** (the §4.2 composite sequence exactly), SHA-256 the
  pixel buffer. Run the identical script headless in Chrome AND WebKit (Puppeteer/Playwright
  are set up in `Fizzygum-tests`). PASS = identical hashes per angle across engines. Also
  INSPECT: are the rotated quad's edges antialiased (coverage) or hard, and is the clip edge
  clean? This validates the composite primitive AND the reference-sharing story.
- **0b. Deterministic trig.** `grep -rn "fdlibm" vendor/swcanvas/swcanvas.js` (and
  `src/`): locate the deterministic sin/cos; determine how Fizzygum-side code can call it
  (exposed on the SWCanvas global? if not, port the ~2 functions into `src/boot/` with
  provenance comments). Record the decision. Matrices in §4.3 must use it on BOTH backends
  (native too — the matrix feeds damage/hit-test math that must agree with SW-rendered tests).
- **0c. Warp cost micro-benchmark.** Measure axis blit vs. scaled blit vs. rotated blit
  (per-megapixel) on SWCanvas, **minified build** (standing lesson: unminified/shadow profiles
  overstate JS pixel-loop shares — do a minified A/B before believing any ranking). Record
  numbers in §0-R; they calibrate §4.7 expectations.
- **0d. Native parity eyeball.** Same harness on native canvas; screenshots for the owner —
  visual check only, no pixel gate (native is not pixel-tested; fact §2).
- **0e. (Already verified 2026-07-09, keep unless drifted):** the suite runs `?sw=1`
  (`run-all-headless.js:112`).
- **0f. Nearest-neighbor acceptance (VERIFIED FACT, needs an owner decision).** SWCanvas
  `drawImage` samples **nearest-neighbor**, by design, consistently with Pattern
  (`swcanvas.js:1837-1838`) — NOT bilinear. So SW rotated composites are deterministic but
  aliased/chunky, while native-canvas composites are smoothed — the cross-backend visual gap
  is larger than generic "Squeak-soft" (SW is "Squeak-crunchy"; the owner's own observation
  that SWCanvas's scaled text blits look "pretty bad" is this same fact, since the text slow
  path shares the primitive). Produce side-by-side samples (SW vs native, dpr 1 and 2, text +
  line art, at 15°/45°) for the owner to accept or reject for v1. If rejected → the banked
  SWCanvas item §7.8 (fixed-point bilinear) gets promoted to a Phase-0-blocking prerequisite.

DONE = §0-R filled in with hashes, numbers, the trig-exposure decision, and the 0f verdict.
If 0a FAILS (cross-engine hash mismatch), STOP: the whole testing strategy needs owner
discussion.

### Phase 1 — `TransformSpec` + `TransformFrameWdgt`, scale-only (all plumbing, zero quads)

> **PHASE 1 (2026-07-09) — COMPLETE, incl. the click-through macro (the last deferred item, landed
> as a follow-up — see the "CLICK-THROUGH MACRO" note further down). Steps 1–6 + click-through all
> done.** The foundation was COMMITTED earlier (Fizzygum `44b42161`, Fizzygum-tests `f25030f0e`,
> not pushed); the click-through follow-up (3 source files + 1 new macro + a benign inspector
> recapture) is verified but NOT YET committed.
> GATES (foundation): `fg gauntlet` = dpr1 **200/200** · dpr2 **200/200** · webkit **200/200** ·
> apps · **paint** (no over-repaint offenders) · settle · capstone — ALL PASS. `fg homepage`
> production build boots clean. `doubleCheckCachedMethodsResults` coherence probe PASS (island
> two-faces == SLOW twins, incl. nested in a clipping panel). Dormant guarantee held. The
> click-through follow-up adds one macro (suite → **201**) and its gauntlet re-run is recorded in
> the click-through note below. Details follow.
>
> **PHASE 1 FOUNDATION (Stage A) LANDED + VERIFIED.**
> Landed `src/TransformSpec.coffee` (scalars + isIdentity + matrixForSlot + mapRect; rotation
> clamped to 0; rotation-0 fast path ⇒ no trig dependency yet — DetTrig branch ready for Phase 2)
> and `src/TransformFrameWdgt.coffee` (extends `PanelWdgt`; invisible clipping frame via
> `appearance=nil`; content buffered un-transformed and composited via the §4.2 **scale-only fast
> path** — unequal-src/dst `drawImage`, axis-aligned, no `setTransform`/`clip`; two-faces bounds
> overrides for clipThrough/clippedThroughBounds + **SLOW twins**, all gated on `isIdentity`; spec
> mutation invalidates via `__breakMoveResizeCaches`+`fullChanged`). VERIFIED (headless probe +
> gates):
> - build OK — syntax/layering/dead-methods/stinks/thin-wraps all green (dormant feature).
> - scale-2 island composites correctly (120×80 rect → 240×160 about centre; footprint bounds
>   `clippedThroughBounds` = exact scaled slot + 1px pad); a scaled island casts a correctly
>   **scaled content shadow** for free (§4.8 — achieved by reverting the PanelWdgt opaque-panel
>   JustShadow shortcut to the base "paint content as shadow" so a transparent island casts its
>   content's silhouette).
> - **identity-island == bare-widget pixel-identical** (SHA-256 match) — the identity gate holds.
>   (Key finding: the wrapped widget must retain the drop-shadow it had as a world child; the
>   island carries it — do NOT `skipsAddShadowManagement`.)
> - **dormant suite 196/196 GREEN, 0 failed** (dpr1) — zero reference changes; the dormant
>   guarantee holds.
>
> **STAGE B (§4.5 damage hook) — LANDED + VERIFIED.** `Widget::mapRectToScreen` (walks the
> parent chain, maps through each non-identity island's forward matrix, ∩ outermost island's
> screen clip; returns the SAME object when not inside an island ⇒ dormant byte-identical);
> both flesh-out lanes (`fleshOutBroken`/`fleshOutFullBroken`) map BOTH source-snapshot AND
> destination rects BEFORE merge/dedupe; `world.paintingIntoIslandBuffer` lets island
> descendants record their virtual last-painted bounds while they paint into the buffer.
> Proven by `macroTransformFrameScaledTextEditRepaints` (grow-then-shrink text inside a scale-2
> island; the shrunk shot is asserted BYTE-IDENTICAL to a fresh-short shot ⇒ no stale pixels).
>
> **STAGE C (§4.6 pointer mapping) — LANDED + VERIFIED.** `Widget::screenPointToMyPlane`
> (applies each ancestor island's INVERSE, outermost-first; identity chain returns the point);
> the one spatial hit-test predicate (`ActivePointerWdgt.topWdgtUnderPointer`) tests each
> candidate against the plane-mapped pointer; the island overrides `isTransparentAt → true` +
> `noticesTransparentClick=false` so it never claims a hit itself (content does);
> `BackBufferMixin.getPixelColor` floors the (now possibly-float) sample coords;
> `_showResizeAndMoveHandlesAndLayoutAdjustersNoSettle` refuses handles on island-inner widgets
> (Phase-4 maps drag deltas). Proven by a headless probe: screen points inverse-map into the
> inner widget's virtual plane and hit it; points outside the scaled footprint fall through.
> (The `Widget.coffee:323` "second predicate" is a unique-ID lookup, NOT spatial — out of scope.
> Menu/desktop-icon predicates are hand/screen-plane and not inside islands in Phase 1.)
>
> **STEP 5 AUDIT (recorded here).** `toLocalCoordinatesOf` callers in `src/` are ALL same-plane:
> `CircleBoxyAppearance` (draws into its own buffer), `Widget._applyMoveTo*`/`_moveToNoSettle`
> (move delta in the widget's OWN plane — an inner widget's `moveTo(virtualPoint)` stays
> virtual), `Widget.positionPixelsInWidget` (relative position of same-plane widgets),
> `BackBufferMixin.getPixelColor` (fed the already-plane-mapped hit point — handled). Cross-plane
> actors: **HandleWdgt** restricted (Phase 1); **CaretWdgt** is IN-PLANE — `WorldWdgt:2493` adds
> it to `target.parent`, so it is a sibling of its target and shares the target's (virtual)
> plane, and it paints into the island buffer ⇒ caret editing inside an island works unchanged;
> menus/prompts open at the hand (screen plane); inspector highlights are ephemeral screen
> overlays; there is NO visual connector widget. None cross a plane boundary in Phase 1.
>
> **BUG FOUND + FIXED (drag test):** `_compositeIslandBuffer` did not clamp its `drawImage`
> SOURCE sub-rect to the buffer; float rounding at a partial-clip edge (the shadow-offset pass
> during a drag) pushed it a pixel past the edge, and SWCanvas `drawImage` THROWS on an
> out-of-bounds source (native silently clips) → the island was banned from repainting → a
> nondeterministic frame. Fixed with the BackBufferMixin-style `Math.min` clamp (dst keeps its
> extent; ≤ sub-pixel edge strip, deterministic).
>
> **CLICK-THROUGH MACRO (the last Phase-1 item) — LANDED + VERIFIED (2026-07-09, follow-up).**
> Added `TransformSpec::mapPoint` (forward point map, exact inverse of `inverseMapPoint`) and
> `Widget::localPointToScreen` (the inverse of `screenPointToMyPlane`: maps a point in a
> widget's virtual plane UP to screen through each ancestor island's forward matrix, innermost →
> outermost; returns the SAME object when not inside an island ⇒ dormant byte-identical), plus
> the MacroToolkit verb `moveToAndClickAtScreenFractionOf_InputEvents` (via `screenPointAtFractionOf`).
> New macro `macroTransformFrameScaledClickThrough` (dpr1+2): a short editable string at the LEFT
> of a wide box wrapped in a scale-2 island, so the string's SCREEN centre is pushed well LEFT of
> its virtual bounds; a click there focuses the string (only the inverse-mapped hit-test lands it)
> and select-all + type replaces "edit me" → "HIT" (a value assertion `label.text=="HIT"` FAILS if
> the click missed; image_2 shows "HIT" scaled). ⚠ NOTE recorded for Phase 4: the click still
> dispatches the RAW screen position to the widget's handler (`ActivePointerWdgt:759` `w[click]
> @position()`), so sub-widget geometry that reads the click position (caret slot, slider fraction,
> drag delta) is NOT itself plane-mapped yet — this verb/test only prove the click ROUTES to the
> island-inner widget; select-all makes the outcome independent of the exact caret slot.
> Adding `localPointToScreen` to `Widget` shifted `macroDuplicatedInspectorDrivesCopiedTargetOnly`
> image_2/image_3 again — recaptured (benign, per standing rule).
> GATES (click-through follow-up): `fg gauntlet` = dpr1 **201/201** · dpr2 **201/201** · webkit
> **201/201** · apps · paint · tiernaming · settle · capstone — ALL PASS; `fg homepage` boots
> clean. Files: Fizzygum `src/TransformSpec.coffee`, `src/basic-widgets/Widget.coffee`,
> `src/macros/MacroToolkit.coffee` (M); Fizzygum-tests `SystemTest_macroTransformFrameScaledClickThrough`
> (NEW, dpr1+2) + `macroDuplicatedInspectorDrivesCopiedTargetOnly` image_2/3 recapture.
> NOTE: `inverseMapRect` and `setRotationDegrees`/`setAnchor` remain deferred (dead-method gate) —
> re-introduced with their first callers (Phase 2 / Phase 4).

Rationale: uniform scale exercises every choke point (buffer, composite, damage mapping,
pointer mapping, flesh-out hook, clipThrough integration) while every mapped rect remains an
axis-aligned `Rectangle` — the entire existing rect machinery keeps working. Ships per-window
zoom as a real feature.

Steps:
1. `TransformSpec` (new file, one class): scalars + `claimsSpace` (only `'slot'` wired in this
   phase); `isIdentity()`, `matrixFor(slotBounds)`, `inverseMapPoint`, `mapPoint`, `mapRect`
   per §4.3 (rotation locked to 0 — assert/clamp, so no trig dependency yet).
2. `TransformFrameWdgt` (new file): slot-box widget, `clipsAtRectangularBounds: true`, single
   content child convention, buffer per §4.4, composite per §4.2 (identity blit path; scale
   via unequal src/dst `drawImage` — no `setTransform` in this phase), **two-faces bounds
   overrides per §4.11 INCLUDING the SLOW twins** (`SLOWclipThrough`,
   `SLOWclippedThroughBounds`, `SLOWfullClippedBounds`) — run at least one suite leg with
   `world.doubleCheckCachedMethodsResults` enabled to exercise the coherence gate against the
   new overrides. Spec mutation = `WorldWdgt.geometryVersion++` + `fullChanged()` + break the
   chain-flag caches (same invalidation family as a move — bump sites precedent:
   `Widget.coffee:1304`, `WorldWdgt.coffee:203,207`).
3. Damage hook per §4.5 (`mapRectToScreen` + BOTH flesh-out lanes, source AND destination
   rects, mapped BEFORE merge/dedupe + the inside-an-island cached flag + buffer-dirty
   accumulation).
4. Pointer mapping per §4.6 (`screenPointToMyPlane`, predicate changes at
   `ActivePointerWdgt.coffee:96` and `Widget.coffee:323`, island containment refinement,
   per-event memoization, the Phase-1 no-drop-into-island restriction, AND the Phase-1
   handle restriction: `HandleWdgt` refuses a `@target` inside a non-identity island).
5. Audit pass, two sweeps, classification table recorded in this doc:
   (a) grep `toLocalCoordinatesOf` callers in `src/` — classify (same-plane: fine) /
   (crosses-plane: route through the new mapping);
   (b) cross-plane actors — widgets reading ANOTHER widget's `position()`/`bounds`/
   `center()` to place themselves (known list in §4.6: HandleWdgt, CaretWdgt, menu/prompt
   open-at-widget paths, inspector highlight overlays) — verify each is in-plane or
   restricted/mapped.
6. Macro tests (new): identity-island world (see gate below); scale-2 island containing a
   BoxWdgt + StringWdgt (screenshot); click-through accuracy inside a scaled island (button
   press lands correctly); edit text inside a scaled island → damage repaints correctly (no
   stale pixels, no over-repaint assertion if the harness supports paint-gating — see the
   paint-gate leg precedent in `fg gauntlet`); drag the island itself.

GATES (all must pass before Phase 1 is declared done — verify, don't assert):
- `fg gauntlet` fully green with the feature dormant (no island instantiated in existing
  tests) — expectation: zero reference changes; any reference change means a hot path was
  disturbed → find and fix, do not recapture.
- Identity-island macro: screenshots pixel-identical to the same scene without the island.
- New scale macros green on dpr1 + dpr2 + webkit.

### Phase 2 — rotation

> **PHASE 2 (2026-07-09) — COMPLETE + VERIFIED + COMMITTED (Fizzygum `a5f4ef97`, Fizzygum-tests
> `188404618`; NOT pushed).** Steps 1–4 all done. Rotation is live end to end: the general warp
> composite, the setter + its damage, exact quad hit-testing, rotated shadows, ancestor clipping,
> occlusion invariant, and 6 macros.
> IMPLEMENTATION:
> - `TransformSpec` — removed the Phase-1 rotation clamp; added `setRotationDegrees`. The matrix
>   (`matrixForSlot`/`inverseMatrixForSlot`) already used `_cosSin`, which for a non-zero angle
>   calls `DetTrig.cos/sin` (the rotation-0 fast path still returns `[1,0]` with no trig) — so a
>   pure scale/identity spec has no trig dependency and rotated pixels are cross-engine identical.
>   `mapRect` already corner-maps to a padded integer AABB (used for both damage and footprint).
> - `TransformFrameWdgt` — added `setRotation(deg)` (same invalidation family as `setScale`).
>   `_compositeIslandBuffer` now DISPATCHES: identity → super blit (caller); pure scale → the
>   Phase-1 `_compositeScaleOnly` fast path (unchanged, so Phase-1 scale refs stay byte-identical);
>   rotation → the new `_compositeTransformed`. That path is render-straight-then-warp: `save`;
>   `clipToRectangle(visibleDst × cpr)` (the MANDATORY §4.2 real path clip — a transformed
>   `drawImage` cannot express the broken-rect clip via src/dst rects); `transform(cpr·matrix)`
>   (⚠ `transform` = COMPOSE, **not** `setTransform` — so the unified shadow pass' pre-applied
>   offset-translate CTM is honoured, giving a correctly rotated shadow for free, §4.8; on the
>   normal pass the incoming CTM is identity so it equals setTransform); `drawImage(buffer, full →
>   slot box)`; `restore`. v1 warps the WHOLE buffer under the clip (correctness-first); the §4.2
>   sub-rect optimisation is BANKED.
> VERIFIED (all visually inspected + value-asserted where applicable):
> - `macroTransformFrameRotatedRenders` — 30°, 45°+scale-1.5, 90° (crisp transpose); + a value
>   assertion that `island.opaqueCoveredRect()` is `nil` (step 2: islands never occlude — holds by
>   construction, `@color` is nil).
> - `macroTransformFrameStepRotation` — `setRotation` in steps; the rotate-then-unrotate return to
>   0 is asserted BYTE-IDENTICAL to the identity baseline (damage cleaning exact; identical dataHash
>   confirmed).
> - `macroTransformFrameRotatedCornerClickThrough` — EXACT quad hit-test: a click in the AABB ear
>   (outside the rotated quad) falls through to the widget behind while a centre click reaches the
>   inner string (value-asserted); also caret editing inside a rotated island. (⚠ inner-first
>   ordering: a click raises the clicked widget to the foreground.)
> - `macroTransformFrameRotatedShadow` — a rotated island's drop shadow is the rotated content
>   silhouette (validates the `transform`-compose shadow handling).
> - `macroTransformFrameRotatedInClippingFrame` — a rotated island nested in a `ClippingBoxWdgt`;
>   the overhang is cut off at the frame's straight edge (§4.11 ancestor screen clip on the mapped
>   footprint). Rotated SLOW-twins coherence separately verified (`doubleCheckCachedMethodsResults`
>   probe with a 35° island in a clipping panel: cached == SLOW for all three faces, no alerts).
> - `macroTransformFrameOverlappingRotatedIslands` — z-order + exactness: a click in the TOP
>   island's ear falls through to the rotated island behind (value-asserted A/B).
> GATES: `fg gauntlet` = dpr1 **207/207** · dpr2 **207/207** · webkit **207/207** · apps · paint ·
> tiernaming · settle · capstone — ALL PASS; `fg homepage` boots clean. Suite 201→207 (6 new
> rotation macros). Phase-1 scale references unchanged (the scale fast path is untouched, so the
> dispatch adds nothing on the scale/identity/dormant paths). Files: Fizzygum
> `src/TransformSpec.coffee`, `src/TransformFrameWdgt.coffee` (M). BANKED: the §4.2 composite
> sub-rect optimisation (v1 warps the whole buffer under the clip); `mapPoint`/`inverseMapRect`
> and the `setAnchor` setter (Phase 4 anchor UI).

1. Unlock `rotationDegrees`; matrix per §4.3 with the Phase-0b deterministic trig; composite
   via `setTransform` + `drawImage`; `mapRect` = corner-map AABB (floor/ceil + 1px pad).
2. Confirm islands yield `opaqueCoveredRect() == nil` (should hold via fact 3.5 gating — the
   coverer test is double-gated on `opaqueCoveredRect()` AND `clippedThroughBounds()`
   containment, so islands are never selected as coverers even though their footprint AABB
   over-approximates; add a unit-ish assertion into an existing occlusion macro if cheap).
3. Shadow per §4.8 (appliedShadow composite — no special casing expected; verify with the
   shadow macro below).
4. Macro tests: static rotated window at 15° / 45° (screenshot, SW-deterministic per Phase 0a);
   90° rotation (crisp — near-lossless remap expected; verify visually at recapture time);
   corner click-through (click inside outer AABB but outside the rotated quad hits the widget
   behind); TWO overlapping rotated islands — click in the AABB-overlap region that is inside
   only one quad (z-order + exactness combined); a rotated island WITH a drop shadow
   (screenshot: the shadow must be the rotated silhouette); a rotated island inside a scroll
   frame with the overhang partially clipped (exercises §4.11 both faces); caret/text editing
   inside a rotated island; step-rotation determinism (advance angle in N scripted steps,
   screenshot at each step).

GATES: `fg gauntlet` green incl. all Phase 1+2 macros; dormant-feature references still
unchanged.

### Phase 3 — layout coupling (`claimsSpace`)

> **PHASE 3 (2026-07-09) — COMPLETE + VERIFIED + COMMITTED (Fizzygum `707f9720`, Fizzygum-tests
> `0d720b550`; NOT pushed).** `'footprint'` and `'sweep'` are wired; the paint-only `'slot'` firewall holds.
> IMPLEMENTATION (all gated so the blast radius is contained — no existing test has an island in a
> stack, and everything keys off `!isIdentity()` / `claimsSpace != 'slot'`):
> - `TransformSpec` — `setClaimsSpace`; `_claimedBoxFor`/`claimedExtentFor` (the box/extent the
>   parent reserves: slot box for 'slot', corner-mapped AABB for 'footprint', anchor-aware
>   circumscribed square for 'sweep'); `slotOffsetWithinClaim` (translation-invariant offset —
>   the §10.8 claimed-box = extent AND offset); `_sweepSquareFor` (radius = max scaled corner
>   distance from the anchor; `Math.sqrt` is IEEE-correctly-rounded ⇒ deterministic, and the
>   square is rotation-invariant by construction).
> - `TransformFrameWdgt` — `setClaimsSpace` (reflows once on mode change); `_transformChanged` now
>   calls `_reflowIfClaimChanged` (reflows via `_invalidateLayout` — the SAME entry a resize uses,
>   `_setExtentNoSettle`→`_invalidateLayout`, found by reading the resize path — ONLY when the
>   claimed extent actually changed: so 'footprint' reflows on angle/scale, 'sweep' reflows on
>   scale/extent but NOT rotation, and 'slot' NEVER reflows). A NON-IDENTITY island is a fixed
>   figure for layout: `preferredExtentForWidth` reports the claimed extent (not stretched);
>   `_applyExtentBase` is a no-op (⇒ `@bounds` stays the SLOT box — Phases 1-2 untouched);
>   `_applyMoveToBase` offsets the slot box by `slotOffsetWithinClaim` within the reserved claimed
>   box (arrange-leaf placement only — a drag/direct move goes through `_applyMoveTo`/`moveTo`, not
>   offset). Identity islands fall through to super (dormant).
> VERIFIED (2 macros, all value-asserted + visually inspected):
> - `macroTransformFrameFootprintReflow` — the FIREWALL (rotating a 'slot' plot in a stack does not
>   move the footer below) + footprint reflow (coupling to 'footprint' claims the rotated AABB, one
>   reflow, footer drops below it) + the 90° exact integer transpose (claimed extent = slot box
>   swapped, within the 1px AA pad).
> - `macroTransformFrameSweepReserve` — 'sweep' reserves the circumscribed square ONCE (footer
>   drops on entry), then spinning to 40°/80° does NOT reflow (footer steady — rotation-invariant).
> GATES: `fg gauntlet` = dpr1 **209/209** · dpr2 **209/209** · webkit **209/209** · apps · paint ·
> tiernaming · settle · **capstone** — ALL PASS; `fg homepage` boots clean. Suite 207→209. Phase-1/2
> island refs UNCHANGED (the 'slot' path invalidates nothing, so its self-settle is a no-op —
> verified byte-identical). Files: Fizzygum `src/TransformSpec.coffee`, `src/TransformFrameWdgt.coffee`
> (M). BANKED: container-level 'freeze' veto (§4.9); anchor setter + `mapPoint`/`inverseMapRect`
> (Phase 4).
> ⚠ LESSONS: (1) invalidating layout from a public mutator leaves a CARELESS end-of-cycle push
> (capstone gate) unless it self-settles — wrap the mutator as the canonical `set*` → `_settleLayouts-
> After => @_set*NoSettle` with a bare `_invalidateLayout` reached inside the core (the `_inLayout-
> Mutation` window suppresses the careless-push audit, `Widget.coffee:3956`). The self-settle must
> live at the PUBLIC tier (layering rule [G] rejects a low-level `_` method calling a self-settling
> wrapper). (2) The layering gate's textual scanner false-trips when a `_…NoSettle` core calls a
> `@member.setX` whose name collides with THIS widget's self-settling `setX` wrapper — set the
> member's canonical scalar field DIRECTLY instead (`@transformSpec.scale = s`).

1. Wire `'footprint'` and `'sweep'` per §4.9 (extent reporting + the resize-equivalent layout
   invalidation; find the invalidation entry by reading the resize path — do NOT add a new
   one).
2. Macro tests (the brainstorm's document scenario, made executable): a vertical stack
   ("document") holding a title StringWdgt and a plot BoxWdgt:
   - both `'slot'`, step-rotate both in opposite directions → assert sibling/document geometry
     is IDENTICAL at every step (positions of un-rotated neighbors unchanged);
   - plot `'footprint'` at a fixed 30° → exactly one reflow; text sits below the enlarged AABB;
   - title `'sweep'` while step-rotating → one reflow on entry, geometry stable at every
     subsequent step;
   - `'footprint'` at 90° → exact width/height swap (integer, no breathing).

GATES: `fg gauntlet` green; the `'slot'` macro must prove the layout engine never ran during
the animation (assert via geometry equality; if a cheap layout-run counter exists in the
settle machinery, assert on it too).

### Phase 4 — UX + the Lively-flavored API (sub-step plan authored 2026-07-09; owner-gated)

Phases 0–3 shipped the ENGINE (islands composite, hit-test, damage, layout coupling, all
gate-green + committed). Phase 4 is the INTERACTION layer — the largest phase, and unlike
0–3 it is not one shippable unit but four distinct sub-features with a dependency order. It
is therefore executed as ordered sub-steps **4A → 4E**, each independently gate-green and
each ending at a resting point (present a summary, wait for the owner, commit on approval —
standing rule). The recommended order below is **foundation-first** (fix the content-
interaction seam before building UX on top of it); it is adjustable — if the owner wants an
early *visible* win, 4B (halo rotation on an explicitly-wrapped island) can lead, since it
does not strictly depend on 4A. Each sub-step lists: goal · depends-on · seams (file:line,
verified 2026-07-09) · approach · macros · risks.

**As-built interaction guards (verified 2026-07-10 against the code — these EXIST and must be
lifted by the sub-step named):**
- **Handles refused on island-inner widgets IS wired** (correction of an earlier note that wrongly
  said it wasn't): `_showResizeAndMoveHandlesAndLayoutAdjustersNoSettle` (`Widget.coffee` ~:3145)
  returns early via `_isInsideNonIdentityIsland()`, so resize/move handles never appear on a widget
  inside a non-identity island. ⚠ **4A-2 (drag-delta mapping) MUST remove this guard**, or handles
  stay inert on island-inner widgets and 4A-2 looks mysteriously ineffective.
- **Float-drag OUT of an island escalates to the island** (Phase-1-symmetric guard added 2026-07-10,
  Widget `_isInsideNonIdentityIsland` used in `grabsToParentWhenDragged`): a widget inside a non-
  identity island grabs-to-parent, so a float-drag lifts the whole ISLAND (rigid rotated figure)
  instead of extracting the inner widget onto the hand — which would misread its virtual bounds as
  screen bounds (a visual jump). ⚠ **4D (pick/drop) replaces this** with proper pick-OUT that carries
  the accumulated similitude. (Non-float drags — sliders — are unaffected: `findFirstLooseWidget`
  tests `nonFloatDragging` first.)
- **Islands refuse drops** (Phase 1, minimal): `TransformFrameWdgt` ctor sets `@_acceptsDrops = false`
  (`:53`); `wantsDropOfChild` returns it (`Widget.coffee:2998`). A drop over island content climbs
  past the island (`dropTargetFor`, `ActivePointerWdgt.coffee:171-175`) to an accepting ancestor —
  no error, just won't nest INTO the island. ⚠ **4D lifts this.**
- The hit-test predicate ALREADY plane-maps the pointer (`topWdgtUnderPointer`,
  `ActivePointerWdgt.coffee:104` — `m.screenPointToMyPlane @position()`), so widget *identification*
  inside islands is correct today. The gap 4A-1 closed is only the *position passed to the handler*.

#### 4A — Interaction-plane dispatch plumbing (the foundation)

> **STATUS 2026-07-10:** **4A-1 (click POSITION mapping) COMPLETE + COMMITTED** (Fizzygum
> `354e6edf`, tests `f5098fb28`; NOT pushed). `ActivePointerWdgt._pointerPositionInPlaneOf`
> maps the position at all six click-dispatch sites (mouseDown/Up L+R, main click, double,
> triple); proven end-to-end (caret lands at the mapped slot, not the raw-screen slot) by
> macro `macroTransformFrameScaledCaretSlot`; gauntlet dpr1/dpr2/webkit 210/210, existing refs
> byte-identical (dormant). ⚠ Test-design lesson: a CROPPED StringWdgt routes `edit()` to the
> pop-out editor (returns nil ⇒ no inline caret) — widen the string so it fits.
> **4A-2 (drag DELTA mapping) COMPLETE + COMMITTED** (Fizzygum `92e8b77e`, tests `a066b3b28`; NOT
> pushed). Approach chosen: **point-map both endpoints**, not a separate `inverseMapVector`. The
> drag-start offset (`ActivePointerWdgt` ~:1042) becomes `handle.screenPointToMyPlane(pos) −
> handle.position()` and `HandleWdgt.nonFloatDragging` differences `@screenPointToMyPlane(pos) −
> startOffset`; since BOTH operands are now affine-mapped points, the translation cancels in the
> subtraction and the pointer DELTA is left mapped through the inverse LINEAR part only — exactly the
> vector semantics §4.6 wants, reusing existing `screenPointToMyPlane` (no new API, byte-identical off
> every island). The Phase-1 handle-refusal guard in `_showResizeAndMoveHandlesAndLayoutAdjustersNoSettle`
> is REMOVED. The generalized macro verb `dragResizeMoveHandleTo_InputEvents` now presses at
> `handle.localPointToScreen(handle.center())` (the on-screen handle, not its virtual centre).
> ⚠⚠ **THE REAL BUG was NOT the drag math** — it was a THIRD, pre-existing plane mismatch in the grab
> path: `ActivePointerWdgt`'s "if the mouse left its fullBounds, center it" block tested the widget's
> VIRTUAL `fullBounds()` against the RAW screen `pos`, so for an island-inner handle (pointer ON it on
> screen, but outside its virtual bounds) it mis-fired and `@grab`bed the handle onto the hand —
> yanking it OUT of the island, after which the drag saw an identity plane and resized at raw screen
> scale (a 2× runaway at scale 2). Fixed by mapping: `fb.containsPoint w.screenPointToMyPlane(pos)`.
> This is the kind of latent screen-vs-plane comparison that only an island exposes — grep the input
> path for other `containsPoint(pos)` / bounds-vs-raw-`@position()` tests when touching 4D. Proven by
> `macroTransformFrameResizeInsideScaledIsland` (scale-2 island: a −40,−40 screen drag shrinks the box
> by −20,−20 so the on-screen corner tracks the pointer 1:1; value-asserts extent == inverse-linear of
> the screen delta + that the handle appears at all). Probe confirmed scale/rotate-90/rotate-30 all map
> to `inverseLinear(deltaScreen)` exactly. Gauntlet dpr1/dpr2/webkit + gates + homepage green.
> **DEFERRED (not needed here; a refinement):** (a) `ActivePointerWdgt:1007,1137` mouseMove-position
> mapping — no consumer needs it yet (resize/move use `nonFloatDragging`; revisit for a slider inside an
> island); (b) **sugar-island slot tracking** — resizing a widget past the frozen slot box clips at the
> buffer edge, so the macro drags INWARD (shrinks). Real design questions (anchor behaviour on
> asymmetric grow), so it is its own follow-up; it matters mainly for resize-AFTER-rotate on a sugar
> island (the universal-handle path).

- **Goal:** every pointer POSITION and DELTA handed to a handler is expressed in the
  receiver's own plane, so caret slot, slider fraction, button-relative clicks, and
  handle-drag deltas are correct for widgets INSIDE a non-identity island. Dormant-identical
  by construction (`screenPointToMyPlane` returns the same object when not inside an island).
- **Depends on:** nothing (pure correctness fix; foundation for 4B/4C/4D).
- **Seams (raw `@position()` handed to handlers — all in `src/ActivePointerWdgt.coffee`):**
  `processMouseDown` dispatch `w[actualClick] @position()` (`:607`); `processMouseUp` main
  dispatch `w[expectedClick] @position(), …` (`:759`), `mouseUpLeft?/mouseUpRight?` (`:656,658`);
  double/triple-click `mouseDoubleClick/mouseTripleClick @position()` (`:885,894`). Drag
  handler: `HandleWdgt::nonFloatDragging(startOffset, pos, deltaFromPrev)` computes
  `newPos = pos.subtract startOffset` and calls `@target._setExtentDeferredSettle` /
  `_moveToDeferredSettle` / `_setWidthDeferredSettle` / `_setHeightDeferredSettle`
  (`HandleWdgt.coffee:252-269`) — all in screen space today.
- **Approach:**
  - Dispatch position: replace `@position()` at the handler-dispatch call sites with
    `w.screenPointToMyPlane @position()` (the helper already exists, `Widget.coffee:1282`;
    it no-ops off-island). Audit each handler that RE-EMITS the received position into screen
    space (menu-at-point, prompt-at-point) — those must re-forward via `localPointToScreen`
    (`Widget.coffee:1303`); most open at the hand (`popUpAtHand`, already screen) and need no
    change. The audit is the real work, not the substitution.
  - Handle/drag deltas: a delta is a VECTOR — it maps through the inverse of the island
    matrix's **linear part only** (a,b,c,d — drop the translation e,f), not the full affine.
    Add `TransformSpec::inverseMapVector(v, slotBounds)` (first caller; sibling of the existing
    `inverseMapPoint`) and a `Widget::screenVectorToMyPlane(v)` chain-walker (sibling of
    `screenPointToMyPlane`). Map both `pos` and `startOffset` (or map the resulting delta) in
    `nonFloatDragging` when `@target` is inside a non-identity island; leave the dormant path
    byte-identical.
- **Macros (new):** `macroTransformFrameScaledCaretSlot` (click into a text field inside a
  scale-2 island → caret lands at the slot the on-screen pixel names, asserted via caret index
  or a follow-up type); `macroTransformFrameRotatedResizeHandle` (drag a resize handle on a
  widget inside a rotated island → the visually-correct edge moves; assert resulting slot
  extent). Both must FAIL against pre-4A code (prove the seam) and pass after.
- **Risks:** (1) some handler may read `@position()` again internally rather than the passed
  arg — grep handlers for `world.hand.position()`/`activePointer.position()` and map at the
  read site too. (2) Deltas vs points is the classic bug — a rotation delta mapped as a point
  translates spuriously; the linear-only `inverseMapVector` is mandatory, add a unit-style
  assertion macro if practical.

#### 4B — Halo / handle rotation (the marquee gesture)

> **STATUS 2026-07-10: COMPLETE + COMMITTED** (Fizzygum `b84b19d2`, tests `03bf430b8`; NOT
> pushed). A new `HandleWdgt` type **`"rotateHandle"`** corner-attaches at the island's TOP-RIGHT,
> INSIDE the island (in-plane content — it warps with the content and tracks the transformed corner
> for free, §4.6). `TransformFrameWdgt.providesRotateHandleInHalo` (dispatched via `?()` from the
> show-handles path — plain widgets lack it, so every existing halo is byte-identical) adds it to a
> free-floating island's halo. The handle's `nonFloatDragging` computes the angle in the SCREEN plane
> — `DetTrig.atan2` of the RAW pointer (`world.hand.position()`, immune to a future 4A-2 mapping the
> passed `pos`) about `island.screenAnchor()` (the anchor is the transform's FIXED POINT, so it is a
> constant pivot) — captures the grab-start reference in `mouseDownLeft`, and drives
> `island._setRotationDeferredSettle` (new deferred-settle sibling of `setRotation`; caller
> `nonFloatDragging` is already in the rule-[O] allowlist). `_quantizeRotationDegrees` snaps to a
> cardinal within ~3° AND rounds to an integer grid — clean snap + the determinism belt-and-braces
> over `atan2` (any sub-ULP wobble rounds identically). The handle draws a small **ring glyph** (arc
> via SWCanvas, deterministic since `DetTrig.install(Math)` runs before SWCanvas at boot). Macros:
> `macroTransformFrameRotateViaHandle` (drag → rotate to 45°, value-asserted + pixel proof) +
> `macroTransformFrameRotateSnap` (drag ~88° → snaps 90°; ~85° → stays free). Gauntlet
> dpr1/dpr2/webkit + gates green; suite 213→215. ⚠ **GOTCHA:** CoffeeScript `%%` compiles to a
> `modulo()` helper that Fizzygum's FRAGMENTED in-browser compile does NOT provide (runtime
> `ReferenceError: modulo is not defined`) — use explicit `((x % 360) + 360) % 360`; the codebase
> uses plain `%` everywhere for this reason.

- **Goal:** a rotation handle in the widget's halo; drag rotates the island about its anchor;
  snap to 0/90/180/270 within ~3°.
- **Depends on:** the engine (`setRotation`, live since Phase 2). Does NOT require 4A (the
  rotate handle lives ON the island/world and computes in screen space). Benefits from 4C for
  rotating arbitrary widgets, but is demonstrable on an explicitly-wrapped island.
- **Seams:** `HandleWdgt` (`src/HandleWdgt.coffee`) is the precedent — a corner-attached
  overlay whose `nonFloatDragging` mutates `@target`. The halo/handle-show entry is
  `Widget::showResizeAndMoveHandlesAndLayoutAdjusters` (menu item wired at
  `Widget.coffee:3322,3331`). `TransformFrameWdgt::setRotation(deg)` (`:98`) is the mutator to
  call; anchor is `transformSpec._anchorFor(bounds)` (`TransformSpec.coffee:100`).
- **Approach:** add a `"rotateHandle"` type (or a small `RotateHandleWdgt`) whose
  `nonFloatDragging` computes the angle of (pointer − anchor) relative to the grab-start angle,
  snap-rounds, and calls `island.setRotation`. Reuse `HandleWdgt` machinery
  (`defaultLayoutSpecWhenAddedTo`, `updateVisibility`) as far as it fits.
- ⚠ **PLANE DECISION (make it explicit — this is a real feedback-loop bug if got wrong):** the
  rotate handle may attach either ON the island (screen-plane geometry) OR, consistent with the halo
  model above, INSIDE the island as in-plane content — the in-plane choice warps with the content, so
  the grabbed handle **stays under the finger** as it spins (nice physics, like swinging an object by
  its corner). EITHER way the angle math MUST be computed in the **SCREEN plane**: `angle(hand's RAW
  screen `@position()` − `island.localPointToScreen(island.transformSpec._anchorFor(island.bounds))`)`
  — NOT the 4A-1-mapped position that handlers now receive. If an in-plane rotate handle used its
  received (plane-mapped) position, it would compute the angle in the very plane it is rotating → a
  feedback loop. (This is the exception to 4A-1: rotation input is inherently screen-plane.)
- **Macros (new):** `macroTransformFrameRotateViaHandle` (scripted pointer drag rotates a
  wrapped widget to a target angle); `macroTransformFrameRotateSnap` (drag to ~88° → snaps to
  90°; drag to ~85° → stays free).
- **Risks (determinism):** the handle computes the raw angle via `atan2`, and `Math.atan2` is NOT
  cross-engine bit-identical (the suite asserts byte-exact pixels under WebKit). GOOD NEWS: **`DetTrig`
  already exposes `atan2`** (confirmed §0-R 0b: `DetTrig = {sin,cos,tan,atan,atan2,asin,acos,install}`,
  `runtime-prelude/deterministic-trig.js`) — call `DetTrig.atan2` directly, no SWCanvas-repo change
  needed. Belt-and-suspenders: **quantize the committed `rotationDegrees` to an integer grid** before
  `setRotation` (also gives clean snap) and choose macro drag endpoints safely inside a grid cell.
  Record the choice in §8.

#### 4C — Property sugar: `widget.rotation` / `widget.scale` (auto-materialize / auto-remove)

> **STATUS 2026-07-10: COMPLETE + COMMITTED** (Fizzygum `07c789cc`, tests `9db75f989`; NOT
> pushed). `Widget.setRotationDegrees` / `setScaleFactor` (method form) → `_applyTransformSugar`
> finds-or-materializes the enclosing sugar island, applies via the island's NoSettle cores, and
> dematerializes at identity — all NoSettle inside the one public-tier settle (`_addNoSettle` /
> `_moveToNoSettle` / `_destroyNoSettle`). `TransformFrameWdgt._materializedBySugar` gates the
> auto-remove (explicit islands stay, dormant). Macros: `macroWidgetRotationSugarMaterializes`
> (island appears, reused not nested) + `macroWidgetRotationSugarRemovesAtIdentity` (removal →
> box a direct world child, bounds preserved, frame PIXEL-IDENTICAL to never-transformed — same
> dataHash). Gauntlet dpr1/dpr2/webkit 212/212 + capstone; the ONE benign recapture
> (`macroDuplicatedInspectorDrivesCopiedTargetOnly` image_2/3, member-list shift from the new
> Widget methods) is folded in. The `= θ` defineProperty sugar is left as an optional follow-up.

#### 4B-universal — rotate ANY widget from its halo (built on 4A-2)

> **STATUS 2026-07-10: COMPLETE + COMMITTED** (Fizzygum `b9770bb7`, tests `f20b81006`; NOT pushed).
> The rotate handle is added to EVERY free-floating widget's halo (the island-only
> `providesRotateHandleInHalo` gate is DROPPED). A Widget **halo rotation protocol** —
> `rotationHalo_screenAnchor` (my centre → screen = the sugar island's fixed-point pivot),
> `rotationHalo_currentDegrees` (the enclosing sugar island's rotation, or 0), `rotationHalo_apply`
> (`setRotationDegrees` — the 4C sugar) — lets the one handle drive any target; `TransformFrameWdgt`
> overrides all three to drive its own spec (`rotationHalo_apply` → self-settling `setRotation`, NOT the
> deferred setter, which is REMOVED — the protocol is a polymorphic dispatch, not a per-event stream, so
> rule [O] forbids it textually calling a `*DeferredSettle`; a per-drag self-settle is a no-op for the
> 'slot' island every sugar island is). Rotating a bare widget materialises a sugar island on the fly
> and removes it at identity. Proof: `macroWidgetRotateViaHaloHandle` — the fully MOUSE-ONLY path
> (right-click → "resize/move…" → drag the ring) rotates a plain box 40°, value-asserting the sugar
> island materialised. Blast radius = 6 resize/move-halo tests recaptured (they now show the rotate
> ring) + 1 benign inspector; owner approved the recapture. ⚠ Needed 4A-2 first: with resize/move now
> correct inside a rotated island, the whole halo stays coherent once a widget is rotated. Resize-GROW
> past a sugar island's slot still clips (the deferred 4A-2 slot-tracking refinement).

#### Phase 4 — ROUGH EDGES exposed by 4B-universal (rotation on real windows) — R1, R2, R3, R4 DONE

Making rotation reachable on any window surfaced several coordinate gaps — the 4A-2 deferrals,
ephemeral-overlay rotation, and (found later) the slider/palette drag consumers 4A-2 missed. NOT
regressions from the universal handle (it just made rotation easy to trigger); they are follow-ups to
the transform feature. Reported by the owner 2026-07-10 testing the **Drawings Maker** app in a rotated
window (hierarchy there: `TransformFrame → Window → StretchableWidgetContainer → StretchableCanvas →
CanvasGlassTop`, plus a `ReconfigurablePaint`); R4 reported testing the **C↔F converter** window's sliders.
Priority was **R1 (paint) > R3 (resize-clip) > R2 (highlight)**, then R4 (slider/palette drag). All
cold-executable. **R1, R2, R3, R4 COMPLETE 2026-07-10.**

**R1 — pointer position not mapped for `mouseMove` consumers (paint draws in the wrong place).**

> **STATUS 2026-07-10: COMPLETE + COMMITTED** (Fizzygum `b51062e9`, tests `1d54b5d11`; NOT pushed).
> `ActivePointerWdgt` now maps the pointer PER-RECEIVER through `screenPointToMyPlane` at BOTH `mouseMove`
> dispatch sites — `determineGrabs` (`topWdgt.mouseMove`, :1007) and `dispatchEventsFollowingMouseMove`
> (`newWdgt.mouseMove`, :1149) — exactly the 4A-1 click-site mapping. Dormant-safe: identity off any island
> ⇒ every existing test byte-identical (gauntlet 218/218 dpr1/dpr2/webkit + apps/paint/tiernaming/settle/
> capstone + homepage all green). AUDIT of the other position-reading `mouseMove` consumers: `StringWdgt`
> (`slotAt` text selection) and `Example3DPlotWdgt` (drag-delta) both just BECOME correct inside an island;
> `SliderButtonWdgt.mouseMove` reads no position; no double-mapping (only `HandleWdgt`/`ActivePointerWdgt`
> call `screenPointToMyPlane`). Proof: `macroMouseMovePositionMappedInRotatedIsland` (a box records the pos
> its own `mouseMove` receives; rotated 40°; bare pointer moved to an OFF-CENTRE interior point because the
> centre is the rotation's fixed point ⇒ maps trivially) value-asserts delivered-pos == plane-map,
> non-trivial (>5px), island at 40°. The suggested extra audit (slider track-hover) came out clean.
- Symptom: in a rotated window the paint stroke appears offset from the cursor (the green cursor square
  and the black stroke are far apart).
- Root cause: `ActivePointerWdgt` dispatches `mouseMove` with the RAW screen `@position()` at two sites —
  `determineGrabs` (~:1007, `topWdgt.mouseMove pos`) and `dispatchEventsFollowingMouseMove` (~:1137,
  `newWdgt.mouseMove?(@position(), @mouseButton)`). The paint tool's handler in
  `src/apps/ReconfigurablePaintWdgt.coffee` (`mouseMove = (pos) -> … context.translate pos.x, pos.y`, at
  ~:85/:99, :135/:143, :330/:338, :389/:397) draws at that raw pos, wrong-plane for a canvas inside a
  rotated island. This is 4A-2's explicitly-DEFERRED item (a).
- Fix: map the position PER-RECEIVER exactly like 4A-1's click sites —
  `newWdgt.mouseMove?(newWdgt.screenPointToMyPlane(@position()), @mouseButton)` at :1137, and
  `topWdgt.mouseMove topWdgt.screenPointToMyPlane(pos)` at :1007. Dormant-safe (screenPointToMyPlane
  returns the same object off any island ⇒ byte-identical for every existing test; nothing today drives a
  position-reading mouseMove inside a non-identity island).
- ⚠ Audit other `mouseMove` position consumers (slider track-hover?) for the same benefit; hover
  state (`mouseEnter`/`mouseLeave`) reads no position, unaffected.
- Test: rotate a small paint window (or wrap a `CanvasWdgt` in an island), paint a short stroke, screenshot
  the stroke landing under the mapped cursor. Value-assert is hard (paint → buffer); a lighter fixture is a
  probe widget that records its last `mouseMove` pos inside an island and asserts the mapped value.

**R3 — sugar-island slot not tracked: resize-after-rotate clips (ALL windows).**

> **STATUS 2026-07-10: COMPLETE + COMMITTED** (Fizzygum `6ccf1ccc`, tests `dc712c27e`; NOT pushed; gauntlet
> 219/219 dpr1/dpr2/webkit + apps/paint/tiernaming/settle/capstone + homepage). Owner-reviewed design.
> Symptom: rotate a window, enlarge it → content + right/bottom borders clip at the OLD footprint. Root
> cause: the sugar island's slot (`@bounds`) is frozen to the wrapped widget's bounds at materialize;
> `_refreshIslandBuffer` builds the buffer at that slot size; resizing the wrapped window grows ITS bounds
> but not the slot ⇒ clip. **Fix = a SUBCLASS, not a per-instance flag.** In this layout architecture the
> size-tracking-container capability is a CLASS (a freefloating child's `_invalidateLayout` climbs THROUGH
> to its parent iff the parent DEFINES `_reLayoutChildren`, `Widget:4039` — an existence/class check, and
> there are FIVE such capability sites across Window/Stack/ScrollPanel). A class-wide `_reLayoutChildren`
> on the base island turned EVERY island (incl. explicit COUPLED islands in a stack) into a tracking
> container and destabilized the coupled-island reflow settle → `macroTransformFrameFootprintReflow` /
> `macroTransformFrameSweepReserve` went NONDETERMINISTIC (screenshot raced the reflow). So R3 is a
> capability VARIANT: `TrackingTransformFrameWdgt extends TransformFrameWdgt` defines `_reLayoutChildren`
> (slot ← single content child's bounds), `_reLayout` (`super; @_reLayoutChildren`, the Stack/ScrollPanel
> shape), and pins `implementsDeferredLayout` false; `Widget._materializeSugarIslandNoSettle` materializes
> THIS class. The base stays a FIXED figure that does NOT define `_reLayoutChildren`, so Phases 1–3 are
> byte-identical BY CONSTRUCTION (zero framework edits). The re-fit is a one-pass idempotent arrange (no
> public setter, no `_invalidateLayout`, no reflow — a sugar island is 'slot'). Option A (chosen): default
> anchor = slot centre, so an asymmetric grow re-centres the figure (Option B, pin the anchor, banked).
> `_materializedBySugar` stays the orthogonal auto-remove-at-identity gate. Proof macro
> `macroTransformFrameSlotTracksContentResize` (slot 100×80 → 200×160, image_2 all corners intact).
> Explicit-island content-resize has the SAME latent clip → future path banked §7.10. Lessons folded into §8.

**R2 — ephemeral highlight overlays not rotated (highlight axis-aligned + offset).**

> **STATUS 2026-07-10: COMPLETE + COMMITTED** (Fizzygum `a8c4459d`, tests `9a58a18d8`; NOT pushed; gauntlet
> dpr1/dpr2/webkit 220/220 + apps/paint/tiernaming/settle/capstone + homepage). Owner-reviewed design (5
> refinements folded in). Symptom: the hierarchy-menu target highlight (blue wash) shows as a screen-aligned box OFFSET
> from a rotated target. Root cause: `HighlighterWdgt` is built one-per-target by the reconciler
> (`WorldWdgt.addHighlightingWidgets`, fed by the `world.widgetsToBeHighlighted` Map) as a WORLD child sized
> to `target.clippedThroughBounds()` — which, for a target inside a non-identity island, is the target's rect
> in the island's VIRTUAL plane (the transform is applied later, at composite time, via `mapRectToScreen`). A
> world child interprets those bounds in the SCREEN plane ⇒ axis-aligned + offset. **Fix = the §4.6
> halo-handle model: the reconciler now parents each highlight INTO its target's innermost enclosing
> non-identity island** (`Widget._enclosingNonIdentityIsland`, or the world when there is none). The island
> paints all its children into the buffer (`_refreshIslandBuffer` iterates every child) and composites through
> the matrix, so the highlight **warps + clips with the target for free**; its damage maps to screen correctly
> (`fleshOutBroken` already runs island-interior damage through `mapRectToScreen`). Off any island ⇒ world
> parent ⇒ BYTE-IDENTICAL dormant (verified). Three edits + one lifecycle fix + one hardening:
> - `HighlighterWdgt` gains `isLayoutInert: -> true` (it is layout-inert chrome exactly like `HandleWdgt`/
>   `CaretWdgt`). This excludes it from `childrenNotHandlesNorCarets` / `subWidgetsMergedFullBounds`, so it can
>   never disturb a size-tracking container's content bounds — in particular it can NEVER count as the single
>   content child of a sugar island. **This flushed a latent bug that existed regardless of R2:** without it, a
>   highlighted sugar island fails the `TrackingTransformFrameWdgt` single-child check and a second
>   `setRotationDegrees` while hovered would NEST a second island. Still PAINTED into the buffer (painting
>   iterates all children, not just the non-inert ones).
> - `Widget._enclosingNonIdentityIsland()` (innermost non-identity `TransformFrameWdgt` ancestor, or nil);
>   `_isInsideNonIdentityIsland` refactored to delegate to it (one boolean-context caller).
> - `WorldWdgt.addHighlightingWidgets` resolves `desiredParent = target._enclosingNonIdentityIsland() ? world`
>   in both the create branch and the update branch (re-parents if it changed, so a mid-hover rotate/unwrap
>   re-homes it; `add` keeps the highlighter free-floating — it has no intrinsic `layoutSpec`).
> - **Lifecycle (owner refinement 1):** `_dematerializeSugarIslandIfIdentityNoSettle` re-homes any layout-inert
>   ephemeral chrome OUT to the island's parent (at unchanged position — dematerialize is at identity, so
>   virtual ≡ screen) BEFORE `island._destroyNoSettle()`. `_destroyNoSettle` merely NULLS `island.children`
>   (it does not orphan/clean them), so a highlight left inside would dangle the world's highlight bookkeeping
>   on a dead widget. Now the SAME highlighter instance survives an unwrap-while-hovered.
> - **resetWorld teardown gap (surfaced by the new test):** `WorldWdgt._resetWorldNoSettle` destroyed the
>   world's children but NEVER cleared the ephemeral-overlay bookkeeping (`widgetsToBeHighlighted` /
>   `currentHighlightingWidgets` / `widgetsBeingHighlighted`, + the pinout trio) — Sets/Map on the singleton
>   world holding DEAD refs to the destroyed targets/overlays. Pre-existing latent gap (menu tests always
>   dismiss their highlights, so it never bit); the new test deliberately leaves its highlight ON at teardown,
>   which leaked dead refs into the NEXT test in the same headless process → 2 unrelated tests
>   (`macroHoppingBetweenSubMenus`, `macroTextRelayoutsCorrectlyOnResize`) mis-rendered (passed alone, failed
>   in-suite — the classic resetWorld-between-tests signature). Fix: `_resetWorldNoSettle` now `.clear()`s all
>   six. The test KEEPS its dangling highlight on purpose, as a live regression guard for this teardown.
> - **Z-ORDER semantic change (owner refinement 4), consciously accepted:** an in-plane highlight composites at
>   the island's z-position, so a widget overlapping the rotated island now OCCLUDES the highlight (before, a
>   world-child highlight painted above everything). This is MORE correct — an occluded target ⇒ an occluded
>   highlight — but it is a behaviour change; recorded here so it is not later bisected as a regression.
> - **Audit tail — resolved:** the drag-embed **candidate/reluctant outline** flows through the SAME
>   `world.widgetsToBeHighlighted` channel (`ActivePointerWdgt:245`), so it is fixed by this change. The
>   **charge-ring / armed-label / lock-badge** are cursor-relative (screen plane) and correct as-is.
>   **CaretWdgt / text selection** are in-plane by parentage already. **Pinout labels** (`addPinoutingWidgets`)
>   carry the SAME latent bug but are debug tooling out of the repro → BANKED §7.11 (identical one-liner via
>   `_enclosingNonIdentityIsland`). Proof macro `macroHighlightTracksRotatedIslandTarget` (value-asserts parent
>   ∈ island + bounds == virtual-plane `clippedThroughBounds`, then the unwrap-survives case; image_1 the
>   rotated wash, image_2 the re-homed axis-aligned highlight). Possible ONE benign inspector member-list
>   recapture from the new `Widget` method (the standing benign-recapture rule — run the WebKit leg).
> - **Why NOT the rotated-quad alternative:** it is dead not because "no polygon-stroke primitive exists" (both
>   backends stroke paths fine) but because a screen-plane quad highlighter would need its OWN painting code +
>   quad damage accounting, and would neither clip with the island nor reuse the mapping machinery — it is
>   architecturally FOREIGN, whereas in-plane is architecturally FREE (the same model as halos and carets:
>   widget-attached chrome lives in-plane and warps/clips/damages with its target for nothing).
- Symptom: the hierarchy-menu TARGET highlight (blue wash/outline) shows as a screen-aligned box offset
  from a rotated target; likely also hover / drag-embed outlines.
- Root cause: `HighlighterWdgt` (extends `RectangleWdgt`) is built one-per-target by the reconciler
  (`world.widgetsToBeHighlighted` Map → `WorldWdgt`), positioned/sized to the target's bounds in the SCREEN
  plane with NO mapping through the enclosing island ⇒ axis-aligned rect at the wrong place/orientation.
  Same class as the §4.6 world-overlay-halo problem (screen-space overlays don't rotate).
- Test: highlight a widget inside a rotated island (open its hierarchy menu) — the highlight tracks the
  rotated shape.

**R4 — slider thumb drag not axis-tracked in a rotated island (value snaps toward an extreme).**

> **STATUS 2026-07-10: COMPLETE + COMMITTED** (Fizzygum `0895b1d5`, tests `eaa852ea6`; NOT pushed; gauntlet
> dpr1/dpr2/webkit 222/222 + apps/paint/tiernaming/settle/capstone + homepage). Owner-reported: the C↔F converter
> window's sliders became very tricky as the window rotated toward 45° — the value SNAPPED all the way up or
> down — while the thumb's hover/grab still worked. Root cause: 4A-2 fixed the drag-pointer plane mapping for
> ONE `nonFloatDragging` consumer (`HandleWdgt`, which does `newPos = (@screenPointToMyPlane pos).subtract
> nonFloatDragPositionWithinWdgtAtStart`, `HandleWdgt.coffee:315`) but MISSED the other one,
> `SliderButtonWdgt.nonFloatDragging` — it differenced the RAW screen `pos` (`ActivePointerWdgt:1093` passes it
> un-mapped) against the slider's VIRTUAL-plane bounds (`@parent.top()/bottom()/left()/right()`) and clamped,
> so the thumb position (hence value) drifted with rotation. The gap SCALES with the slider's distance from the
> island's rotation anchor: on a widget rotated about its own centre the error is modest (a 40° drag to 75%
> gave 73 vs the correct 80); in a real window the slider sits far from the window centre, so the screen-vs-
> virtual gap is large and the clamp pins to an extreme — the reported snap. Hover/grab work because the
> hit-test (§4.6) and click dispatch (`_pointerPositionInPlaneOf`, R1/4A-1) already plane-map; only the
> nonFloatDragging `pos` was raw. **Fix: one line — map `pos` into the button's plane exactly like `HandleWdgt`**
> (`@offset = (@screenPointToMyPlane pos).subtract nonFloatDragPositionWithinWdgtAtStart`). Off any island
> `screenPointToMyPlane` is identity ⇒ byte-identical dormant. Proof macro `macroSliderDragTracksAxisInRotated-
> Island`: the SAME visual drag (thumb → 75% down the track) yields the SAME value rotated-or-not (80==80;
> pre-fix 73≠80) — a magnitude-free discriminator that also exercises the reproduction.
> - **Audit tail (all four `nonFloatDragging` consumers):** `HandleWdgt` ✅ (4A-2). `SliderButtonWdgt` ✅ (R4).
>   `PaletteWdgt.nonFloatDragging` ✅ ALSO FIXED (owner-requested in the same pass): it sampled `@getPixelColor
>   pos` with a RAW `pos` (its `mouseDownLeft` is fine — clicks are plane-mapped), so drag-picking a colour from a
>   palette inside a rotated island read the wrong pixel (often out of the short backbuffer ⇒ transparent). Fix =
>   the same pattern, mapping the whole screen sample point: `@getPixelColor @screenPointToMyPlane (pos.add …)`.
>   Proof macro `macroPaletteDragPicksCorrectColourInRotatedIsland` (a gray palette picks the SAME colour rotated
>   or not). Needed a public colour reader for the tolerance assert ⇒ added `Color.channelDistanceTo` (macros may
>   not touch private `_r/_g/_b`, layering rule [D]). The FOURTH consumer, `StackElementsSizeAdjustingWdgt.nonFloat-
>   Dragging`, resizes stack cells from the screen `deltaDragFromPreviousCall.x` — a DELTA (vector) needing
>   linear-part mapping; niche (a stack divider inside a rotated island), BANKED (§7.12).
- Symptom: in a rotated window the slider value snaps to an extreme as rotation → 45°; hover/grab are fine.
- Root cause: `SliderButtonWdgt.nonFloatDragging` used the raw screen `pos` against the slider's virtual bounds
  (the second `nonFloatDragging` consumer, missed by 4A-2 which only fixed `HandleWdgt`).
- Test: drag a rotated slider's thumb along its (rotated) axis — the value tracks the axis (identical to the
  un-rotated slider), rather than snapping.

- **Goal:** set rotation/scale on ANY widget; an enclosing `TransformFrameWdgt` is created on
  demand and REMOVED when the spec returns to identity — structural identity restored (matters
  for the dormant guarantee, serialization cleanliness, and byte-identical dormant references).
- **Depends on:** the engine. Independent of 4A/4B. (Sequenced after 4A/4B because it is the
  most structurally invasive — it reparents live widgets — so land it once the interaction
  seams are proven.)
- **Seams:** `TransformFrameWdgt::wrapContent(widget)` (`:74`) already does the wrap (slot box
  = widget bounds, widget becomes the single free-floating child). Unwrap has no method yet.
  Reparent primitives: `add`/`_addNoSettle`, `_reactToChildGrabbed`/`_reactToChildDropped`;
  the self-settling wrapper is `_settleLayoutsAfter` (used throughout `TransformFrameWdgt`).
- **Approach:** add Widget-level `setRotationDegrees(θ)` / `setScaleFactor(s)` (method form —
  Fizzygum does not use JS property accessors; the `= θ` sugar, if wanted, is a thin
  `Object.defineProperty` over the method, decided at implementation time). Logic: if my parent
  is already a single-child island wrapping EXACTLY me → forward to it; else wrap me in a fresh
  island in place (preserving my absolute position). On a set that returns the spec to identity
  → unwrap: reparent the child back to the island's parent at the slot origin, drop the island.
  "Adjusts the existing one" applies ONLY when the island wraps exactly this widget (else a
  second set would nest).
- **Macros (new):** `macroWidgetRotationSugarMaterializes` (set rotation on a bare widget →
  island appears, renders rotated); `macroWidgetRotationSugarRemovesAtIdentity` (set back to 0
  → island gone, tree structurally identical to before, pixel-identical to the bare widget).
- **Risks:** (1) **inspector member-list recapture is expected** — adding `Widget`-level
  methods shifts `macroDuplicatedInspectorDrivesCopiedTargetOnly` (the standing benign-
  recapture rule; run the full gauntlet after, WebKit leg included). (2) Serialization: a
  materialized island must round-trip (scalars only, §4.10); an unwrap must leave NO island in
  the snapshot. (3) Reparent-during-interaction ordering — do the wrap/unwrap through the
  self-settling public tier, never mid-settle.

#### 4D — Pick / drop across islands (the hardest sub-feature)

> **STATUS 2026-07-10 — 4D SPLIT into 4D-1 (drop-IN) + 4D-2 (pick-OUT), owner-gated
> ("4D-1 first, gate, then 4D-2"; owner chose FULL N-deep similitude composition for 4D-2).**
> **4D-1 (drop-IN) COMPLETE + COMMITTED** (Fizzygum `cd87222c`, tests `7dec60dee`; NOT pushed).
> `ActivePointerWdgt.drop` now re-expresses a dropped payload's SCREEN bounds in the target's plane
> when the drop target lives inside a non-identity island: it maps the payload's on-screen CENTRE via
> `target.screenPointToMyPlane` and re-homes the payload's UNCHANGED-size bounds there, so the payload
> becomes content of the transformed thing (native virtual size, correctly rotated/scaled, centred
> where released) instead of keeping its raw screen bounds and double-transforming off the drop point.
> Centre-preserving, NOT a corner-bbox `inverseMapRect` (a rotated rect's screen-corner bounding box
> would inflate + mis-centre — the same reason 4A-2 point-maps instead of adding an `inverseMapVector`;
> `inverseMapRect` stays unimplemented). Guarded by `_isInsideNonIdentityIsland()`, and
> `screenPointToMyPlane` is identity off any island ⇒ byte-identical dormant (only the new macro trips
> it; all 222 prior references unchanged). `screenPointToMyPlane` composes ALL ancestor islands, so the
> remap is already N-deep-correct. NO `_acceptsDrops` flip was needed — a drop-accepting content
> container INSIDE the island (`enableDrops()`) already resolves as the `dropTargetFor` climb target;
> the frame's Phase-1 refusal only bites when the climb REACHES the frame (the single-content sugar
> case, out of 4D-1 scope). Proven by `macroTransformFrameDropIntoRotatedLandsCorrectly` (drop a payload
> onto a 35° container: value-asserts it nested into the island's content AND its on-screen centre
> landed at the release point within 3px; image_2 shows it nested + rotated by the same 35°). Gauntlet
> dpr1/dpr2/webkit 223/223 + apps/paint/tiernaming/settle/capstone + homepage green (suite 222 → 223).
> The stack/menu insert-index (`positionOnScreen`, the raw `@position()` still passed at the drop `add`)
> inside an island is the SAME latent screen-vs-plane point — banked §7.13.
> **4D-2 SPLIT into 4D-2a (pick-OUT to desktop) + 4D-2b (drop-back-INTO + unwrap-on-match), owner-gated
> ("4D-2a first, gate, then 4D-2b"; grab model = loose-unit rules decide).**
> **4D-2a (pick-OUT to desktop) COMPLETE + COMMITTED** (Fizzygum `2dd55413`, tests `78f7512bd`; NOT
> pushed). The Phase-1 escalation guard in `grabsToParentWhenDragged` is REMOVED;
> `ActivePointerWdgt.determineGrabs` resolves the on-hand figure via `Widget._resolvePickOutFigureNoSettle`
> — REUSE the existing island when the grabbed widget is its sole content (Phase-1 whole-figure grab, no
> churn; `macroTransformFrameScaledDragged` relies on it — box.parent == island still holds) or EXTRACT +
> wrap a genuine sub-part via `_pickOutRotatedFigureNoSettle`. **KEY DESIGN FINDING — no
> `TransformSpec.compose`, no matrix decomposition needed.** The accumulated map's LINEAR part is exactly
> (scale = ∏ ancestor scales, rotation = Σ ancestor degrees) — scalar rotations commute + multiply;
> summing integer degrees is EXACT (dodges the atan2 wobble 4B quantized). Two similitudes with the same
> linear part differ only by a translation, so matching ONE point (my centre) coincides the whole figure:
> the fresh island pivots on its slot centre (= my centre), and `localPointToScreen(centre)` (composes all
> N ancestors) says where it was → translate by the difference, no jump. So `TransformSpec.compose` /
> `inverseMapRect` / `inverseMapVector` all stay UNIMPLEMENTED (no-speculative-API). The fresh island is a
> `TrackingTransformFrameWdgt` marked `_materializedBySugar` (behaves exactly like a setRotation'd widget:
> auto-unwrap at identity, scalar serialization). n=1 pixel-identical; n≥2 resamples once (crisper). Off
> any island `_resolvePickOutFigureNoSettle` returns the widget unchanged ⇒ byte-identical dormant. Proven
> by `macroTransformFramePickOutStaysRotated` (grab a loose child out of a 35° 2-child panel → extracted
> into a fresh island carrying rotation 35, panel + sibling stay in the original island, fresh island lands
> on the desktop). Gauntlet dpr1/dpr2/webkit 224/224 + apps/paint/tiernaming/settle/capstone + homepage
> green (suite 223 → 224); ONE benign inspector member-list recapture
> (`macroDuplicatedInspectorDrivesCopiedTargetOnly` image_2/3 — the 2 new Widget methods).
> **4D-2b (drop-back-INTO + unwrap-on-match) REMAINING** — drop a picked figure into another island,
> unwrap-on-match to avoid nested-island buildup, with a round-trip structural-identity assertion (risk 2).

- **Goal:** pick a widget OUT of a non-identity island and it stays visually transformed while
  floating; drop INTO an island and it lands at the correct inner position. Lifts the Phase-1
  no-drop restriction.
- **Depends on:** 4C (reuses materialize/unwrap) and 4A (drop-point plane mapping).
- **Seams:** grab reparents to the hand (`ActivePointerWdgt::grab`, `:295`; records
  `@grabOrigin = aWdgt.situation()`, `:331`; `_beforeBeingGrabbed`, `Widget.coffee:3650`). Drop
  resolves `target = dropTargetFor wdgtToDrop` (`:410-432`) then `target.add wdgtToDrop, …,
  @position()` (`:436`). Drop acceptance = `wantsDropOfChild` → `_acceptsDrops`
  (`Widget.coffee:2998`); the island sets it false (`TransformFrameWdgt.coffee:53`).
  `inverseMapRect` (deferred TransformSpec method) gets its first caller here.
- **Approach:** pick-OUT — when the grabbed widget is inside a non-identity island, wrap it (on
  the hand) in a fresh island carrying the ACCUMULATED similitude of its former ancestor
  islands (concatenate specs innermost→outermost; a similitude ∘ similitude is a similitude, so
  the scalars compose cleanly — scale multiplies, degrees add, anchor maps). Drop-IN — allow
  the island (or its content container) to accept drops, inverse-map the drop point into the
  target plane (`screenPointToMyPlane`), place the child there, and if the dropped payload is
  itself a single-child island whose plane MATCHES the target, unwrap it (avoid nested-island
  buildup). Reuse 4C's wrap/unwrap.
- **Macros (new):** `macroTransformFramePickOutStaysRotated` (grab a widget from a rotated
  island → floating copy stays visually rotated → drop on desktop lands as a rotated island);
  `macroTransformFrameDropIntoRotatedLandsCorrectly` (drop onto a rotated window → payload
  appears at the inner position the screen drop-point maps to).
- **Risks:** (1) spec composition correctness (anchor mapping under composition is the subtle
  part — derive and test at 90° first, where it's exact). (2) nested-island accumulation if
  unwrap-on-match is wrong → growth over repeated pick/drop; assert structural identity after a
  round-trip. (3) `@grabOrigin`/sticky-target logic (`:415-432`) already special-cases
  re-nesting into the pre-grab parent — make sure island wrap/unwrap composes with it.

#### 4E — Suite consolidation + final gate + doc close-out

- Run the full `fg gauntlet` (dpr1/dpr2/webkit + apps/paint/tiernaming/settle/capstone) and
  `fg homepage` after the last sub-step; confirm the dormant references are byte-identical except
  the single expected inspector member-list recapture (4C, `macroDuplicatedInspectorDrivesCopiedTargetOnly`).
- **⚡ SERIALIZATION MAP (2026-07-10, Explore agent): the island round-trip is ALREADY CORRECT BY CONSTRUCTION —
  4E's serialization half collapses to TEST-AUTHORING, no new machinery.** `TransformSpec` is pure scalars +
  optional `Point` anchor (`TransformSpec.coffee:29-37`), serialized structurally as a `{class:"TransformSpec"}`
  record via the registered-class branch (`Serializer.coffee:323-334`) — NO cached matrix (recomputed live on load),
  NO transients, NO `rebuildDerivedValue` (§4.10 intent holds). The island holds NO canvas as an instance field
  (`_refreshIslandBuffer` returns a local); `backBuffer`/`backBufferContext` + the clip caches are already in
  `Widget.@serializationTransients` (`Widget.coffee:42,46-47`). `_materializedBySugar` is a plain boolean serialized
  as-is (intentional, `TransformFrameWdgt.coffee:48`). deepCopy already works (no stamp needed — no cached derived
  state). `TransformFrameWdgt`/`TrackingTransformFrameWdgt` are globals ⇒ `record.class` resolves. The ONLY existing
  serialize macro is `macroSerializeRoundTripWindow` (a plain window — no transform). **Minor hygiene: mark
  `_lastClaimedExtent` (`TransformFrameWdgt.coffee:43`) a serialization transient** (a stale reflow memo re-derived
  on next measure — transients-by-default is the cleaner posture).
- **Serialization round-trip tests (verify by GATE, not code-reading — no conclusions before evidence):**
  - **(a) ✅ LANDED `SystemTest_macroSerializeRoundTripRotatedIsland`** (2026-07-10): explicit rotated
    `TransformFrameWdgt` serialize→destroy→deserialize is PIXEL-IDENTICAL (screenshot refs dpr1/dpr2) and the
    restored `transformSpec` scalars survive. **This is the evidence gate for Bug B model (a)'s premise.** Also
    landed the position-invariance macro **`SystemTest_macroSugarIslandPreservesSiblingOrder`** (desktop z-order +
    arranged-stack slot order preserved across tilt/de-tilt).
  - **(b)/(c) ✅ LANDED `SystemTest_macroSugarIslandSurvivesSerializationRoundTrip`** (2026-07-10): a reloaded
    SUGAR island is still auto-removable ((b): de-tilt the reloaded content ⇒ the island count drops to 0, a
    BEHAVIOURAL proof that `_materializedBySugar` round-tripped — a macro can't read the `_`-prefixed flag), and a
    tilt-then-untilt widget reloads with NO island ((c)). Ends with a trailing settle + a paint-truthful self-
    assert (the earlier paint-audit trip was a MISSING-SETTLE test artifact, not a bug — see §7.5 Bug C, resolved).
- **Index/z-order-preservation macro (STILL OWED — the 4C fix landed; the existing macros used a lone
  world widget so they don't cover it):** materialize a sugar island on a widget that has SIBLINGS
  (both a desktop z-stack and an arranged panel) → assert the sibling order / z-order is unchanged, and
  restored on unwrap.
- Re-introduce the remaining deferred `TransformSpec` methods WITH their first callers only
  (`setAnchor` if/when an anchor UI lands — do NOT add speculative API). **`inverseMapVector` and
  `inverseMapRect` are PROVEN UNNEEDED and must NOT be added "for tidiness":** mapping a displacement is
  just point-mapping BOTH endpoints and subtracting — `M⁻¹p₁ − M⁻¹p₂ = L⁻¹(p₁−p₂)` cancels the affine
  translation, so 4A-2 got the correct delta semantics from `screenPointToMyPlane` alone, and 4D-2a coincided
  whole figures by matching ONE point (no rect/vector inverse). Record this identity so nobody re-adds them.
- Finalize §6 Phase-4 banners (implementation notes + gate results + commit hashes) and mirror
  status into the memory note; then Phase 4 is the feature's shipping point (Phase 5 = §7
  banked follow-ons, each its own future plan).

GATES (every sub-step): `fg gauntlet` green incl. the sub-step's new macros; `fg homepage`
clean; dormant references unchanged (the ONLY sanctioned recapture in the whole phase is the
4C inspector member-list, under the standing benign-recapture justification). A NEW test's
first `capture-macro-test-references.js` run fails (manifest lacks it) then its own rebuild
adds it — RE-RUN once (recurring gotcha, not a bug).

### Phase 5 — BANKED follow-ons (owner-gated; each is its own future plan)

See §7. None of these block declaring the feature shipped.

---

## §7 Banked / deferred work (recorded so ideas are not lost)

0. **⭐ TOP PERF FOLLOW-UP — §4.4 island buffer cache** (promoted 2026-07-10): as-built
   `_refreshIslandBuffer` allocates a fresh canvas and re-rasterizes the whole content subtree on
   EVERY composite (twice per damaged frame: shadow + normal pass) — so the plan's headline "rotation
   animation never re-rasterizes content" (§9/§10.9/§10.10) is NOT yet true. Wire the content-version-
   keyed validity check + virtual-plane buffer-dirty accumulation (§4.4/§4.5): keep the buffer across
   composites, rebuild only the dirty sub-rects, and reuse the same buffer for the shadow pass. This is
   the single biggest island-perf win and makes the design's central claim true. (Distinct from item 1,
   the general layer-policy engine — this is just the static per-island cache the current code stubs.)
1. **Dynamic layer policy engine** — generalize island buffering into per-layer
   `cached-raster | vector-replay` chosen by measured cost (EWMA of replay time vs. rasterize
   cost vs. memory budget, with hysteresis and an LRU eviction pool; eviction falls back to
   replay). Decision table: content-static/transform-animating → cached+warp;
   content-animating/transform-static → replay; both-animating → replay-under-matrix;
   both-static → cached. Correctness override: abutting/tiling content must stay
   raster-under-warp when rotated (seams, §4.2). Policy flips are pixel-identical at identity
   (blit ≡ replay under a deterministic rasterizer — VERIFY before relying on it) but visibly
   different under rotation (soft vs crisp) → under non-identity transforms the mode must be
   sticky/pinned, never per-frame. Refactor `AnalogClockWdgt` as the pilot (face = cached
   layer, hands = replay layer, both under one matrix).
2. **Leaf self-warp** — a leaf widget that already owns a back buffer (text, canvases) can
   composite it through a matrix directly, skipping the wrapper's second buffer; plain
   vector-appearance leaves (rects) can render as transformed paths with no buffer at all.
3. **Quad-aware damage + occlusion recovery** — OBB (4-corner) rejection tests in paint
   descent; `opaqueCoveredRect` for 90°-family islands (still axis-aligned); quad-in-quad
   containment for the frontmost-coverer scan behind rotated widgets.
4. **Rasterization-scale folding ("contentsScale")** — render a scaled island's buffer at
   `scale × ceilPixelRatio` so text/vectors rasterize crisp under zoom (only rotation ever
   resamples). Watch the SWCanvas atlas size-snapping limits (fact 3.7). Long-term this
   unifies `ceilPixelRatio`, per-window zoom, and warp into one per-layer number; world zoom
   = one root island.
5. **Native crisp-rotated-text mode** — render-through on the native backend only;
   pixel-test-excluded by construction. Low priority; Squeak-soft is the accepted look.
6. **Container-level "freeze" veto** for `claimsSpace` (presentation mode: treat all children
   as `'slot'`); build only on demonstrated need.
7. **Appearance conversion to local-logical-coordinate drawing** (through the ctx matrix,
   legacy integer path kept as the identity fast path) — the prerequisite for widespread
   vector-replay; bounded set: the rectangular family + the 9 custom painters (fact 3.5's
   exclusion list enumerates them).
8. **Bilinear (fixed-point) sampling for SWCanvas transformed `drawImage`** — SWCanvas
   currently samples nearest-neighbor by design (`swcanvas.js:1837-1838`; Phase 0f). A
   fixed-point-weight bilinear path (weights quantized so results are integer-exact →
   determinism preserved) would close most of the SW-vs-native visual gap for rotated
   composites AND improve the existing text slow path. SWCanvas-repo work, owner-gated;
   promoted to a prerequisite only if Phase 0f is rejected.
9. **Screen-constant handle size under transform** — inside-attached handles scale with their island
   (§4.6 halo model): double-size at scale 2, small hit targets at 0.5. Design tools keep handles
   screen-constant. Compensation is LOCAL and needs no architecture change: a handle sizes its own
   extent by the inverse of the accumulated ancestor-island scale (query the chain via the same walk
   as `_isInsideNonIdentityIsland`). Bank until a real need; the v1 accepted look is Squeak-consistent
   (handles are part of the transformed figure). Glyph rotation + nearest-neighbor chunkiness on SW is
   the same accepted 0f trade-off, no compensation planned.
10. **Explicit hugging island for content-resize** (banked 2026-07-10, from the R3 review) — R3 gave
   the SUGAR path a size-tracking island (`TrackingTransformFrameWdgt`, §6 R3), so a rotated/scaled
   widget's slot grows with the widget. An EXPLICITLY-authored island (`new TransformFrameWdgt content,
   spec`) is still a FIXED figure: resizing its content past the authored slot clips (the same symptom
   R3 fixed for sugar). The clean future path is to let an author opt into hugging by instantiating
   `TrackingTransformFrameWdgt` for the explicit wrap (it already exists and IS-A TransformFrameWdgt) —
   NOT a per-instance flag (capability is class here, §6 R3). Owner-gated; build only on demonstrated
   need (no current test/app authors an explicit island whose content resizes).
11. **Pinout labels in a rotated island** (banked 2026-07-10, from the R2 audit) — `WorldWdgt.addPinoutingWidgets`
   builds a `StringWdgt` overlay per pinouted widget and places it at `clippedThroughBounds().right()+10` as a
   WORLD child — the SAME latent screen-vs-plane bug R2 fixed for highlights (a pinouted widget inside a rotated
   island gets its label at the virtual-plane rect drawn in screen space → offset). Pinout is a debug/inspection
   overlay, out of the reported repro, so it was left as KNOWN-LATENT. Fix is the identical one-liner pattern:
   parent the label into `widget._enclosingNonIdentityIsland() ? world` (and the offset becomes an in-plane
   offset that rotates with the island). Owner-gated; no current test drives pinout on a rotated target.
12. **`StackElementsSizeAdjustingWdgt.nonFloatDragging` in a rotated island** (banked 2026-07-10, from the R4
   audit) — R4 fixed `SliderButtonWdgt` AND `PaletteWdgt` (the two position-reading consumers); this fourth
   consumer (`src/StackElementsSizeAdjustingWdgt.coffee:55`) resizes stack cells from the screen
   `deltaDragFromPreviousCall.x` — a DELTA/vector that needs the inverse LINEAR-part mapping (not point mapping),
   so dragging a stack divider inside a rotated island would resize by the wrong amount. Niche (no app/test puts a
   resizable stack inside a rotated island); banked until a demonstrated need.
13. **Stack/menu drop insert-index in a rotated island** (banked 2026-07-10, from 4D-1) — the drop passes
   the RAW screen `@position()` as the 6th `add` arg (`positionOnScreen`), which the stack/menu panels
   (`SimpleVerticalStackPanelWdgt`, `ToolPanelWdgt`, `HorizontalMenuPanelWdgt`) consume to compute a
   child-insert INDEX. For such a panel INSIDE a non-identity island the un-mapped point picks the wrong
   slot — the same screen-vs-plane class 4D-1 fixed for the payload's own bounds. 4D-1 fixed the
   payload-bounds remap (every base container) but left this raw, because (a) those panels don't
   `enableDrops()` by default so the path is rarely reachable and (b) there is no stack-in-island fixture.
   Fix is the identical one-liner: map the point via `target.screenPointToMyPlane` before passing it when
   `target._isInsideNonIdentityIsland()`. Owner-gated; build on demonstrated need.

---

## §7.5 KNOWN OPEN BUGS — owner-reported 2026-07-10, ROOT-CAUSED + confirmed headless

Both stem from the SUGAR-ISLAND wrap (`setRotationDegrees`/`setScaleFactor` → `_materializeSugarIslandNoSettle`
wraps the widget in a `TrackingTransformFrameWdgt`, so the widget's `@parent` becomes the island). Confirmed
against the actual `DegreesConverterApp` window in `index.html?sw=1` (scratch `investigate-2bugs.js`).

**STATUS (2026-07-10): BUG A ✅ FIXED + COMMITTED. BUG B ✅ FIXED (model a "move the figure", generic — see
its section). BUG C ❌ was NOT A BUG (an audit-phase error, fixed in the gate).** Two audit follow-ons are
recorded KNOWN-LATENT under Bug B (the basement "only show lost items" GC filter; explicit-island empty frame).

### BUG A — a tilted window takes the INTERNAL skin (should stay external) — ✅ FIXED 2026-07-10

- **Symptom (owner):** "as soon as you tilt a window, it takes the appearance of an internal window."
- **Confirmed (pre-fix):** before tilt `wm.parent=WorldWdgt, isInternal=false, appearance=BoxyAppearance`
  (external, correct); after `wm.setRotationDegrees 15` → `wm.parent=TrackingTransformFrameWdgt
  (_materializedBySugar=true), isInternal=TRUE, appearance=RectangularAppearance` (internal skin — WRONG).
- **Root cause (TWO parts, both needed):**
  1. `WindowWdgt.isInternal` (`WindowWdgt.coffee:184`) derived internal-ness straight from `@parent` (`@parent
     isnt world and isnt hand`). The skin is parentage-derived (no stored flag; `_deriveAndSetBodyAppearance` +
     `setAppearanceAndColorOfTitleBackground` run on every `_reactToBeingAdded`: internal ⇒ `RectangularAppearance`,
     external ⇒ `BoxyAppearance`). The sugar island is a container that is neither world nor hand ⇒ tilted window
     read as "nested" ⇒ internal. So `isInternal` gives the wrong answer while tilted.
  2. Even with a corrected `isInternal`, `_materializeSugarIslandNoSettle` moved the window INTO the island and
     THEN homed the island — so the `_reactToBeingAdded` skin-derive fired while the island was still a detached
     root (`island.parent` nil), reading external. Homing the island afterwards fires `_reactToBeingAdded` on the
     ISLAND, never re-deriving the window, so the wrong skin stuck. (An INTERNAL window tilted in place would
     wrongly go external; the reported external case happened to look right only because external-at-nil matches
     external-final.)
- **Fix as-built (clean, no new method — `WindowWdgt.coffee` `849e79ed`..HEAD src `<this commit>`):**
  1. `isInternal` looks THROUGH any `_materializedBySugar` island(s) to the REAL parent before classifying — a
     sugar island is "this widget is tilted", not a real nesting:
     ```coffee
     isInternal: ->
       p = @parent
       while p instanceof TransformFrameWdgt and p._materializedBySugar
         p = p.parent
       p? and p isnt world and p isnt world?.hand
     ```
  2. `_materializeSugarIslandNoSettle` (`Widget.coffee`) now HOMES the empty island into my former slot FIRST,
     THEN reparents me into it — so the EXISTING `_reactToBeingAdded` derives my skin against the island's true
     (homed) parent, correctly, the first time. This ROOT-CAUSES the ⚠ "is the skin re-derived?" concern the old
     fix-shape flagged — the answer is "derive it at the right moment," not "re-derive it afterward." No corrective
     `_reDeriveSkinFromNesting` method (an early draft added one; deleted as redundant — the two skin-derivers
     already exist and now simply run at the right time). Final tree is identical either way (island at my former
     index, me free-floating inside); homing an empty tracking island is safe (`_reLayoutChildren` no-ops with no
     content, `__add` skips the extent recalc). Byte-identical across the whole suite (gauntlet 226/226 dpr1/dpr2/
     webkit + gates + homepage).
- **Verified:** external window stays external/Boxy AND internal window stays internal/Rectangular, across
  tilt→de-tilt (headless probe `probe-bugA.js` + the test below).
- **Test:** `SystemTest_macroTiltingWindowKeepsInternalExternalSkin` (assertion-only, no screenshot) — builds the
  real `DegreesConverterApp` (external outer + two internal inner windows), asserts `isInternal()` + body-appearance
  class for both windows before/after tilt 15 / after de-tilt 0. Proven to catch the bug: on the buggy build the
  "tilted outer window stays EXTERNAL" assertion fails (`expected true found false`).

### BUG B — closing a tilted window loses its rotation (basement + reopen both STRAIGHT) — ✅ FIXED 2026-07-10

- **✅ AS-BUILT (model a, generic) — Fizzygum src `<this commit>`:** `Widget._enclosingSugarFigure` resolves the
  re-home FIGURE (climbs `_enclosingSugarIsland` to the outermost sole-content sugar island, or me) — the ONE
  greppable re-home verb, sibling of 4D-2a's `_resolvePickOutFigureNoSettle` (pick-OUT extracts; re-home never
  does). `Widget._closeNoSettle` swaps ONLY its `_addLostWidgetNoSettle` argument to `@_enclosingSugarFigure()`
  (my own close bookkeeping still runs on me; `_beforeChildClosed` is a dead no-op hook, never defined).
  `IconicDesktopSystemWindowedApp.launch` re-homes + repositions the FIGURE (`existingWindow._enclosingSugarFigure()`)
  not the plane-resident bare window. **Classification look-through unified:** `Widget._parentThroughSugarIslands`
  (= `_enclosingSugarFigure().parent`) is the ONE idiom for "where does this widget really live"; `BasementWdgt.holds`
  now uses it (else a tilted widget in the basement reads not-held), and `WindowWdgt.isInternal` (Bug A) was
  refactored onto it — no bespoke per-site loop. Verified (probe + test): tilt 15° → close → the island travels
  WHOLE to the basement (rotation preserved, `holds`=true, ZERO desktop islands = leak self-fixes) → reopen →
  island re-homed to world still at 15°, exactly one island; a tilted NON-window widget behaves identically
  (generic). Test `SystemTest_macroTiltedWindowKeepsRotationThroughCloseReopen` (value-assert; catches the bug —
  buggy build fails rotation-preserved / no-orphan / reopen-still-tilted).
- **⚠ AUDIT outcomes (from the design-locked table below):** `BasementWdgt.holds` ✅ FIXED (look-through).
  `hideUsedWidgets` / "only show lost items" filter — **KNOWN-LATENT, RECORDED (not fixed):** its reachability
  (`isInBasementButReachable` via `doGC` GC-session marks, `TreeNode.coffee:160`) walks UP; a sugar island's
  content-window is referenced but the ISLAND (the basement child) is not, so a used tilted window reads as "lost"
  and shows in the filter. Minor basement-UI cosmetic, NOT the core rotation path (reopen keys off `world[@slot]` +
  `existingWindow.parent?`, never `holds`/reachability). Fix later = make basement reachability look through the
  sugar figure to its content. The explicit (non-sugar) island wrapping a closed window (strands an empty frame)
  stays KNOWN-LATENT too (out of scope for sugar-figure resolution).
- **Symptom (owner):** "when you close a tilted window it gets put in the basement — STRAIGHT through. And when
  brought back (its reference/link icon re-opens it) it's put back in the world STRAIGHT." (Try: open the C↔F
  converter via its reference icon, rotate it, close it → it's straight in the basement; re-open via the icon →
  straight in the world.)
- **Confirmed:** after `wm.close()` on a tilted converter → `wm.parent=PanelWdgt (basement scrollPanel contents),
  enclosingIsland=nil (STRAIGHT), inBasement=true`, AND `TransformFrameWdgt islands still in world tree: 1` (the
  now-EMPTY sugar island is left ORPHANED in the world).
- **Root cause (two parts):**
  1. **Close** — `Widget._closeNoSettle` (`Widget.coffee:473`) re-homes `@` (the WINDOW, which is the sugar
     island's content) to the basement via `world.basementWdgt._addLostWidgetNoSettle @`. The window LEAVES the
     island ⇒ un-rotated; the empty sugar island is left behind in the world (a leak). The rotation lived ONLY on
     the transient sugar island (dormant-guarantee: rotation is not a stored property of the widget), so it is lost.
  2. **Re-open** — `IconicDesktopSystemWindowedApp.launch` (`IconicDesktopSystemWindowedApp.coffee:50-56`) for a
     singleton (`@slot` set, e.g. `degreesConverterWindow`) does `existingWindow = world[@slot]; world.add
     existingWindow; …` — re-parents the SAME (already-straight) window to the world. No rotation restored.
- **✅ DESIGN LOCKED by owner 2026-07-10 — MODEL (a) "move the FIGURE", GENERIC scope, SEQUENCED AFTER the 4E
  round-trip tests.** Rejected model (b) "persist scalar on content": it is a second store of the same scalar,
  violates the dormant guarantee, needs explicit orphan cleanup, AND makes close/reopen a destroy-and-rebuild of
  the island (anything holding island state across the cycle — `claimsSpace`, a future anchor, `_materializedBySugar`
  itself — would need re-plumbing). Model (a) preserves it all by construction, and it is the SAME shape the
  serializer already round-trips (island-in-tree ⇒ basement-holds-island-in-tree is congruent). Two enabling facts:
  the basement is a FREE-FORM scatter (`_addLostWidgetNoSettle` → `_addInPseudoRandomPositionNoSettle`), so a rotated
  island lands with no layout fight and its scatter `moveTo` targets the island's ordinary parent-plane slot box (no
  plane mismatch); and since R3 sugar islands are `TrackingTransformFrameWdgt`, so content-bounds fixups on reopen
  are absorbed by slot tracking (no stale-slot clipping).
- **Model (a) implementation shape:**
  1. **ONE canonical figure-resolution helper** (reuse/rename 4D-2a's "resolve the figure" verb — do NOT re-derive
     `_enclosingSugarIsland() ? @` inline at each site; keep re-homing sites greppable). Close/launch route through it.
  2. **`_closeNoSettle`: swap only the RE-HOMING TARGET.** The window's own close bookkeeping (stepping, focus, app
     registry, `_beforeChildClosed`) MUST keep running on the WINDOW; only the `_addLostWidgetNoSettle` ARGUMENT
     becomes the figure (the enclosing sugar island).
  3. **`launch` (reopen): `world.add figure`** and, if it repositions, reposition the FIGURE — moving the bare
     window by screen coords while it is island-resident is a plane mismatch (4A-2 territory).
  4. **Do NOT push figure-resolution into `add` itself** — auto-resolving there would break `dematerialize`, which
     legitimately extracts content FROM its island.
- **⚠ AUDIT before/while coding — every basement/reopen consumer that assumes "basement child == the window" is a
  latent break (fix each with the Bug-A LOOK-THROUGH idiom, not per-site bespoke checks):**
  | site | file:line | risk | disposition |
  |---|---|---|---|
  | `BasementWdgt.holds(w)` = `w.parent == @scrollPanel.contents` | `BasementWdgt.coffee:147` | CONFIRMED breaks — child is the island, so `holds(window)` goes false while the window IS in the basement (the launch "is it closed?" check keys off this) | FIX: look through `w.parent`→its sugar island |
  | `hideUsedWidgets` / `showAllWidgets` + "referenced/used children" classification | iterate `scrollPanel.contents.children` | see islands where they expect windows; hide/show mechanics work, but the "still referenced elsewhere?" classification runs on the island not the window | VERIFY it classifies THROUGH the wrapper, else lost-items filter miscounts tilted windows |
  | other by-reference RE-HOMING sites (window ejection from containers, other launch/restore variants, "send to desktop"-style menu items) | grep | same latent bug | fix now if one-line, else record here |
  | explicit (NON-sugar) island wrapping a closed window | — | strands an empty invisible frame on the desktop | KNOWN-LATENT, out of scope for sugar-figure resolution (record only) |
- **Also FIX THE LEAK** — under model (a) the leak SELF-FIXES (the island is not emptied; it travels whole).
- **Test (macro):** rotate a window, close → screenshot (basement shows it TILTED — this is intended UX under (a),
  surface to owner) → reopen → value-assert the reopened figure's rotation scalar == the set angle, the island is
  parented to `world`, and a STRUCTURAL assert that EXACTLY ONE `TransformFrameWdgt` exists end-to-end (catches both
  the orphan leak and a double-wrap). Assert GENERICITY by also closing+reopening a tilted NON-window widget. If
  cheap, fold in a serialize→reload WHILE basement-resident (discharges part of 4E's basement-resident coverage).

### BUG C — ❌ NOT A BUG — an AUDIT-PHASE error, FIXED IN THE GATE 2026-07-10

- **What triggered the investigation:** the 4E removability test `SystemTest_macroSugarIslandSurvivesSerializationRoundTrip`
  tripped the **paint-truthfulness gate** (`fg gauntlet` `--paint` leg, `run-paint-audit.js`). Owner (design-first)
  called for forensics BEFORE assuming a framework damage bug, or that Bug B was independent, or (a later trap) that
  the macro was at fault — each demand of evidence was correct, and each successive framing was too pessimistic.
- **Root cause (evidence, not inference): a PHASE ERROR in the audit, not a broken-rect bug and not test hygiene.**
  Paint is frame-cadenced BY DESIGN: a public mutator self-settles LAYOUT (geometry converges on return via
  `recalculateLayouts`), but `changed()`/`fullChanged()` only QUEUE damage rects — pixels update once per frame when
  `doOneCycle` reaches `updateBroken()`. So a settled world with queued-but-unpainted damage is the NORMAL mid-frame
  state every mutation passes through, NOT something a macro must clean up. `AutomatorPlayer.checkPaintTruthfulness`
  fingerprinted the live canvas at `stopTestPlaying` — which can land INSIDE the frame (after the last mutation,
  before that frame's paint) — then did `fullChanged()+updateBroken()` and compared. When the last mutation was still
  mid-frame, the audit's own repaint painted it ⇒ before≠after ⇒ FALSE ghost. `takeScreenshot` never had this
  problem: it force-settles via `readyForMacroScreenshot` first. The screenshot path encoded "complete the frame
  before observing pixels"; the audit path forgot it. Proven with a minimal control (`SystemTest_macroGateFixVerify`,
  deleted): a value-assert-ending macro with a final `world.add` and NO trailing yield FAILED the old audit and
  PASSES the fixed one.
- **THE FIX (gate, not tests): `checkPaintTruthfulness` now COMPLETES THE FRAME before baselining** —
  `world.recalculateLayouts()` (also flushes the deferred-settle input lanes) + `world.updateBroken()`, then the
  before-fingerprint. Strictly one-sided: an already-settled test is unaffected (no-ops); a merely-pending frame is
  completed, not flagged; a REAL stale region survives settling by definition (stale pixels are exactly the ones
  nothing queued for repaint). ~2 lines in `AutomatorPlayer.coffee` (guarded on `_recalculatingLayouts`; only ever
  runs under `FIZZYGUM_PAINT_AUDIT`). Macros need NO knowledge of paint — Test 2 ends on its value assertions like
  any other macro (its earlier trailing-settle + self-assert compensations were REMOVED).
- **The de-tilt / dematerialize path is CLEAN (independently established).** The instrumented flesh-out trace
  (temporary log in `WorldWdgt.fleshOutFullBroken`, reverted) showed the de-tilt correctly pushes BOTH the island's
  and the content's frozen 40° footprint (`fullClippedBoundsWhenLastPainted` = `[410@177|110@106]`) as the erase
  source; a step-by-step empty-world diff of the whole round-trip was **0 at every step**.
- **⚠ Measurement note (rigor):** the "~150 px ghost" in the earlier `index.html?sw=1` probes was LOCATED at box
  `[1127,44→1160,72]` — the animated desktop **CLOCK** (top-right), NOT the widget (40° footprint at `[409,176]`);
  the "~84 px" case was the same contamination by INFERENCE (not separately located), but the empty-world zeros carry
  the conclusion regardless. Measure broken-rect diffs in the EMPTY harness world, never `index.html?sw=1`.
- **Bug B:** no shared framework damage bug exists, AND the close-path footprint erase already has its own
  regression macro (`macroClosingRotatedIslandChildClearsFootprint`) — enough to proceed; phrased as what was shown,
  not "confirmed independent" in the abstract.
- **PROCESS LESSON:** "no conclusions before evidence" applies to bug REPORTS, not just fixes. The first Bug C
  write-up asserted a confident SYMPTOM ("user-visible: stale corners linger") derived from the clock-contaminated
  probes — a symptom statement is itself a conclusion. Locate the evidence before writing the symptom.
- **Note (still true):** `_materializedBySugar` is a `_`-prefixed field, so a macro CANNOT read it (layering rule [D]
  regex `/[@.]\s*_[A-Za-z]\w*/` matches field reads too) — the removability test is BEHAVIOURAL (de-tilt ⇒ island
  count drops), which round-trips the flag through actual behaviour.

---

## §8 Gotchas ledger (standing lessons that WILL bite this work)

- **Macro tests:** authored ONLY via `/author-macro-test`; a backtick in a macro COMMENT kills
  the test-.js syntax gate; no complex class static initializers; `?speed=` invariance rules
  apply to references.
- **Zero failed screenshots ≠ pass** — an uncaught error stalls the shard; if a shard stalls,
  suspect a thrown exception in new code, and clear zombie headless browsers (`fg` does).
- **Recapture bakes crash frames in** — after ANY recapture, the WebKit leg is the one that
  surfaces a baked-in crash; always run the full gauntlet after recapturing.
- **Passes-alone-but-stalls-in-suite** = `resetWorld` looping a teardown — check teardown
  ordering before suspecting the feature.
- **deepCopy of derived state** — cached matrices/buffers need the `rebuildDerivedValue`
  stamp (`@serializationTransients` alone is insufficient).
- **CoffeeScript `%%` is BANNED in Fizzygum source** (4B) — it compiles to a call to a `modulo()`
  helper CoffeeScript injects per-file, but the FRAGMENTED in-browser meta-compile does not provide
  it ⇒ runtime `ReferenceError: modulo is not defined` (NOT caught by the build syntax gate, only at
  boot/replay). Use explicit `((x % 360) + 360) % 360`; the codebase uses plain `%` throughout.
- **Latent screen-vs-plane comparisons bite inside islands** (4A-2) — the drag math wasn't the bug; a
  pre-existing `fb.containsPoint(pos)` in the grab path compared VIRTUAL `fullBounds()` to the RAW screen
  pointer, mis-firing only for an island-inner widget and yanking it onto the hand. When touching input/
  drag/hit code for 4D, grep for bounds-vs-raw-`@position()`/`containsPoint(pos)` and map the point
  (`w.screenPointToMyPlane(pos)`) — these are invisible until a non-identity island makes screen ≠ plane.
- **Drag DELTAs need no new vector API** (4A-2) — mapping a displacement through the inverse LINEAR part
  is just point-mapping BOTH endpoints and subtracting: `screenPointToMyPlane(a) − screenPointToMyPlane(b)`
  cancels the affine translation. Reuse `screenPointToMyPlane`; don't add an `inverseMapVector`.
- **Damage-on-detach erases the un-transformed slot** (bug fix 2026-07-10, Fizzygum `86d3ee5e`) — closing/
  destroying (or reparenting-OUT) an island-interior widget left stale pixels in its rotated footprint:
  `_closeNoSettle`/`_destroyNoSettle` call `fullChanged()` while attached, then sever `@parent`; the erase-rect
  is computed LATER in `fleshOut(Full)Broken` via `mapRectToScreen(...WhenLastPainted)`, which walks the
  now-severed chain → identity → erases only the un-transformed slot. FIX: `recordDrawnAreaForNextBrokenRects`
  now freezes the SCREEN footprint at PAINT time (`mapRectToScreen` while attached); `fleshOutBroken`/
  `fleshOutFullBroken` use it directly (byte-identical dormant + attached-island). Owner-reported via a tilted
  DegreesConverterApp inner-window close.
- **⚠ A SCREENSHOT MACRO CANNOT CATCH BROKEN-RECT STALENESS** (bug fix 2026-07-10) — `readyForMacroScreenshot`
  (`MacroToolkit:227`) forces `world.fullChanged()` (a full repaint) before EVERY capture, erasing incremental
  broken-rect staleness. To test a broken-rect bug: read the INCREMENTAL canvas pixels right after the gesture
  (`world.worldCanvasContext.getImageData`, NO `takeScreenshot`), then `world.fullChanged()` + settle and read
  again, and assert 0 RGB-differing pixels (assertion-only, no references) — proven by
  `macroClosingRotatedIslandChildClearsFootprint` (diff 0 fixed / 5257 un-fixed). Use the EMPTY harness world
  (no animated clock) so the fixed-build diff is exactly 0.
- **⚠ PAINT IS FRAME-CADENCED; the paint audit OBSERVES POST-FRAME STATE by construction** (2026-07-10, §7.5 Bug
  C). A public mutator self-settles LAYOUT, but `changed()`/`fullChanged()` only QUEUE damage — pixels land once
  per frame at `updateBroken()`. So pending paint at macro end is the NORMAL mid-frame state, NOT an offender, and
  a macro needs NO knowledge of paint (no trailing `yield` "to settle the canvas"). The suite-wide
  **paint-truthfulness audit** (`AutomatorPlayer.checkPaintTruthfulness`, run at `stopTestPlaying` when
  `FIZZYGUM_PAINT_AUDIT`) was fixed 2026-07-10 to COMPLETE the frame (`recalculateLayouts()` + `updateBroken()`)
  before baselining — matching what `takeScreenshot`/`readyForMacroScreenshot` always did. (Earlier it fingerprinted
  mid-frame → false ghosts; that cost a full Bug-C forensic pass — do NOT re-chase it or re-impose a "macros must
  end settled" rule.) The ONLY real macro-side settle obligation is EVENT-DRAIN sequencing: `yield
  "waitNoInputsOngoing"` between steps when a later step reads state that earlier SYNTHESIZED input events produce —
  unrelated to paint. Also: measure broken-rect diffs in the EMPTY harness world, never `index.html?sw=1` — the
  desktop CLOCK (top-right) ticks between reads and contaminates the diff (LOCATED at box `[1127,44]`, nowhere near
  the widget). Suite-wide lesson mirrored in `Fizzygum-tests/DETERMINISM.md`.
- **Rotation input is SCREEN-plane** (4B) — the rotate handle reads `world.hand.position()` (raw) and
  `island.screenAnchor()`, NOT its 4A-1-mapped position: an in-plane handle reading the mapped
  position would measure the angle in the very plane it is rotating (a feedback loop). Quantize the
  committed `rotationDegrees` to integers (`_quantizeRotationDegrees`) so `DetTrig.atan2` wobble is
  absorbed — clean cardinal snap AND cross-engine determinism in one step.
- **`fg` guard hook** blocks cd-chained cross-repo commands — use `git -C <path>` and the `fg`
  wrappers; don't pipe the build through filters.
- **Commit messages**: never inline backticks/`$()` in `git commit -m` from the Bash tool —
  use `git commit -F <file>`. And NEVER commit/push without explicit owner approval.
- **No conclusions before evidence** — do not write "byte-identical", "deterministic", or
  "safe" into docs/commits until the corresponding gate has actually passed.
- **Perf claims need a minified A/B** — unminified/shadow profiles overstate JS pixel-loop
  percentages.
- **One unified drop-shadow** — do not reintroduce per-part shadows (see §4.8).
- **Scope searches** — never grep from the workspace root (`Fizzygum-builds/` is huge).

---

## §9 Performance expectations (estimates; ⚠ two headline claims are NOT true AS-BUILT — see notes)

- Dormant feature: zero overhead on all hot paths was the DESIGN intent via **one cached
  inside-an-island boolean**. **AS-BUILT (2026-07-10) that flag is NOT yet implemented** — the
  dormant path instead does a *live parent-chain walk* per operation: `screenPointToMyPlane` per
  hit-test candidate (every pointer move), `mapRectToScreen` per flesh-out rect (every damaged
  widget, every frame), and `_isInsideNonIdentityIsland` per grab/handle-show. Each returns
  false/unchanged with no island, so it is almost certainly noise — but it is NEW dormant hot-path
  work under a byte-exact perf culture. **TOP dormant-perf follow-up: implement the cached flag
  (invalidated on reparent / spec change) + the per-event hit-test memoization (§4.6), OR run a
  minified `prof-interactive.js --sw` A/B and update this claim to the measured reality.** The walk
  is consolidated behind `Widget._isInsideNonIdentityIsland` — the natural place to add the cache.
- Identity island: one extra buffer + one extra equal-extent blit per composite (≈ the cost
  every text widget already pays).
- Rotation animation of a static window: per step = matrix update + damage (oldAABB ∪ newAABB) +
  one warped `drawImage`; the layout engine does NOT run (in `'slot'` mode). ⚠ **The "content
  subtree is NOT re-rasterized" claim is the DESIGN goal but is FALSE AS-BUILT: `_refreshIslandBuffer`
  allocates a fresh canvas and re-rasterizes the whole content subtree on EVERY composite, and each
  damaged frame composites TWICE (shadow pass + normal pass). This is correctness-first (documented
  §4.4); the content-version-keyed buffer cache + buffer-dirty accumulation that make the claim true
  are BANKED (§4.4/§4.5) and NOT yet wired. Promoting §4.4 buffer caching is the TOP island-perf
  follow-up.**
- SW warp throughput: estimate 3–10× per painted pixel vs. axis blit (Phase 0c measures).
  Native backend: GPU-composited, expected negligible.
- Occlusion: no culling behind non-identity islands (= pre-2026-07-09 repaint behavior in
  those regions). Recovery is banked (§7.3).

## §10 Facet dossier — fresh-eyes verification pass (2026-07-09)

A second, adversarial pass over the design, facet by facet, done against the actual source
(not the first pass's notes). Each facet states: how the chosen design behaves, what the
pass FOUND (deltas are already folded into §4/§6 above), and the per-facet verdict vs the
alternatives (matrix in §10.11). Findings labeled **[FIX]** changed the spec; **[OK]**
confirmed it.

### 10.1 Coordinates handling

Behavior: one coordinate convention outside islands (today's absolute integer screen coords,
untouched); one inside each island (the virtual plane, numerically coincident with the slot
box region, so identity islands are bit-compatible). Crossing a boundary is explicit
(`screenPointToMyPlane` / `localPointToScreen` / `mapRectToScreen`) and only ever happens at
islands — nested islands concatenate.

- **[OK]** Overlapping virtual planes are harmless: nothing does global spatial queries on raw
  coordinates; hit-testing is a tree descent (`TreeNode.coffee:546`), damage is mapped
  per-widget through its own chain, and `world.broken` only ever holds post-mapping screen
  rects (§4.5).
- **[FIX → §4.6]** Cross-plane actors enumerated and dispositioned: `HandleWdgt` (world-parked,
  manipulates `@target` — restricted in Phase 1, delta-mapped in Phase 4); `CaretWdgt`
  (expected in-plane, verify); menus (hand-positioned — fine). Verified there is NO visual
  connector widget ("Connector" = dataflow method-lane naming).
- **[OK]** Fractional machinery (`desiredExtent`/`desiredPosition`,
  `positionFractionalInHoldingPanel`) is in-plane, unaffected.
- Float hygiene: inverse-mapped points are floats; floor at the `getImageData` boundary
  (§4.6); mapped rects floor/ceil+pad at the damage boundary (§4.3). The MODEL stays integer
  (slot boxes) / exact (scalars) — approximation is confined to composite/hit instants.

### 10.2 Damage rects and redraw

Behavior: inner widgets damage themselves unchanged; rects are plane-mapped at flesh-out,
before any merge/dedupe; the island accumulates virtual buffer-dirty rects; transform changes
damage `oldFootprint ∪ newFootprint` and never dirty the buffer (§4.5 invariant).

- **[FIX → §4.2]** The composite MUST clip to `damageRect ∩ footprint` (path clip): the
  broken-rect contract forbids painting outside the rect (front content isn't repainted
  there — spill = z-order corruption). This was the largest hole in the first draft.
- **[FIX → §4.5]** Both flesh-out lanes (`fleshOutBroken` `WorldWdgt.coffee:863`,
  `fleshOutFullBroken` `:914`) consume per-widget virtual rects in BOTH the source
  (`*BoundsWhenLastPainted` snapshots) and destination lanes — both are mapped; mapping runs
  before `mergeBrokenRectsIfCloseOrPushBoth`/`checkARectWithHierarchy` so merge logic never
  sees mixed planes.
- **[OK]** Shadow growth (`.growBy @maxShadowSize`, `:879-938`) is screen-space and applies
  after mapping — no per-widget shadow-rect work needed.
- **[OK]** The 2015 notes' "third damage option" (AABB of the transformed damage ∩ clip) is
  exactly what corner-mapping the already-clipped virtual rect produces — at option-4 cost,
  because the pre-image is axis-aligned.
- Worst case remains the thin-widget-at-45° footprint AABB (the 2014 note) — correctness
  unaffected, over-repaint bounded by the footprint; quad-aware damage is banked (§7.3).

### 10.3 Clipping

Behavior: inside the island, scroll-frame clipping stays what it is today (rect intersection
of paint areas, fact 3.2) — the virtual plane is axis-aligned, nothing changes. At the
boundary, the island clips its content at the slot box by construction (the buffer edge). On
screen, the composite clips to the damage rect (§4.2) and the footprint respects ancestor
clips (§4.11).

- **[FIX → §4.11]** Clip chains don't commute with transforms — the island must be a
  plane-pure clip terminal for descendants (slot box only) while presenting a screen-space
  footprint (∩ ancestor clips) to the world. Naive single-plane chaining can DROP damage
  (missed repaints).
- **[FIX → §4.11]** "Ink overflow": a rotated island's visible pixels exceed its own slot
  box, so its `clippedThroughBounds`/`fullClippedBounds` overrides must report the footprint,
  and their SLOW-oracle twins must be overridden in lockstep (`Widget.coffee:1059-1083`,
  `doubleCheckCachedMethodsResults` gate).
- **[OK]** Paint recursion cannot accidentally cull the overhang: there is no bounds-based
  descent culling — `preliminaryCheckNothingToDraw` (`Widget.coffee:1905`) checks only
  visibility/empty-clip; each painter self-intersects with the clip. The island's own
  composite does the footprint ∩ damage check.
- **[OK]** Nested clipping composes: outer scroll frame narrows the screen damage rect it
  hands down; the island's composite clip intersects with it; inner scroll frames operate
  virtually.

### 10.4 Hit-testing

Behavior: descent untouched (`topWdgtSuchThat`); predicates test the per-widget plane-mapped
point against unchanged virtual bounds; per-pixel alpha unchanged modulo the mapped point.

- **[OK — better than designed]** Exactness is free: the virtual-plane rect test IS the exact
  rotated-quad test (§4.6). No point-in-polygon code anywhere; corner fall-through between
  overlapping rotated widgets is automatic, including for `noticesTransparentClick` widgets.
  "Hit between widgets" resolves by z-order descent + exact per-plane tests: the pointer
  lands on the topmost widget whose quad (and, where applicable, whose non-transparent
  pixels) contain it, else falls through.
- **[OK]** The island's buffer doubles as its transparency oracle (sample at the
  inverse-mapped point) — per-pixel hit accuracy through rotation for free.
- Perf: one 2×3 inverse-apply per island boundary per tested widget, memoized per pointer
  event (§4.6) — negligible against today's per-candidate `getImageData` calls.
- Residual risk: hover/enter-leave consistency during animation — matrices mutate in the
  step/input phase only, so all tests within one world cycle see one matrix (§10.9).

### 10.5 Back buffers (mixed & dynamic raster/vector within one widget)

Behavior: the island intercepts at the COMPOSITING boundary, not inside anyone's paint — so a
widget's internal mix of cached raster + vector strokes (the clock: `faceBuffer` blit
`AnalogClockWdgt.coffee:98` + `context.rotate` hands `:254-279`) renders into the island
buffer through its completely ordinary paint path (context-translate riding is an existing
documented behavior, `:95-98`).

- **[OK]** Anything a widget can draw against the world canvas it can draw against the island
  buffer — `useLogicalPixelsUntilRestore`, own back buffers, vector content, SW3D
  `putImageData` frames included.
- **[OK]** The dynamic vector-vs-raster *policy* ambition is architecturally compatible and
  deliberately deferred (§7.1): the transform tree (scalars) is orthogonal to the layer tree
  (caches); policy flips are pixel-safe at identity but visibly different under rotation
  (soft vs crisp) → under non-identity transforms the mode must be sticky (spec'd in §7.1).
- Honest cost: while transformed, a region's pixels exist ~3× (leaf buffers + island buffer +
  world canvas). Banked mitigation: leaf self-warp (§7.2) removes the middle copy for
  single-widget transforms.

### 10.6 Occlusion culling

- **[OK]** Correctness is automatic by double-gating: a coverer needs `opaqueCoveredRect()`
  non-nil AND containment (`WorldWdgt.coffee:729-739`); islands are custom painters with
  buffers → nil by the existing gate (`Widget.coffee:1944`) → never chosen as coverers, so
  their over-approximating footprint AABB can never cause a false skip. Islands in FRONT of a
  coverer repaint correctly because the composite is damage-clipped (§4.2).
- **[COST]** No culling behind non-identity islands — those regions repaint as the whole
  world did before the 2026-07-09 occlusion arc. Banked recovery (§7.3): 90°-family islands
  can report an exact axis-aligned opaque rect; general angles need quad containment.
- **[OK]** Phase 4's remove-wrapper-at-identity rule protects the common case (an identity
  wrapper around a maximized window would otherwise silently disable desktop culling).

### 10.7 HTML5 Canvas and SWCanvas support

Both backends already provide every primitive the design needs: `setTransform`, `drawImage`,
path `clip` (native trivially; SWCanvas `Transform2D` `swcanvas.js:1088`, `PolygonFiller` +
`ClipMask` `:18607,18617`). SWCanvas's own text slow path IS the design's primitive, shipped
(`TextRenderer.fillText` `:23559`).

- **[FIX → Phase 0f, §7.8]** SWCanvas `drawImage` is **nearest-neighbor by design**
  (`swcanvas.js:1837-1838`): SW rotated composites are deterministic but aliased; native is
  smoothed. The cross-backend visual gap is therefore bigger than "Squeak-soft" — owner
  acceptance is now an explicit Phase 0 decision, with fixed-point bilinear banked as the
  fix.
- **[OK]** Test strategy unaffected: the suite is SW-only (`?sw=1`,
  `run-all-headless.js:112`); SW is the pixel truth, native is eyeball-verified (Phase 0d).
- **[OK]** No wrapper-class work: the backend split is the canvas factory + prototype
  extension installation (fact 3.7); the island uses only standard context API.
- Determinism dependency: matrix trig must be the shared fdlibm implementation on BOTH
  backends (Phase 0b) — a 1-ULP matrix difference shifts sampled texels under nearest-neighbor
  (no averaging to hide it), so this is MORE critical with nearest than with bilinear.

### 10.8 Interaction with layouts (all couplings)

Behavior: §4.9 — `'slot'` (default; layout never learns), `'footprint'` (one settle per
change, exact at 90° multiples), `'sweep'` (one settle on entry). All three supported
simultaneously in one container; the knob is per-widget on the `TransformSpec`, serializes
and travels with the widget.

- **[FIX → §4.9]** Claimed-box must carry `{extent, slotOffset}` — extent alone places the
  slot box wrong. Extent is translation-invariant (no position→extent feedback loop), so the
  system stays acyclic in every mode.
- **[FIX → §4.9]** Stretch semantics pinned: stretch always binds the SLOT extent;
  footprint/sweep children are measured-not-stretched; the forbidden inversion (solve slot
  extent from a transformed constraint) stays forbidden — it is the documented Lively failure
  mode.
- **[OK]** Layouts INSIDE an island are untouched (virtual plane). Footprint islands inside
  layouts inside other islands compose (claims are computed in the widget's own parent
  plane).
- **[OK]** The document scenario (title CW + plot CCW in a vertical stack) under `'slot'`:
  document geometry frozen, overlap-and-clip by design; under `'footprint'`: the breathing
  document, correct-but-jumpy, documented as sharp-edged; under `'sweep'`: one reflow, then
  stable. Macro-tested in Phase 3.

### 10.9 Step-animating a transformation

Per step, `'slot'` mode: setter updates the scalar → `geometryVersion++` + `fullChanged()`
(cost identical to a `moveBy` of the same widget — the version-keyed caches already absorb
exactly this every frame of any drag today, `Widget.coffee:1304` precedent) → damage
`oldFootprint ∪ newFootprint` → one clipped, transformed `drawImage`. NO layout, NO text
remeasure. ⚠ **"NO buffer re-rasterization" is the DESIGN goal, FALSE as-built** — `_refreshIsland-
Buffer` re-rasterizes the whole subtree every composite (twice per damaged frame: shadow + normal);
the §4.4 content-version buffer cache that makes this true is banked, not yet wired (see §9).

- **[OK]** Ordering guarantee: spec mutations happen in the step/input phase, damage+composite
  in the same world cycle, hit tests between cycles — one consistent matrix per cycle; the
  per-event memoization (§4.6) leans on this.
- **[OK]** Determinism: angle sequences are scripted exact scalars; matrices are pure
  functions through fdlibm trig; SW rendering is deterministic → per-step screenshots are
  stable references (Phase 2 macro).
- **[COST]** `'footprint'` animation = one settle per step (the breathing document) — works,
  deterministic, documented as a feature with sharp edges, never the default.
- Watch item: per-step damage is TWO footprint AABBs; for large rotated windows near 45° this
  approaches 2× the window area per step on the SW backend — the §10.10 numbers apply.

### 10.10 Performance

Cost ladder (estimates until §0-R): dormant = ⚠ AS-BUILT a live parent-chain walk per op (the
"one cached flag" is not yet wired — see §9); identity island ≈ one extra window-sized buffer +
equal-extent blit (= what a text widget already costs); scale-only ≈ same plus unequal-extent
blit; rotated = per-pixel inverse-map + nearest sample within the damage clip (estimate 3–10× per
painted pixel on SW — Phase 0c measures; native composites on GPU).

- Structural wins vs alternatives — ⚠ these are the DESIGN targets, several NOT yet true as-built
  (§9): animation is INTENDED to never re-rasterize content (needs the §4.4 buffer cache — banked;
  as-built it re-rasterizes every composite); occlusion/damage/layout engines never run for `'slot'`
  animation (TRUE as-built);
  the existing `data32.fill` opaque-span fast paths are untouched for everything
  untransformed.
- Structural costs: damage AABB inflation (√2-ish typical, thin-widget-at-45° worst);
  occlusion loss behind non-identity islands; ~3× pixel residency while transformed (§10.5);
  SW warp throughput (§10.7).
- Mitigation ladder, all banked with owners: composite sub-rect (§4.2 — in scope Phase 2),
  per-event inverse memoization (§4.6 — Phase 1), leaf self-warp (§7.2), quad
  damage/occlusion (§7.3), rasterization-scale folding (§7.4), bilinear SW sampling (§7.8).
- Measurement discipline: minified A/B only (standing lesson); harness =
  `docs/profiling/prof-interactive.js --sw`, extended with a rotated-window drag/animation
  phase when Phase 2 lands.

### 10.11 Why this solution over the alternatives (per-facet matrix)

Candidates: **A** = full Lively conversion (parent-relative coords + matrix per widget,
render-through); **B** = render-through matrices without subtree buffers (keep absolute
coords, apply CTM in paint descent); **C** = THIS PLAN (islands: rasterize-straight,
buffer, warp); **D** = dihedral-only tier (90° steps, no general angles).

| Facet | A (Lively) | B (render-through) | C (islands) | D (90° only) |
|---|---|---|---|---|
| Coordinates | rewrite of `bounds` semantics across ~470 files + every cache | unchanged coords, but every paint/hit needs a live matrix stack | unchanged outside; explicit boundary mapping | unchanged, rect swaps |
| Damage | re-derive merge machinery on derived screen rects | per-widget mapped rects, same as C but no buffer to amortize | mapped at flesh-out; pre-image axis-aligned = cheap exact-ish AABBs | exact rects |
| Clipping | scene-graph clip stack | needs path clips per nested clipper under rotation | rect clipping preserved inside; ONE path clip per composite | rect clipping throughout |
| Hit-testing | matrix chain per test (same math as C) | same as C | exact-for-free in virtual space | trivial |
| Back buffers | still needed for text (SW can't rasterize rotated text) → islands anyway | leaf buffers warped individually → **seams at abutting AA edges** (disqualifying) | subtree buffer = seam-free by construction | unchanged |
| Occlusion | re-derive on derived rects | nil coverage under rotation, same as C | automatic correctness via existing double gate | keeps exact opaque rects |
| Canvas/SWCanvas | needs everything C needs | needs everything C needs, plus rotated text per-string every frame | one exercised primitive (transformed drawImage + clip) | plain blits/remaps |
| Layouts | historically the breakage zone (live transformed bounds) | same coupling questions as C | `claimsSpace` menu, acyclic by construction | footprint exact |
| Step-animation | re-rasterize subtree every frame | re-rasterize every frame + per-frame seams | matrix-update + one warp; content never re-rasterized | cheap remaps |
| Performance | O(1) parent moves (its one real win) but months of cache re-derivation | no buffer memory, worst animation cost | buffer memory ↔ cheapest animation; degrades gracefully | cheapest overall, weakest feature |
| Migration risk | months, whole-suite churn | medium; touches every painter | additive; dormant = zero delta (gated) | small |

Verdict: **C dominates on every facet except two honest concessions** — memory while
transformed (vs B; mitigated by §7.2) and O(subtree) parent moves (vs A; unchanged from
today, already compensated by the occlusion arc). B is disqualified outright by AA seams +
per-frame re-rasterization; A is a superset of C's work with months of added risk for no
user-visible gain; D is not an alternative but a subset C gets for free (90° islands are
lossless remaps) — worth surfacing in the UX as snap points. C is also the only candidate
whose dormant state is *provably* today's code.

## §0-R Phase-0 results (RAN 2026-07-09)

**Status: Phase 0 executed. 0a PASSES (STOP condition not triggered). 0f = OWNER ACCEPTED
nearest-neighbor for v1 (2026-07-09) — SWCanvas "crunchy" rotated look is the accepted look;
§7.8 fixed-point bilinear stays banked, NOT a prerequisite. Phase 1 go-ahead GIVEN
2026-07-09.**

Harness lives OUTSIDE the three repos (session scratchpad
`…/scratchpad/affine-phase0/`): `inpage-harness.js` (shared §4.2 composite + §4.3 matrix +
pure-JS SHA-256 + edge inspector), `run-0a.js`, `run-0c.js`, `run-0df.js`, `out/` (JSON +
8 comparison PNGs). No product code written; only this §0-R was edited.

Provenance: macOS 15.6.1 arm64 (Darwin 24.6.0), Node v22.15.0. Chrome = Puppeteer bundled
`HeadlessChrome/127.0.0.0` (V8). WebKit = Playwright `Version/26.4 Safari/605.1.15`
(webkit build 2287, JavaScriptCore). SWCanvas pin `468c5f76…` (matches `vendor/swcanvas.pin`).
Both engines ran deterministic-trig → `DetTrig.install(Math)` → SWCanvas, in that order
(mirroring `build_it_please.sh:540-551`).

### 0a — transformed-drawImage determinism + edge behavior: **PASS**

Faithful §4.2 sequence (`save` → `clip(rect)` → `setTransform(matrix)` → `drawImage(buffer)`
→ `restore`) on a 240×240 opaque checker source into a 512×512 SWCanvas surface, matrix from
§4.3 built with `DetTrig.cos/sin`. IDENTICAL in-page script in Chrome (V8) and WebKit (JSC).
Full 32-byte SHA-256 of the surface pixels is **byte-identical across engines for every
scene**:

| scene | SHA-256 (Chrome == WebKit) |
|---|---|
| 15°            | `9c81610b2eb39fc2b47e7e37510d5ab2f0db9b39e39ef75245830dc25ec16e1b` |
| 30°            | `f12ea20f1931dabc71e3c5cfa963ed617e91027065a3d56cc05b82278eedd79f` |
| 45°            | `b65b00e841d03b276e4bea92240b2cf5da6815b35fe9465785d76066c13fe808` |
| 90°            | `08dc99267ef47238b8edec220714870c61f3477dccf3c4aa93f2dfb60c1576e1` |
| scale 1.7×     | `048e5b9525df2677ada488ae5ae8691cb0b6041ccc4857034d662e2038d2eaa0` |
| 45° + 1.7×     | `74e7c82ccacdb12036c12a331d44e0b4c9824def18e4c41f53d61dc2b2dd09d2` |
| 45° partial-clip | `a5bb34bd02d1167fd2b12bd6539018fa9c3d376af9bc1ef706540203f5ec5951` |

**Edge / AA inspection (measured, not assumed):** every scene's whole 512×512 surface has
exactly **two distinct alpha values (0 and 255)** and **zero partial-alpha pixels**. The 45°
mid-scanline goes transparent→opaque at x=87 and opaque→transparent at x=426 with no
in-between coverage (alpha histogram `{0: 204683, 255: 57461}`). ⇒ the transformed
`drawImage` produces **hard, aliased quad edges — no anti-aliased coverage** — and the rect
`clip()` edge is a clean 1-bit axis-aligned boundary. This is the nearest-neighbor behavior of
fact 3.7 / §7.8, confirmed directly, and is the root of the 0f visual question.

**Caveat on the control (reported honestly):** a "native trig" control (same scenes, matrix
built with the platform `Math.cos/sin`) ALSO produced identical Chrome-vs-WebKit hashes on
these specific browser builds, and `Math.cos(15°)`/`sin(15°)` were bit-identical across the
two engines here. So THIS run did not, by itself, reproduce the historical ~1-ULP cross-engine
trig divergence — the sampled angles (15/30/45/90 + their cos/sin) fell in the majority that
agree on these builds. It does NOT weaken the PASS: the DetTrig path is deterministic **by
construction** (pure `+−×÷`/`sqrt`, no host transcendentals), and the historical clock-test
campaign already established the divergence that motivates the shim. Scope note: because the
island composites via `setTransform` + `drawImage` (never `ctx.rotate`/`arc`), the ONLY trig
in the island's hot path is the §4.3 matrix build — which 0b pins to DetTrig — so this test
covers the island's actual determinism surface.

### 0b — deterministic trig exposure: DECISION = call `DetTrig.cos/sin` explicitly

Located the port: **`Fizzygum/runtime-prelude/deterministic-trig.js`** (a faithful SunPro
fdlibm port; 345 lines; `+−×÷`/`sqrt` only). It exposes `globalThis.DetTrig` = `{ sin, cos,
tan, atan, atan2, asin, acos, install }` and, per its header, **does NOT auto-install** (so
tests can compare against native). `build_it_please.sh:540-551` prepends it to
`fizzygum-boot-min.js` and runs `DetTrig.install(Math)` BEFORE the SWCanvas engine, so
SWCanvas's own `Math.cos/sin` calls become deterministic at runtime.

Decision for §4.3 matrix code: **call `DetTrig.cos(θ)` / `DetTrig.sin(θ)` explicitly** — not
raw `Math.*`. Rationale: (a) install-order-independent (correct even if some path runs before
`install`); (b) self-documenting about the determinism requirement; (c) `DetTrig` is on
`globalThis` in every build (the prelude is prepended unconditionally, gated by
`vendor/swcanvas.pin`); (d) works identically on BOTH backends, satisfying §4.3's requirement
that damage/hit-test math agree with SW-rendered references. **No porting is needed** — §6 task
0b's fallback ("port the ~2 functions into `src/boot/`") is unnecessary; the functions already
exist and are globally exposed.

### 0c — warp micro-benchmark (minified `swcanvas.min.js`, Node/V8): calibrates §4.7

Fixed 1.05-Mpx opaque source (1024²), dest 1600². Median of 3 runs (very stable, ±2%):

| mode | ms / composite | ns / source-px | Mpx/s | × axis blit |
|---|---|---|---|---|
| raw `data32` row copy (floor) | 0.11 | 0.10 | ~9600 | 0.02 |
| **axis blit** (identity translate) | **6.4** | **6.1** | **163** | **1.00** |
| scale blit (uniform 1.7×) | 16.5 | 15.7 | 63 | **2.58×** |
| rotated blit (45°) | 11.5 | 11.0 | 90 | **1.80×** |
| rotated + scale (45° × 1.7×) | 15.9 | 15.2 | 65 | 2.48× |

Findings that **revise §4.7's "3–10× per painted pixel" downward**: the per-pixel warp math is
NOT the cost driver. Rotation's ~1.8× wall-time multiplier comes almost entirely from
**AABB inflation** — a 45° 1:1 blit iterates the ~2.0-Mpx bounding box but only ~1.05 Mpx land
inside the quad (the rest hit a cheap `destPoint < dst` reject); per *iterated* pixel it costs
~5.6 ns, essentially the SAME as the axis blit's 6.1 ns. Uniform scale is the MOST expensive
(2.58×) simply because 1.7× covers ~2.9× the area (all opaque writes), not because scaling is
hard. Net: transformed composites here are **≤2.6× the axis-blit wall-time**, driven by
area/AABB, not by the sampler. Separately, the JS per-pixel `drawImage` loop is ~60× slower
than a bulk typed-array copy (6.1 vs 0.10 ns/px) — i.e. the identity fast path (§4.2) matters,
but that fixed cost is the same one every text/back-buffered widget already pays today (fact
3.2), consistent with §9. Native backend composites on the GPU (0d/0f visual only; not timed).

### 0d + 0f — SW (nearest) vs native (bilinear), nearest-neighbor acceptance

Method: a straight-rasterized "island buffer" (real `fillText` + line art) warped through the
SAME DetTrig matrix by (i) SWCanvas `drawImage` = nearest (`?sw=1` pixel truth), (ii) native
`drawImage` `imageSmoothingEnabled=true` = bilinear (production native), (iii) native nearest
(isolates the sampler). 8 side-by-side PNGs (1:1 + 5× nearest-zoom), for content ∈
{text, line-art} × angle ∈ {15°, 45°} × dpr ∈ {1, 2}, in `out/0f_*.png`.

Measured visual findings (0d = the native panels; 0f = the SW-vs-native gap):
- **The gap is ENTIRELY the sampler.** native-nearest ≈ SW-nearest in every case (same
  chunky staircases), so the difference vs production native is bilinear-vs-nearest, not
  V8-vs-anything. Confirms the island's cross-backend look is a sampling choice, isolated.
- **Text:** SW nearest is legibly "crunchy" at dpr 1 (visible staircasing on glyph stems);
  native bilinear is smoother. At **dpr 2 the 1:1 renders are nearly indistinguishable at
  physical size** — the difference only surfaces in the 5× zoom.
- **Line art (the harder case):** a genuine TRADE-OFF, not "native better". SW nearest keeps
  thin lines **solid/full-contrast but staircased**, and can **drop/dash a 1-px line** when
  the inverse-map lands between source rows (a sampling-PHASE artifact that persists even at
  dpr 2). Native bilinear keeps lines continuous but **softens them to low-contrast gray**.
- **dpr 2 materially closes the gap** for both content types at physical viewing size (modern
  HiDPI displays are the common case).

**Recommendation (owner decides): ACCEPT nearest-neighbor for v1.** It is deterministic
(required by the SW-only pixel-test suite), legible, and dpr-2-mitigated; its one real wart —
thin-line dropout in rotated line art — is narrow and is exactly what the banked §7.8
fixed-point bilinear would fix. If the owner rejects the look, §7.8 (bilinear SWCanvas
`drawImage`, integer-exact weights) is promoted to a Phase-0-blocking prerequisite per §6.

**OWNER DECISION 2026-07-09: ACCEPTED** — nearest-neighbor is the accepted v1 look. §7.8 stays
banked (not a prerequisite). Phase 1 authorized.

### §3 drift found (report-only; NOT a STOP — dependency intact)

- **§3.7 wording is imprecise.** It says "SWCanvas carries an fdlibm-based shim." In fact the
  vendored `vendor/swcanvas/swcanvas.js` calls **raw `Math.cos/sin`** (e.g. `:760-761`,
  `:1193-1194`, `:9177`), and the fdlibm port is **Fizzygum-side**
  (`runtime-prelude/deterministic-trig.js` = `DetTrig`), globally installed over `Math.*` by
  the build before SWCanvas loads. The determinism *dependency* the plan relies on ("matrix
  trig must be the shared deterministic sin/cos") is fully INTACT and cleaner than described
  (0b). Suggest amending §3.7's phrasing to "Fizzygum installs `DetTrig` over `Math.*`; SWCanvas
  consumes it" — but that edit is out of scope for Phase 0 (only §0-R was to be modified).
- **Anchors verified accurate:** `swcanvas.js:1837-1838` nearest-neighbor comment (exact);
  the transformed `drawImage` inverse-map loop is `_drawImageInternal` (`:24421`, nearest via
  `Math.floor`, `:24575-24577`); `run-all-headless.js:112` uses `?sw=1&dpr=…&speed=…` (0e,
  exact). SWCanvas Core API used: `Core.Surface(w,h).data`, `createCanvas().getContext('2d')`
  (setTransform/rect/clip/drawImage/getImageData/toDataURL all present).
