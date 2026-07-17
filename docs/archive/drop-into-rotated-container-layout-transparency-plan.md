> **ARCHIVED — COMPLETE (2026-07-17 restructure).** IMPLEMENTED + F1 LANDED + VERIFIED 2026-07-13 evening; full gauntlet green, pushed per project ledger.
> Historical record + case law; do not execute. Index: `docs/archive/INDEX.md`.

# Widgets dropped into a rotated container don't stretch/fit on resize — root cause + fix plan ("layout transparency" for sugar islands)

**Status: ✅ IMPLEMENTED + F1 LANDED + VERIFIED 2026-07-13 evening — the whole arc (§5a/§5b/§5c +
follow-up F1) sits UNCOMMITTED in both repos' working trees, gauntlet-gated, awaiting owner
commit approval. §9 (FOLLOW-UP F1) — the pinned-anchor render drift under arrange-driven resize —
is DONE: `_reLayoutChildren` now takes an `arrangeDriven` argument and nils the anchor on
arrange-driven re-fits (the two §5a forward sites pass `true`); probe leg E → drift 0px both markers,
verdict POST-FIX; the two new SystemTests were recaptured with the drift REMOVED; the headless eyeball
(.scratch/eyeball-{before,after}.png) shows both markers stay glued to their fractional spots through a
handle-like shrink. See §9 for full detail.**
§5a/§5b/§5c all landed;
probe ends POST-FIX (all 4 legs OK); two new SystemTests authored + captured (proven to FAIL pre-fix via
a source-revert A/B). Changes in `Fizzygum`: `src/TrackingTransformFrameWdgt.coffee` (§5a),
`src/basic-widgets/Widget.coffee` (§5b transfer + §5c routing), `src/StretchablePanelWdgt.coffee` (§5b
nil-guard). Implementation notes / deviations from the locked sketch:
- **§5a overrides `_applyExtent` (the polymorphic dispatch point), NOT `_applyExtentBase`** — the layering
  gate rule [K] forbids a `_apply*Base` twin routing back through the polymorphic `_applyExtent`, and the
  arrange only ever sizes a tracking island (a `_reLayoutChildren?` child) through `_applyExtent` /
  `_setWidthSizeHeightAccordingly`, never a direct `_applyExtentBase` (that path is for LEAF children). Same
  identity/empty⇒super dormant guarantee. A LOAD-BEARING `aPoint.equals @extent()` guard was added: the
  island's own `_reLayout` (super ⇒ Widget._reLayout ⇒ _applyExtent) re-applies the CURRENT slot extent
  each pass, which — the slot being content-coincident — would otherwise re-forward a stale extent onto a
  content-first growth and shrink it (would have broken `macroExplicitIslandFixedVsTrackingResize`).
- **`getMinimumExtent` forwarding INCLUDED** (the "check" item): keeps the stack's measure/arrange clamp
  coherent; dormant at identity/empty; the island's own `__commitExtent` reads the field, not this getter.
- **§5c also routes the inline extent-remember in `_setExtentNoSettle`** and the `wasPositionedSlightly-
  OutsidePanel` line of `_rememberFractionalSituationInHoldingPanel` through `_enclosingIslandFigure()` (for
  consistency), guarded on `fig.parent?`.
- **§3c (`_reactToBeingDropped` → content forwarding): DEFERRED** — optional, not needed for the headline
  fix, and forwarding a notification hook to the content could fire geometry-changing overrides
  (`_constrainToRatio`) and churn references. Revisit only if a ratio-drop-into-tilted-plane need surfaces.
- **Leg-D tilted-stack SystemTest (§7.3): NOT authored** (plan says "optionally") — the §5a stack path is
  covered by the probe (leg D OK post-fix); the two required tests cover the reported bug + the crash.
- **Expected fallout that materialised:** `macroDuplicatedInspectorDrivesCopiedTargetOnly` needed a benign
  recapture — the new `Widget#_moveHoldingPanelBookkeepingTo` method adds one row to the inherited-member
  list it renders (confirmed visually: only the scrolled list pane shifted; the alpha-edit behaviour is
  unchanged; image_1 unchanged). This matches `fg`'s documented "a no-op Widget METHOD breaks only that one
  test". `macroDropIntoTiltedStackInsertsAtVisualSlot` did NOT need a recapture (it passed unchanged).

