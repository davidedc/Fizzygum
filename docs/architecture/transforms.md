# Affine widget transforms (rotate / scale islands)

How Fizzygum rotates and scales a widget subtree **now**. This is the present-tense
reference for the transform subsystem: the "island" model, the canonical
`TransformSpec`, the two-vocabulary geometry law, layout coupling, input plane-mapping,
the rendering/caching path, and how duplication/save preserve a transform.

Related evergreen docs (do not duplicate — this doc points):
- Two-vocabulary geometry naming, full API table: `docs/archive/affine-geometry-api-plan.md`.
- Integer placement/sizing policy: `docs/architecture/integer-pixel-placement-and-sizing.md`.
- Layout / settle / arrange mechanics: `docs/architecture/layout.md`.
- Serialization/duplication internals: `docs/architecture/serialization-duplication-reference.md`.

---

## 1. The mental model: a transform is an "island", not a widget property

A widget carries no rotation/scale of its own. A transform lives on an **island** — a
`TransformFrameWdgt` (`src/TransformFrameWdgt.coffee`) that wraps exactly one content
subtree and owns one `TransformSpec`. The island is the Squeak/CSS-compositor primitive:
an **invisible clipping frame** that rasterizes its content **un-transformed** into a back
buffer, then composites that buffer **through the transform** at paint time.

Everything inside the island uses ordinary absolute Fizzygum coordinates as if the island
were untransformed — the **virtual plane**. The transform is applied only at composite
time. So layout, arrange, settle, and content code never see the matrix; only rendering,
damage-mapping, and hit-testing do.

`TransformFrameWdgt extends PanelWdgt` to inherit `ClippingAtRectangularBoundsMixin`: a
clipping frame whose bounds-recursion terminates at itself and whose children clip to its
box. The island's own `@bounds` is the **slot box** — integer, axis-aligned, absolute,
ordinary Fizzygum geometry that layout sees. The frame paints no chrome of its own
(`@appearance = @color = @strokeColor = undefined` in the constructor), so an **identity** island
is byte-for-byte just its children painted normally.

**Dormant guarantee.** When a spec is identity (`TransformSpec::isIdentity` — an exact test
on the canonical scalars, `rotationDegrees % 360 == 0 and scale == 1`), every override in
`TransformFrameWdgt` falls back to stock `PanelWdgt`/`Widget` behaviour via `super`. An
identity island is a plain invisible clipping panel; the whole feature adds zero behaviour
on any hot path when no non-identity island exists. This is why the subsystem can ship
"always on" — off-island code paths are unchanged, object-for-object.

### 1.1 Two island classes

- **`TransformFrameWdgt`** — the base island. A **fixed figure** for its parent's layout:
  it reports a claimed extent, is never stretched, and does **not** define `_reLayoutChildren`,
  so a free-floating child's `_invalidateLayout` climb stops at it. This is the
  explicitly-authored island.
- **`TrackingTransformFrameWdgt`** (`src/TrackingTransformFrameWdgt.coffee`) — a *size-
  tracking* variant whose slot (`@bounds`) **hugs** its content child's bounds. It defines
  `_reLayout`/`_reLayoutChildren`, so it participates in the settle loop's ordered up-edge
  like `SimpleVerticalStackPanelWdgt`/`ScrollPanelWdgt` (tracking-container capability is a
  *class*, never a per-widget flag). It also carries the **layout-transparency** overrides
  (§5). `implementsDeferredLayout` is pinned `false` so defining `_reLayout` does not flip
  its resize classification away from the base island's.

### 1.2 Rotation/scale "sugar" on a plain widget

Any widget can be rotated/scaled without an author ever naming an island. `Widget`
(`src/basic-widgets/Widget.coffee`) exposes the property sugar `setRotationDegrees` /
`setScaleFactor` (self-settling wrappers over `_setRotationDegreesNoSettle` /
`_setScaleFactorNoSettle` → `_applyTransformSugarNoSettle`). The shared core finds the enclosing
**sugar** island (`_enclosingSugarIsland` — one that `_materializedBySugar` **and** wraps exactly
this widget as sole content), applies the partial spec change, and:

- If none exists and the target is non-identity, **materializes** one in place
  (`_materializeSugarIslandNoSettle`): creates a `TrackingTransformFrameWdgt`, sets
  `_materializedBySugar = true`, homes it into the widget's former parent slot + layoutSpec
  (position-invariant — no z-order raise), then reparents the widget into it as a free-floating
  child (holding-panel / stack bookkeeping rides across via `_moveHoldingPanelBookkeepingTo`).
