# Deferred-layout residuals audit — every synchronous relayout still at a non-settle point

> **STATUS: LIVE — the campaign map.** Canonical current state + the re-queue mechanism: `deferred-layout-OVERVIEW.md`
> (it supersedes this doc on any conflict). Originally a read-only audit (2026-06-21, 3 parallel sweeps over `src/`).
> **Progress so far: the seam + twin + drag/drop gesture re-fits are now DEFERRED** (see "Already compliant" below).
> This maps the ~40 synchronous relayouts that REMAIN. Line numbers are approximate (as of `1e5d3745`) — grep the
> method name (authoritative).

## The aim + the two legal settle points (confirmed in code)

Every relayout must run at exactly one of:
- **(a) a public-method FLUSH** — `Widget.mutateGeometryThenSettle` records intent + runs `recalculateLayouts`
  (Widget.coffee ~:748); batch variant `settleLayoutsOnceAfter` (~:795). The 7 self-settling public methods:
  `setBounds`, `setExtent`, `setWidth`, `setHeight`, `fullMoveTo`, `add`, `addRaw`. Batch caller:
  `WindowWdgt.buildAndConnectChildren` (settleLayoutsOnceAfter).
- **(b) the CYCLE** — `WorldWdgt.doOneCycle → recalculateLayouts` until-loop (`_recalculateLayoutsCore` ~:876, loop
  ~:885), draining `widgetsThatMaybeChangedLayout` via `doLayout` until convergence.

Low-level `raw*`/`silent*`/`fullRaw*` mutators must only MUTATE, never schedule layout (`invalidateLayout` THROWS
mid-pass, Widget.coffee ~:3804) — but they MAY APPLY layout synchronously during a pass (the sanctioned in-pass apply).

## Already compliant (this effort)

- **The in-pass container re-fit cascade** (the seam `_reFitContainerAfterRawGeometryChange` + the twin
  `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt`) now DEFERS via the re-queue (enqueue the container into the
  until-loop). ~99% of cascade re-fits.
- **Resize/move handle drag** — `HandleWdgt.nonFloatDragging` uses the public `setExtent`/`fullMoveTo`/`setWidth`/
  `setHeight` (a FLUSH per move). Not residual.
- **The hand's own move** — `ActivePointerWdgt.fullRawMoveBy` → seam → DEFER (invalidate). Not residual.
- **Construction re-fits** — on orphan widgets, `invalidateLayout` is a no-op until the widget is added (~36 sites).
- **~26 `invalidateLayout` calls from public setters/structural mutators** — legal deferred scheduling.
- **The twin's outside-pass container re-fit now DEFERS (2026-06-21).** `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt`
  is now a 3-way (recalc→enqueue, `_reFittingContents`→synchronous cascade, **else→invalidate the container**). The
  twin's callers are the `VerticalStackLayoutSpec` alignment/elasticity/base-width setters (part of 3), collapse (4),
  and content-edit/soft-wrap (5) — for all of them the shared synchronous container re-fit (the
  `_refreshScrollPanelWdgtOrVerticalStackIfIamInIt` call) is now deferred. Byte-identical (165/165 dpr1+dpr2+WebKit,
  smoke-apps OK). STILL SYNCHRONOUS (not twin-mediated, untouched): `BoxWdgt.choiceOfWidgetToBePicked` and
  `Widget.newParentChoice*` (direct `_adjustContentsBounds`/`_refitContentsAndScrollBars`) in 3; the `reInflating`-coupled
  direct `_reFitToContents` in collapse (4, must stay synchronous); the `@reLayout()` in content-edit + soft-wrap (5,
  the soft-wrap one is the dedicated hard arc). See those families below.
- **The drag/drop gesture re-fits now DEFER (2026-06-21) — family 2 below.** The four gesture seams
  `ScrollPanelWdgt`/`PanelWdgt`/`SimpleVerticalStackPanelWdgt` `reactToDropOf`/`reactToGrabOf` + the stack's
  `childRemoved` are now 2-way (in a pass/cascade → synchronous; **else → invalidate the container**). They dispatch
  from `ActivePointerWdgt.drop`/`grab` AFTER a self-settling `add` (outside any pass), so the re-fit settles on the
  next `doOneCycle` (each container's `doLayout` is `super; @_reFitToContents`). Byte-identical (165/165
  dpr1+dpr2+WebKit, smoke OK). LEFT synchronous (correct, per the mapping Workflow): `childGeometryChanged` (the
  cascade SINK the two prior seams call), `reLayOutAfterContainedPanelChange`/`_refitContentsAndScrollBars` (absorb
  return-value contract), `PanelWdgt.childRemoved` + `addInPseudoRandomPosition` (later slice / verify-and-drop), and
  `WindowWdgt.reactToDropOf` (no direct re-fit — covered by `super`, verified byte-identical).
