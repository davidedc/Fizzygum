# Deferred-layout residuals audit — every synchronous relayout still at a non-settle point

> Read-only audit, 2026-06-21 (3 parallel sweeps over `src/**/*.coffee`). The companion of
> `deferred-layout-c2-execution-plan.md` (the seam/twin re-queue) and `deferred-layout-OVERVIEW.md`.
> This is the map of what remains to reach the all-deferred aim. Nothing here is fixed yet.

## The aim + the two legal settle points (confirmed in code)

Every relayout must run at exactly one of:
- **(a) a public-method FLUSH** — `Widget.mutateGeometryThenSettle` records intent + runs `recalculateLayouts`
  (Widget.coffee:783); batch variant `settleLayoutsOnceAfter` (:808). The 7 self-settling public methods:
  `setBounds`, `setExtent`, `setWidth`, `setHeight`, `fullMoveTo`, `add`, `addRaw`. Batch caller:
  `WindowWdgt.buildAndConnectChildren` (settleLayoutsOnceAfter).
- **(b) the CYCLE** — `WorldWdgt.doOneCycle → recalculateLayouts` until-loop (WorldWdgt.coffee:885-947), draining
  `widgetsThatMaybeChangedLayout` via `doLayout` until convergence.

Low-level `raw*`/`silent*`/`fullRaw*` mutators must only MUTATE, never schedule layout (`invalidateLayout` THROWS
mid-pass, Widget.coffee:3751) — but they MAY APPLY layout synchronously during a pass (the sanctioned in-pass apply).

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

## Residual families — the remaining campaign (~40 synchronous relayouts at non-flush points)

Ordered roughly by how self-contained the conversion is. Each family is a SEPARATE determinism-sensitive arc (own
soak). The codebase comments self-identify most of these as "the intermediate residual the deferred-model
conversion will remove."

1. **Scroll-input handlers (ScrollPanelWdgt)** — synchronous `_adjustContentsBounds`/`_adjustScrollBars` straight
   from input handlers: `wheel` (:720/721), `mouseDownLeft` momentum (:571/572), `autoScroll` (:619/620),
   `scrollCaretIntoView` (:630/650/651), `scrollTo`/`scrollToBottom` (:415/420), `adjustContentsBasedOnHBar/VBar`
   (:84/85/89/90). ~13 sites. (These respond to direct manipulation; the re-fit result is byte-exact — converting
   them is more about uniformity than correctness.)

2. **Drag/drop re-fit cascades** — synchronous `_reFitToContents` from `reactToDropOf`/`reactToGrabOf`/`childRemoved`
   on ScrollPanelWdgt (:235/236/239), SimpleVerticalStackPanelWdgt (:86/90), PanelWdgt (:83/88/115/145), dispatched
   from `ActivePointerWdgt.grab` (:217) / `drop` (:257) and `Widget.destroy` (:549). The "sanctioned C1 public-op
   cascade" (kept synchronous deliberately; `_reFittingContents`>0 keeps it convergent). ~10 sites.

3. **Menu actions** — `VerticalStackLayoutSpec.setAlignmentToLeft/Right/Center`/`setElasticity`/
   `setWidthOfElementWhenAdded` (:58/63/68/91/114), `BoxWdgt.choiceOfWidgetToBePicked` (:21/22),
   `Widget.newParentChoice`/`newParentChoiceWithHorizLayout` (:3391/3403) → synchronous re-fit via the twin /
   `_refitContentsAndScrollBars`. ~7 sites.

4. **Collapse / uncollapse** — `WindowWdgt.childCollapsed`/`childUnCollapsed` (:253/254/263/266) via
   `Widget.collapse`/`unCollapse` (button handlers). Synchronous `_reFitToContents` + the twin.

5. **Content-edit / soft-wrap** — `TextWdgt.reLayoutAndRefreshContainerIfContainedText` (:445/446) fanned out from
   `setText`/`setFontSize`/`setFontName`/`toggle*` (menu/button), and `SimplePlainTextWdgt.setSoftWrap` (:133/134,
   a click handler that self-documents bypassing the deferred model). Synchronous `reLayout` + the twin.

6. **Slider family** — `SliderWdgt.setValue` (:117/119, **mid-drag** via `SliderButtonWdgt.nonFloatDragging`),
   `updateHandlePosition` (:106/107), `setStart`/`setStop`/`setSize`/`updateSpecs` (config setters), `rawSetExtent`
   (:74). ~13 synchronous `reLayout` sites.

7. **LabelButton** — `alignCenter`/`alignLeft`/`setLabel` (:104/110/115) → synchronous `reLayout` from menu/button.

8. **THE STRUCTURAL ROOT — `rawSetExtent` runs `reLayout`.** Base `Widget.rawSetExtent` (:1532-1537) =
   `silentRawSetExtent` + `changed` + **`@reLayout()`**, unconditionally (no pass guard; base `reLayout` is empty, so
   it bites only where `reLayout`/an override runs layout). This is INTENDED as the in-pass synchronous-APPLY
   mechanism (`rawSetWidthSizeHeightAccordingly` relies on it, Widget.coffee:706-712), but it makes `rawSetExtent`'s
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
- **lint [E] tightening is the END of the campaign** — it can forbid synchronous `_reFitToContents`/
  `childGeometryChanged`/`reLayout` from immediate mutators only once the seam's `_reFittingContents` branch, the
  twin's outside-pass branch, AND families 1-8 are converted.

## Suggested order (each its own arc + soak)

Cheapest/most-self-contained first: **3 (menu) → 4 (collapse) → 5 (content-edit/soft-wrap)** (these route through the
already-deferred twin pattern — convert the caller to record-intent + flush, or invalidate-the-container);
then **2 (drag/drop cascade)** (the C1 public-op cascade → defer); then **1 (scroll-input)** (uniformity);
then **6/7 (Slider/LabelButton)**; finally **8 (the `rawSetExtent`→`reLayout` root)** + **lint [E]**.
The transport pass (OVERVIEW §4) overlaps family 2 + the `fullMoveWithin` adoption.
