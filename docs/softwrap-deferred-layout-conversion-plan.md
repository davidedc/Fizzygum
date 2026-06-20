# Deferred-layout: the model is INTERMEDIATE — completing it (soft-wrap is the originating case)

This started as a narrow plan to convert `SimplePlainTextWdgt`'s soft-wrap toggle from IMMEDIATE
(raw) to DEFERRED (`invalidateLayout`) layout. Investigating it surfaced a bigger, more useful truth:
**Fizzygum's deferred-layout mechanism is half-built by construction, and the handler-level raw
geometry (soft-wrap and ~a dozen siblings) is a *symptom* of that, not a set of independently
"legitimately immediate" sites.** This doc records the state of the model, why handler raw geometry is
currently forced, and the two paths — applied **case by case** — to complete it.

*Path/line note: `Widget.coffee` is `src/basic-widgets/Widget.coffee`; `SimplePlainTextWdgt.coffee` is
`src/SimplePlainTextWdgt.coffee`. Line numbers are against source as of 2026-06-18.*

> **Author's note (the system's author):** the deferred system was *started* and added
> **accretively on top of the original immediate system**, pushed as far as it could be pushed without
> finishing the job. It is intentionally **intermediate**. That is *why* the accessors still read
> applied `@bounds`, `@desired*` is consulted in only a few places, and many handlers still mutate
> geometry immediately. It is unfinished work to be completed deliberately.

> **Status — 2026-06-19 (progress + a key Path-A finding):**
> - **Macro raw-API cleanup SHIPPED** (`Fizzygum-tests` `51b064fc0`, `Fizzygum` `7c720908`): 117 of 133
>   SystemTest macro command files now use the deferred API (`setExtent`/`fullMoveTo`/`setWidth`) instead
>   of raw, byte-identical (165/165 at dpr1 + dpr2 + WebKit). The remaining **16 keep raw** — they read
>   geometry back *synchronously during construction* (`panel.center()`, explicit `adjustContentsBounds()`,
>   reads inside `add`) before the first settle, so a deferred value would be read stale. The deferred
>   clamp primitive **`fullMoveWithin`** now exists (Widget.coffee); the MacroToolkit window verb is deferred.
> - **Path A was attempted and the blanket "pending-aware accessors" approach EMPIRICALLY DIVERGES** (16 →
>   17 → 18 failures as accessors, then `subWidgetsMergedFullBounds`, then `fullBounds` were made
>   pending-aware). Root cause: the geometry read surface has *conflicting* needs — `adjustContentsBounds`/
>   `add` want the PENDING value, but canvas pixel-buffers, the inspector, and dirty-rect repaint want the
>   APPLIED value; one accessor cannot serve both. So Path A is a **per-reader audit**, not a blanket
>   change — the full plan is in **`docs/deferred-layout-path-a-design.md`**, which supersedes the
>   "Path A = pending-aware accessors" framing in §1/§6 below.

---

## 0. The finding

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
   consulted in exactly three methods: **`fullRawMoveWithin`** (`:1344-1352`, def `:1336`),
   **`__calculateNewBoundsWhenDoingLayout`** (`:3761-3772`, def `:3759`; `doLayout` at `:3787` reads
   `@desired*` only by delegating here), and **`pickUp`** (`:2712-2713`) — "into the `desiredExtent` as
   the true extent has yet [to settle]". There are TWO pending-aware reads: `fullRawMoveWithin` is
   itself pending-aware (it peeks at `@desired*` and bakes them in via `rawSetBounds`), exactly like
   `pickUp`. The pattern exists (in two places); it was never generalized to the accessors.

3. **So handler raw geometry is FORCED by a synchronous read-back of applied-only geometry.** A handler
   that mutates geometry and then, *in the same cycle before `recalculateLayouts`*, reads it back —
   a clamp, a derived value, hit-testing, a coordination flag — must apply immediately, because the
   accessor won't surface the pending value. That is the real reason `raw*` is used in handlers. It is
   **not** "cross-frame lag" and **not** a determinism minefield: a wrong conversion would read stale
   geometry and fail *deterministically* — tests go red — not flakily.

