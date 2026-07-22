# How the Fizzygum layout system works

**What this is.** The durable, present-tense reference for how Fizzygum computes widget geometry: the per-frame
cycle it lives in, the settle discipline that keeps it sound, the sizing model it applies, and the invariants the
build and the runtime enforce. Written to be picked up cold. It points rather than duplicates:

- naming tiers (the `_`/`__` scheme, the geometry-apply 2×2, the notification grid) → `docs/architecture/layering-naming-convention.md`
- the build-time gates and run-time censuses → `docs/architecture/lint-and-static-checks.md`
- integer placement policy, the back-buffer caveat, the plane-local vs `screen*` two-vocabulary law → `docs/architecture/integer-pixel-placement-and-sizing.md`

**The one principle everything below is a corollary of.** Layout is a *pure function of the event stream and the
final geometry* — never of wall-clock timers, frame counts, or intermediate passes. A widget **measures** (no side
effects), then **arranges** (applies geometry once); a settle-time up-edge does any container re-fit. That purity is
what makes the pixel-exact SystemTest suite deterministic.

---

## 1. The world cycle

`WorldWdgt.doOneCycle` (`src/WorldWdgt.coffee`) runs, in order, every frame:

1. update time references; surface errors deferred out of the previous cycle's repaint and settle
   (`_showErrorsHappenedInRepaintingStepInPreviousCycle`, `_showLayoutErrorsFromPreviousCycle`)
2. **process input** — `_playQueuedEvents` drains the *whole* event backlog this frame, returning only at a
   future-timed event
3. **step functions** — `_runChildrensStepFunction` (animation, stepping widgets), test replay, frame-paced loads
4. **dataflow drain (VALUES)** — `world.dataflow.recalculateDataflow()` (`src/dataflow/DataflowEngine.coffee`)
5. **layout settle (GEOMETRY)** — `recalculateLayouts()`
6. **hover re-sync** — `hand.reCheckMouseEntersAndMouseLeavesAfterPotentialGeometryChanges()`
   (`src/ActivePointerWdgt.coffee`), which reads the *settled* geometry paint will read
7. **paint** — `updateBroken()` repaints the dirty rectangles of an already-settled world

**Two parallel drain stations, one-way coupled.** Steps 4 and 5 are deliberate siblings: `recalculateDataflow`
settles values, `recalculateLayouts` settles geometry. The coupling is **strictly one-way — dataflow may dirty
layout, never the reverse** — which is why dataflow runs *before* layout: a formula/connection that writes a widget's
text feeds this frame's geometry settle and paint. (The dataflow engine has its own spec; see
`docs/specs/dataflow-engine-spec.md` and `src/dataflow/CLAUDE.md`. This doc covers only the layout station.)

**Paint reads layout but never schedules it.** The events→settle→paint boundary is the load-bearing invariant:
events fix layout step-by-step, the end-of-cycle settle drains the rest, then `updateBroken` paints. There is no
caret step in `doOneCycle` — a caret move self-settles its scroll-follow in-place during its own event, and paint-time
caret work is the *inert* re-sync `CaretWdgt.justBeforeBeingPainted → _adjustAccordingToTargetText`, which schedules no
layout. The "paint never schedules layout" boundary is enforced by a dynamic gate (see §7).

---

## 2. The settle discipline

Geometry is stateful, so the engine forbids the one failure mode that makes stateful layout unmaintainable: a
mutation re-entering the machinery that is mid-way through applying it. Three tiers, and **mixing them throws**.

### 2.1 The three tiers

- **Public self-settling wrappers.** Every public geometry/structural mutator is shaped
  `@_settleLayoutsAfter => @_<name>NoSettle(…)` — a thin wrapper over a non-settling core. `Widget._settleLayoutsAfter`
  (`src/basic-widgets/Widget.coffee`) sets `world._inLayoutMutation`, runs the core, then runs `recalculateLayouts()`
  **exactly once** before returning. So each public call leaves the world settled on return. The pure-geometry setters
  are `setBounds`, `moveTo`, `setExtent`, `setWidth`, `setHeight`; the structural entry point is `add` (over an
  `_addNoSettle` core). The same wrapper backs structural mutators — `close`, `destroy`, `fullDestroy`,
  `collapse`/`unCollapse`, `createReference`, `setMaxDim`, `_buildAndConnectChildren` (defined per-subclass), … — each
  over a `*NoSettle` core.