---
**Status (original): plan AUTHORED 2026-07-13 — root cause CONFIRMED empirically, no code written yet.**
This document is self-contained and executable cold: it embeds the report, the confirmed mechanism
with file:line references, probe evidence, the locked fix shape, and what is deliberately left to the
implementing session. Probe/verifier: `Fizzygum-tests/.scratch/repro-drop-into-rotated-container.js`
(gitignored scratch; run `cd Fizzygum-tests/.scratch && node repro-drop-into-rotated-container.js` —
it prints a per-leg table and a PRE-FIX / POST-FIX verdict, exit 0 always).

## 1. Reported symptom (owner, 2026-07-13)

Drop widgets into a `StretchablePanelWdgt` / `StretchableWidgetContainerWdgt` **after** it has been
rotated (e.g. inside the dashboards maker or the slides maker): the newly-added widgets **do not
stretch** when the panel is resized. Widgets added *before* the rotation keep stretching fine. The
owner asked whether this is a more generic problem with drops into any tilted container (vertical
stack etc.) — **it is** (§3, §4).

## 2. Background you need (affine-transforms recap)

- Rotating/scaling any widget (halo or `setRotationDegrees`/`setScaleFactor` sugar) wraps it in a
  **`TrackingTransformFrameWdgt`** "sugar island" (`Widget._materializeSugarIslandNoSettle`,
  `src/basic-widgets/Widget.coffee:1483`). The island is invisible plumbing: its `@bounds` is the
  plane-local **slot box**; the transform applies only at composite time.
- §7.5 **Bug F (reparent-transparency, DROP half)**: dropping a *plain* payload into a container that
  lives inside a non-identity island wraps the payload in a fresh **compensating** sugar island at the
  inverse spec ("what you see while dragging is what you get") —
  `Widget._reExpressFigureForPlaneOfNoSettle`, `src/basic-widgets/Widget.coffee:1712` (wrap at
  1719-1732), called from the drop at `src/ActivePointerWdgt.coffee:462`.
  **So after a rotated container receives a drop, the container's child is NOT the widget — it is a
  non-identity `TrackingTransformFrameWdgt` wrapping the widget.**
- §4.9 layout coupling: a **non-identity island is a FIXED FIGURE for its parent's layout**
  (`TransformFrameWdgt._claimsFixedFigure`, `src/TransformFrameWdgt.coffee:239`) — designed for
  islands the *user* authored/rotated, **before** Bug F started inserting invisible wrappers around
  plain drops.

## 3. Root cause (confirmed)

All parent-driven child sizing funnels through **two methods that the island deliberately blocks**
when non-identity:

1. **`TransformFrameWdgt._applyExtentBase` early-returns** (`src/TransformFrameWdgt.coffee:274`):
   "a non-identity island IGNORES that so @bounds stays the SLOT box". Every extent-apply path dead-ends
   here: `_applyExtent` (Widget base is a pure pass-through to `_applyExtentBase`,
   `src/basic-widgets/Widget.coffee:2050`), `_applyWidth`/`_applyHeight`
   (`Widget.coffee:2213/2251`), and therefore `_setWidthSizeHeightAccordingly`
   (`Widget.coffee:728` → `_applyWidth`).
2. **`TransformFrameWdgt.preferredExtentForWidth` returns the fixed claimed extent**
   (`src/TransformFrameWdgt.coffee:266`) instead of measuring the content at the offered width.

Container-by-container:

- **Stretchable panel** (the report): `StretchablePanelWdgt._reLayout`
  (`src/StretchablePanelWdgt.coffee:57-66`) loops children and calls
  `w._moveInStretchablePanelToFractionalPosition` (works — the move path is NOT blocked) then
  `w._setExtentToFractionalExtentInPaneUserHasSet` (`Widget.coffee:1881`) → `_applyExtent` →
  **blocked by (1)**. Net: the wrapped widget translates to the right fractional position but never
  resizes — exactly the reported symptom.
