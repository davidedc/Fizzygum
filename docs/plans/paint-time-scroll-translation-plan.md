# Scroll as a clamped paint-time translation — dissolving the moved-plane model

> **PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
> Authored 2026-08-19 against Fizzygum master `44bba15e` / Fizzygum-tests master `6da0e1300`
> (both pushed; gauntlet 17/17 at these heads). Every `file:line` here is a hint that WILL
> drift — the method name and the quoted code are authoritative; grep them fresh before
> trusting any line number. STATUS: **no phase started; Phase 0 spikes are MANDATORY before
> any later phase.**
>
> This is the BACKLOG item `archive/scroll-frame-role-architecture-plan.md` §7.6
> ("transform-island scrolling"). ⚠ That alias is a MISNOMER the fact-check falsified: the
> island machinery is NOT the carrier (§6 route A below). The honest name is the one this
> file carries.

## §0 Orientation

Fizzygum (CoffeeScript, single `<canvas>`, damage-rect repaint, Morphic descent) inherits
Morphic's ABSOLUTE COORDINATES: a widget's `@bounds` normally IS its screen rectangle, and
scrolling therefore PHYSICALLY MOVES a contents plane — `ViewportWdgt` slides its `@contents`
panel and every descendant with it (one `_applyMoveBy` subtree bounds-rewrite per scroll
step), and the scroll offset is *derived*: `getScrollX: -> @left() - @contents.left()`.

Two prior arcs set this plan up:

- **The scroll-frame role arc (2026-08-19, archived:
  `docs/archive/scroll-frame-role-architecture-plan.md`)** produced the current vocabulary —
  `ViewportWdgt` (chrome composite: contents panel + two `SliderWdgt` bars; `scrollPolicy
  'auto'|'never'`), the plane ROLE (`ScrolledPaneWdgt` default), `PanelWdgt` the pure
  surface — and the scrolled-content contract (`docs/architecture/viewports-and-planes.md`,
  the living truth). Its §7.6 banked THIS arc.
- **The affine-transforms arc** produced the transform islands (`TransformFrameWdgt`,
  `docs/architecture/transforms.md`) and, crucially, the TWO-VOCABULARY LAW: inside an
  island, `@bounds` is PLANE-LOCAL integer (layout-box family) and screen positions are
  DERIVED (screen family — every name contains `screen`, possibly fractional). The framework
  already knows how to break "bounds == screen rect" locally; scrolling is the second,
  far more common customer.

**The critical reframe (why now, sharpened 2026-08-19).** The §7.2 menu-sandwich revisit
re-falsified width-owning content as direct viewport contents and identified the REAL
conflict: under the moved-plane model the viewport must OWN its plane's frame (sole frame
committer), so any self-frame-writing plane livelocks (`RECALC_NONCONVERGENCE`; measured
two-writer oscillation, recorded in `docs/BACKLOG.md` §7.2 refusal). A paint-time offset has
NO second frame-writer — the viewport stops committing content-hull-sized frames entirely.
This arc is therefore not just a coordinates cleanup: it is the only architecture in which
the pop-up rows sandwich (`PopUpRowsPaneWdgt`) and the arrange's densest case-law
(anchor-merge, grow-to-fill, `keepContentsInViewport` nudges, `managesOwnScrollPinning`) can
ever dissolve.

**Mandate: complete elimination of the moved-plane model.** The scroll offset becomes STORED
TRUTH (two integer scalars), applied as a clamped paint-time translation; the plane is
PINNED at the viewport's content origin forever; `_applyMoveBy`-as-scroll-engine dies;
scrollability becomes a capability any clipping container can carry (the viewport is the
first user; scrollable desktop/islands become cheap follow-ons, not re-architectures).

## §1 The mechanism as it stands today (verified 2026-08-19)

### 1.1 Paint — one shared plane, self-locating widgets

The recursion carries ONE damage rect and never translates the ctx per widget:
`WorldWdgt._repaintDamagedRects` → `Widget.fullPaintIntoAreaOrBlitFromBackBuffer` (~:2882) →
`_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow` (~:2941) paints self then
`@children.forEach (child) -> child.fullPaintIntoAreaOrBlitFromBackBuffer aContext,
clippingRectangle, appliedShadow` — the `clippingRectangle` descends UNCHANGED. Each widget
self-locates: `Appearance._paintInLocalScope` clips to the damage box in device px
(`al/at = damageBox.left/top() * ceilPixelRatio`, from `@bounds` directly) and translates
the ctx by `@widget.position()`. Clipping containers narrow the DESCENDING RECT, not the
ctx: `ClippingAtRectangularBoundsMixin._fullPaintIntoAreaOrBlitFromBackBufferContent…`
(~:119) intersects `@boundingBox()` with the rect and recurses.