- **Dematerializes** the island if the spec returned to identity
  (`_dematerializeSugarIslandIfIdentityNoSettle`), reparenting the widget back at the island's
  index + layoutSpec and dropping the empty island — restoring the exact pre-materialize structure.

Only a **sugar-materialized** island auto-removes at identity; an explicitly-authored island
stays (merely dormant). The `_materializedBySugar` boolean serializes, so a saved-then-
reloaded sugar island stays sugar-removable. The getters `rotationDegrees()` / `scaleFactor()`
mirror the sugar setters' scope; `accumulated*()` walks **all** ancestor islands (sugar +
explicit) for the total visual transform (rotations sum, scales multiply — a similitude).

---

## 2. `TransformSpec`: the canonical description

`src/TransformSpec.coffee` describes a **similitude** — uniform scale + rotation about an
anchor. The design rule: **the scalars are canonical and exact; the 3×2 matrix is derived on
demand and never stored as truth.**

- **Canonical scalars (the only serialized state):** `rotationDegrees` (float),
  `scale` (float > 0), `anchor` (`undefined` ⇒ slot-box centre, else a `Point` in slot-box/plane
  coords), `claimsSpace` (layout-coupling mode, §5). Extracting angle/scale back out of a
  matrix is what forced Lively's epsilon-hacks — Fizzygum never does it, so `isIdentity`'s
  `% 360 == 0` / `== 1` tests stay exact.
- **IMMUTABLE.** A `TransformSpec` is never mutated after construction: the owning island
  replaces its whole spec through the withers (`withScale` / `withRotationDegrees` /
  `withAnchor` / `withClaimsSpace`), each returning `this` when the value is unchanged and a
  fresh spec (through the constructor, preserving its `scale > 0` normalization) otherwise.
  The withers are deliberately named `with*`, not `set*` — a `set*` name would collide with
  the widget-side self-settling wrappers and false-trip the layering gate. Being an immutable
  value it declares `keptByReferenceOnDeepCopy`, so deep copies share the spec instance.
- **Matrix is cheap and derived.** `matrixForSlot(slotBounds)` returns `{a,b,c,d,e,f}` for
  `p' = A + s·Rot(θ)·(p − A)` mapping slot/virtual coords up to the island's **parent** plane;
  `inverseMatrixForSlot` is its exact inverse (for hit-testing). Because the matrix is derived
  there is no cached-matrix bookkeeping to get wrong under `deepCopy` — only scalars serialize.
- **Point maps:** `mapPoint` (forward, virtual → parent plane) and `inverseMapPoint`
  (parent → virtual). There is deliberately no `inverseMapRect` / `compose` / `inverseMapVector` —
  point-map both endpoints and subtract for deltas.
- **Rect maps — two twins:**
  - `mapRect` (via `_mapRectWithMatrix`) → the **integer, padded** AABB of the 4 transformed
    corners (floor mins, ceil maxes, **+1px** for AA bleed). This is the **damage / footprint**
    box, safe to feed the damage-rect machinery unchanged.
  - `mapRectExact` (via `_mapRectExactWithMatrix`) → the **exact, unpadded, possibly-fractional**
    AABB of the same corners. This is the **screen-family** backing store — never fed to
    layout/moveTo. Kept as a parallel method so `mapRect`'s proven damage padding stays
    byte-untouched.
- **Trig.** `_cosSin` returns exact `[1,0]` with **no trig call** for a zero angle (identity
  and pure-scale specs have no trig dependency); a non-zero angle goes through the shared
  deterministic `DetTrig` port (§9). `Math.PI` and `Math.sqrt` are IEEE-exact across engines,
  so the sweep-square and matrix `e/f` terms are deterministic.

---

## 3. The two-vocabulary geometry law

Under an island, a widget's screen position is **not** its bounds position. Fizzygum resolves
this by splitting the geometry API into two families **distinguishable by name** (canonical
spec: `docs/archive/affine-geometry-api-plan.md`; law summary also in `Fizzygum/CLAUDE.md`):

- **Layout-box family** — `width` / `height` / `extent` / `bounds` / `boundingBox` /
  `position` / `center` / `left` / … : the widget's **own-plane** layout box. Plane-local,
  untransformed, **integer**. Inside an island these are virtual-plane values. Transforms never
  affect them. Layout / settle / arrange / content code operate on these — the load-bearing
  invariant.
- **Screen family** — every name contains **`screen`**: `screenBounds`,
  `localPointToScreen`, `screenPointToMyPlane`, … : post-transform screen-plane values,
  **possibly fractional**. Never feed them to layout / moveTo.