- **Vertical stack** (and `WindowWdgt`, which is a stack subclass): the arrange
  (`SimpleVerticalStackPanelWdgt._positionAndResizeChildren`,
  `src/SimpleVerticalStackPanelWdgt.coffee:257-262`) discriminates on `widget._reLayoutChildren?` —
  a `TrackingTransformFrameWdgt` DEFINES `_reLayoutChildren`, so it is driven via
  `_setWidthSizeHeightAccordingly` → **blocked by (1)**; the pure measures
  (`_childMeasuredExtentInStack`, `preferredExtentForWidth`, `subWidgetsMergedPreferredBounds`)
  hit **(2)**. Net: a widget dropped into a tilted stack never width-fits and ignores later stack
  resizes (children normally track proportionally via `VerticalStackLayoutSpec.getWidthInStack`,
  `src/VerticalStackLayoutSpec.coffee:31`).

**Position is not blocked** (`_applyMoveTo`/`_applyMoveToBase` work, and for 'slot' islands the
claim offset is zero) — which is why the symptom is "moves but doesn't stretch".

### 3b. Latent sibling bug (confirmed): halo-rotate a widget already IN a stretchable panel

`_materializeSugarIslandNoSettle` (`Widget.coffee:1483`) transfers the content's former **index and
`layoutSpec`** to the island but NOT the stretchable-panel bookkeeping:
`positionFractionalInHoldingPanel`, `extentFractionalInHoldingPanel`,
`wasPositionedSlightlyOutsidePanel` (nor `layoutSpecDetails`). The panel's `_reLayout` then reads
`@positionFractionalInHoldingPanel[0]` unguarded (`Widget.coffee:1871`) on the island → `TypeError:
Cannot read properties of undefined (reading '0')`, caught+logged by the recalculateLayouts guard as
`LAYOUT_ERROR` (`src/WorldWdgt.coffee:1558`) — so no visible crash, but the panel's whole relayout
pass silently aborts: NOTHING in the panel stretches or re-positions after that.

### 3c. Adjacent transparency leak (note, lower priority)

`_reactToBeingDropped` fires on the WRAPPER, not the content (`src/ActivePointerWdgt.coffee:536-538`),
so a content widget's own drop hook (e.g. `_constrainToRatio` when dropped into a ratio-imposing
container — see the comment at `ActivePointerWdgt.coffee:522-525`) never runs for drops into a tilted
plane. Decide during implementation whether to forward the hook to the sole content (recommended) or
defer; it is NOT needed for the headline fix.

## 4. Empirical confirmation (probe, 2026-07-13, current master build)

`node Fizzygum-tests/.scratch/repro-drop-into-rotated-container.js` drives the REAL pipeline
(`pickUp()` → hand move → `ActivePointerWdgt.drop()`, so the Bug-F wrap genuinely happens):

| leg | scenario | result (PRE-FIX) |
|---|---|---|
| A | control: drop into UNROTATED stretchable container, resize ×1.5 | OK — child 80×50 → 120×75 |
| B | container rotated 30° FIRST, then drop, then resize ×1.5 | **FAIL** — child arrives as `TrackingTransformFrameWdgt` (deg=330, compensating) inside the panel; pre-rotation sibling stretches 80×50→120×75, dropped child and its wrapper stay 80×50 |
| C | drop, then halo-rotate the child in place, then resize | **FAIL** — wrapper fractional fields NIL; `LAYOUT_ERROR … reading '0'`; panel relayout aborts |
| D | stack: pre-rotation child in stack; rotate 30°; drop 2nd; widen stack 220→340 | **FAIL** — plain child grows 80→126 (proportional), wrapped child stays 80 |

POST-FIX the probe must print all four legs OK (it is written as the verifier — keep it until the
SystemTests below exist, then it can be deleted).

## 5. The fix — "layout transparency" for tracking (sugar) islands  [locked shape]

The sugar island already has **hit transparency** (`isTransparentAt`), **interaction transparency**
(Bug E, `mouseClickLeft`), and **reparent transparency** (Bug F pick/drop). The missing member of the
family is **LAYOUT transparency: parent-driven sizing protocols must pass THROUGH the island to its
sole content**; the existing tracking re-fit (`TrackingTransformFrameWdgt._reLayoutChildren`,
`src/TrackingTransformFrameWdgt.coffee:46` — slot ← content bounds, with the Bug-D anchor-pinning
rules) then re-hugs the slot, so the island ends up at the requested extent.

