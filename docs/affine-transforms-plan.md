# Affine transforms for widgets (rotated / scaled windows) — design + phased execution plan

**STATUS: AUTHORED 2026-07-09, hardened same day by an adversarial fresh-eyes verification
pass (§10 facet dossier; three correctness fixes folded into §4: composite damage-clip §4.2,
plane-purity/two-faces §4.11, flesh-out mapping order §4.5; one new fact: SWCanvas drawImage
is nearest-neighbor → Phase 0f owner decision). NOT STARTED. Owner-gated; do not begin a
phase without owner go-ahead.**

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
- Deterministic trig: cross-engine trig differs by ~1 ULP; SWCanvas carries an fdlibm-based
  shim (this was a past campaign; see memory note "SWCanvas deterministic trig"). **Any
  Fizzygum-side matrix construction MUST use the same deterministic sin/cos** (Phase 0 task
  0b locates and exposes it) or rotated references will differ across engines.

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
- **Cross-plane actors** (widgets that read/write ANOTHER widget's geometry — enumerated by
  the fresh-eyes pass, §10.1): `HandleWdgt` lives on the world/hand and manipulates
  `@target`'s bounds (`src/HandleWdgt.coffee:41,82-89`) — Phase 1 refuses handles on widgets
  inside non-identity islands, Phase 4 maps drag deltas through the inverse rotation.
  `CaretWdgt` does geometry math against `@parent`/`@target`
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

> **PHASE 1 (2026-07-09) — COMPLETE + ALL GATES GREEN + COMMITTED (owner-reviewed, not pushed).**
> Steps 1–6 done; the ONE deferred item is the click-through MACRO (behaviour is
> headless-probe-verified; the macro needs a `Widget::localPointToScreen` forward-map + a verb).
> GATES: `fg gauntlet` = dpr1 **200/200** · dpr2 **200/200** · webkit **200/200** · apps · **paint**
> (no over-repaint offenders) · settle · capstone — ALL PASS. `fg homepage` production build boots
> clean. `doubleCheckCachedMethodsResults` coherence probe PASS (island two-faces == SLOW twins,
> incl. nested in a clipping panel). Dormant guarantee held (zero reference changes; the sole
> recapture was the benign inspector member-list, from the 2 new `Widget` members). Details below.
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
> STILL TODO for Phase 1: the click-through MACRO (behaviour is probe-verified; needs a
> `Widget::localPointToScreen` forward-map + a macro verb that clicks a widget at its SCREEN
> centre) and the full 3-engine gauntlet incl. a `doubleCheckCachedMethodsResults` leg. NOTE:
> `mapPoint`/`inverseMapRect` and `setRotationDegrees`/`setAnchor` remain deferred (dead-method
> gate) — re-introduced with their first callers (Phase 2 / Phase 4). Adding `mapRectToScreen` +
> `screenPointToMyPlane` to `Widget` shifted one inspector member-list test
> (`macroDuplicatedInspectorDrivesCopiedTargetOnly`) — recaptured (benign, per standing rule).

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

### Phase 4 — UX + the Lively-flavored API

1. Halo/handle rotation (precedent: `src/HandleWdgt.coffee`): drag to rotate around the
   anchor; snap to 0/90/180/270 within ~3°.
2. Property sugar: `widget.rotation = θ` / `widget.scale = s` auto-materializes a
   `TransformFrameWdgt` around the widget (or adjusts the existing one), and REMOVES it when
   the spec returns to identity (structural identity restored — important for the dormant
   guarantee and for serialization cleanliness). Note the standing inspector lesson: adding
   members to a common base is inspector-safe only if the member panel hides inherited
   members — check how the inspector treats new `Widget`-level accessors before adding them.
3. Pick/drop across islands: picking a widget out of a non-identity island wraps it in a
   fresh single-child island carrying the accumulated similitude (concatenate specs if
   nested); dropping INTO an island inverse-maps the drop point and unwraps if the target
   plane matches (Phase 1's no-drop restriction is lifted here).
4. Resize handles on transformed widgets: map drag deltas through the inverse rotation so
   edge-drags move the visually-correct edge.
5. Macro tests: rotate-via-handle (scripted pointer drag); snap behavior; pick from rotated
   window → floating widget stays visually rotated → drop on desktop; drop into a rotated
   window lands at the correct inner position.

GATES: `fg gauntlet`; plus one full `fg recapture`-free run (recaptures in this phase should
be limited to genuinely new references; recapturing an EXISTING reference needs the standing
justification — benign inspector member-list changes only).

### Phase 5 — BANKED follow-ons (owner-gated; each is its own future plan)

See §7. None of these block declaring the feature shipped.

---

## §7 Banked / deferred work (recorded so ideas are not lost)

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

## §9 Performance expectations (estimates — UNMEASURED until Phase 0c/§0-R)

- Dormant feature: zero overhead expected on all hot paths (one cached boolean per widget for
  the inside-an-island flag; verify no measurable regression via the existing
  `docs/profiling/prof-interactive.js --sw` harness).
- Identity island: one extra buffer + one extra equal-extent blit per composite (≈ the cost
  every text widget already pays).
- Rotation animation of a static window: per step = matrix update + damage
  (oldAABB ∪ newAABB) + one warped `drawImage`; the content subtree is NOT re-rasterized and
  the layout engine does NOT run (in `'slot'` mode). This is the headline win over
  render-through designs.
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
`oldFootprint ∪ newFootprint` → one clipped, transformed `drawImage`. NO buffer
re-rasterization, NO layout, NO text remeasure.

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

Cost ladder (estimates until §0-R): dormant = zero new hot-path work (one cached flag);
identity island ≈ one extra window-sized buffer + equal-extent blit (= what a text widget
already costs); scale-only ≈ same plus unequal-extent blit; rotated = per-pixel inverse-map +
nearest sample within the damage clip (estimate 3–10× per painted pixel on SW — Phase 0c
measures; native composites on GPU).

- Structural wins vs alternatives: animation never re-rasterizes content (buffer static,
  matrix-only updates); occlusion/damage/layout engines never run for `'slot'` animation;
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