- **Immediate (geometry) mutators only mutate.** The `__commitExtent` / `_commitBounds` / `_applyExtentBase` /
  `_applyMoveByBase` family sets `@bounds` and **never** schedules layout. The `_apply*Base` members repaint; the
  `__commitExtent`/`_commitBounds` leaves are silent bottoms (no repaint, no self-relayout — the calling arrange
  already owes both). Inside an *arrange* a container applies its own geometry through these non-notifying twins, so a
  settled container never re-dirties itself.

- **Off-settle code records intent, never applies.** An event handler that is not inside a settle schedules layout via
  `_invalidateLayout()` (which climbs to the parent) or records a `@desired*` and lets a public flush drain it — never
  a synchronous `_reLayout`.

**Internal callers use the cores, not the wrappers.** Other product code and gesture streams call `_<name>NoSettle`
directly; calling the public wrapper mid-sequence would flush early and re-order deferred work.

### 2.2 The throws are the enforcement

Clean layering here is a *checked* invariant, not a convention. Two runtime tripwires guard it:

- `_settleLayoutsAfter` **throws** the moment a public setter is reached on an *attached* widget while a
  settle/pass is already open (`world._inLayoutMutation` or `world._recalculatingLayouts`).
- `_invalidateLayout` **throws `FLOWRULE_VIOLATION`** if an immediate mutator tries to schedule layout mid-pass.

Plus the build-time layering lint (`buildSystem/check-layering.js`) catches the name-recognizable offenders before
they can run. Together they make "public self-settles once; low-level code never schedules layout" a property the
build and the runtime *verify* (rules and predicates: `docs/architecture/lint-and-static-checks.md`). The motivation
is a real recursion/hang, not purity: a container that re-invalidated itself mid-pass once made the convergence loop
(§3) never terminate.

### 2.3 The orphan defer and the connector lane

`_settleLayoutsAfter` has two sanctioned exceptions to the throw:

- **Orphan defer.** If the receiver is detached from both world and hand (`TreeNode.isOrphan`), a call reached inside
  an open settle **defers** (runs the core, does not flush) — a constructor building its innards on an orphan must not
  re-enter `recalculateLayouts`. A *top-level* orphan call still flushes its own subtree, so `new Foo()` returns
  settled (every constructor routes children through `_buildAndConnectChildren` over a `_buildAndConnectChildrenNoSettle`
  core; the `check-constructors-build.js` gate enforces this).
- **The connector lane.** Reactive wiring cascades use a parallel wrapper,
  `_settleLayoutsAfterOrJoinEnclosingPass`, reached only through `_<name>Connector` entrypoints (e.g.
  `StringWdgt._setTextConnector`, `_setFontSizeConnector`). It is identical to `_settleLayoutsAfter` **except** that,
  reached inside an enclosing settle's mutation window, it **joins** it instead of throwing — so a value propagating
  around a wired circuit (the °C↔°F converter) opens **one** settle and every later hop joins it, settling the whole
  cascade once. Reached from inside the flush walk itself it keeps the strict orphan-defer + throw. The lane is opt-in
  per entrypoint and gated by check-layering rule `[P]`.

### 2.4 The layout-method family

These names are the durable vocabulary (full convention: `docs/architecture/layering-naming-convention.md`):

| method | role |
|---|---|
| `_reLayout(newBounds)` | the per-node **arrange**: position self, apply own extent, place corner/edge-internal children, mark fixed, re-lay any child the arrange moved |
| `_reLayoutSelf` | self-only heal hook (empty on base `Widget`); fired by `_applyExtentBase` when a widget's own extent commits |
| `_reLayoutChildren` | the **container arrange chokepoint** — the marker that a container *tracks its content's size*; the stack/scroll containers dispatch it to `_positionAndResizeChildren`, the tracking island's override does its own content-hug math |
| `_positionAndResizeChildren` | the actual measure-and-place-children body (per container: `SimpleVerticalStackPanelWdgt`, `ScrollPanelWdgt`, `FrameWdgt`) |