- **The `newParentChoice*` dev-menu re-fits now DEFER (2026-06-21) — family 3 leftover.** `Widget.newParentChoice`
  and `newParentChoiceWithHorizLayout` ("attach this selected widget to me") used to call `@_refitContentsAndScrollBars?()`
  synchronously right after a self-settling `@add`. Now the call site is the 2-way deferred form (mirrors
  `reactToDropOf`): an existence check `if @_refitContentsAndScrollBars?` does the old `?()`-soak's job (no-op off a
  scroll panel), then `if _recalculatingLayouts or _reFittingContents → synchronous; else → @invalidateLayout()`. Safe
  because `_refitContentsAndScrollBars` IS `@_reFitToContents`, the very method `doLayout` (`super; @_reFitToContents`)
  runs next cycle — and `@add` already flushed `@desired*`, so `super` is a no-op. Byte-identical (165/165
  dpr1+dpr2+WebKit, smoke OK). The shared `_refitContentsAndScrollBars`/`reLayOutAfterContainedPanelChange` pair stays
  synchronous (return-value contract); `BoxWdgt.choiceOfWidgetToBePicked` is dead code (left untouched).

## Residual families — the remaining campaign (~40 synchronous relayouts at non-flush points)

Ordered roughly by how self-contained the conversion is. Each family is a SEPARATE determinism-sensitive arc (own
soak). The codebase comments self-identify most of these as "the intermediate residual the deferred-model
conversion will remove."

1. **Scroll-input handlers (ScrollPanelWdgt) — VERDICT: LEAVE SYNCHRONOUS (assessed 2026-06-21).** Synchronous
   `_adjustContentsBounds`/`_adjustScrollBars` straight from input handlers: `wheel` (~:666), `mouseDownLeft`
   momentum (~:469), `autoScroll` (~:614), `scrollCaretIntoView` (~:636), `scrollTo`/`scrollToBottom` (~:424/430),
   `adjustContentsBasedOnHBar/VBar` (~:82/87). ~13 sites. **Do not convert** — three reasons, source-verified:
   (i) **Wrong problem class.** Unlike the seam (a freefloating CHILD notifying its CONTAINER), here the panel
   adjusts its OWN `@contents` in direct response to scroll input — the re-queue/freefloating-non-climb machinery
   does not apply; deferral would just relocate the identical `_adjustContentsBounds`+`_adjustScrollBars` to
   end-of-cycle. (ii) **Highest determinism risk of any residual, for zero correctness gain.** `autoScroll` gates
   on `Date.now()-@autoScrollTrigger < 500` and is NOT harness-suppressed; `mouseDownLeft` carries frame-cadence
   release momentum/glide; `adjustContentsBasedOnVBar` is the known dpr2 scroll-thumb flake path (cf.
   `Fizzygum-tests` swcanvas-scrollthumb / multi-click-event-time case law). Moving these re-fits off end-of-handler
   shifts WHEN geometry settles relative to timer/momentum sampling — the dpr2-under-load starvation class. The
   re-fit result is already byte-exact, so there is no correctness payoff to offset the risk. (iii) **Does not
   block the capstone** — these are event handlers, not `raw*`/`silent*`/`fullRaw*` immediate mutators, so lint [E]
   (which polices immediate mutators) does not need them; and they call `_adjustContentsBounds` directly, never via
   the seam's `_reFittingContents` branch, so they are independent of the counter retirement. (`scrollCaretIntoView`
   additionally has an internal read-back — `_adjustContentsBounds` at ~:642 must run BEFORE the caret math reads
   applied bounds — that a deferral boundary would split.)

2. **Drag/drop re-fit cascades — DONE (DEFERRED 2026-06-21, `1e5d3745`; see "Already compliant" above).** The gesture
   seams `reactToDropOf`/`reactToGrabOf` (ScrollPanelWdgt/PanelWdgt/SimpleVerticalStackPanelWdgt) + the stack's
   `childRemoved` now defer (2-way: pass/cascade → synchronous; else → invalidate the container). What REMAINS here is
   left synchronous BY DESIGN: the cascade SINK `childGeometryChanged`, `reLayOutAfterContainedPanelChange` /
   `_refitContentsAndScrollBars` (the absorb return-value contract), and `PanelWdgt.childRemoved` +
   `addInPseudoRandomPosition` (a later verify-and-drop slice).