**The in-tree proof that a bufferless paint-time translation is cheap** — the shape already
exists twice:
- the shadow pass, `Widget._fullPaintIntoAreaOrBlitFromBackBufferJustShadow` (~:2920):
  `clippingRectangle = clippingRectangle.translateBy appliedShadow.offset.neg()` then
  `aContext.translate offset.x * ceilPixelRatio, offset.y * ceilPixelRatio` and recurse —
  cull rect −offset, ctx +offset, done;
- the island buffer rasterize, `TransformFrameWdgt._rasterizeIslandContent` (~:526):
  `bctx.translate -slot.origin.x * ceilPixelRatio, …` then the ordinary child recursion.

### 1.2 The islands are raster-warp — NOT the carrier for scrolling

Island children do NOT paint through an island ctx matrix: content rasterizes UN-transformed
into a per-island back buffer and the affine touches the ctx exactly once, at the buffer's
composite `drawImage` (`_compositeTransformed` / `_compositeScaleOnly`). Consequences,
each verified:
- **every non-identity island pays a buffer** (slot × dpr² × 4 B + a shadow-silhouette twin;
  even cache-OFF rasterizes a throwaway buffer per composite) — a per-scrolled-pane buffer
  is exactly the cost scrolling must not pay;
- **`TransformSpec` cannot express a translation at all** — it is a similitude
  `p' = A + s·Rot(θ)·(p−A)`; at s=1,θ=0 the anchor cancels and `isIdentity()` (
  `rotationDegrees % 360 == 0 and scale == 1`) reads it as identity and skips it;
- the island is hit-invisible sole-content chrome with claims-space layout coupling —
  ~700 lines of semantics a viewport must not inherit.

### 1.3 The screen↔plane mapping walks — hardcoded but centralized

ALL cross-plane mapping lives in `src/basic-widgets/Widget.coffee`: `mapRectToScreen`
(~:1467), `screenPointToMyPlane` (~:1496), `localPointToScreen` (~:1517), `screenBounds`
(~:1572), `_isInsideNonIdentityIsland` (~:1530), `_enclosingNonIdentityIsland` (~:1539),
`accumulatedRotationDegrees`/`accumulatedScaleFactor` (~:1598/:1607). Every walk repeats the
same loop — quoted, because the whole plan hangs on this shape:

```coffee
screenPointToMyPlane: (aPoint) ->
    islands = undefined
    ancestor = @parent
    while ancestor?
      if ancestor instanceof TransformFrameWdgt and !ancestor.transformSpec.isIdentity()
        islands ?= []
        islands.push ancestor            # innermost first
      ancestor = ancestor.parent
    return aPoint if !islands?           # same-object identity off any island — DORMANCY
    result = aPoint
    for island in islands by -1          # inverses outermost → innermost
      result = island.transformSpec.inverseMapPoint result, island.bounds
    result
```

`grep -rn "instanceof TransformFrameWdgt" src/` → 10 hits, ALL in Widget.coffee. The mapping
VALUE interface is four verbs + an identity test, called on `ancestor.transformSpec` with
`ancestor.bounds` as the slot: `mapPoint` / `inverseMapPoint` (exact), `mapRect` (integer
padded damage AABB — ⚠ unconditional ±1px AA pad for any non-identity spec), `mapRectExact`
(exact fractional AABB). Off any island every walk returns its input UNCHANGED (same
object) — the dormant guarantee the 300+ byte-exact tests stand on.

Beyond the walks, an island provides four class-side seams the walks do not cover:
`clipThrough` (child-facing plane-pure clip terminal) + `clippedThroughBounds`
(world-facing, footprint ∩ ancestor clip), the paint interception (§1.2), hit policy
(hit-invisible), and the buffer-damage deposit (`mapRectToScreen`'s `depositBufferDamage`
arg — buffer-cache-specific).

### 1.4 Input and damage are already funneled

- Every pointer handler receives a PLANE-MAPPED `pos` (`ActivePointerWdgt.
  _pointerPositionInPlaneOf` = `w.screenPointToMyPlane @position()`); hit-testing maps the
  pointer per candidate (`topWdgtUnderPointer`: `m.clippedThroughBounds().containsPoint(
  m.screenPointToMyPlane @position()) and m.catchesPointerAt(mapped)`; the tree walk itself
  has NO spatial pruning, so correctness lives entirely in the predicate); the build gate
  `buildSystem/check-raw-pointer-reads.js` bans raw `world.hand.position()` in handler
  bodies (same-line `screenPointToMyPlane` sampling idiom excepted). Wheel passes DELTAS
  only.