The rule is total: no non-`screen` method returns transformed geometry; no `screen` method
returns plane-local geometry. The Widget-level accessors (`src/basic-widgets/Widget.coffee`):

- `screenBounds` — walk `@parent` innermost→outermost, mapping the box's corners through each
  non-identity ancestor island's **exact** matrix (`mapRectExact`). No clip, no padding.
  Identity fast path returns `@boundingBox()` (same object).
- `localPointToScreen(aPoint)` — a virtual-plane point up to screen, each ancestor island's
  **forward** map innermost→outermost.
- `screenPointToMyPlane(aPoint)` — a screen point down into this widget's plane, each ancestor
  island's **inverse** map outermost→innermost. Used by hit-testing (§7).

All three return the point/rect **unchanged** (same object) off any non-identity island, so
they are byte-identical when dormant. The island's own `clippedThroughBounds` / `clipThrough`
"two faces" (§7) are framework-internal damage/hit machinery, **not** a public screen-bounds
proxy — which is exactly why `screenBounds()` exists.

---

## 4. Slot box, footprint, and the island's two faces

The island presents two different rectangles to two different audiences
(`TransformFrameWdgt`):

- **To descendants** (`clipThrough`, consumed via `firstParentClippingAtBounds`): the **slot
  box only** — a plane-pure clip terminal. Ancestor *screen* clips do not commute with the
  transform, so they are deliberately **not** intersected here; they are applied to inner
  damage *after* mapping, in the flesh-out hook (`Widget::mapRectToScreen`).
- **To the outer world** (`clippedThroughBounds` / `fullClippedBounds`): the **screen
  footprint** = `mapRect(slot box)` ∩ the ancestor screen-clip chain (`_screenFootprintForDamage`
  ∩ `_ancestorScreenClip`). Larger than the slot box when scaled up ("ink overflow").

Both cached methods have `SLOW*` oracle twins overridden in lockstep for the
`doubleCheckCachedMethodsResults` gate.

---

## 5. Layout coupling & transparency

### 5.1 `claimsSpace` — what an island reserves from its parent's layout

`TransformSpec.claimsSpace` picks how much space a non-identity island claims (methods
`_claimedBoxFor` / `claimedExtentFor` / `slotOffsetWithinClaim`):

- **`footprint`** — **THE DEFAULT**. The corner-mapped integer
  AABB of the transformed slot box. Changes with angle/scale, so the parent **reflows on a
  transform change**. Serves the document author: a rotated image must not overlap the text
  below it.
- **`slot`** — paint-only ("Lively firewall"): the claimed box is the slot box itself; the
  parent reserves nothing extra and **never reflows** on a transform change. An expert opt-in.
- **`sweep`** — the anchor-aware circumscribed square (`_sweepSquareFor`): depends on
  scale/extent/anchor but **not** angle, so a spinning figure reflows once then stays put.

A non-identity island is a **fixed figure** for arrange: `preferredExtentForWidth` reports the
claimed extent (never stretched), `_applyExtentBase` early-returns to keep `@bounds` the slot
box, and `_applyMoveToBase` parks the slot at `claimedOrigin + slotOffsetWithinClaim`.
Reflow-on-transform-change is gated to `claimsSpace != 'slot'`
(`_reflowIfClaimChangedNoSettle`, memoized on `_lastClaimedExtent`). Public mutators
(`setScale` / `setRotation` / `setClaimsSpace`) are self-settling wrappers over `*NoSettle`
cores; the settle resolves a coupled island's reflow.

Because `footprint` is the default, a halo-rotate drag inside a tracking container reflows its
siblings **per drag event** (each settle re-reserves the rotated AABB) — the owner-accepted D1
implication (`rotationHalo_apply` note).

### 5.2 Scroll reachability (the D2 twin)

Layout and *reachability* answer different questions: even a `slot` island claims nothing from
siblings, yet its rotated ink must still be scrollable-to. `TransformSpec.scrollOverflowBoxFor`
returns **claimed box ∪ the ink's integer hull** (the unpadded exact mapped AABB, floor/ceil'd
— nested inside the sweep square at every angle). `TransformFrameWdgt` exposes it as
`scrollOverflowBoundsInParentPlane` (undefined at identity) for the enclosing scroll frame's content-
extent merge, and re-fits that frame when the box changes
(`_reFitScrollFrameIfReachChangedNoSettle`, memoized on `_lastScrollOverflowBox`).

### 5.3 Layout transparency (the tracking island)