**Net:** the raw-in-handler smell (soft-wrap + ~a dozen siblings, §5) is a symptom of the half-built
model. Reigning it in is real, coherent work — completing the deferred model — not a marginal cleanup.

---

## 1. The two paths to complete it — applied CASE BY CASE

Whether a given handler can go deferred depends on **whether the same event also entails a relayout /
constraint resolution.** This is the crux distinction:

### Path A — defer + pending-aware read (when NO relayout/constraint: `desired == actual`)
For an **unconstrained freefloating transport** — pick a widget up, move it, drop it; *most
drag-and-drops* — the requested position IS the position it gets. Here you can either make the
accessors pending-aware (generalize the `pickUp` / `fullRawMoveWithin` pending-aware read — both
already do it) or have the specific read-back consult
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
| **Scrollbar drag** `ScrollPanelWdgt:80/85` | `adjustContentsBasedOnHBar/VBar` read `@contents.position()` (clamped scroll offset) on the raw-move line itself (`:80/:85`); the following `@adjustContentsBounds()` reads `@contents.width/height/left/top/boundingBox` (NOT `position()`). | **B** |
| **Grab-anchor** `KeepsRatioWhenInVerticalStackMixin:27-29`, `Example3DPlotWdgt:104-106` | `@parent.fullRawMoveWithin world` clamps by reading the just-set position; `rawSetExtent` applies a ratio constraint. | **B** |
| **Ratio-on-drop** `Example3DPlotWdgt:87/110`, `KeepsRatio:12` (`constrainToRatio`) | dropped INTO a vertical stack → stack-attached (non-FREEFLOATING); the stack's `doLayout` reads the child's ratio-derived `@height()`. | **B** |
| **Window collapse/uncollapse** `WindowWdgt:247-257` (`childUnCollapsed`) | inline `@adjustContentsBounds()` (`:254`) runs while `@reInflating = true` (set `:249`, reset `:255`); the layout reads `@reInflating` (`:157`). | **B** |
| **Spawn-at-hand** `InspectorWdgt:269` | `fullRawMoveWithin` clamps the just-set position before `add`. | **B** (or A if the clamp is a no-op) |

(`StretchableEditableWdgt.smartPlace:42` is NOT a smell — `fullRawMoveTo center; add` has no
clamp/read-back; it is construction-time positioning before `add`, legitimate construction per this
section's audit.)

(The ratio pair `KeepsRatioWhenInVerticalStackMixin` ⇄ `Example3DPlotWdgt` is a known duplicate: the
real ratio-logic duplication is `Example3DPlotWdgt.coffee:77-112` ≈ mixin `:9-43`; `:158-163` is a
*comment* about deliberately not deduplicating the paint scaffold, a different thing.)
**Most handler smells are Path B (constraint-entangled). The
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
  an invalidate on a freefloating widget does NOT climb to its parent — relevant to soft-wrap, §5).
- **The cycle:** `recalculateLayouts` (`WorldWdgt.coffee:841`) tail-drains the dirty list, climbs to
  the topmost-still-invalid ancestor, and calls `doLayout()`. `doLayout` consumes `@desired*` via
  `__calculateNewBoundsWhenDoingLayout` and applies constraints to produce `@bounds`. Runs once per
  `doOneCycle`, before paint (§0.1).

**The scroll panel's content `PanelWdgt` is `ATTACHEDAS_FREEFLOATING`** (`ScrollPanelWdgt.coffee:37`
`@addRaw @contents` → `addRaw` default FREEFLOATING `Widget.coffee:2227`; class default `:235`), so
`setExtent`'s gate passes — `setExtent` is usable on the content.

---

## 4. The geometry accessors read applied `@bounds` (verified)