**Scope (locked): implement on `TrackingTransformFrameWdgt`**, NOT on the base `TransformFrameWdgt` —
the capability-is-a-class doctrine (see the class-comment in `TrackingTransformFrameWdgt.coffee`).
Explicit/base islands keep the §4.9 fixed-figure contract unchanged (an authored island in a stack
stays a fixed figure — `SystemTest_macroExplicitIslandFixedVsTrackingResize` pins that distinction).
All sugar/compensating wrappers are this class (`_materializeSugarIslandNoSettle`,
`_pickOutRotatedFigureNoSettle`, `_reExpressFigureForPlaneOfNoSettle` all `new
TrackingTransformFrameWdgt`). Keep the **identity ⇒ `super` dormant guarantee** on every override
(byte-identity gates).

### 5a. Forward the three sizing protocols (the core fix — legs B and D)

Sketch (details for the implementing session; names/guards per the base class):

```coffee
# in TrackingTransformFrameWdgt — layout transparency: parent-driven sizing passes
# through to my sole content; my tracking re-fit re-hugs the slot afterwards.

_soleContent: -> @childrenNotHandlesNorCarets()?[0]

_applyExtentBase: (aPoint) ->
  return super aPoint if @transformSpec.isIdentity()    # dormant guarantee
  content = @_soleContent()
  return if !content?                                   # empty: stay inert (fixed figure)
  content._applyExtent aPoint
  @_reLayoutChildren()                                  # slot ← content (Bug-D anchor rules live there)

_setWidthSizeHeightAccordingly: (newWidth) ->           # Path B: MUST return the resulting height
  return super newWidth if @transformSpec.isIdentity() or !@_soleContent()?
  h = @_soleContent()._setWidthSizeHeightAccordingly newWidth
  @_reLayoutChildren()
  h

preferredExtentForWidth: (availW) ->                    # keep measure and arrange coherent
  return super availW if @transformSpec.isIdentity() or !@_soleContent()?
  @_soleContent().preferredExtentForWidth availW
```

Watch-outs the implementer must handle:
- **Path-B contract**: `_setWidthSizeHeightAccordingly` must return the resulting height (all 8
  existing overrides do — comment at `Widget.coffee:720-727`). Return the height in the ISLAND's
  plane = the slot height after the re-fit (= content height, since slot ≡ content box).
- After forwarding an extent, the content's own subtree may need its `_reLayout()` — mirror what
  `StretchablePanelWdgt._reLayout` does for plain children (raw extent set, then `w._reLayout()`;
  the panel already calls `w._reLayout()` on the island afterwards, and
  `TrackingTransformFrameWdgt._reLayout = super + _reLayoutChildren` — trace whether the content's
  relayout is reached through that, or forward it explicitly).