`TrackingTransformFrameWdgt` is the **fourth member of the sugar-island transparency family**
(hit / interaction / reparent / **layout** — see
`docs/archive/drop-into-rotated-container-layout-transparency-plan.md`). The invisible sugar
wrapper is plumbing, so a **parent-driven sizing protocol** must pass through to its sole
content — otherwise a widget dropped into / rotated inside a stretchable panel or a vertical
stack never stretches on a container resize.

- `_applyExtent` — **deliberately NOT mode-gated**: a *dictating* container (stretchable-panel
  fractions, a window sizing its content) owns its children's geometry, and that contract holds
  in every `claimsSpace` mode. It forwards the extent to the content, then re-hugs the slot
  (`_reLayoutChildren true`, arrange-driven).
- The **stack protocol trio** — `preferredExtentForWidth` / `_setWidthSizeHeightAccordingly` /
  `getMinimumExtent` — **is** mode-gated (the S2 mode gate): under `slot` they forward
  transparently to the content; under a coupled mode ('footprint'/'sweep') they fall back via
  `super` to fixed-figure behaviour — `preferredExtentForWidth` reports the claimed extent
  (the base island's override), while the other two fall through to the plain `Widget`
  defaults (`getMinimumExtent` reads the stored `@minimumExtent` field). So the coupled
  island measures as a fixed figure, and the `footprint` default reaches the mainstream case
  (a halo-rotated image in a document is a sugar = tracking island).

The **content→slot** hugging direction (`_reLayout` sync-settles a pending content, then
`_reLayoutChildren` re-hugs) stays for all modes. Slot-set is `@bounds = newSlot` directly (the
established island slot-set idiom); the buffer rebuilds from `@bounds` on the next composite, so
content stops clipping at the frozen footprint.

### 5.4 The LENS declarations — an island's content-stack preferences ARE its content's knob

The content-stack spec (layout.md §4.2) holds preferences about the DISPLAYED thing's nature
("empty vertical space around a clock is meaningless") — and the island displays exactly that
thing, transformed; it has no content-nature of its own. Same doctrine as `isTransparentAt` /
the escalate-only click / `resolvesEditorSelectionToContent`: the invisible wrapper adds no
behavior of its own. So base `TransformFrameWdgt` overrides the two content-stack initialisers
(`initialiseDefaultFrameContentLayoutSpec` / `initialiseDefaultVerticalStackLayoutSpec`) to
DELEGATE creation to `_soleContent()`'s own class-specific initialiser and SHARE the object —
identity-mapped by both graph engines, so edits made through the island hit the one knob the
content resumes on unwrap (a rotated clock's window stays height-locked while wrapped; a
rotated stack element adopted by a document applies the content's alignment/grow edits). One
seam asks while the island is still EMPTY — `_materializeSugarIslandNoSettle` homes the island
into a FrameWdgt former parent BEFORE reparenting the content (the skin-derivation order), and
the frame's mount guard runs the initialiser right then — so the materialize PRE-SEEDS the
island's field with the content's knob before homing.

The island's **`colloquialName` is the third lens member**: it reads through to
`_soleContent()`'s name ("transform frame" only when empty), so a window bar / inspector
title / console title naming the island names the displayed thing (dev-facing hierarchy and
menus stay CLASS-named — they never ask `colloquialName`). Its timing twin of the pre-seed:
the frame bar CAPTURES the name at mount, during the materialize's empty window, so the
island's `_reactToChildAdded` nudges `FrameWdgt.noteContentsNameMayHaveChanged()` (an
intent-named public note, the `noteWallpaperChanged` idiom) once the content arrives.

Pinned by `SystemTest_macroIslandLensWindowHeightLock` (identity + name oracles, the
wrapped-resize height-lock, the bar reading "analog clock" while wrapped) and the two
`.scratch` kept-spec probes' C/D/E sections.

---

## 6. Pinned anchors

The `anchor` is `undefined` (⇒ slot-box centre) for the entire un-resized population. A `undefined` anchor
derives from the slot centre and rides moves for free. But a resize of a rotated figure would
move the derived centre and rigidly translate every persisting screen point by `(I − sR)·delta`
— the title bar of a collapsed tilted window would visibly jump. The fix (§7.5 **Bug D**) is to
**pin** the anchor at its current absolute point across extent changes:

- **Set/pin.** `TrackingTransformFrameWdgt._reLayoutChildren` pins the anchor on a
  **content-driven** extent change (`@transformSpec.anchor = @transformSpec._anchorFor @bounds`)
  and translates an already-pinned anchor on a pure move; it **un-pins** (back to `undefined`) when the
  anchor coincides with the new slot centre again (canonical minimal form).
- **Cleared on arrange.** On an **arrange-driven** re-fit (`arrangeDriven = true`, forwarded from
  `_applyExtent` / `_setWidthSizeHeightAccordingly`) it **clears** the anchor: the parent's
  fractional model owns placement, so a stale pinned anchor would telescope and drift the render
  off the slot. Clearing it re-glues render to slot.
- **Pinned anchors ride moves.** A pinned anchor is an absolute plane point, so it must ride a
  rigid translation of the island. `TransformFrameWdgt` overrides the three distinct move
  primitives — `_applyMoveBy`, `_applyMoveByBase`, `__commitMoveBy` — each adding `delta` to the
  anchor. Dormant off pinned anchors (the guard skips a `undefined` anchor).
- **Pick-up normalization** (§7.5 **Bug G**). Before a figure travels across planes,
  `_normalizePinnedAnchorNoSettle` re-expresses a pinned-anchor similitude as its rendering-
  identical **undefined-anchor** form (translate the whole figure by
  `t = (I − sR)(A − centre)`, computed by `TransformSpec._nilAnchorEquivalentTranslation`).
  **Order matters:** read `t` while the anchor is still pinned, undefined the anchor, *then* translate
  — else the move-level anchor-rides would drag `A` along and void the algebra. Integer rounding
  of `t` costs ≤1px, accepted at a grab (a new state).

---

## 7. Input under transform

Pointer events are **plane-mapped** before they reach a handler. The dispatcher
(`ActivePointerWdgt`, `src/ActivePointerWdgt.coffee`) hands every handler a plane-mapped `pos`
**parameter**, and hit-testing runs in the plane where a widget's virtual geometry lives:
`w.screenPointToMyPlane(@position())` maps the raw screen pointer down through each ancestor
island's inverse transform, so a widget's bounds test, corner fall-through, and per-pixel
transparency (`isTransparentAt`) come out exact for free. Off every island `screenPointToMyPlane`
returns the same point ⇒ byte-identical dormant.

The island itself is invisible plumbing and never claims a hit: `isTransparentAt` returns `true`
and `noticesTransparentClick` is `false`, so the hit-test predicate never selects the frame — a
click descends into content first, then falls through empty content to what is behind.

**Gate.** A build-time lint (`buildSystem/check-raw-pointer-reads.js`, in the static-check
suite — see `docs/architecture/lint-and-static-checks.md`) **bans** a pointer-event handler body
(`mouse*` / `wheel` / `nonFloatDragging` / …, closures included) from consuming the raw
screen-plane `world.hand.position()` unmapped. Consume the mapped `pos` parameter, or map at the
read site with `screenPointToMyPlane` on the same line (the drag-scroll idiom). Off-island the
mapped point *is* the raw point, so the bug class is invisible until a widget is **tilted** —
which is exactly why it needs a structural gate rather than review.

---

## 8. Rendering

The island intercepts at the content-recursion point
(`_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow`): identity → stock
invisible-panel blit; else → `_compositeIslandBuffer`. Three composite paths, picked by the spec
(`TransformFrameWdgt`):

- **identity** — stock clipping-panel blit (byte-identical to the bare children).
- **pure scale** (`_compositeScaleOnly`) — the **whole buffer** drawn through the one
  slot→dst mapping under a rect clip to the damage region (`clipToRectangle`, no
  `setTransform`); every mapped rect stays axis-aligned. The clip — not a src sub-rect —
  is what confines the draw: under the smoothing sampler a per-strip src sub-rect would
  give each damage strip its own rounded mapping (a half-texel phase shift) and starve
  edge taps, so an incremental composite would visibly diverge from a full one at strip
  seams; one continuous mapping + clip makes strips byte-identical to the full composite
  by construction (pinned by `SystemTest_macroOversizedShadowChildInScaledIslandRepaintsBuffer`'s
  numeric A/B). At an INTEGER scale the composite sets `imageSmoothingEnabled = false`
  for the one draw: an integer axis-aligned upscale is pure pixel duplication — crisp,
  information-preserving — and both backends honor the standard flag, so native and
  SWCanvas agree at every scale (integer crisp-NN, non-integer smooth).
- **rotation** (`_compositeTransformed`) — render-straight-then-warp: `ctx.transform` composes
  `(device × island matrix)` onto the incoming CTM and `drawImage`s the buffer onto the slot box
  under a **mandatory** real path clip to `(damage ∩ screen footprint)`. A transformed
  `drawImage` cannot express the damage-rect clip via src/dst rects, and a spill would paint over
  un-repainted front content (z-order corruption). v1 warps the **whole** buffer under the clip
  (correctness-first).

  **Sampling contract (SWCanvas).** SWCanvas's `drawImage` samples **bilinear** whenever
  the draw actually RESAMPLES the source: any non-axis-aligned transform (`b ≠ 0 || c ≠ 0`
  — every rotated composite), and any axis-aligned draw whose **effective sample step ≠ 1**
  (the per-device-pixel source step `invA·xScale` / `invD·yScale` — the CTM scale and the
  src/dst rect ratio COMPOSE, so a `ctx.scale` re-blit and a rect-scaled blit both count,
  while dpr-2's scale(2)×half-size-rect compensation steps exactly 1 and does not).
  Step-1 axis-aligned draws — every plain blit, glyph, back-buffer and shadow-scratch
  blit — keep the historical nearest-neighbor bytes BY CONSTRUCTION. The bilinear path
  samples at the dest pixel center, filters **premultiplied** (the arbitrary RGB under the
  buffer's transparent background cannot fringe into edges), treats taps outside the
  source sub-rect as transparent black, and reduces bit-exactly to the pure texel when a
  sample lands on a texel center — so an exact-90° composite with integer translation
  stays crisp, no blur. `imageSmoothingEnabled` is implemented per HTML5 (default `true`,
  boolean, save/restore state, both API layers; `false` forces nearest-neighbor for every
  transform). Fizzygum sets it `false` in exactly ONE place: `_compositeScaleOnly`'s
  integer-scale opt-out (§ above) — never at any step-1 site, whose bytes need no flag.
  WHY bilinear on rotation: nearest-neighbor's floor-quantized sample point periodically
  lands on the texel BESIDE a 1-2px source feature, disintegrating hairline strokes and
  selection overlays into dashes — a compensating wrapper (`TrackingTransformFrameWdgt`)
  resamples TWICE (±θ) and suffers it worst. WHY smooth on scale: native smooths scaled
  draws by default, so NN scaled islands were the one remaining visible backend
  divergence; and NN downscale DROPS rows/columns (dashed diagonals, vanished hairlines)
  where bilinear averages them. v1 sampled nearest-neighbor everywhere; the rotation half
  landed first (bilinear arc), the scale half second (scale-smoothing arc). Contract
  pinned SWCanvas-side by `tests/core/057-drawimage-rotated-bilinear-contract.js` +
  `tests/core/058-drawimage-scaled-smoothing-contract.js` (step-1 byte-equality, the
  opt-out, seam-free clipped composition); Fizzygum-side by
  `SystemTest_macroRotatedStrokedRectSingleComposite`,
  `SystemTest_macroDropStrokedRectIntoRotatedPanel`, and the scaled-island references.

### 8.1 The island buffer cache

The content subtree is rasterized **un-transformed once** and kept across composites
(`docs/archive/island-buffer-cache-plan.md`), so a transform-only change (rotation/scale step,
island drag) re-warps with **zero** re-rasterization, and a content change re-rasterizes only the
dirty sub-rect. Fields on `TransformFrameWdgt` (all **derived render state**, listed in
`@serializationTransients`, dropped on `deepCopy` via `_reactToBeingCopied`):

- `_islandBuffer` — the kept content canvas (physical pixels).
- `_islandBufferSlotExtent` — the slot extent it was built at (the realloc key; a slot **extent**
  change forces a full rebuild, a pure move keeps the buffer).
- `_islandBufferDamageRects` — `undefined` (clean) | a **coalesced disjoint rect-list** (virtual coords) |
  `"all"`.
- `_islandBufferGeneration` — the `WorldWdgt.immutableBackBufferGeneration` the buffer was built
  at.
- `_islandShadowSilhouette` — the black-silhouette twin of `_islandBuffer` the shadow pass
  composites (§8.2); cleared by every `_rasterizeIslandContent` (the one funnel for buffer-pixel
  changes), so it rebuilds at most once per content change and never on a pure transform change.

`_refreshIslandBuffer` forces a full rebuild when there is no buffer, on a slot-extent change, or
when `_islandBufferGeneration != WorldWdgt.immutableBackBufferGeneration` — the **async glyph-
atlas invalidation**: SWCanvas warms text atlases asynchronously, and when one warms the immutable
text-back-buffer epoch bumps, so this downstream cache must rebuild from the now-warm text (a
render change with no `_changed()` event — the one non-event invalidation the cache needs; native
never loads an atlas, so the epoch never bumps). The cache is active only when both the global
kill-switch (`WorldWdgt.islandBufferCacheEnabled`) and the per-island opt-in (`cachesBuffer`) are
on; the OFF path is byte-identical to the pre-cache rebuild-every-time.

**A transform change never dirties the buffer** (`_transformChangedNoSettle` — the §4.5
invariant: buffer content depends only on virtual content; the matrix affects only compositing).
Content-damage rects are deposited **only** from the two damage flesh-out lanes
(`Widget::mapRectToScreen` with `depositBufferDamage = true`, and the source lane) via
`_depositIslandBufferDamageRect`, which grows each rect by `expandBy(1).growBy world.damageRectMargin`
(a child's shadow + AA fringe) and coalesces the disjoint list. A cost ceiling
(`_coalesceDamageList`, gated by `WorldWdgt.damageRectListEnabled` and the class constants
`ISLAND_DIRTY_MAX_RECTS` / `ISLAND_DIRTY_AREA_FRACTION`) collapses the list to its bounding box
when N clipped subtree walks would cost more than one bbox walk
(`docs/archive/island-buffer-cache-rectlist-plan.md`). The identity path never reads the buffer,
so returning to identity drops it (`_dropIslandBufferIfIdentity`).

### 8.2 Shadows and damage-rect under rotation

The island is transparent (`@appearance = undefined`), so it casts its **content's** shadow, not a box
silhouette: `_fullPaintIntoAreaOrBlitFromBackBufferJustShadow` reverts to the base `Widget`
shadow-paint. Because the warp composes onto the incoming CTM (which carries the unified shadow
pass' offset translate), the warp lands the shadow at the correctly rotated/scaled place — no
quad-silhouette special case. What gets composited in the shadow pass is **not** the buffer
itself but its **black silhouette** (`_shadowSilhouetteOfIslandBuffer`: the buffer's alpha
channel with every visible pixel black, via a `source-in` fill — cached as
`_islandShadowSilhouette`, see §8.1): the recursive shadow paint blackens every widget's fill
(`appliedShadow? ⇒ Color.BLACK`) before applying the shadow alpha, and the composite must match
it. Re-tinting the buffer's own colours at shadow alpha instead is the trap: a near-white
window's "shadow" would then *lighten* the desktop.
Per-pixel coverage (AA fringes, semi-transparent content) carries through the silhouette, so
partially-covered pixels shade proportionally, exactly as in the recursive pass. Regression
guard: `SystemTest_macroTiltedFigureShadowAsDarkAsStraight` (numeric A/B — survives reference
recapture). Broken-rect repaint stays correct
because damage crosses each island via `mapRectToScreen` (virtual → screen AABB, clipped in the
screen plane against the outermost island's visible rect), and the mandatory composite clip
guarantees the warp touches only the damage region.

---

## 9. Determinism & accepted limitations

- **Deterministic trig.** ECMAScript leaves `Math.sin/cos/tan/atan2/asin/acos`
  implementation-approximated (only `+ − × ÷` and `sqrt` are correctly-rounded everywhere), and
  V8 vs JavaScriptCore disagree by ~1 ULP on 10–20% of trig values — which shifts SWCanvas'
  rotated output a pixel or two per engine and breaks the exact SHA reference match. The fix is
  `DetTrig`, a faithful JS port of SunPro's **fdlibm** computed only with `+ − × ÷` and
  `Math.sqrt` (`runtime-prelude/deterministic-trig.js`). The build prepends the shim to the boot
  bundle and runs `DetTrig.install(Math)` **before** SWCanvas loads (`build_it_please.sh`), so
  every rotated composite is engine-independent. `TransformSpec._cosSin` routes non-zero angles
  through it; the zero-angle fast path takes no trig at all. (`HandleWdgt` likewise uses `DetTrig`
  for its rotate-angle math.)
- **Sampling: smooth whenever the draw resamples; integer zooms crisp by policy.** SWCanvas
  `drawImage` samples bilinear on rotation AND on axis-aligned draws whose effective sample
  step ≠ 1 (§8 sampling contract); step-1 blits stay byte-exact nearest-neighbor.
  `imageSmoothingEnabled` is implemented (default true; Fizzygum's one opt-out is the
  integer-scale island composite, which renders crisp pixel-duplication on BOTH backends).
  Accepted nuances: at an island's outer boundary the smoothing sampler fades the last
  pixel against the background (taps outside the buffer are transparent) where native
  edge-clamps — ~1px of extra anti-aliasing; 90°-multiple ROTATED islands take the
  smoothing sampler even at integer scale (the spec matrix carries ~1e-16 trig residues
  at quadrant angles, and NN's floor through a residue-skewed inverse picks wrong texels
  — extending the crisp policy there needs quadrant-exact `_cosSin`, see `docs/BACKLOG.md`);
  and bilinear minification below ~0.5× aliases (native's bilinear tier does too — a
  box-filter/mipmap tier is future work).
- **Whole-buffer warp (v1).** `_compositeTransformed` warps the entire buffer under the clip
  rather than a sub-rect (correctness-first). The sub-rect optimisation is banked.
- **≤1px at a grab.** `_normalizePinnedAnchorNoSettle` rounds its compensating translation to
  integer pixels — a ≤1px shift accepted at a pick-up (a new state).
- **Integer own-plane placement still holds.** Widgets remain integer-placed **in their own
  plane**; only the screen-family queries are derived/fractional (§3, and
  `docs/architecture/integer-pixel-placement-and-sizing.md`).

---

## 10. Duplication, save, and pick-up preserve the transform

A widget's rotation/scale lives on its enclosing island, not on the widget, so any operation that
"takes the widget" must take the **figure** (widget + island plumbing). The one look-through idiom
is `Widget::_enclosingIslandFigure` — it climbs through sole-content island(s) and returns the
outermost island (or the widget itself off any island, byte-identical dormant). Entry points
(`src/basic-widgets/Widget.coffee`):

- **Duplicate** (`duplicateMenuAction`) — `fullCopy` the figure (its `deepCopy` deep-copies the
  `TransformSpec` for free), offset from the figure's position; the copy's `_applyMoveTo` rides a
  pinned anchor along.
- **Duplicate + pick up** (`duplicateAndPickItUp`) — same figure resolution, then
  `_normalizePinnedAnchorNoSettle` first (the hand-carry pipeline assumes a slot-centre pivot). Public
  API with no menu item since arc 3 phase 7 — the one "duplicate" item means copy-in-place.
- **Pick up** (`pickUpMenuAction`) — `_resolvePickUpFigure` (the same resolution the drag pipeline's
  `determineGrabs` uses, so a menu pick-up and a drag grab take the same thing), then `pickUp`.
- **Save to file** (`saveToFile`) — serialize the figure, not the bare content: the Serializer
  clears the root's parent, and serializing bare content actually **throws** a `SerializationError`
  (the content still references its island). The filename stays derived from the content.

Related look-throughs: `_parentThroughIslands` (container-side, for classification like
`FrameWdgt.isInternal` / bin residency) and `_dropPolicyProxy` (payload-side, so a tilted
window is seen as a window by drop policy). Full serialization internals:
`docs/architecture/serialization-duplication-reference.md`.

---

## 11. History, future work & case law

- The subsystem was built by the (still-open, as-built-documented) **affine transforms** arc.
  Banked / deferred work lives in `docs/plans/affine-transforms-plan.md` §7 — not enumerated
  here.
- The `§7.5 KNOWN BUGS` dossier in that plan (Bugs A/B/D/E/F/G; C was an audit-phase error) is the
  as-built record of the interaction/reparent/anchor edge cases summarized above.
- The island-over-per-widget-local-coordinates decision was re-examined 2026-07-24 against
  Maloney's Morphic retrospective and the Morphic 3 / Cuis VectorGraphics record, and
  REAFFIRMED — the decision record, the evidence, and the falsifiable reopen conditions are
  that plan's §5-R.
- Archived closed plans (see `docs/archive/INDEX.md`):
  - `affine-geometry-api-plan.md` — the two-vocabulary API + `mapRectExact` (full table).
  - `island-buffer-cache-plan.md` + `island-buffer-cache-rectlist-plan.md` — the buffer cache and
    disjoint damage rect-list.
  - `drop-into-rotated-container-layout-transparency-plan.md` — island layout transparency on
    resize.
  - `duplication-and-save-preserve-transforms-plan.md` — the enclosing-island figure lookup at
    duplicate/save/pick-up.
  - `claimsspace-footprint-default-and-scroll-reachability-plan.md` — the D1 (`footprint` default)
    and D2 (scroll reachability) decisions.
  - `island-content-preferences-plan.md` — the LENS declarations (§5.4): content-stack
    preferences + `colloquialName` read through to the content; ⚖ a lens answer a consumer
    CAPTURES during the materialize's empty window needs a pre-seed or an arrival-time nudge.
- The `footprint`-default flip (owner decision D1, 2026-07-17) makes a sugar-rotated document
  image reflow its siblings per drag — the current, intended behaviour, not a regression.
