# Deferred-layout: the model is INTERMEDIATE — completing it (soft-wrap is the originating case)

**Status: investigation complete 2026-06-18. This supersedes the earlier "deferred for now / LEAVE"
framing, which was BIASED (see §6) — the conclusions below are de-biased.**

This started as a narrow plan to convert `SimplePlainTextWdgt`'s soft-wrap toggle from IMMEDIATE
(raw) to DEFERRED (`invalidateLayout`) layout. Investigating it surfaced a bigger, more useful truth:
**Fizzygum's deferred-layout mechanism is half-built by construction, and the handler-level raw
geometry (soft-wrap and ~a dozen siblings) is a *symptom* of that, not a set of independently
"legitimately immediate" sites.** This doc records the state of the model, why handler raw geometry is
currently forced, and the two paths — applied **case by case** — to complete it.

> **Author's note (the system's author, 2026-06-18):** the deferred system was *started* and added
> **accretively on top of the original immediate system**, pushed as far as it could be pushed without
> finishing the job. It is intentionally **intermediate**. That is *why* the accessors still read
> applied `@bounds`, `@desired*` is consulted in only a few places, and many handlers still mutate
> geometry immediately. None of this is an accident to be "left" — it is unfinished work to be
> completed deliberately.

---

## 0. The finding (lead with the honest conclusion)

1. **Deferral is within-frame — there is NO cross-frame lag.** Verified order inside
   `WorldWdgt.doOneCycle` (`:1198`): `@playQueuedEvents()` (`:1207`, events incl. hand move) →
   `@runChildrensStepFunction()` (`:1219`) → `@recalculateLayouts()` (`:1222`) → `@updateBroken()`
   (`:1230`, "here is where the repainting happens"). A deferred `setExtent`/`fullMoveTo` called during
   event handling sets `@desired*` + `invalidateLayout()`, and `recalculateLayouts` applies it **later
   in the same cycle, before paint.** The determinism contract (`Fizzygum-tests/DETERMINISM.md`)
   actually *favours* this — "never depend on an intermediate layout pass"; a single `doLayout`/cycle
   is the clean path and raw mutation in a handler is the intermediate state.