3. **Menu actions** (the twin-mediated part is **DONE — deferred `1caea690`**). `VerticalStackLayoutSpec.setAlignmentToLeft/Right/Center`/`setElasticity`/`setWidthOfElementWhenAdded`
   re-fit via the twin → done. The two non-twin-mediated "attach selected widget to me" dev-menu sites
   `Widget.newParentChoice`/`newParentChoiceWithHorizLayout` are now **DONE — deferred 2026-06-21** (see "Already
   compliant" below): the post-`@add` synchronous `@_refitContentsAndScrollBars?()` is now the 2-way deferred form
   (gated by a scroll-panel existence check; `else → @invalidateLayout()`). **Nothing remaining here.**
   `BoxWdgt.choiceOfWidgetToBePicked` is **DEAD CODE** (its re-fit is guarded by `if @ instanceof ScrollPanelWdgt`
   inside a `BoxWdgt` method, but `ScrollPanelWdgt extends PanelWdgt extends Widget` — `BoxWdgt` is never an
   ancestor, so the branch never runs; also homepage-excluded) — leave untouched.

4. **Collapse / uncollapse** (the twin-mediated part is **DONE — `1caea690`**). `WindowWdgt.childCollapsed`/`childUnCollapsed`
   via `Widget.collapse`/`unCollapse`. **REMAINING:** the `reInflating`-coupled direct `@_reFitToContents()` (must stay
   synchronous — `contentsRecursivelyCanSetHeightFreely` reads `@reInflating` while it runs; deferring would break it).

5. **Content-edit / soft-wrap — VERDICT: LEAVE SYNCHRONOUS (assessed 2026-06-21).** The twin-mediated container re-fit
   is **DONE — `1caea690`**. The widget's own `@reLayout()` re-wrap was given a full design pass (mapping Workflow +
   read-audit + adversarial verify) → **leave synchronous in its entirety**: (a) `TextWdgt.rawSetExtent`'s re-wrap is
   the in-pass APPLY the base `doLayout` depends on (family-8; converting throws); (b) `setSoftWrap` wrap-OFF `@reLayout()`
   is the sole producer of the natural-width collapse (no cycle path replaces it); (c) `reLayoutAndRefreshContainerIfContainedText`'s
   `@reLayout()` is redundant ONLY in a text-wrapping scroll panel, and **that case is blocked by a same-cycle caret
   read** (`CaretWdgt.insert` `:318 setText` → `:319 gotoSlot → slotCoordinates` reads the wrapped geometry before the
   settle; `scrollCaretIntoView` is a second reader) → deterministic red; the other topologies are non-redundant. No
   `TextWdgt.doLayout` (no-go — flips `implementsDeferredLayout`, fires a redundant re-wrap, buys nothing). Reward is
   thin (deferring soft-wrap does NOT unlock lint [E] — co-gated on family-8). Full closure = a large owner-gated
   determinism-sensitive sub-arc. See `softwrap-deferred-layout-conversion-plan.md` §5 VERDICT.