```coffee
position: -> @bounds.origin        extent: -> @bounds.extent()
left:  -> @bounds.left()           width:  -> @bounds.width()
top:   -> @bounds.top()            height: -> @bounds.height()   # …all via @bounds
```
`@desiredExtent`/`@desiredPosition` (`Widget.coffee:56-57`, default `nil`) are SET by
`setExtent`/`setWidth`/`setHeight`/`fullMoveTo` **and `setBounds`** (`:721/:726`) — four deferred
writers, all FREEFLOATING-gated — and READ by `fullRawMoveWithin` (`:1344-1352`),
`__calculateNewBoundsWhenDoingLayout` (`:3761-3772`), and `pickUp` (`:2712`). One more out-of-band
touch: `StretchablePanelWdgt.coffee:67-68` clears children's `@desired*` to `nil` before
`w.doLayout()` — a pending-aware-accessor change must survive it. **This split — request in
`@desired*`, applied in `@bounds`, accessors expose only `@bounds` — is the half-built-ness.** Path A
is "teach the accessors the pending-aware read (`pickUp` **and** `fullRawMoveWithin` already do it:
pending if set, else applied)." Path B exists precisely because, under a constraint, the pending
request is *not* the applied result, so the trick gives the wrong answer.

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
  consulted in `subWidgetsMergedFullBounds` (`Widget:975`), so adding a `doLayout` flips every scroll
  panel's merged-bounds contribution — a nested-scroll geometry change to verify.
- The `adjustContentsBounds:289` `widget.softWrap = true` overwrite is a **single-pass code-ORDER**
  correctness issue (one authority must own the wrap geometry, in a fixed order), deterministic and
  caught by tests.

So soft-wrap is real but is one of the *harder* cases (Path B + extra reachability work), not the place
to start. The clean first win is Path A (unconstrained drag-drop transport, §2).

---

## 6. Sequencing / what completing this would take

**Method:** pattern-match each site against the adhering flows (§2b) — `HandleWdgt.nonFloatDragging` is the
worked template (compute from the event, set via the deferred API, no read-back). Each rewrite is one unit.

1. **Pilot Path A on the cleanest constrained-free case to prove the mechanism** — e.g. a single
   freefloating-transport handler, or a self-contained Path-B de-read-back (the slider: derive the
   value from the clamped `newPosition` instead of reading `@button.top()` back). Small, verifiable.