- `getMinimumExtent` may also want forwarding (the stack's measure clamps to it) — check.
- The extent handed by the stretchable panel is in the PANEL's plane; the slot box lives in that
  same plane, so no coordinate mapping is needed — the content just becomes that size and renders
  rotated about its (possibly Bug-D-pinned) anchor. The rotated screen footprint overflowing the
  panel at the corners is ACCEPTED ink overflow (the island's two-faces clipping already handles it).

### 5b. Transfer the stretchable-panel bookkeeping across materialize/dematerialize (leg C)

In `_materializeSugarIslandNoSettle` (`Widget.coffee:1483`), alongside the existing index+layoutSpec
inheritance, MOVE to the island: `positionFractionalInHoldingPanel`,
`extentFractionalInHoldingPanel`, `wasPositionedSlightlyOutsidePanel`, and `layoutSpecDetails`
(a stack child's island otherwise has layoutSpec == VERTICAL_STACK_ELEMENT but nil details, and the
stack's init block at `SimpleVerticalStackPanelWdgt.coffee:216` is skipped because the enum already
matches → `_childWidthInStack` falls back to raw available width). Hand all of them BACK in
`_dematerializeSugarIslandIfIdentityNoSettle` (`Widget.coffee:1510`). (The DROP path needs none of
this: the drop calls `_reactToBeingDropped` on the wrapper, which records fresh fractional data, and
a FREEFLOATING-spec'd wrapper goes through the stack's init block normally.)

**Hardening (recommended, cheap)**: nil-guard the two consumers so a stale/foreign child can never
abort a whole panel relayout again — skip the child (or lazily
`_rememberFractionalSituationInHoldingPanel`) when `positionFractionalInHoldingPanel` /
`extentFractionalInHoldingPanel` is nil (`Widget.coffee:1871/1881`, loop at
`StretchablePanelWdgt.coffee:57`).

### 5c. Keep the figure's fractional data fresh on user resizes (follow-on, same family)

A handle-resize of a wrapped widget records fractional geometry against `@parent` — the ISLAND, not
the panel (`_setExtentNoSettle`, `Widget.coffee:2082`; `_moveToNoSettle`, `Widget.coffee:1925`) — so
the figure's panel-relative data goes stale. Route the remember through the figure:
`_rememberFractionalPositionInHoldingPanel` / `_rememberFractionalExtentInHoldingPanel`
(`Widget.coffee:1937-1941`) should operate on `fig = @_enclosingIslandFigure()` w.r.t. `fig.parent`
(`_enclosingIslandFigure`, `Widget.coffee:1659`, is identity off islands ⇒ dormant byte-identical).

## 6. Expected test impact / risks

- **Full gauntlet must stay green**; the identity-guard on every override keeps dormant paths
  byte-identical. Run `fg presuite` while iterating, `fg gauntlet` to close.
- `SystemTest_macroDropIntoTiltedStackInsertsAtVisualSlot`: at DROP time the proportional width is
  the added width (ratio 1), so its references likely survive — but if its payload is wider than the
  stack's available width, `rememberInitialDimensions` clamps and the post-fix render changes →
  benign recapture (recapture freely per owner policy; never contort code to avoid one).
- `SystemTest_macroExplicitIslandFixedVsTrackingResize` pins fixed-vs-tracking semantics — it tests
  the content→slot direction (unchanged); verify it still passes untouched.
- Bug-D anchor pinning: panel-driven stretches are asymmetric extent changes, so
  `_reLayoutChildren` will pin the anchor — the figure stays screen-still by design. Eyeball one
  interactive rotate+resize in the dashboards app (`?sw=1` optional) before closing.
- Serialization: the transferred fractional fields are plain arrays/booleans already handled by the
  serializer; a saved tilted dashboard must reload and still stretch — cover in the new test or probe.

## 7. NEW SystemTests to author (REQUEST — keep in the test base)

Work out (via `/author-macro-test` in `Fizzygum-tests`) macro tests that reproduce the bug and
demonstrate the fix, screenshot-asserted:

1. **`macroDropIntoRotatedStretchablePanelStretchesOnResize`** (the headline): build a stretchable
   container, drop one widget, rotate the container via the rotation halo, drop a second widget via a
   real drag, resize the container via its handle, screenshot — both children must have stretched.
   (Pre-fix this renders the second child un-stretched — the probe's leg B as pixels.)
2. **`macroRotateChildInsideStretchablePanelThenResize`** (leg C): drop a widget, halo-rotate IT (not
   the container), resize the container — no LAYOUT_ERROR, child stretches and repositions.
3. Optionally a tilted-stack variant (leg D): rotate a stack, drop a widget in, widen the stack —
   dropped child tracks width proportionally like its pre-rotation sibling.

## 8. Verification recipe (in order)

1. `cd Fizzygum-tests/.scratch && node repro-drop-into-rotated-container.js` → all 4 legs OK,
   verdict POST-FIX.
2. `/Users/davidedellacasa/code/Fizzygum-all/fg presuite` while iterating.
3. New SystemTests (§7) captured + green.
4. `/Users/davidedellacasa/code/Fizzygum-all/fg gauntlet` to close the arc.

---

## 9. FOLLOW-UP F1 (2026-07-13 evening) — pinned-anchor RENDER DRIFT under arrange-driven stretch. **Status: ✅ IMPLEMENTED + VERIFIED (probe leg E drift 0px, POST-FIX; two new tests recaptured; eyeball glued; full gauntlet green). AS-BUILT notes in §9.4/§9.5 below.**

### 9.1 Symptom (owner, slides maker, screenshots on file)

With the §5 fix in the working tree: markers dropped into a tilted slide AFTER the tilt now DO
resize with the window (the §5a forwarding works), but they **drift off their spots** as the window
is resized (handle dragged up-right, window getting shorter): the bottom marker moves away from its
corner, the top marker leaves the visible slide entirely. Markers added BEFORE the tilt stay glued.
"They SEEM to shrink correctly" — extents are right; **placement of the RENDER is wrong**.

### 9.2 Replication (probe leg E — added to the same probe; run it to reproduce)

`repro-drop-into-rotated-container.js` leg `E.glued-render-after-resize`: 30°-tilted stretchable
container, two markers dropped (near top edge / bottom-right corner), multi-step shrink 300→120
(handle-drag-like). Measured (current working tree): both markers shrink correctly 80×50 → 32×20 but
each renders **14.7px away from its slot centre**, wrapper anchor **pinned** at |A−c| = 28.
Verdict line: `drift=14.7px pinnedAnchor=true |A-c|=28` on both. POST-F1 the leg must show
drift ≤ 2px (the probe asserts exactly that).

### 9.3 Root cause (confirmed — measurement matches the algebra to the decimal)

The §5a forwarded re-fit runs through `TrackingTransformFrameWdgt._reLayoutChildren`, whose **Bug-D
anchor-stability rule pins the anchor on ANY extent change** (`src/TrackingTransformFrameWdgt.coffee:61`,
`@transformSpec.anchor = @transformSpec._anchorFor @bounds` — pins at the OLD slot centre on the first
resize step, and `_anchorFor` returns the existing anchor ever after). Per panel-relayout frame:

1. The panel MOVES the wrapper to its fractional position — the move-level overrides ride the anchor
   (`TransformFrameWdgt._applyMoveBy` et al.), so moves keep (A − c) invariant. Moves are innocent.
2. The forwarded extent-apply resizes the CONTENT top-left-anchored, so the slot centre c shifts by
   extΔ/2 while the pinned anchor A stays ⇒ **d = A − c telescopes to (ext₀ − ext₁)/2** over the
   gesture.
3. A pinned island renders its content offset from the slot by **(I − sR)(A − c)** (the Bug-D
   compensation term). Probe check: d = ((80,50) − (32,20))/2 = (24,15), |d| = 28.3 (measured 28);
   drift = 2·sin(15°)·28.3 = 14.65px (measured 14.7). Exact match — no other contributor.
4. The panel CLIPS its children (`PanelWdgt`), so a near-edge marker whose render drifts on a
   now-small panel is clipped out — "the top one goes out of sight entirely". Plain pre-tilt children
   have no wrapper ⇒ no anchor ⇒ always glued (matches the report).

WHY the pin exists: Bug-D serves the CONTENT-DRIVEN direction — a user handle-resizing the wrapped
widget must not see it jump (persisting screen points stay still). An **ARRANGE-driven** stretch is
the opposite regime: the panel's fractional model OWNS placement (it places SLOT boxes — §5c records
slot-box fractions), the figure is SUPPOSED to move with the panel, and a pinned anchor decouples the
render from the slot the model is placing. Pinning is right for content-driven re-fits, wrong for
arrange-driven ones.

### 9.4 Fix (follow-up F1) — suppress the pin on ARRANGE-driven re-fits  [shape locked, details open]

Distinguish the two regimes with an ARGUMENT, not a stateful flag: the two §5a forward sites call
`@_reLayoutChildren true` (arrange-driven); every other caller (the settle-loop up-edge, `_reLayout`)
stays bare ⇒ content-driven, pins as today (Bug-D untouched ⇒
`macroExplicitIslandFixedVsTrackingResize` untouched). In `_reLayoutChildren`'s extent-change branch:

```coffee
_reLayoutChildren: (arrangeDriven = false) ->
  ...
  else   # extent changed
    if arrangeDriven
      @transformSpec.anchor = nil                       # arrange owns placement: render GLUED to the slot
    else
      @transformSpec.anchor = @transformSpec._anchorFor @bounds   # Bug-D, unchanged
```

**Nil outright (recommended), not Bug-G-normalize**: under an arranged parent the slot box is the
truth (the fractional model records and places slot boxes), so the render must coincide with it; a
pinned anchor inherited from an earlier user gesture is *already* inconsistent with the recorded
fractions, and nil-ing corrects it by exactly the current drift, then converges (leg E: every
subsequent frame stays glued). The alternative — `_normalizePinnedAnchorNoSettle()` first (preserves
the current render via a compensating slot translate) — keeps mid-gesture visual continuity but
displaces the slot from its just-applied fractional position each frame; rejected as the default,
note it if a visible one-frame snap ever bothers in practice (it equals at most the accumulated
drift). Implementation details left open: exact guard placement; whether
`_setWidthSizeHeightAccordingly`'s re-hug needs the same arg (it does — pass true there too);
optional deeper hardening (normalize/unpin at the fractional-REMEMBER seam so a user content-resize
inside a panel re-syncs the model at gesture end) — implementer's discretion, verify with leg E.

**AS-BUILT (F1, 2026-07-13 evening — `src/TrackingTransformFrameWdgt.coffee` only):**
- `_reLayoutChildren: (arrangeDriven = false) ->` — the extent-changed branch (the `else # extent
  changed` of the `newSlot.extent().equals @bounds.extent()` test) now reads:
  `if arrangeDriven then @transformSpec.anchor = nil else @transformSpec.anchor =
  @transformSpec._anchorFor @bounds`. The nil choice was taken (not Bug-G-normalize), as recommended.
  Nothing else in the method changed — the move branch (extent unchanged: translate a pinned anchor)
  and the trailing `un-pin when anchor == slot centre` line are byte-identical, and the latter is a
  harmless no-op when the anchor was just nil-ed.
- BOTH §5a forward sites pass `true`: `_applyExtent` → `@_reLayoutChildren true`, and
  `_setWidthSizeHeightAccordingly` → `@_reLayoutChildren true` (the re-hug DID need the same arg, as
  the sketch anticipated). Every OTHER caller stays bare ⇒ content-driven, Bug-D pin unchanged: the
  class's own `_reLayout` (`super` + `@_reLayoutChildren()`) and the settle-loop up-edge
  (`_reFitMyTrackingContainerAfterSettle` → `_reFitContainer` → `_scheduleRelayoutRespectingPhase` →
  `_reLayout` → bare `@_reLayoutChildren()`). No stateful flag was added.
- WHY a later bare `_reLayout` does not re-pin after an arrange-driven re-fit: once the arrange re-fit
  has re-hugged the slot to the content, `@bounds` equals the content's bounds, so the bare re-fit's
  `return if newSlot.equals @bounds` early-returns before touching the anchor. Empirically confirmed —
  after the full multi-step shrink (each step runs its own settle loop) leg E ends `pinnedAnchor=false`.
- The §5c fractional-REMEMBER-seam hardening (optional deeper item) was NOT taken — not needed; leg E
  converges to drift 0 without it. Revisit only if a user content-resize inside a tilted panel is ever
  seen to leave a stale pin.

### 9.5 Expected fallout + verification for F1

- ✅ **The two NEW SystemTests were recaptured** (`fg recapture` at dpr 1+2, both PASS-verified) —
  their references had the drift baked in (`macroDropIntoRotatedStretchablePanelStretchesOnResize`
  resizes ×1.5 after the drop; `macroRotateChildInsideStretchablePanelThenResize` likewise). Only
  those two tests' refs changed; no other tracked reference file moved (the git tree shows only the two
  untracked new-test dirs + the pre-existing §5 benign `macroDuplicatedInspectorDrivesCopiedTargetOnly`
  inspector recapture). ✅ `macroExplicitIslandFixedVsTrackingResize` passes UNCHANGED (content-driven
  pin untouched — all 4 of its value assertions green).
- ✅ Probe leg E → **drift 0px both markers, `pinnedAnchor=false`, verdict POST-FIX**; legs A–D stay OK
  (extents still correct: markers 80×50 → 32×20 as before, i.e. §5a forwarding intact).
- ✅ Eyeball (headless, `.scratch/eyeball-glued-render.js` → `eyeball-before.png` / `eyeball-after.png`,
  since the interactive Chrome extension was unavailable): a 30°-tilted stretchable container with two
  dropped markers (near top edge / near bottom-right corner) through a handle-like multi-step shrink —
  both markers stay glued to their fractional spots inside the shrinking tilted panel (the top marker
  does NOT drift out of the panel, the §9.1 failure). The slides-maker uses this same StretchablePanel
  mechanism.
- ✅ `fg gauntlet` GREEN over the F1 build + recaptured refs — all 8 legs PASS (dpr1 / dpr2 / webkit /
  apps / paint / tiernaming / settle / capstone), 248 tests, 0 failed (2026-07-13 21:29).