6. **Slider family — VERDICT: LEAVE SYNCHRONOUS (assessed 2026-06-21).** `SliderWdgt.setValue` (:117/119, **mid-drag**
   via `SliderButtonWdgt.nonFloatDragging`), `updateHandlePosition` (:106/107), `setStart`/`setStop`/`setSize`/`updateSpecs`
   (config setters), `rawSetExtent` (:74). ~13 synchronous `reLayout` sites. **No pattern surface:** `SliderWdgt.@reLayout()`
   resolves to the EMPTY `Widget.reLayout` base (no `SliderWdgt`/`CircleBoxWdgt` override) — a no-op; the `@button.reLayout()`
   only repositions the slider's OWN thumb via `silentRawSetExtent`/`silentFullRawMoveTo` (own internals, not a container
   re-fit), and the mid-drag path is cadence-sensitive for zero correctness gain. The byte-safe Path-B step here is
   owner-gated (don't do unprompted). Not worth an arc.

7. **LabelButton — VERDICT: LEAVE SYNCHRONOUS (assessed 2026-06-21).** `alignCenter`/`alignLeft`/`setLabel` (:104/110/115)
   → synchronous `reLayout` from a menu/button. Already compliant in substance: the `reLayout` re-centers only the
   button's OWN label via raw setters (not a container re-fit), fired from a discrete menu action that completes
   synchronously. Low-risk but zero-reward; leave as-is.

8. **THE STRUCTURAL ROOT — `rawSetExtent` runs `reLayout`.** Base `Widget.rawSetExtent` (~:1520) =
   `silentRawSetExtent` + `changed` + **`@reLayout()`**, unconditionally (no pass guard; base `reLayout` is empty, so
   it bites only where `reLayout`/an override runs layout). This is INTENDED as the in-pass synchronous-APPLY
   mechanism (`rawSetWidthSizeHeightAccordingly` relies on it, Widget.coffee ~:706), but it makes `rawSetExtent`'s
   `reLayout` an off-settle residual at every **off-pass** call site — collapse handlers (WindowWdgt:259-260), the
   hand's `drop`/`determineGrabs` (ActivePointerWdgt:252/840), and the Stretchable*/Slider/TextWdgt `rawSetExtent`
   overrides that add `@doLayout()`/`@reLayout()`. This underlies families 4/6/7 and is the hardest to convert
   (it touches the apply primitive). NB `setExtent` does NOT go through `rawSetExtent` — they are disjoint tiers
   (`setExtent` = schedule+flush; `rawSetExtent` = internal apply).

## Two clarifications worth keeping

- **The transport/drag path is mostly compliant.** Handles use public setters; grab/drop use `add`/`setExtent`/
  `fullMoveTo`. The genuine drag residuals are only the `reactToGrabOf`/`reactToDropOf` `_reFitToContents` cascades
  (family 2) and the hand's `rawSetExtent`→`reLayout` (a no-op for the hand). The deferred clamp `fullMoveWithin`
  EXISTS but is deliberately NOT used in `grab` (a conscious determinism call to keep the real-time grab raw —
  ActivePointerWdgt.coffee:162).
- **lint [E] tightening + retiring `world._reFittingContents` is the END of the campaign — and it is genuinely LAST,
  not a separable "cheap first half" (verified 2026-06-21).** `check-layering.js` rule [E] currently polices only
  `invalidateLayout` from `raw*`/`silent*`/`fullRaw*`; tightening it to also forbid synchronous `_reFitToContents`/
  `childGeometryChanged`/`reLayout` needs **family 8** (the `rawSetExtent→reLayout` structural root) converted first —
  it is the load-bearing blocker. Retiring the `_reFittingContents` counter is blocked independently: the counter's
  synchronous middle arm stays load-bearing as long as ANY `_reFitToContents` runs outside a recalc pass with a nested
  raw change, and two such roots are un-deferrable / not at a settle point — **`WindowWdgt.add:212`** calls
  `@_reFitToContents()` BEFORE its `super` flush (:213), and **`WindowWdgt.childUnCollapsed:258-264`** runs a
  `reInflating`-coupled `@_reFitToContents()` whose `_adjustContentsBounds` reads `!@reInflating` mid-run (WindowWdgt:157).
  So the counter cannot be deleted ahead of resolving the structural root + those un-deferrable sites + the
  `reLayOutAfterContainedPanelChange` return-value contract. (A naive in-pass seam removal already broke 7 tests — the
  C2 wall; the risk here is the high-severity until-loop NON-CONVERGENCE/freeze the counter was introduced to prevent,
  not a dpr2 flake.)

## What REMAINS — and why the high-value phase is COMPLETE (reassessed 2026-06-21)

**The high-value deferred-layout work is done.** Every synchronous re-fit triggered by an immediate mutator, a
drag/drop gesture, a menu (twin-mediated + the `newParentChoice*` leftover), collapse, or content-edit now defers
(commits `1caea690`, `1e5d3745`, + the 2026-06-21 `newParentChoice*` arc). A read-only mapping Workflow + adversarial
verification (2026-06-21) then assessed everything that was "next" on the old order and found it should NOT be ground
through:

- **Families 1 (scroll-input), 6 (Slider), 7 (LabelButton): LEAVE SYNCHRONOUS** (verdicts above). Family 1 is the
  highest-determinism-risk residual for zero correctness gain (timer/momentum/scroll-thumb-flake path) and is the
  wrong problem class (self-container, not child→container). Family 6 has no pattern surface (empty-base `reLayout`).
  Family 7 is already compliant in substance. None blocks the capstone.
- **`BoxWdgt.choiceOfWidgetToBePicked`: dead code** — leave it.
- **Soft-wrap `reLayout` (family 5 remainder): its own dedicated hard arc** — `softwrap-deferred-layout-conversion-plan.md`.
- **The capstone — family 8 (`rawSetExtent→reLayout` structural root) + retire `_reFittingContents` + tighten lint [E]:
  genuinely LAST, and BLOCKED** (see the lint clarification above). It is not a separable cheap first half: the
  un-deferrable `childUnCollapsed` re-fit + the pre-flush `WindowWdgt.add` re-fit + the return-value contract keep the
  counter's synchronous arm load-bearing, and a naive removal already broke 7 tests (the C2 wall). It carries the
  high-severity until-loop non-convergence/freeze risk and must be scoped as ONE large determinism-sensitive arc (per
  root: dpr1 byte-exact + dpr2-under-load + WebKit soak), NOT pursued opportunistically.

**Bottom line:** the campaign has banked its correctness payoff. What's left is (a) deliberately-left-synchronous
borderline-compliant handlers (1/6/7 — do not "fix"), (b) the soft-wrap hard arc, and (c) the last + hardest +
highest-risk lint-enforcement capstone. Absent a specific reason to pursue (c) or (b), this campaign is at a natural
**stop-and-report** point.