- Damage: marks are widgets, rects are born at flush — both flesh-out lanes map through
  `damagedWidget.mapRectToScreen(shadowExtendedRect(clippedThroughBounds()), true)` BEFORE
  spread/margin/merge, and the erase side (`_recordDrawnAreaForNextDamageRects`) records
  ALREADY-MAPPED screen rects at paint time. One seam, both directions.

⚠ Four call sites GATE mapping on the island predicate instead of trusting the map's
identity fallback: `ActivePointerWdgt.coffee` ~:466/~:486 (`if
target._isInsideNonIdentityIsland() then target.screenPointToMyPlane @position() else
@position()` — drop centre + stack insert-index hint) and `WorldWdgt.coffee` ~:1544/~:1559
(highlight overlay re-parented into `target._enclosingNonIdentityIsland() ? @`). If the maps
generalize and these predicates don't, drops land at raw screen coords and highlights sit
offset by exactly the scroll amount.

### 1.5 The moved-plane consumer inventory (the execution checklist)

Verdicts: MECH = mechanical rewrite · DESIGN = needs design · UNAFF = unaffected.
All in `src/basic-widgets/ViewportWdgt.coffee` unless noted.

| Consumer | What it does today | Verdict |
|---|---|---|
| `scrollX(steps)` ~:682 / `scrollY(steps)` ~:728 | THE movement cores: clamp `newX ∈ [right()−contentW, left()]`, then `@contents._moveLeftSideTo newX`; return moved?; refuse under `'never'` | MECH → clamp + write the offset + damage the viewport |
| `getScrollX/Y` ~:200 | derive offset from relative positions; pin getters | MECH → read stored field |
| `setScrollX/Y` ~:211 | pin setters, express request as delta through the cores | MECH |
| `scrollTo` ~:714 / `scrollToBottom` ~:723 | deltas through cores (callers: SampleSlideApp, `DocumentViewportWdgt.smartPlace`) | MECH |
| `wheel` ~:972 | at-limit escalation reads RAW plane positions (`@contents.top() >= @top()` etc., EXACT integer comparisons); destroys temporary handles ("they'll follow the contents being moved!") | MECH → at-top = offset 0, at-end = offset max; re-decide the handle-destroy (likely keep) |
| drag-to-scroll + momentum `mouseDownLeft` ~:752 | per-frame mapped hand samples → deltas → cores; glide decays via `world.wdgtsWithOngoingScrollMomentum` (macro pump holds on it) | MECH (all through the cores) |
| edge auto-scroll `maybeStartAutoScrollForDraggedWidget` ~:881 | edge bands tested with **raw `hand.position()`** vs my `boundingBox()` | MECH for cores; DESIGN for the band geometry once viewports can nest in scrolled planes (map like `mouseDownLeft` does) |
| `scrollCaretIntoView` ~:938 | moves the plane DIRECTLY (bypasses cores), moves the caret too; refuses 'never' | MECH but delicate — the full-scroll-in-ONE-pass case-law (CaretWdgt ~:224/:303, deliberately un-clamped negative caret placement) re-derives SIMPLER: visible ⇔ caret bounds ∈ [offset, offset+window] |
| `CaretWdgt._reLayout` ~:235 convergence probe | "stable" = the PLANE didn't move between passes | MECH → read the offset instead |
| `keepContentsInViewport` ~:671 | four one-sided `_applyMoveByBase` nudges = "plane covers viewport"; sole caller: arrange tail | MECH → `offset = clamp(offset, 0, max(0, content−window))` + the pinned-origin invariant |
| `_applyExtent` ~:495 reset-scroll pin + `managesOwnScrollPinning` | re-pin plane to my position on real resize unless the stack declares it owns its position | MECH (`offset = 0`); the `managesOwnScrollPinning` seam LIKELY DISSOLVES (no position left to own) |
| `setContents` ~:472, `setTextLineWrapping` ~:1062 | `_applyMoveTo @position()` pins | MECH |
| the arrange `_positionAndResizeChildren` ~:563 | width-normalize/wrap/measure UNAFF; **the anchor-merge ~:631** (merge with the plane's CURRENT scrolled position — what preserves scroll across arranges), grow-to-fill, `_commitBounds` | MECH, SIMPLIFIES: anchor is always the window origin; case-law (off-origin icon centring, delete-at-bottom shrink-up) re-derives as offset clamps — do not drop the behaviors |
| bars + pins | `trackTarget @, "setScrollX"` reciprocal wires; `_scrollRangeAlong` reads EXTENTS; `_reLayoutScrollbars` places from MY frame + announces `markNonValueChange` (the §P8 funnel — `announces: true` is audited on it) | UNAFF except the getters; **every offset write must still reach `_reLayoutScrollbars`** (`fg pinsweep` drives this) |
| `ListWdgt._applyExtent` (src/ListWdgt.coffee ~:130) | drags `@listContents` edges on growth (anti-vacant-space) | MECH, re-derive in pinned coords |
| `ClippingAtRectangularBoundsMixin._applyMoveBy` ~:190 | translate self + `__commitMoveBy` every child — TODAY'S per-scroll-step engine | retired as the scroll mechanism; stays for moving whole panels/windows |
| `ChangeFontButtonWdgt` ~:24/:37 (authoring/) | `menu.popUp @position().subtract(new Point 80,0), world` — re-emits OWN bounds as screen coords | MECH once `localPointToScreen` learns scroll; **sweep for siblings** (`grep "popUp .*position()"`) — the one live pop-up that breaks (others open at the hand) |
| `plausibleTargetAndDestinationWidgets` (Widget ~:1147 + mixin ~:17) | raw cross-plane `@bounds.isIntersecting` (handle attach, slider bind scans) | pre-existing hole islands never fixed; WIDENS hugely — fix with the mapped probe rect in this arc |
| overlays: highlight (re-home idiom), lock badge + pinouts (`mapRectToScreen` funnel), selection (paint-tail, ambient), handles + caret (plane residency) | two bridge idioms | MECH-by-inheritance once walks + predicates generalize; highlights need the re-home lookup to SEE the pane |
| drop INTO / grab OUT of a scrolled pane (`ActivePointerWdgt.drop` ~:400–530; islands' `_reExpressFigureForPlaneOfNoSettle` Widget ~:1943) | today no conversion needed (absolute bounds); islands built the bespoke seam | DESIGN — mirror the island 4D-1 block with a general predicate; grab-out needs the inverse at the same seam |
| serialization | positions are ordinary own-`@bounds`; scroll state implicit in moved coords; **the spreadsheet is the stored-offset precedent** (`viewOriginCol/Row`: prototype defaults, own-only-when-scrolled, document state — src/spreadsheet/CLAUDE.md §F1) | MECH: two integer scalars, own-only-when-scrolled; old snapshots restore at offset 0 (owner: NO compat obligations) |
| macro toolkit (`src/macros/MacroToolkit.coffee`) | locates/clicks via `localPointToScreen`-composed points | MECH-by-inheritance — load-bearing for the whole suite |

Unaffected by construction: the spreadsheet (already the target model), `fullBounds` past a
clipping pane (mixin short-circuits to `@bounds`), duplication (plane-consistent verbatim
copy), pop-ups at the hand, wheel delta plumbing, occlusion culling (top-level-only scan),
`Duplicator`/`isWiredTo` stray-bar guard. The caret's horizontal TEXT follow
(`@target._moveLeftSideTo` — text-level physical scroll INSIDE the plane) is plane-local
and STAYS physical.

### 1.6 Why it is shaped this way

Morphic made everything absolute so painting is a self-locating recursion with no matrix
state — simple, debuggable, and the damage machinery falls out. Scrolling-by-moving was the
zero-cost corollary. The islands broke absoluteness only where rotation forced them to, and
bought their dormancy by identity-`super` fallbacks everywhere. Scrolling stayed
moved-plane because nothing forced it — until the role arc's §7.2 showed the model's frame-
ownership cost, and the affine arc built (and funneled) all the machinery a second plane
type needs.

## §2 The distilled argument

1. **The pieces exist and are funneled.** Input is plane-mapped at ONE dispatcher funnel +
   a build gate; damage maps through ONE seam in both directions; the mapping walks live in
   ONE file with a uniform 4-verb interface; the bufferless translated recursion exists
   twice in-tree. The arc is mostly *generalizing seams that already exist*, not building
   new machinery.
2. **Integer translation is byte-safe where it matters.** Step-1 axis-aligned blits stay
   byte-exact (SWCanvas samples nearest-neighbor by construction when nothing resamples);
   plane-local child bounds under a pinned plane EQUAL today's unscrolled coordinates, so
   the dormant state (offset 0,0) is structurally byte-identical — the suite's survival
   condition, same trick the islands used.
3. **The wins are structural, not cosmetic**: the per-scroll-step whole-subtree bounds
   rewrite dies (a scroll step becomes two integer writes + damage); the arrange's densest
   case-law collapses into an offset clamp; frame ownership stops being contested (§7.2's
   conflict class dissolves at the root); scrollability generalizes to any clipping panel
   (desktop, islands — banked); serialization gains honest stored scroll state.
4. **Why not before**: the two-vocabulary law, the pointer funnel + gate, the island
   mapping walks, and the P5 scrolled-content contract are all 2026 constructions. Before
   them this arc would have been a rewrite of everything at once; now it is a seam
   generalization plus one class's mechanics.

## §3 Fix shape

### 3.1 The offset

`ViewportWdgt` gains **two integer scalar fields** `scrollOffsetX: 0` / `scrollOffsetY: 0`
(class-level prototype defaults — scalars, NOT a `Point`: ⛔ a class-level constant may
never reference another class, `docs/architecture/immutable-value-classes.md` §3; scalars
also serialize own-only-when-scrolled, the spreadsheet pattern). Semantics: how far the view
has scrolled into the content; `≥ 0`; clamped to `[0, max(0, contentExtent − windowExtent)]`
per axis. `getScrollX/Y` return the fields; the movement cores clamp and write them.
`scrollPolicy 'never'` pins them at 0 (the existing refusal point, unchanged).

**The plane is PINNED**: `@contents.position()` ≡ the viewport's content origin, forever —
asserted (a one-line invariant in the arrange), never nudged. Children of the plane keep
plane-local integer `@bounds` that no longer change when scrolling. The plane keeps its
content-sized EXTENT (the measure/commit/bars-range machinery reads extents and survives
unchanged) — only its POSITION semantics change.

### 3.2 The capability protocol (the mapping generalization)

One duck-typed per-edge hook, asked of each ancestor crossed by the 7 walks and by the
paint/hit recursions — the design follows the ONE existing general plane hook in the
geometry layer (`subWidgetsMergedFullBounds` preferring
`child.scrollOverflowBoundsInParentPlane?()`):

- `ancestor.scrollTranslationOfChild?(child)` → an `{x, y}` integer pair or `undefined`.
  `ViewportWdgt` answers `(child is @contents and (@scrollOffsetX or @scrollOffsetY))` →
  `{x: -@scrollOffsetX, y: -@scrollOffsetY}` — i.e. the translation applied to the CONTENTS
  subtree when mapping plane→screen; `undefined` otherwise (bars are FIXED children of the
  same parent — the §7.6 "fixed-vs-scrolled children" split answered structurally, per
  child edge, with no stored role).
- The 7 walks generalize from `if ancestor instanceof TransformFrameWdgt and !…isIdentity()`
  to a two-arm check: the island arm (unchanged verbs) OR the translation arm
  (`rect/point.translateBy` — EXACT, no ±1px pad, no buffer deposit). ⚠ The walks must
  track WHICH child edge they climbed through (the loop keeps `previous = current` before
  `current = current.parent`) so the per-child question is answerable — a mechanical loop
  reshape.
- Dormancy: offset (0,0) → `undefined` → the walk contributes nothing → same-object
  returns preserved. Byte-identical by construction; Phase 1's gate proves it.
- The four gated predicates generalize with it: `_isInsideNonIdentityIsland` /
  `_enclosingNonIdentityIsland` gain a general sibling (`_isInsideMappedPlane` /
  `_enclosingMappedPlaneRoot`) and the four call sites (drop ×2, highlight ×2) move onto
  the general one. (Cheapest sound alternative — dropping the gates entirely and always
  mapping, since the maps are identity off-plane — is ALSO acceptable; decide at
  execution on the diff's readability.)
- `isVisuallyTransformed` stays rotation/scale-only (a scrolled pane is NOT visually
  transformed); `accumulatedRotationDegrees/ScaleFactor` correctly ignore translations.

### 3.3 The paint interception

`ViewportWdgt` overrides the content-recursion point (the island's own seam,
`_fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow`): paint self (the mimic
rect) and the BAR children normally; for the CONTENTS child, when the offset is nonzero, do
the shadow-pass two-step — descend `clippingRectangle.translateBy(+offset)` and
`aContext.translate(-offset.x * ceilPixelRatio, -offset.y * ceilPixelRatio)` around the
contents recursion (save/restore). No buffer, no matrix, no new flag
(`preliminaryCheckNothingToDraw`'s `aContext == world.worldCanvasContext` disjunct still
holds — we paint the world ctx directly). The clip: the mixin's rect-narrowing already
clips children to the viewport box; the translated descent rect must be intersected with
the (translated) window box so scrolled-out content prunes exactly as clipped-out content
does today. Zero-offset takes the stock `super` path — dormancy again.

### 3.4 Damage

Nothing new: both flesh-out lanes and the erase-side snapshot already route through
`mapRectToScreen`, which learns the translation arm in §3.2 (exact `translateBy`, no pad).
A scrolled caret blink / editing text / stepping clock damages the right screen rect
through the same seam that fixes hit-testing. The mixin's `_applyMoveBy` stops being the
scroll engine (nothing calls it for scroll any more) and needs no change itself.

### 3.5 What dissolves, what stays

- DISSOLVES: the derived-offset getters' position reads; `keepContentsInViewport`'s four
  nudges (→ one clamp); the anchor-merge/grow case-law (→ offset clamps re-deriving the
  same behaviors: delete-at-bottom shrink-up = clamp shrinks offset; off-origin centring =
  measure anchored at window origin); the reset-scroll-on-resize plane re-pin (→
  `offset = 0`); likely `managesOwnScrollPinning` (no plane position left to own — verify
  the wrapping-stack pixels before deleting); the wheel's raw at-limit position reads.
- STAYS: the viewport/plane/bars tree shape and ALL of the role arc's chrome, policy, and
  contract work; `scrollPolicy`; the pin vocabulary and the `_reLayoutScrollbars` announce
  funnel (every offset write must still land there — `fg pinsweep` audits the promise);
  the §7.2 sandwich (its dissolution becomes POSSIBLE but is explicitly a banked follow-on,
  §7 below); the caret's text-level horizontal follow; the spreadsheet (untouched).
- The two-vocabulary law survives UNTOUCHED in both naming and semantics: scrolled
  children's `@bounds` are layout-family plane-local (numerically equal to today's
  unscrolled values); screen-family answers subtract the offset.

## §4 Central risks

1. **A missed consumer of "bounds == screen rect" under a scrolled pane.** The inventory
   (§1.5) is the checklist; the class of bug is silent (wrong-place paint/hit). Mitigation:
   Phase 1 lands the protocol with islands re-expressed on it and ZERO behavior change
   (byte-identical gauntlet); Phase 2 flips ONE mechanism at a time with the scroll-test
   subset (§6) after each.
2. **FP ≤1px shifts (the C1 lesson).** Relocating draws changes float CTMs; FP-sensitive
   content (rotated strokes, icon fit-scales) inside scrolled panes may shift ≤1px vs the
   moved-plane pixels even at integer offsets. Expect a SMALL recapture set; every diff
   eyeballed; webkit re-verified. Integer/axis-aligned/text content is byte-safe.
3. **Fractional offsets are forbidden** — they inherit the fracplane dpr1-INVISIBLE bug
   class at 10× exposure and break step-1 back-buffer blits (SWCanvas bilinear engages).
   The offset fields are integers by contract; clamp with `Math.round` at the write
   funnel; `fg presuite`'s fracplane rider and the dpr2 gauntlet leg are the eyes.
4. **Determinism cadence.** Momentum glide, edge auto-scroll saturation, and the caret
   one-pass convergence carry DETERMINISM.md case-law; each rewrite must preserve the
   event-stream purity (no new wall-clock reads; the macro pump's
   `anyScrollMomentumOngoing` hold must keep working).
5. **Walk perf.** The 7 walks run in hot paths (hit-test predicate per candidate, damage
   flush per widget). The per-edge duck call replaces an `instanceof` — comparable cost,
   but MEASURE (Phase 1 gate: suite wall-clock within noise of baseline).
6. **Macros reading scroll internals** (7 macros grep `contents.top()` / `.vBar` in their
   source): they break at the SOURCE level when the derivation moves — rewrite them to the
   pin getters in the same phase as the cores (their tests are the proof the getters
   stayed honest).
7. **`Rectangle.floor/spread` clamp to ≥ 0** — plane-local rects stay non-negative under
   the pinned model (offset stored separately), so this stays dormant; do not route
   translated-negative intermediates through them.

## §5 Phases

**Phase 0 — spikes (MANDATORY, throwaway, `.scratch` + uncommitted src hacks; revert after).**
- **S1 pixel-identity probe**: hack the paint interception (§3.3) + a hardcoded offset onto
  a ViewportWdgt in a headless boot; render a scrolled state both ways (moved-plane vs
  pinned+translate) on 2–3 real scroll tests' worlds; pixel-diff. Decides: the recapture
  budget (risk 2) and whether any content class shifts.
- **S2 walk-generalization probe**: prototype the two-arm walk in `screenPointToMyPlane` +
  `mapRectToScreen` only, islands on the island arm, nothing on the translation arm; run
  the full suite + time it. Decides: byte-identity of the reshape + the perf answer
  (risk 5).
- **S3 gated-call-site behavior probe**: with S1+S2 hacked together, drive drop-into-
  scrolled-pane, highlight-on-scrolled-child, `ChangeFontButtonWdgt`'s menu, and a caret
  scroll-follow, headless; record which behave and which misplace. Decides: the Phase 2c
  worklist is complete.
- Each spike's verdict goes in this plan's STATUS BOX before Phase 1 starts.

**Phase 1 — the mapping protocol, zero behavior change.** Reshape the 7 walks onto the
two-arm form (+ the child-edge tracking); add the general predicates; move the four gated
call sites onto them; islands re-expressed, translation arm EXISTS but has zero providers.
Gate: `fg gauntlet` byte-identical (no recaptures allowed in this phase), suite wall-clock
within noise.

**Phase 2 — the offset model on ViewportWdgt.** In sub-steps, each suite-gated:
- **2a cores + clamp + arrange**: fields, getters/setters, cores rewritten, pinned-plane
  invariant, `keepContentsInViewport` → clamp, arrange simplification (anchor/grow →
  clamps), reset-scroll → `offset = 0`, wheel at-limit reads, `setContents`/wrap pins,
  `ListWdgt._applyExtent`, paint interception live, serialization (two scalars;
  spreadsheet pattern), the 7 internals-reading macros rewritten.
- **2b gesture family**: drag-to-scroll/momentum (deltas already route through the cores —
  verify the pump hold), edge auto-scroll (map the band samples), `scrollCaretIntoView` +
  `CaretWdgt._reLayout` probe re-derivation (the one-pass law re-proved in offset terms —
  its ~dozen caret screenshots are the gate).
- **2c cross-plane seams**: drop-into/grab-out re-expression at the generalized gate,
  highlight re-home, `ChangeFontButtonWdgt` (+ the `popUp .*position()` sweep),
  `plausibleTargetAndDestinationWidgets` mapped probe rect (fixes the pre-existing island
  hole too).
- Gate per sub-step: `fg presuite` + the scroll-test subset; close Phase 2 with
  `fg gauntlet` + eyeballed recaptures (if S1 predicted any) + webkit.

**Phase 3 — retirement + truth.** Delete the dead moved-plane residue (derivation
comments, the mixin's "scrolling optimization" note, `managesOwnScrollPinning` if 2a
confirmed, `keepContentsInViewport`'s old body); sweep the docs that hard-code the
moved-plane fact (`viewports-and-planes.md` ×3 incl. the horizon note, `transforms.md`
island-scroll interplay, `ScrolledPaneWdgt`/`ViewportWdgt` headers, BACKLOG ~:248);
update `layout.md`'s viewport commit-seam wording; memory note.

**Phase 4 — the property-of-every-panel statement (small, or banked).** Either lift the
offset + interception from `ViewportWdgt` to the clipping mixin level behind the same
per-child hook (making any clipping panel scrollable-in-principle, viewport still the only
chrome'd user), or record the lift as designed-but-unneeded. ⛔ OWNER-GATED — it changes
no behavior either way; the honest default is "lift only when a second user exists"
(YAGNI, but state where the seam is).

## §0.5 Cold-execution protocol

1. `/Users/davidedellacasa/code/Fizzygum-all/fg status` — confirm clean trees; note heads.
2. Read THIS plan in full, then `docs/architecture/viewports-and-planes.md` and
   `docs/architecture/transforms.md` (§1, §2, §7, §8), then skim
   `docs/architecture/layout.md` §1 and `Fizzygum-tests/DETERMINISM.md` §2.
3. Re-verify §1's facts that your phase touches (grep the method names — every line number
   here has drifted by the time you read this). If a fact is WRONG, fix the plan first.
4. Phase 0 before anything; each spike's verdict written into the STATUS BOX. Two
   falsified fix shapes on one problem = STOP and re-frame (standing owner rule).
5. One phase per session-ish; update the STATUS BOX + this plan's inventory table verdicts
   in the SAME pass as the code. Never edit src/tests while an fg run is live.
6. Commits: present per phase, `git commit -F <file>`, NEVER push without the owner's word.
7. Recaptures: only via `fg recapture --auto` (build first), every diff eyeballed, webkit
   re-verified; a fuzz failure is never a recapture reason.

## §6 Verification protocol

- Inner loop: `fg build` (25 gates — the raw-pointer gate and layering rules will police
  the new code), then `fg presuite` (dpr1 + paint audit + the fracplane dpr2 rider — the
  ONLY inner-loop eye for fractional-plane regressions).
- The scroll-test subset (run with `run-sequence-headless.js` or full suite — it is ~15%
  of the suite, so the full `fg suite` at ~1 min is usually simpler): the ~45–50 tests
  enumerated in the role-arc fact base — the `macroScroll*`, `macroList*`,
  `macroDocument*`, `macroSimpleDocument*`, `macroNestedScrollPanelsRouteWheel`,
  `macroCaret*`/text-caret family, `macroTransformFrameSlotScrollReachability`,
  `macroTransformFrameSweepScrollSpinStable`, `macroWindowCellsInConstrainedScrollStackReflow`,
  spreadsheet scroll tests (must stay untouched), and `macroScrollPolicyNeverFlip`.
- Phase close: `fg gauntlet` (17 legs; `settle`/`capstone`/`revisits` will catch arrange
  regressions, `pinsweep` the announce funnel, `serialization` the stored offset,
  `menusweep` the over-tall menu, webkit the cross-engine pixels).
- Determinism: any new flake → `DETERMINISM.md` playbook BEFORE touching references;
  `fg fuzz` on demand for text-settle coverage of new pixel reads.

## §7 Rejected alternatives — do NOT re-attempt

1. **`TransformSpec` as the offset carrier** — falsified by inspection: the spec is a
   similitude about an anchor; translation is inexpressible and `isIdentity` would skip a
   hypothetical translated spec. Extending it would also drag every `isIdentity`-keyed
   dormant guarantee through a semantic change.
2. **Scrolled pane as a `TransformFrameWdgt` subclass** — mechanically instant (walks light
   up for free) and semantically wrong: hit-invisible sole-content wrapper + mandatory
   buffer (slot × dpr² × 4 B per pane + silhouette twin; even cache-OFF rasterizes) +
   claims-space layout coupling. A viewport is opinionated, hit-testable chrome.
3. **Fractional scroll offsets** (momentum "smoothness") — inherits the fracplane
   dpr1-invisible class at scale and de-bytes every step-1 back-buffer blit.
4. **Letting planes own their origin again** ("the offset is just the plane's position") —
   that IS the moved-plane model; and the §7.2 refusal (BACKLOG) stands: frame ownership
   stays with the container, offset or no offset.
5. **A new parallel mapping funnel for scroll** (separate from the island walks) — two
   funnels drift; the walks are centralized in one file precisely so a second plane type
   is an ARM, not a fork.
6. **Menu-sandwich dissolution INSIDE this arc** — banked follow-on: after Phase 2/3, the
   viewport no longer commits content frames, so `MenuRowsPanelWdgt`-as-direct-contents
   stops being a two-writer livelock BY CONSTRUCTION — but it needs its own probe (hit
   policy, `PopUpRowsPaneWdgt`'s chrome declarations re-homed) and its own plan. Same for
   scrollable desktop/islands and the `'always'` policy gutters.

## §8 References

- Living: `docs/architecture/viewports-and-planes.md` · `docs/architecture/transforms.md` ·
  `docs/architecture/layout.md` · `docs/architecture/appearance-paint-convention.md` ·
  `docs/architecture/integer-pixel-placement-and-sizing.md` ·
  `docs/architecture/immutable-value-classes.md` · `src/spreadsheet/CLAUDE.md` (§F1, the
  stored-offset precedent) · `Fizzygum-tests/DETERMINISM.md`.
- Archive: `docs/archive/scroll-frame-role-architecture-plan.md` (§7.6 the banking; §7.2
  via BACKLOG) · `docs/archive/affine-geometry-api-plan.md` (two-vocabulary law, normative).
- BACKLOG: the §7.6 line (update it to point HERE on landing this plan) and the §7.2
  recorded refusal (stands regardless).
- Memory: `scroll-frame-role-architecture-arc` (the §7.2 mechanism + this arc's genesis).
