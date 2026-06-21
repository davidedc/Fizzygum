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

## Residual families — the remaining campaign (~40 synchronous relayouts at non-flush points)

Ordered roughly by how self-contained the conversion is. Each family is a SEPARATE determinism-sensitive arc (own
soak). The codebase comments self-identify most of these as "the intermediate residual the deferred-model
conversion will remove."

1. **Scroll-input handlers (ScrollPanelWdgt)** — synchronous `_adjustContentsBounds`/`_adjustScrollBars` straight
   from input handlers: `wheel` (~:666), `mouseDownLeft` momentum (~:469), `autoScroll` (~:614),
   `scrollCaretIntoView` (~:636), `scrollTo`/`scrollToBottom` (~:424/430), `adjustContentsBasedOnHBar/VBar`
   (~:82/87). ~13 sites. (These respond to direct manipulation; the re-fit result is byte-exact — converting
   them is more about uniformity than correctness.)

2. **Drag/drop re-fit cascades — DONE (DEFERRED 2026-06-21, `1e5d3745`; see "Already compliant" above).** The gesture
   seams `reactToDropOf`/`reactToGrabOf` (ScrollPanelWdgt/PanelWdgt/SimpleVerticalStackPanelWdgt) + the stack's
   `childRemoved` now defer (2-way: pass/cascade → synchronous; else → invalidate the container). What REMAINS here is
   left synchronous BY DESIGN: the cascade SINK `childGeometryChanged`, `reLayOutAfterContainedPanelChange` /
   `_refitContentsAndScrollBars` (the absorb return-value contract), and `PanelWdgt.childRemoved` +
   `addInPseudoRandomPosition` (a later verify-and-drop slice).

3. **Menu actions** (the twin-mediated part is **DONE — deferred `1caea690`**). `VerticalStackLayoutSpec.setAlignmentToLeft/Right/Center`/`setElasticity`/`setWidthOfElementWhenAdded`
   re-fit via the twin → done. **REMAINING (not twin-mediated):** `BoxWdgt.choiceOfWidgetToBePicked` and
   `Widget.newParentChoice`/`newParentChoiceWithHorizLayout` — direct synchronous `_adjustContentsBounds`/`_refitContentsAndScrollBars` from a menu action.

4. **Collapse / uncollapse** (the twin-mediated part is **DONE — `1caea690`**). `WindowWdgt.childCollapsed`/`childUnCollapsed`
   via `Widget.collapse`/`unCollapse`. **REMAINING:** the `reInflating`-coupled direct `@_reFitToContents()` (must stay
   synchronous — `contentsRecursivelyCanSetHeightFreely` reads `@reInflating` while it runs; deferring would break it).

5. **Content-edit / soft-wrap** (the twin-mediated part is **DONE — `1caea690`**). `TextWdgt.reLayoutAndRefreshContainerIfContainedText`
   (from `setText`/`setFontSize`/`toggle*`) and `SimplePlainTextWdgt.setSoftWrap` (a click handler that self-documents
   bypassing the deferred model). **REMAINING:** the widget's own `@reLayout()` re-wrap — soft-wrap is the dedicated
   hard arc (`softwrap-deferred-layout-conversion-plan.md`).

6. **Slider family** — `SliderWdgt.setValue` (:117/119, **mid-drag** via `SliderButtonWdgt.nonFloatDragging`),
   `updateHandlePosition` (:106/107), `setStart`/`setStop`/`setSize`/`updateSpecs` (config setters), `rawSetExtent`
   (:74). ~13 synchronous `reLayout` sites.

7. **LabelButton** — `alignCenter`/`alignLeft`/`setLabel` (:104/110/115) → synchronous `reLayout` from menu/button.

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
- **lint [E] tightening is the END of the campaign** — it can forbid synchronous `_reFitToContents`/
  `childGeometryChanged`/`reLayout` from immediate mutators only once the seam's `_reFittingContents` branch, the
  twin's outside-pass branch, AND families 1-8 are converted.

## Suggested order for what REMAINS (each its own arc + soak)

DONE so far: the twin/seam/gesture-mediated re-fits of families 2–5 (commits `1caea690` + `1e5d3745`). Remaining,
cheapest/most-self-contained first:
**family 1 (scroll-input)** → **6/7 (Slider/LabelButton)** → the small leftover bits of 3/4/5 (BoxWdgt/`newParentChoice`,
the soft-wrap `reLayout`) → **8 (the `rawSetExtent`→`reLayout` structural root)** → finally **retire the now-mostly-
redundant `_reFittingContents` machinery + tighten lint [E]** (only possible once the seams' `_reFittingContents`
branches + the above are converted). The soft-wrap `reLayout` is its own hard arc.