Only three classes define `_reLayoutChildren` — `SimpleVerticalStackPanelWdgt`, `ScrollPanelWdgt`,
`TrackingTransformFrameWdgt` — plus `FrameWdgt`, which inherits it from `SimpleVerticalStackPanelWdgt`. Anything
without it is not a size-tracking container, and the re-fit machinery (§3) is a no-op on it.

---

## 3. The settle engine: invalidate up, walk down in order, iterate to a fixed point

`recalculateLayouts` (`src/WorldWdgt.coffee`) is a thin re-entrancy guard around `_recalculateLayoutsBody`, which is
the engine. The drain is an **ordered root-down walk**:

```
until the work-list is empty:
   sweep out the settled entries
   derive the dirty flags + dirty ROOTS fresh, climbing current parent pointers
   for each root: descend parent-BEFORE-child along "has dirty descendant" flags,
       settling each not-yet-valid node (_reLayout), and re-laying any child
       the arrange moved or resized
```

Two facts make this a *fixed-point* loop, not a fixed count of passes:

1. **Invalidation climbs up; layout flows down.** `_invalidateLayout` marks the widget invalid (via the shared no-climb
   atom `__markForRelayout`) then recurses to `@parent` — short-circuiting if the triggering child is free-floating — so
   one deep change enqueues the whole ancestor chain, and the walk then descends once from the dirty root. In the common
   case a localized change is **climb up once, walk down once**: one top-down arrange. Each `_reLayout` ends in
   `_markLayoutAsFixed`, so the next round drops the entry.

2. **A settle can re-dirty something outside the subtree it just settled — the settle-time up-edge.** After a chain-top
   settles, `Widget._reFitMyTrackingContainerAfterSettle` re-fits its size-tracking container via `_reFitContainer`,
   **iff the chain-top's frame actually changed** (a no-op early-return otherwise). Because the container reads the
   chain-top's *final*, just-settled geometry, it re-fits correctly in one visit. This is the only source of genuine
   iteration, and it is concentrated at container boundaries that re-dirty each other (free-floating content ↔ its
   tracking container).

**Order-independence.** Settled layout is a pure function of geometry-at-that-instant and converges to the same fixed
point regardless of iteration order — that is what licenses the ordered down-walk and the fact that a heavy frame's
final layout is the composition of several full settle passes in event order.

**Who may enqueue into a *draining* flush.** New breakage may originate **only from the settle machinery itself**,
through the no-climb atom `__markForRelayout`, aimed at the one directly-affected widget. Every outside channel throws
mid-pass (§2.2). The sanctioned mid-pass writers all route through the shared phase-valve
`_scheduleRelayoutRespectingPhase` (`if world._recalculatingLayouts then @__markForRelayout() else @_invalidateLayout()`):
the settle-time up-edge, the collapse-by-width valve, the composite schedule-valve in
`_applyExtent`, and the scroll-panel commit-seam. (The caret's scroll-follow is not one of them: it enqueues itself
via `_invalidateLayout`, whose inert-receiver branch handles it, and the follow then runs as the caret's own
`_reLayout` inside the draining flush.) A crashing `_reLayout` cannot wedge the drain: the loop's catch
force-marks the thrower fixed and hides it, deferring the report to the next cycle — outside the flush.

**Termination.** Each arrange is an idempotent fixed point and non-notifying (a settled container never re-enqueues
itself), the up-edge skips an unchanged frame, and the constraint-box sizing model (§4) makes width↔height cycles
structurally impossible. A never-fire iteration-cap assert exists only to convert a hypothetical non-terminating
cycle into a loud `RECALC_NONCONVERGENCE` throw (`src/WorldWdgt.coffee`) rather than a frozen tab — it is a backstop,
not a convergence budget.

---

## 4. The sizing model — one constraint box, pure measure

**No accessor reports where geometry is heading.** `width()`, `height()`, `bounds`, … read the *applied* `@bounds`.
A container that must size itself to its content therefore cannot ask "how big will you be?" by reading — it must
**measure**.

### 4.1 The pure measure protocol