2. **The accessors read APPLIED geometry only — that is the incompleteness.** `position()` →
   `@bounds.origin`, `extent()` → `@bounds.extent()`, `left/top/width/height()` → `@bounds.*`
   (`Widget.coffee:630-800`). `@desiredExtent`/`@desiredPosition` hold the *pending* value but are
   consulted in exactly three places: `__calculateNewBoundsWhenDoingLayout` (`:1344-1352`), `doLayout`
   (`:3761-3772`), and **`pickUp` (`:2710-2713`)** — the lone pending-aware read ("into the
   `desiredExtent` as the true extent has yet [to settle]"). The pattern exists; it was never
   generalized to the accessors.

3. **So handler raw geometry is FORCED by a synchronous read-back of applied-only geometry.** A handler
   that mutates geometry and then, *in the same cycle before `recalculateLayouts`*, reads it back —
   a clamp, a derived value, hit-testing, a coordination flag — must apply immediately, because the
   accessor won't surface the pending value. That is the real reason `raw*` is used in handlers. It is
   **not** "cross-frame lag" and **not** a determinism minefield (a wrong conversion would read stale
   geometry and fail *deterministically* — tests go red — not flakily). Both of those were this doc's
   earlier bias (§6).

**Net:** the raw-in-handler smell (soft-wrap + ~a dozen siblings, §5) is a symptom of the half-built
model. Reigning it in is real, coherent work — completing the deferred model — not a marginal cleanup
to leave.

---

## 1. The two paths to complete it — applied CASE BY CASE

Whether a given handler can go deferred depends on **whether the same event also entails a relayout /
constraint resolution.** This is the crux distinction:

### Path A — defer + pending-aware read (when NO relayout/constraint: `desired == actual`)
For an **unconstrained freefloating transport** — pick a widget up, move it, drop it; *most
drag-and-drops* — the requested position IS the position it gets. Here you can either make the
accessors pending-aware (generalize the `pickUp` trick) or have the specific read-back consult
`@desired*`, and the move defers cleanly (settling at `recalculateLayouts`, before paint). This is the
**broad, systematic** fix and unblocks the largest class at once.
- Caveat (breadth): the accessors are the most-called methods in the system, and the hand/input root
  drives spatial queries (hit-testing, spatial-multiplexing, drop detection) that read *applied*
  positions of the whole sub-tree mid-cycle. So "pending-aware accessors" must be applied coherently
  enough that those queries see the right thing. The in-flight window is intra-cycle (paint runs after
  `recalc`, so rendering is unaffected), which contains the risk — but this is a **core
  geometry-model change**, to be done with a deliberate invariant/determinism pass, not a one-liner.

### Path B — case by case (when the event entails a relayout/constraint: `desired ≠ actual`)
When constraints transform the request, `@desired*` is the **request**, not the **result**, so a
pending-aware read would return the *wrong* (pre-constraint) value. **Author's example:** dragging a
**vertical** slider thumb **sideways** — the desired delta may be horizontal, but the thumb is
constrained to its track (and clamped to the slider's length), so where it *ends up* ≠ what was
requested. `SliderWdgt.updateValue` needs the **constrained** position (it reads `@button.top()`),
which only exists after the constraint resolves. Here you cannot just read desired; you must either
**eliminate the read-back** (compute the constrained result locally — e.g. the slider derives the
value from its own clamped `newPosition`, then `setValue` + let `reLayout` reposition the thumb) or
**order the work** so the constraint resolves before the read. Per-site.

**Therefore: classify each handler by "does this event also trigger a relayout / hit a constraint?"**
No-relayout freefloating transports → **A**. Constraint-entangled (sliders, vertical-stack elements,
ratio locks, clamps via `fullRawMoveWithin`, `FIT_BOX_TO_TEXT` wrap) → **B**. It is genuinely a mix;
neither path is universal.

---

## 2. The handler sites today (the symptoms), mapped to A / B

A codebase-wide audit (~430 raw-geometry call sites classified by enclosing method) found that ~420 are
legitimate **construction** (initial geometry before the first cycle) or **layout machinery** (inside
`doLayout`/`reLayout`/`adjustContentsBounds`/raw-override delegation). The genuine handler smells — raw
geometry in response to a discrete event — are the following. Each is annotated with the read-back that
forces immediacy today and its likely path:

| Site | Read-back that forces immediate today | Path |
|---|---|---|
| **Hand move** `ActivePointerWdgt:731` (`@fullRawMoveTo pos`) | hit-tests mouse-over from the hand's new position (`:740+`); `reCheckMouseEntersAndMouseLeaves` at `WorldWdgt:1220` runs *before* `recalc :1222`. Hand transport is unconstrained, but the read-back is pervasive (spatial queries over the dragged sub-tree). | **A** (the case that exercises A's full breadth) |
| **Generic drag-drop transport** of a freefloating widget | the dragged widget follows the hand via the tree (`fullRawMoveBy` recurses to children); spatial/drop queries read applied positions. | **A** |
| **Slider thumb** `SliderButtonWdgt:95` | `@parent.updateValue()` reads `@button.top()/.left()` (the *constrained* track position). | **B** |
| **Scrollbar drag** `ScrollPanelWdgt:80/85` | `@adjustContentsBounds()` + `@adjustScrollBars()` read `@contents.position()` (clamped scroll offset). | **B** |
| **Grab-anchor** `KeepsRatioWhenInVerticalStackMixin:27-29`, `Example3DPlotWdgt:104-106` | `@parent.fullRawMoveWithin world` clamps by reading the just-set position; `rawSetExtent` applies a ratio constraint. | **B** |
| **Ratio-on-drop** `Example3DPlotWdgt:87/110`, `KeepsRatio:12` (`constrainToRatio`) | dropped INTO a vertical stack → stack-attached (non-FREEFLOATING); the stack's `doLayout` reads the child's ratio-derived `@height()`. | **B** |
| **Window collapse/uncollapse** `WindowWdgt:243/250-253` | inline `@adjustContentsBounds()` runs while `@reInflating = true` (set `:249`, reset `:255`); the layout reads `@reInflating`. | **B** |
| **Spawn-at-hand / smart-place** `InspectorWdgt:268`, `StretchableEditableWdgt.smartPlace:42` | `fullRawMoveWithin` clamps the just-set position before `add`. | **B** (or A if the clamp is a no-op) |

(The ratio pair `KeepsRatioWhenInVerticalStackMixin` ⇄ `Example3DPlotWdgt` is a known duplicate —
`Example3DPlotWdgt.coffee:158-163`.) **Most handler smells are Path B (constraint-entangled). The
clean Path-A win is unconstrained drag-drop transport**, which is also the broadest payoff.

---

## 2b. Adhering flows — the success cases (pattern-match against these to finish the job)

The deferred pattern is not hypothetical here: parts of the system already do it correctly — including in
the *exact same real-time-drag shape* as the smells. These are the templates.

### A. `HandleWdgt.nonFloatDragging` (`HandleWdgt:218-235`) — THE gold standard
Dragging a resize/move handle is a real-time drag (the *same* `nonFloatDragging` entry point the slider
thumb uses), yet it is fully deferred and even documents the discipline:
```coffee
nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->
  newPos = pos.subtract nonFloatDragPositionWithinWdgtAtStart
  switch @type
    # 1. all these changes applied to the target are all deferred
    # 2. the position of this handle will be changed when the doLayout method of
    #    the parent of the handle will be called ...i.e. *after* the parent has
    #    re-layouted (in the deferred layout phase).
    when "resizeBothDimensionsHandle"
      newExt = newPos.add(@extent().add(@inset)).subtract @target.position()
      @target.setExtent newExt, @                                  # DEFERRED
    when "moveHandle"
      @target.fullMoveTo (newPos.subtract @inset), @               # DEFERRED
    when "resizeHorizontalHandle"
      @target.setWidth  newPos.x + @extent().x + @inset.x - @target.left()
    when "resizeVerticalHandle"
      @target.setHeight newPos.y + @extent().y + @inset.y - @target.top()
```
**Why it works — and why the slider/scrollbar don't:** it computes the new geometry from the **event data**
(`newPos`) + its own geometry, sets it via the deferred API, and **never reads the target's just-set
geometry back.** The handle's own position is re-derived by the parent's `doLayout` next, in the deferred
phase. This is structurally identical to `SliderButtonWdgt.nonFloatDragging` — except the slider does
`@fullRawMoveTo newPosition; @parent.updateValue()`, and `updateValue` reads `@button.top()` back. The
Path-B fix for the slider is literally *"make it look like `HandleWdgt`"*: it already computes the clamped
`newPosition` (`SliderButtonWdgt:82-93`); derive the value from THAT and `setValue`, instead of moving raw
then reading the thumb back. (`@target.setExtent newExt, @` passes the handle as `widgetStartingTheChange`
— the hook by which "all the resizes via the handles arrive here", `setExtent` comment ~`Widget:1433`.)

### B. `ActivePointerWdgt.grab` inflate/center (`ActivePointerWdgt:161/170/171`) — deferred, beside the raw tracking
When a grabbed widget is created-on-the-fly or inflates out of a glassbox, the grab centres it with the
deferred API — in the very class that does the raw hand-tracking:
```coffee
aWdgt.setExtent aWdgt.extentToGetWhenDraggedFromGlassBox            # DEFERRED
aWdgt.fullMoveTo @position().subtract aWdgt.extent().floorDivideBy 2 # DEFERRED
aWdgt.fullRawMoveWithin world   # TODO no fullMoveWithin ?   <-- the MISSING deferred clamp primitive
```
The `# TODO no fullMoveWithin ?` (`:162`) is a real artifact of the half-built model — there is no
*deferred* clamp, so the code falls back to `fullRawMoveWithin`. **Adding a deferred `fullMoveWithin` is a
concrete Path-A infrastructure item** that would unblock the clamp read-backs in several Path-B sites
(grab-anchor, spawn-at-hand).

### C. Content change → `invalidateLayout()` → `doLayout` re-derives size
Widgets that change their content mark themselves dirty and let the cycle resize them, no raw geometry in
the handler: the patch-programming nodes (`CalculatingPatchNodeWdgt`/`RegexSubstitutionPatchNodeWdgt`:
`setInput`/recompute set text only; the resize happens in `doLayout`), and the `rawSetExtent` overrides
that end in `super` + `invalidateLayout` (`FanoutWdgt:58-60`, `AxisWdgt`, `PlotWithAxesWdgt`). This is the
canonical adhering shape for the "constraint resolves in the cycle" case.

### The suggestion: pattern-match each smell (§2) against A / B / C
The transformation is mechanical and proven: **compute the target geometry from the event + your own
geometry, apply it via the deferred setter, and never read the target's just-set geometry back.** For a
constrained Path-B site, compute the constrained result *locally* — exactly as `HandleWdgt` computes
`newExt` — instead of reading it back post-layout. Each smell in §2 has a `HandleWdgt`-shaped rewrite; that
rewrite is the unit of work. Where a deferred primitive is missing (the clamp, §B), add it once and reuse.

---

## 3. The deferred mechanism (verified reference)

- **DEFERRED (high-level):** `setExtent` (`Widget.coffee:1420`), `setWidth`, `setHeight`, `fullMoveTo`
  (`:1226`) — set `@desired*` + `invalidateLayout()`; **NO-OP unless `@layoutSpec ==
  LayoutSpec.ATTACHEDAS_FREEFLOATING`.**
- **IMMEDIATE (low-level/raw):** `rawSetExtent` (`:1397`, comment `:1398`: *"in theory the low-level
  APIs should only be in the recalculateLayouts phase"*), `silentRawSetExtent` (`:1444`), `rawSetWidth`
  (`:1490`), `rawSetHeight` (`:1527`), `rawSetBounds` (`:691`), `fullRawMoveTo` (`:1208`), … — change
  `@bounds` now. `rawSetBounds` routes extent through `rawSetExtent`; `TextWdgt` overrides
  `rawSetExtent` (`TextWdgt.coffee:426-428`: `super; if FIT_BOX_TO_TEXT then @reLayout()`).
- **`invalidateLayout`** (`Widget.coffee:3571`): pushes to `world.widgetsThatMaybeChangedLayout`, marks
  `@layoutIsValid = false`, and propagates to the parent **only if `@layoutSpec != FREEFLOATING`** (so
  an invalidate on a freefloating widget does NOT climb to its parent — relevant to soft-wrap, §6).
- **The cycle:** `recalculateLayouts` (`WorldWdgt.coffee:841`) tail-drains the dirty list, climbs to
  the topmost-still-invalid ancestor, and calls `doLayout()`. `doLayout` consumes `@desired*` via
  `__calculateNewBoundsWhenDoingLayout` and applies constraints to produce `@bounds`. Runs once per
  `doOneCycle`, before paint (§0.1).

**Corrected fact (the original "Blocker #1" was WRONG):** the scroll panel's content `PanelWdgt` IS
`ATTACHEDAS_FREEFLOATING` (`ScrollPanelWdgt.coffee:37` `@addRaw @contents` → `addRaw` default
FREEFLOATING `Widget.coffee:2227`; class default `:235`). So `setExtent`'s gate would *pass*; the
original claim that `setExtent` is unusable on the content was false.

---

## 4. The geometry accessors read applied `@bounds` (verified)

```coffee
position: -> @bounds.origin        extent: -> @bounds.extent()
left:  -> @bounds.left()           width:  -> @bounds.width()
top:   -> @bounds.top()            height: -> @bounds.height()   # …all via @bounds
```
`@desiredExtent`/`@desiredPosition` (`Widget.coffee:56-57`, default `nil`) are SET by
`setExtent`/`fullMoveTo` and READ only by the layout machinery (`:1344-1352`, `:3761-3772`) and
`pickUp` (`:2712`). **This split — request in `@desired*`, applied in `@bounds`, accessors expose only
`@bounds` — is the half-built-ness.** Path A is "teach the accessors the `pickUp` trick (pending if
set, else applied)." Path B exists precisely because, under a constraint, the pending request is *not*
the applied result, so the trick gives the wrong answer.

---

## 5. The soft-wrap case (the originating, Path-B specific)

Soft-wrap is constraint-entangled (it entails a re-wrap relayout; content→viewport and text→content
width are constraints), so it is a **Path-B** case — *and* it has an extra structural blocker beyond
the accessor issue:

- The content + text are FREEFLOATING, so `invalidateLayout()` on them does **not** climb to the scroll
  panel (`Widget:3575`).
- The wrap geometry lives in `ScrollPanelWdgt.adjustContentsBounds`, which is **NOT on the `doLayout`
  path**: `ScrollPanelWdgt` has no `doLayout`; no `doLayout` in the tree calls `adjustContentsBounds`;
  and even a forced-dirty scroll panel skips it because `ScrollPanelWdgt.rawSetExtent` is guarded
  `unless aPoint.equals @extent()` (`:222`) and a toggle doesn't change the viewport.
- So even *with* pending-aware accessors, the cycle would re-`reLayout` the text alone and never
  re-derive the wrap geometry. Soft-wrap needs **both** model-completion **and** its own
  `adjustContentsBounds`-reachability fix (e.g. give `ScrollPanelWdgt` a `doLayout`). That second step
  has its own cost: `implementsDeferredLayout()` is `@doLayout != Widget::doLayout` (`Widget:3756`),
  consulted in `subWidgetsMergedFullBounds` (`Widget:990`), so adding a `doLayout` flips every scroll
  panel's merged-bounds contribution — a nested-scroll geometry change to verify.
- The `adjustContentsBounds:289` `widget.softWrap = true` overwrite is a **single-pass code-ORDER**
  correctness issue (one authority must own the wrap geometry, in a fixed order), **deterministic and
  caught by tests** — NOT the flaky dpr2 "ordering hazard" this doc earlier claimed (de-biased).

So soft-wrap is real but is one of the *harder* cases (Path B + extra reachability work), not the place
to start. The clean first win is Path A (unconstrained drag-drop transport, §2).

---

## 6. What this doc said before, and why it was biased (kept for honesty)

Earlier revisions concluded "deferred for now / LEAVE," justified by: (a) "deferring a drag-follow lags
it across frames" — **false**, deferral is within-frame (§0.1); (b) "[DET]-scary, dpr2-under-load
flake class" — **misapplied**, a wrong conversion fails *deterministically* (§0.3); (c) "marginal ROI,
ships nothing user-facing." Those were a LEAVE bias talking. (a) and (b) are retracted. On (c): the ROI
is **architectural** — completing a half-built core mechanism and enabling the broad Path-A
simplification of drag-and-drop — not a single user-facing feature, but not marginal either.

---

## 7. Sequencing / what completing this would take

**Method:** pattern-match each site against the adhering flows (§2b) — `HandleWdgt.nonFloatDragging` is the
worked template (compute from the event, set via the deferred API, no read-back). Each rewrite is one unit.

1. **Pilot Path A on the cleanest constrained-free case to prove the mechanism** — e.g. a single
   freefloating-transport handler, or a self-contained Path-B de-read-back (the slider: derive the
   value from the clamped `newPosition` instead of reading `@button.top()` back). Small, verifiable.
2. **Path A proper — pending-aware accessors** (generalize `pickUp`): the systematic enabler for the
   no-relayout transport class. Core-model change; needs an invariant + determinism pass and the full
   gauntlet. Its own design doc.
3. **Path B — per constraint-entangled site**, classified in §2 (sliders, scroll, ratio, window
   collapse). Each eliminates its specific read-back or re-orders the constraint resolution.
4. **Soft-wrap specifically** (§5): Path B *plus* wiring `adjustContentsBounds` into the cycle without
   the `implementsDeferredLayout` nested-scroll regression.

These can land independently and incrementally; none requires the others first, except soft-wrap which
wants its reachability fix regardless.

---

## 8. Risk & honest framing (de-biased)

- **Failure mode is deterministic, not flaky.** Reading stale/pre-constraint geometry yields the same
  wrong pixels every run → the SystemTests catch it immediately. This is *not* the dpr2-flake class.
- **Path A's risk is breadth** (accessors are everywhere; the hand drives spatial queries), not
  subtlety. Contained to the intra-cycle in-flight window (paint runs after `recalc`).
- **Path B's risk is per-site correctness** — get each constrained read right; low blast radius each.
- **Determinism still mandatory** for any change here: ~41 SystemTests touch wrap/scroll/reflow; run
  dpr1 + dpr2 + WebKit + `--homepage`. A real behaviour-preserving step shifts ZERO pixels; a deliberate
  behavioural change recaptures deliberately and confirms faithfulness.

---

## 9. Test exposure

~41 SystemTests touch wrap-related terms (12 mention `SoftWrap`). Closest to soft-wrap:
`macroSoftWrapping`, `macroSoftWrapTogglesTextReflow`,
`macroSimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent`,
`macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved`,
`macroWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo`,
`macroNonWrappingTextResizesToContent`, `macroFreeWidthScrollStackShowsHorizontalScrollbar`,
`macroWrappingTextFieldResizesOK`, `macroTextRelayoutsCorrectlyOnResize`. Drag-drop transport (Path A)
additionally exercises the grab/drop + scroll-panel tests broadly.

---

## 10. Verification recipe (when any conversion is attempted)

Each repo in a SEPARATE `cd` (chaining build+smoke across repos → MODULE_NOT_FOUND):
1. `cd Fizzygum && ./build_it_please.sh` (CoffeeScript syntax gate).
2. `cd Fizzygum-tests && node scripts/run-all-headless.js --shards=5` (dpr1), then `--dpr=2 --shards=5`,
   then `--browser=webkit --shards=5`. Expect 165/165.
3. `--homepage` 3-step: (a) `cd Fizzygum && ./build_it_please.sh --homepage`; (b) `cd Fizzygum-tests &&
   node scripts/smoke-boot-headless.js --native-only`; (c) `cd Fizzygum && ./build_it_please.sh`.
4. Path A / hand-touching changes: a `scripts/torture-headless.js` soak at dpr2 over the drag/scroll
   tests (the spatial-query breadth is where to look).

---

## 11. Cleanups already shipped (2026-06-18, commit `d01c7f3f`, byte-exact)

1. Deleted the dead `ScrollPanelWdgt.toggleTextLineWrapping` (zero call sites; already homepage-excluded).
2. Added WHY-immediate comments on `ScrollPanelWdgt.setTextLineWrapping` and
   `SimplePlainTextWdgt.setSoftWrap` pointing here. **TODO:** those comments still lean on the
   "deferred would not reach `adjustContentsBounds`" framing (true, §5) but predate the §0/§1 model
   finding — refresh them to "this is intermediate per the half-built deferred model; see this doc."

---

## 12. Context

Spun off from Phase-7 item **7c** (commit `9d3e1234`), which encapsulated the grandparent write +
content-resize into `ScrollPanelWdgt.setTextLineWrapping` and unified `softWrapOn/Off` into
`setSoftWrap` (byte-identical). The campaign tracker is `docs/oo-smells-refactoring-backlog.md`; the
deferred-pattern audit summary lives under its Phase 7. The God-class arc (Phase 6, COMPLETE) is
`docs/god-class-decomposition-plan.md`. The byte-exact contract is `Fizzygum-tests/DETERMINISM.md`.