2. **Path A proper — pending-aware accessors** (generalize `pickUp` **and** `fullRawMoveWithin`, and
   survive the `setBounds` writer + `StretchablePanelWdgt`'s external `@desired*` clear, §4): the
   systematic enabler for the no-relayout transport class. Core-model change; needs an invariant +
   determinism pass and the full gauntlet. Its own design doc — **now written:
   `docs/deferred-layout-path-a-design.md`. NB: the blanket "pending-aware accessors" form of this was
   tried (2026-06-19) and EMPIRICALLY DIVERGES (conflicting pending-vs-applied read semantics); that
   design doc has the per-reader plan that supersedes this bullet.**
3. **Path B — per constraint-entangled site**, classified in §2 (sliders, scroll, ratio, window
   collapse). Each eliminates its specific read-back or re-orders the constraint resolution.
4. **Soft-wrap specifically** (§5): Path B *plus* wiring `adjustContentsBounds` into the cycle without
   the `implementsDeferredLayout` nested-scroll regression.

These can land independently and incrementally; none requires the others first, except soft-wrap which
wants its reachability fix regardless.

### 6a. The slider de-read-back pilot — ready to execute cold (BYTE-SAFE, item 1 above)

The smallest verifiable forward step (a self-contained Path-B de-read-back; the structural twin of
`HandleWdgt`).

**Today** (`src/basic-widgets/`): `SliderButtonWdgt.nonFloatDragging` (`:75-96`) computes the clamped
`newPosition` locally (`:81-92`), then `@fullRawMoveTo newPosition` (`:95`, immediate) and
`@parent.updateValue()` (`:96`). `SliderWdgt.updateValue` (`:123-135`) reads the **just-moved** thumb
back — `@button.top()/.bottom()/.left()` — to derive `relPos → newvalue → setValue`. *That read-back
is what forces the move to be raw.*

**The change — compute the value from the local clamped `newPosition`, never read the thumb back (two
edits):**
- `SliderWdgt.updateValue` (`:123-135`) → `updateValue: (constrainedButtonPosition = nil) ->`; when
  the arg is present, source `buttonTop = arg.y`, `buttonLeft = arg.x`,
  `buttonBottom = arg.y + @button.height()`; else fall back to `@button.top()/.left()/.bottom()`
  (the only caller is the button, but the fallback keeps it safe for serialization/inspector paths).
- `SliderButtonWdgt.coffee` (`:96`) → `@parent.updateValue newPosition`.

**Why it is byte-identical (zero pixel risk):** `@fullRawMoveTo newPosition` (`:95`) is synchronous
and runs *before* `updateValue` (`:96`), so at that instant `@button.top() ≡ newPosition.y`,
`@button.left() ≡ newPosition.x`, `@button.bottom() ≡ newPosition.y + @button.height()` (button
height is invariant during a drag). The new branch computes exactly those three quantities ⇒ identical
`relPos`, `newvalue`, and `setValue` call ⇒ identical pixels. `updateValue` has **exactly one caller**
(`SliderButtonWdgt:96`). What it buys: the read-back (the *forcing* constraint) is
gone, decoupling value-derivation from the thumb's applied geometry — the precondition for any future
deferral of the thumb move — while shifting zero pixels. Verify with §9.

**Step 2 (FOLLOW-ON — owner decision, NOT byte-safe):** flip the thumb move itself to deferred. The
thumb is layout-positioned (`SliderButtonWdgt.reLayout:36-68` places it from `@parent.value` via
`@silentFullRawMoveTo`), so "deferred" means drop the raw move and let `setValue → reLayout`
reposition it. This **changes behaviour**: during *sub-unit* drags (where the rounded value does not
change) the thumb would snap to value-quantized positions instead of smoothly following the cursor
within the frame — a deliberate visual change requiring recapture of any slider test that exercises
sub-unit drags. Do not bundle it into the byte-safe pilot.

### 6b. The inline re-fit triggers → deferred conversion (the `childGeometryChanged`/`_reFitToContents`-from-immediate-mutators arc)

This is the home of what was first scoped as flow-rule task #19 ("forbid `childGeometryChanged`/`_reFitToContents`
from immediate mutators"). An audit (2026-06-20) showed it is **not** a small lint add but a Path-C arc — recorded
here so it's picked up deliberately.

**What these triggers are.** Three immediate mutators carry an inline, *synchronous* container re-fit:
`Widget.silentRawSetExtent` (`~:1592-1594`), `Widget.fullRawMoveBy` (`~:1234-1236`), and the shared helper
`Widget._refreshScrollPanelWdgtOrVerticalStackIfIamInIt` (`~:1597-1600`). On any silent resize/move they call
`@parent.parent._reFitToContents?()` (when directly inside a scroll panel) and/or `@parent?.childGeometryChanged?()`
(stack/window), which synchronously re-fit the container (`_reFitToContents → _adjustContentsBounds`, itself guarded
by `@_adjustingContentsBounds`). This is the §2b-C pattern's *synchronous* (pre-deferred) ancestor.

**Audit — they are SAFE but load-bearing.**
- *Not the flow-rule freeze smell.* They APPLY a re-fit synchronously; they never `invalidateLayout` nor re-enter
  `recalculateLayouts`. Proven: the full gauntlet passes with the #18 `invalidateLayout`-during-recalc `throw`
  active — no re-fit cascade trips it. So it is a LAYERING smell only, not a convergence hazard. **Do NOT extend
  lint [E] to forbid them until C3 below** — that would flag legitimate current code.
- *Load-bearing.* Removing the trigger from `silentRawSetExtent` alone reds **exactly 3 SystemTests**:
  `macroScrollBarsTrackContentChange`, `macroWindowWithAClockInAWindowConstructionTwo`,
  `macroWindowWithSimpleVerticalPanelResizesAsContentChanges`. (`silentRawSetExtent` has 22+ callers;
  `_refresh…` is driven by `VerticalStackLayoutSpec`, `TextWdgt`, `SimplePlainTextWdgt`.)

**Instrumentation that dictates the work** (gated `window.__INSTR19` log at the trigger — class/spec/parent/
grandparent/`_amIDirectlyInsideNonTextWrappingScrollPanelWdgt()`/`world._recalculatingLayouts`/stack):

| Test | trigger path | inside `recalculateLayouts`? |
|---|---|---|
| `macroScrollBarsTrackContentChange` | text → `ScrollPanelWdgt` (`_reFitToContents`) | **100% in-pass** — the text re-wraps inside its own `doLayout` (`doLayout(text)→rawSetExtent→reLayout→silentRawSetExtent`) and must re-fit the panel mid-pass |
| `…ClockInAWindowConstructionTwo` | nested `WindowWdgt`/clock/box → `WindowWdgt` (`childGeometryChanged`) | **~99% in-pass** — square-on-resize converges during the pass |
| `…SimpleVerticalPanelResizesAsContentChanges` | text→stack, stack→`WindowWdgt` | **mostly outside-pass** — content-change (drop/type) re-fit |

**The obstacles (why it is not a small reroute):**
1. **In-pass (tests 1, 2) cannot `invalidateLayout`** — that now throws (#18). The right form is the container's
   re-fit *self-converging to a fixed point* within its own `doLayout` when its (freefloating) content re-lays-out
   and changes size — not a child callback.
2. **The lint blocks the obvious site.** The reroute cannot live in `silentRawSetExtent`/`fullRawMoveBy` (rule [E]
   forbids an immediate mutator scheduling); it must move to the content-change operations or to `_refresh…`
   (a non-immediate method, lint-legal to `invalidateLayout`).
3. **Freefloating content does not climb** (§4, §5): scroll-panel / window content is `ATTACHEDAS_FREEFLOATING`,
   so `invalidateLayout()` on it does not reach the container — the container must be invalidated directly.

**Phased plan** (each phase: build → dpr1 suite → **smoke-apps** → dpr2/WebKit/soak; behaviour-changing phases
recapture ONLY the named tests):
- **C1 — outside-pass first (test 3 class).** At the content-change operations resizing via the silent path
  (stack-element resize, cell add/remove, text grow), route the re-fit through §2b-C: invalidate the container
  directly (handling the freefloating stack→window climb), then drop the inline trigger for those paths. Aim
  byte-identical; recapture only if settle-timing shifts pixels.
- **C2 — in-pass convergence (tests 1, 2 class).** Make `ScrollPanelWdgt`/`WindowWdgt`/`SimpleVerticalStackPanelWdgt`
  `_reFitToContents` converge to a fixed point: after sizing content that itself re-lays-out (wrapping text; square
  clock; nested window), re-measure/re-fit until stable *within the pass*, so no child callback is needed. This is
  the hard core; the soft-wrap reachability case (§5) is the same shape.
- **C3 — remove triggers + extend lint [E].** Once C1+C2 make the triggers redundant, delete them from
  `silentRawSetExtent`/`fullRawMoveBy`/`_refresh…` and extend rule [E] (`isImmediateMutator`) to also forbid
  `childGeometryChanged`/`_reFitToContents` from immediate mutators — the original #19 enforcement, now correctly
  the LAST step.

**Reproduce the audit:** instrument the trigger (`if window.__INSTR19 then console.log "INSTR19|"+…`), build
`--keepTestsDirectoryAsIs`, then `PRELUDE_JS=<file with window.__INSTR19=true> LOG_FILE=/tmp/x.log node
scripts/run-macro-test-headless.js SystemTest_<name>`; `grep INSTR19 /tmp/x.log`. Empirical removal test: delete the
`silentRawSetExtent` trigger, run the dpr1 suite → exactly the 3 tests above fail.

### 6b.1 Deep design + phase status (2026-06-20)

Read the re-fit machinery end-to-end — the grounding for the phases:
- **The deferred re-fit path ALREADY exists.** Every container (`ScrollPanelWdgt` / `SimpleVerticalStackPanelWdgt` /
  `WindowWdgt`) re-fits via `_reFitToContents` (= `_adjustContentsBounds` [+ `_adjustScrollBars`]), reached from MANY
  entry points — public `add`/`addMany`/`setContents`, `reactToDropOf`/`reactToGrabOf`, the `rawSetExtent` resize
  override, the contained-panel notify (`reLayOutAfterContainedPanelChange`/`childGeometryChanged`), AND the Slice-1/2
  `doLayout` (`doLayout: -> super; @_reFitToContents()`). So a container re-fits ON THE CYCLE whenever its layout is
  invalidated.
- **The only gap:** a content widget's geometry change via the silent/raw path does NOT invalidate its container
  (freefloating ⇒ `invalidateLayout` doesn't climb, §4; silent ⇒ no invalidate), so the cycle never re-fits it — which
  the inline synchronous trigger fills.
- **Text-wrapping vs not.** A text-wrapping scroll panel's `_adjustContentsBounds` itself re-wraps the content
  (`widget.rawSetWidth @contents.width()…`, `ScrollPanelWdgt:304-315`) — a one-pass fixed point, so its content needn't
  notify (hence the trigger's `NonTextWrapping` guard). A NON-wrapping panel (test 1) does NOT drive the re-wrap —
  content re-wraps independently, so the panel must react.

Seam + refined phases:
- **C0 — DONE (2026-06-20).** The two identical immediate-mutator triggers (`silentRawSetExtent`/`fullRawMoveBy`) are
  collapsed into one private seam `Widget._reFitContainerAfterRawGeometryChange` — the single site every later phase
  edits. Behaviour-identical; cost = ONE benign inspector recapture (`macroDuplicatedInspectorDrivesCopiedTargetOnly`,
  dpr1+dpr2) because the new method enters the inspector's reflected member list. **NB: adding a Widget method is NOT
  inspector-free** (contra an earlier note) — every C1–C3 method-add re-shifts + recaptures this same one test (benign,
  expected). Verified: lint 0; suite 165/165 dpr1+dpr2; smoke-apps 12/12.
- **C1 — outside-pass deferral.** Make the seam context-aware: when NOT in `recalculateLayouts`, INVALIDATE the
  container directly (`@parent.parent.invalidateLayout()` for the scroll panel; the stack/window for the
  `childGeometryChanged` arm) instead of synchronously re-fitting — the container then re-fits on the cycle. The seam is
  non-immediate, so lint [E] permits the invalidate. Covers test 3's mostly-outside-pass triggers + the freefloating
  stack→window climb. Verify byte-identical at settle; recapture only what settle-timing shifts.
- **C2 — in-pass convergence (the hard core).** Keep the in-pass branch synchronous until each container's
  `_reFitToContents` is a true fixed point: after sizing content that itself re-lays-out (wrapping text / square clock /
  nested window) re-measure WITHIN the pass, so no child callback is needed (tests 1, 2; soft-wrap §5 is the same shape).
- **C3 — remove + enforce.** Once C1+C2 make the seam redundant, delete it (and the `_refresh…` sibling) and extend lint
  [E] to forbid `childGeometryChanged`/`_reFitToContents` from immediate mutators.

---

## 7. Risk & framing

- **Failure mode is deterministic, not flaky.** Reading stale/pre-constraint geometry yields the same
  wrong pixels every run → the SystemTests catch it immediately. This is *not* the dpr2-flake class.
- **Path A's risk is breadth AND conflicting read semantics** (accessors are everywhere; the hand drives
  spatial queries). As the 2026-06-19 attempt showed, a *blanket* pending-aware accessor change DIVERGES
  because some readers need PENDING and others need APPLIED geometry — it must be a per-reader audit. See
  `docs/deferred-layout-path-a-design.md`.
- **Path B's risk is per-site correctness** — get each constrained read right; low blast radius each.
- **Determinism still mandatory** for any change here: ~41 SystemTests touch wrap/scroll/reflow; run
  dpr1 + dpr2 + WebKit + `--homepage`. A real behaviour-preserving step shifts ZERO pixels; a deliberate
  behavioural change recaptures deliberately and confirms faithfulness.

---

## 8. Test exposure

12 SystemTests mention `SoftWrap`; a raw substring scan over the 165 test dirs finds ~64 mentioning
`wrap` broadly (most of the extra are incidental matches like `wrapper`). Closest to soft-wrap:
`macroSoftWrapping`, `macroSoftWrapTogglesTextReflow`,
`macroSimplePlainTextScrollPanelUpdatesWellWhenWrappingUnwrappingFromTheBottomOfContent`,
`macroWrappingSimplePlainTextResizesCorrectlyAsTextIsAddedAndRemoved`,
`macroWrappingSimpleTextScrollPanelResizesCorrectlyAsTexSizeIsChangedPartTwo`,
`macroNonWrappingTextResizesToContent`, `macroFreeWidthScrollStackShowsHorizontalScrollbar`,
`macroWrappingTextFieldResizesOK`, `macroTextRelayoutsCorrectlyOnResize`. Drag-drop transport (Path A)
additionally exercises the grab/drop + scroll-panel tests broadly.

---

## 9. Verification recipe (when any conversion is attempted)

Each repo in a SEPARATE `cd` (chaining build+smoke across repos → MODULE_NOT_FOUND):
1. `cd Fizzygum && ./build_it_please.sh` (CoffeeScript syntax gate).
2. `cd Fizzygum-tests && node scripts/run-all-headless.js --shards=5` (dpr1), then `--dpr=2 --shards=5`,
   then `--browser=webkit --shards=5`. Expect 165/165.
3. `--homepage` 3-step: (a) `cd Fizzygum && ./build_it_please.sh --homepage`; (b) `cd Fizzygum-tests &&
   node scripts/smoke-boot-headless.js --native-only`; (c) `cd Fizzygum && ./build_it_please.sh`.
4. Path A / hand-touching changes: a `scripts/torture-headless.js` soak at dpr2 over the drag/scroll
   tests (the spatial-query breadth is where to look).

---

## 10. Cleanups already shipped (commit `d01c7f3f`, byte-exact)

1. Deleted the dead `ScrollPanelWdgt.toggleTextLineWrapping` (zero call sites; homepage-excluded).
2. Added WHY-immediate comments on `ScrollPanelWdgt.setTextLineWrapping` and
   `SimplePlainTextWdgt.setSoftWrap` pointing here — framing the immediacy as a symptom of the
   half-built model (accessors read applied `@bounds` only), with soft-wrap's
   `adjustContentsBounds`-reachability as an extra blocker on top. Comment-only ⇒ byte-exact.
3. **(2026-06-19, `Fizzygum` `7c720908`)** Added the deferred clamp primitive `fullMoveWithin`
   (`Widget.coffee`), the twin of `fullRawMoveWithin` (the "missing primitive"); converted the
   `MacroToolkit` window-in-window verb to the deferred API; refreshed the `ActivePointerWdgt` grab TODO.
4. **(2026-06-19, `Fizzygum-tests` `51b064fc0`)** Macro raw-API cleanup: 117/133 SystemTest macro command
   files moved to the deferred geometry API (366 call-sites), byte-identical (165/165 at dpr1 + dpr2 +
   WebKit). 16 keep raw (synchronous construction read-backs). See the §"Status — 2026-06-19" note and
   `deferred-layout-path-a-design.md`.

---

## 11. Context

Spun off from Phase-7 item **7c** (commit `9d3e1234`), which encapsulated the grandparent write +
content-resize into `ScrollPanelWdgt.setTextLineWrapping` and unified `softWrapOn/Off` into
`setSoftWrap` (byte-identical). The campaign tracker is `docs/oo-smells-refactoring-backlog.md`; the
deferred-pattern audit summary lives under its Phase 7. The God-class arc (Phase 6, COMPLETE) is
`docs/god-class-decomposition-plan.md`. The byte-exact contract is `Fizzygum-tests/DETERMINISM.md`.