Every width→height widget defines a side-effect-free
**`preferredExtentForWidth(availW) → Point`** — "what extent would I take at this width, without touching `@bounds`."
It is overridden on `TextWdgt`, `SimpleVerticalStackPanelWdgt`, `FrameWdgt`, `AnalogClockWdgt`,
`KeepsRatioWhenInVerticalStackMixin`, `TransformFrameWdgt` (and more); the base `Widget` default returns current
height (width-invariant). A container measures its subtree with `Widget.subWidgetsMergedPreferredBounds` — the pure
twin of the applied-bounds `subWidgetsMergedFullBounds`.

**The one sanctioned applied read-back that survives** is the non-content-sizing folder/toolbar frame merging
children's *applied* bounds (`subWidgetsMergedFullBounds`): it reads genuine user-placed free-floating state, not
layout feedback. It is the layout system's single named state-read — do not add a second. Where a container child
genuinely must be sized-then-measured, the value is **handed forward** from the sizing call
(`_setWidthSizeHeightAccordingly` returns its resulting height) rather than mutated-then-read-back.

### 4.2 One constraint box everywhere

`VerticalStackLayoutSpec` is a constraint box: a `desiredWidth` (the width wish, captured at placement) + a `grow`
factor (0..1 share of extra space) + an `alignment`, with
`width = round( min( availW, desiredWidth + grow·(availW − desiredWidth) ) )`. The horizontal path is likewise a
textbook constraint box (`getRecursiveMinDim`/`getRecursiveDesiredDim`/`getRecursiveMaxDim` computed bottom-up over
the shared `_getRecursiveStackDim` walker; the base `_reLayout` distributes under-min shrink / desired-margin grow /
max-margin grow). There is no add-time proportional state and no width↔height cycle.

**hug vs grow.** `grow 0` is a size-stability choice (a size-stable window content declares it in its
`initialiseDefaultFrameContentLayoutSpec` override — e.g. the clock and `IconWdgt`; the spreadsheet is a grow-1
fill); `grow 1` fills. A
container-owned window sizes like a captured one from birth — the container owns its width; the free desktop-window
hug is desktop behaviour. The aspect contract (`KeepsRatioWhenInVerticalStackMixin`) is documentation now, not a
cycle-breaker: a pure measure + role-appropriate grow, with the cycle structurally impossible.

### 4.3 ASKING containers vs DICTATING containers

The framework's containers split by *who owns the geometry*:

- **ASKING** containers (measure-based flow — the stacks) ask a child how much space it takes and lay out around the
  answer.
- **DICTATING** containers (window content sizing, the stretchable panel's fractional model) impose geometry: they own
  their children's extent.

`_applyExtent` — the extent-impose path — is **never mode-gated**. A DICTATING container forwards its imposed extent
to its content unconditionally: `TrackingTransformFrameWdgt._applyExtent` forwards to the content in *every*
claimsSpace mode (§5). Space *negotiation* is moddable; participation in *dictated* sizing is not.

---

## 5. claimsSpace — how a transformed island occupies its parent's layout

An affine island (`TransformFrameWdgt` / `TrackingTransformFrameWdgt`) rotates/scales its content. Its
`TransformSpec.claimsSpace` scalar (`src/TransformSpec.coffee`) governs how much of the parent's layout the island
*asks* for. Three modes:

| mode | claimed box | reflow behaviour |
|---|---|---|
| **`footprint`** (**the default**) | corner-mapped integer AABB of the transformed slot box | changes with angle/scale, so the parent reflows on a transform change |
| `slot` | the slot box itself (paint-only) | parent reserves nothing extra |
| `sweep` | anchor-aware circumscribed square | depends on scale/anchor but **not** angle — a spinning figure reflows once then stays put |

The default serves the document author: a rotated image in a document must not overlap the text below it; expert
authors set `slot` (paint-only) or `sweep` (spin-stable reserve) deliberately. claimsSpace gates **only** the ASKING
protocol (a coupled island answers the stack measure trio as a fixed figure reporting its claimed box); the DICTATING
contract holds in every mode (§4.3).

**Scroll reachability is a separate question from claim.** A scroll frame must make reachable the **claim ∪ the ink's
integer hull** (`TransformSpec.scrollOverflowBoxFor`), because under `slot` the claim never contains the rotated ink,
and ink alone would drop the claim under `sweep`/`slot`. The ink term is the *unpadded* exact mapped AABB, so it nests
inside the sweep square at every angle.

---

## 6. Integer placement

Every widget is **placed and sized in integer pixels in its own plane**, enforced. `Widget._assertBoundsWellFormed`
(called from each bounds-commit leaf) `console.error`s `NON_INTEGER_GEOMETRY` (fractional applied `@bounds`) and
`NON_FINITE_GEOMETRY` (NaN/Infinity), both wired into the headless runners' fail-gate — a fractional placement fails
the suite even when the pixels match. Bounds round at the *desired* funnel and at every layout producer that computes
a fractional target. Fractional *desired* geometry is kept on the side; internal *content* rendering (vector icons,
charts, rotated strokes) is legitimately fractional; and under an affine island the `screen*` query family is derived,
post-transform, and possibly fractional while the plane-local layout-box family stays integer. Full policy, rationale,
the back-buffer floating-point caveat, and the two-vocabulary law:
`docs/architecture/integer-pixel-placement-and-sizing.md`.

---

## 7. The standing zero-invariants (what a regression looks like)

The layout system holds three empty/zero baselines. A layout change that breaks any of them is a regression:

- **Zero careless end-of-cycle pushes — the end-of-cycle capstone gate.** A public mutator that *defers* to the
  end-of-cycle flush instead of self-settling is a "careless" leak; the careless subset of that population is driven
  to zero and held there. Legitimate riders remain: declared-coalesced streams, orphan/construction deferrals, and the
  in-pass re-fit seam.
- **Empty settle-re-visit baseline (`fg revisits`).** Every widget is visited **at most once per flush**, suite-wide —
  the committed baseline is empty. Any new re-visit means an arrange that is not idempotent, reads half-applied state,
  or is a genuinely new up-edge that must be argued into the baseline consciously.
- **Arrange-idempotence census (`fg census`).** Boots the app battery, resizes every window, then post-order forces a
  re-lay at each widget's *current* frame and diffs subtree geometry. Expected movers: **zero**. Any mover is a
  non-idempotent or stale arrange, fixed at the arrange.

Plus the **paint-readonly gate**: paint schedules no layout (§1). These dynamic gates run under `./fg gauntlet`; the
build-time lints and the read-only censuses are documented in `docs/architecture/lint-and-static-checks.md`.

---

## 8. Introducing a new layout — the rulebook

To fit the engine, a new widget / container / layout spec honours, in priority order:

1. **Never introduce a read-back.** Give a width→height child a pure `preferredExtentForWidth(availW)`; a container
   measures its subtree via `subWidgetsMergedPreferredBounds`. If you catch yourself calling
   `_setWidthSizeHeightAccordingly` and reading `.height()` back, hand the height *forward* from the sizing call
   instead. The one sanctioned applied read-back (§4.1) already exists — do not add a second.

2. **Keep it to ONE pass, and make your arrange IDEMPOTENT.** A container fits its content in a single settle visit;
   you get this for free by obeying the tiers, because the settle-time up-edge re-fits a size-tracking container after
   its content settles, once. **Do not add a mutation-driven container notification.** You declare *nothing* for your
   arrange — the engine re-lays your widget whenever an arrange moves it and schedules your re-lay whenever a raw
   resize commits your frame while you have children. In exchange, a re-run of your `_reLayout` at the converged frame
   MUST move nothing: place children from your OWN committed frame. Any new re-visit fails `fg revisits`; any mover
   fails `fg census`.

3. **Obey the tiers — the FLOWRULE is enforced, not advisory (§2).** Public setters self-settle (`@_settleLayoutsAfter
   => @_<name>NoSettle(…)`); internal callers use the core. Immediate mutators only mutate — never `_invalidateLayout`
   (rule `[E]`), never a structural self-settling wrapper (rule `[G]`); inside an arrange, apply your own geometry
   through the non-notifying `_apply*Base` twins. Off-settle code records intent via `_invalidateLayout` (which throws
   `FLOWRULE_VIOLATION` mid-pass) — never a synchronous `_reLayout` from an event handler. If your arrange genuinely
   must schedule mid-pass (precedent: a width-driven collapse), route it through the phase-valve
   `_scheduleRelayoutRespectingPhase`, aimed at the one directly-affected widget — never the bare climbing verb.

4. **Free-floating content climbs nothing; a size-tracking container gets the up-edge automatically.** A free-floating
   child (`ATTACHEDAS_FREEFLOATING`, `src/LayoutSpec.coffee`) does not invalidate its parent. If your container tracks
   its content's size, define `_reLayoutChildren` — that is the marker `_reFitContainer` gates on — and the settle loop
   re-fits you after your content settles. Do not wire a manual notification.

5. **Aspect content follows the aspect contract:** a pure `preferredExtentForWidth` + role-appropriate grow
   (`grow 0` for a size-stable stack element, `grow 1` for fill), documented at `KeepsRatioWhenInVerticalStackMixin`.

The SCHEDULE/APPLY invariant these realize is build-gated by lint `[F]`; a terminal synchronous apply that is
genuinely sanctioned carries a `# layout-apply-sanctioned: <why>` marker. Prefer a capability query (`foo?()` the
answering subclass defines) over an `instanceof`/type test. Full gate list, predicates, and markers:
`docs/architecture/lint-and-static-checks.md`.

---

## 9. Invalidation and repaint — and what settle does NOT do

Layout settle computes **geometry only**. It does not paint. Repaint is a separate *broken-rectangles* (dirty-region)
loop:

- `Widget._changed()` invalidates just this widget's rectangle; `Widget._fullChanged()` invalidates it plus its subtree.
- `WorldWdgt.updateBroken()` repaints the accumulated dirty rectangles once per frame, at the tail of `doOneCycle`,
  against already-settled geometry.
- Widgets opting into `BackBufferMixin` (`src/mixins/BackBufferMixin.coffee`) cache themselves to an offscreen canvas;
  pluggable `*Appearance` objects do the drawing. (Integer placement is *necessary but not sufficient* for a back
  buffer to be byte-identical to a direct draw — see the integer-placement doc.)

The clean separation is the point: an immediate geometry mutator repaints (`@_changed`) but schedules **no** layout;
the settle loop moves geometry but paints nothing; paint reads settled geometry but schedules nothing. Each stage
touches exactly one of {values, geometry, pixels}, in that order, per frame.

---

## History & case law

Present-tense truth lives here; the *why* — including approaches that were tried and falsified, so they are not
re-attempted — is in the archived plans, indexed in `docs/archive/INDEX.md`:

- **`layout-system-architecture-assessment.md`** — the canonical long-form description this doc distills, with the
  full per-frame spine, the flush model, and the verified code map.
- **`sizing-model-unification-plan.md`** — how the two-philosophies split collapsed into the one constraint box (§4);
  ⚖ shrink-to-fit stays forbidden; storage stays split by ownership.
- **`claimsspace-footprint-default-and-scroll-reachability-plan.md`** — why `footprint` is the default and how scroll
  reachability = claim ∪ ink hull (§5); ⚖ claimsSpace gates ASKING only, never DICTATING `_applyExtent`.
- **`proper-layouts-geometry-seam-removal-plan.md`** + **`ordered-downwalk-stage-b-plan.md`** — the deletion of the
  notify-by-mutation seam and the ordered root-down walk that replaced it (§3); ⚖ settled layout is order-independent.
- **`layout-settle-tier-rename-plan.md`** + **`private-noLayouting-core-callpaths-plan.md`** — the wrapper/`NoSettle`-core
  tier naming (§2).
- **`connection-cascade-settle-fix-plan.md`** — the connector settle lane (§2.3); ⚖ rejected: relaxing the general
  flow guard, or dispatching the cascade to the raw core.
- **`orphan-settledness-plan.md`** + **`all-constructors-settle-plan.md`** — the orphan defer and constructor-settling
  (§2.3).
- **`upedge-endgame-plan.md`** + **`end-of-cycle-flush-drawdown-plan.md`** — the standing zero-baselines (§7): the empty
  re-visit baseline and the arrange-idempotence census.
- **`proper-layouts-4.1-pure-measure-campaign-plan.md`** — the `preferredExtentForWidth` measure protocol (§4.1).
- **`fractional-widget-bounds-investigation-plan.md`** — the integer-placement enforcement arc (§6); ⚖ divider-drag
  reproportion is sub-pixel-sensitive — recapture, don't chase.
