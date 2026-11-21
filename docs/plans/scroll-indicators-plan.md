# Scroll indicators — one placement rule, the document's margin, and the spreadsheet's own

**PLAN ONLY. Written to be executed COLD by an LLM/engineer with ZERO prior context.**
AUTHORED 2026-11-19 against Fizzygum master `99d1540e` and Fizzygum-tests master `1cfecb761` (430 SystemTests, build
FRESH, last gauntlet 20/20). Executed by a loop whose process (the per-unit cycle, the grants, the park and stop rules,
the LEDGER) is `Fizzygum-tests/.scratch/scroll-indicators-loop/BRIEF.md`. This document is the WHAT: each unit's
facts, ruled design, tests, predicted pixel set and proof.

**Mandate: one rule for where a scroll indicator stands, with no special case.** Today one rule gives three looks
because the edge it measures from is in three places. This plan moves the edge (a document keeps its margin itself),
states the rule once (clear of the line at the edge, short of the side's ends), and gives the one scroller that shows
no indicator (the spreadsheet) the same presentation from the same code. Nothing is hidden or patched per window.

Status:

| Unit | Item | Status |
|---|---|---|
| U1 | A thin indicator stands clear of the line at its viewport's edge, and short of its side's ends | CLOSED 2026-11-20 (§U1) |
| U1b | A pane picked up off its window leaves at its own size: the window's hook runs inside the pick-up's settle (`Widget.pickUp`; added by the owner 2026-11-20) | CLOSED 2026-11-20 (§U1b) |
| U2 | A viewport's padding is a margin: its plane shows inside it (mechanism, dormant; the field is `planeMargin`) | CLOSED 2026-11-20 (§U2) |
| U2b | A window whose content leaves it keeps its size and shows its default content, by any door (added by the owner 2026-11-20) | CLOSED 2026-11-20 (§U2b) |
| U3 | The document keeps its margin itself; a viewport paints its plane's selection ring | CLOSED 2026-11-21 (§U3) |
| U4 | The indicator presentation gets a home both scrollers extend (a lift, pixel-neutral) | CLOSED 2026-11-21 (§U4) |
| U4b | A tilted window content's window keeps its size at its next arrange (added by the owner 2026-11-21) | CLOSED 2026-11-21 (§U4b) |
| U4c | "Pick up" on a tilted Maker's payload resets the Maker inside a settle (added by the owner 2026-11-21) | CLOSED 2026-11-21 (§U4c) |
| U4d | A window shows its content only inside its body (added by the owner 2026-11-21) | CLOSED 2026-11-21 (§U4d) |
| U4e | A stretchable panel's arrange places a child whose spec owns its placement, and a caught error's report no longer depends on load (added and widened by the owner 2026-11-21) | CLOSED 2026-11-21 (§U4e) |
| U5 | The spreadsheet's scroll is two pins | open (§U5) |
| U6 | The spreadsheet presents its scroll indicators | open (§U6) |
| U7 | Close: this plan archived, or left open with what parked | open (§U7) |

---

## 0. Orientation

**Fizzygum** is a CoffeeScript GUI framework rendered on one `<canvas>`: windows, a desktop, drag and drop, live
editing tools. Three sibling repos under a directory named `Fizzygum-all`: `Fizzygum/` (source + build),
`Fizzygum-tests/` (the macro SystemTest suite and its Node rigs), `Fizzygum-builds/` (generated). Read
`Fizzygum/CLAUDE.md` and `Fizzygum-tests/CLAUDE.md` first; both route to deeper docs. For this plan also read
`docs/architecture/viewports-and-planes.md` (whole) and `docs/architecture/visual-design-system.md` §4.10.

**The prior arcs this plan stands on.**
- *Scroll indicators* (frames·input·touch program, ruling G4): a viewport's two `SliderWdgt` bars are overlay
  indicators, THIN and untouchable while content overflows, FAT while the pointer is in the scroll band. Living
  truth: `viewports-and-planes.md` "Scroll indicators".
- *The window page gutter* (`docs/archive/window-page-gutter-plan.md`, CLOSED 2026-10-23): a window keeps one 8 px
  gutter around a PAGE; a PANE runs flush. Its problem statement and decisions bind this plan (§1 quotes them).
- *The spreadsheet's scroll* (F1, `src/spreadsheet/CLAUDE.md` "F1 decisions"): the sheet owns its view origin and
  is deliberately NOT a `ViewportWdgt`; its class header says "scrollbar/indicator chrome stays banked".

**What the owner saw (2026-11-19).** The indicators are not placed uniformly: a folder's lie close to the window's
edge and look natural (they asked to see them closer still); a document's lie far from the window's edge and, in edit
mode, over the vertical edges of the content; the spreadsheet shows none although it scrolls.

**Research and prototypes (2026-11-19).** Everything below was rendered on the real build by runtime patches, no
source change, and each candidate was run through the suite as a plant to count what it touches. On this machine,
gitignored:
- `Fizzygum-tests/.scratch/scrollbar-placement/review.html` — the review page the owner ruled from (section M is the
  ruled document design; A the placements; C the spreadsheet mock). `probe.js` beside it renders every variant;
  `make-page.js` assembles the page.
- `Fizzygum-tests/.scratch/scroll-indicators-loop/research/plants/*.js` — the forecast plants (`--prelude=` files).
- `Fizzygum-tests/.scratch/scroll-indicators-loop/research/forecast/*.tests.txt` and `*.shots.txt` — the failing
  tests and shots each plant produced on the dpr 1 mouse suite (every failure a screenshot mismatch, none an
  exception).

> **THE CRITICAL REFRAMES (what research found).**
> - **One rule, three looks.** A thin indicator lies `scrollIndicatorEdgeInset` (2) inside the edge of its
>   VIEWPORT. A pane's viewport reaches the window's lines (thumb 3 px from the window's outer edge, measured); a
>   document's viewport stands 8 px further in behind the window's page gutter (11 px), and its items fill it edge
>   to edge, so the thumb lies on their right edge. The bar is not "part of the content": it is the viewport's
>   child, clipped at the viewport's bounds, so it cannot be drawn out in the gutter.
> - **The document's bar hugs an edge nobody can see.** Window body, gutter and page are all `paper`. Where a
>   viewport's edge is a visible line (a folder, an inspector pane) the same placement reads as natural.
> - **"Make the document flush" alone breaks two 2026-10-22 rulings.** A flush document with a gap kept under the
>   toolbar puts the first paragraph 16 px below the toolbar (the gap plus the document's own 8): the double top
>   spacing the owner rejected (gutter plan §7). Its selection ring lies against the window's border: the look that
>   arc was opened to remove (its §0 problem statement). The owner approved that variant from pictures whose
>   description by the planning session was wrong on the first point; §1 P1 records the correction.
> - **`ViewportWdgt.padding` is a margin nobody uses.** Declared `padding: 0 # around the scrollable area`, read in
>   six places (the caret follow already treats it as the visible window's inset), written by nobody. Making it mean
>   what it says is the whole of the document fix: the plane shows inside it, and the bars and the plane's ring stand
>   in it. A document window then differs from today's ONLY where the bar is (measured, §U3).
> - **A bar pulls its numbers.** `ViewportWdgt._reLayoutScrollbars` writes no start, stop, size or value into a bar.
>   The bar reads them itself (`SliderWdgt.reflectTarget`: the target's pin for its action, that pin's getter, and
>   `sliderRangeForPin`). So the spreadsheet needs two pins and one range answer, not a second bar-driving path.
> - **The sheet's restore sweep destroys every direct child that is not a cell or the formula bar**
>   (`_reindexCellsNoSettle`), and a `new SliderWdgt` opens a settle in its constructor. Bars must be ADOPTED the way
>   the formula bar is, not rebuilt there.

## 0.5 Cold-execution protocol

1. The loop's process is `Fizzygum-tests/.scratch/scroll-indicators-loop/BRIEF.md`. Read it whole before the units.
2. `/Users/davidedellacasa/code/Fizzygum-all/fg status` (by absolute path, never `./fg`): both repos clean and level
   with origin, build FRESH.
3. Units run in the table's order; §U-order says why. A PARKED unit does not stop the loop; a unit that needs a
   parked one follows its own "If parked" line.
4. Per unit: read its section here, then the code. **Line numbers below are approximate: the method name and the
   quoted code are the authority; re-grep every symbol before editing.** Where a unit rules differently from the
   code as found, re-measure, then correct this plan in place.
5. Commands: `fg build`, `fg presuite`, the finger suite (`node scripts/run-all-headless.js --pointer=finger` from
   `Fizzygum-tests/`), `fg diffpage`, `fg recapture --auto --dprs=1,2` (then `--pointer=finger`), `fg gauntlet`.
   Long ops run ONCE in the background with a log, never piped through a filter.
6. Every unit that changes pixels compares its diff page against the review page's pictures (§0): the ruled look is
   what the owner saw there. A changed shot that is not the unit's own target is a FINDING, never a recapture.

## 1. Rulings

**The owner's (2026-11-19, this plan's conversation).**
- **O1 — placement.** A thin indicator stands closer to the edge than today: one pixel of paper between it and the
  line at its viewport's edge, and it stops 3 px short of both ends of its side (review page §A, "inset 1, ends 3").
- **O2 — documents.** In a document's window the bar stands by the window's edge, in edit and in view mode, and not
  over the items' edges.
- **O3 — the toolbar gap.** Scrolled content must not be cut at the toolbar's edge: the spacing between the toolbar
  and the content stays ("I don't like the cut at the toolbar edge").
- **O4 — the ring.** The selection ring of a viewport's plane is painted by the viewport, so it frames what shows
  (asked for as a prototype, then accepted).
- **O5 — the spreadsheet** gets scroll indicators, as its own arc after the above.
- **O6 — architecture first.** Each of these only "in a way that doesn't compromise overall code and architecture
  integrity / quality / cleanliness".

**The 2026-10-22 rulings that still bind** (`docs/archive/window-page-gutter-plan.md` §2, quoted):
- D2: the document's "paragraphs stay exactly where they are today: as wide as the toolbar, 8 below it. (Rejected:
  the document keeping its own 8 inside the gutter — paragraphs at 16, narrower than the toolbar, a double top
  spacing; the owner disliked both.)"
- D3: "A page's selection ring lies OUTSIDE the page, in the gutter, at offset 2: 2 px of air, then the 2 px ring,
  4 px left before the window border."
- Its problem statement: "the 2 px accent selection ring and the menu-hover wash reveal the document's box hugging
  the window border and the toolbar."
- D7: a drop in the gutter goes to the page; a press-drag there still moves the window.
- D10: a caret brought into view keeps `documentItemSpacing` of context.
D10's last sentence ("its overlay scroll indicator over the items' right edge is ACCEPTED") is what O2 withdraws.

**The planning session's (for the owner's second look).**
- **P1 — THE MARGIN DESIGN, in place of "flush with a gap under the toolbar".** The owner approved, from pictures,
  a variant where the document runs flush and a docked band keeps 8 px toward the payload. Fact-checking it against
  the archive found the two conflicts in the reframes above, and that the planning session had described its top
  spacing wrongly ("exactly today's"; it is 16 px at rest). The margin design satisfies O2, O3 and O4 AND D2, D3,
  D7, D10: the document reaches the window's lines and keeps its 8 px as its viewport's `padding`, a fixed margin
  its plane shows inside; the bar and the plane's ring stand in that margin. Rendered and measured (§U3): a document
  window in every state differs from today only where the bar is. The band rule and the flush variant are §7's
  first two entries, with their evidence. **The loop prompt the owner pastes confirms P1 or names the other.**
- **P2 — the placement rule is derived, not a dial per case.** "Clear of the line at my edge" is the theme's
  clearance (1) plus the width of the border the viewport itself paints over its edge (1 or 0). A window's pane
  paints none, so it gets 1 (O1); a bordered panel on the desk keeps today's 2, its thumb already one pixel clear of
  its border.
- **P3 — the thumb is not moved when a ring appears.** With the ring in the margin the thumb and the ring overlap
  by one pixel column while the page is selected. Moving the thumb then would make a paint-time selection feed
  layout.
- **P4 — the two scrollers share the presentation through a base class**, `ScrollIndicatorHostWdgt extends
  ClippingWdgt`, which `ViewportWdgt` and `SimpleSpreadsheetWdgt` extend (they are siblings under `ClippingWdgt`
  today). `widget-authoring-guidelines.md` §16: "behaviour shared by classes on unrelated branches → a base class
  they all extend". A collaborator object would put a new object in every viewport's saved graph and move the
  `vBar`/`hBar` fields tests and rigs read.
- **P5 — the sheet's bars are ADOPTED on restore and copy**, as its formula bar is, for the formula bar's reason.
- **P6 — the sheet's pin labels** are `"scroll column"` and `"scroll row"` (a viewport's are `"scroll x"`,
  `"scroll y"`); they show in connection menus.

## 2. Current state (verified 2026-11-19; re-grep before trusting a line)

### 2.1 The indicators (`src/basic-widgets/ViewportWdgt.coffee`, `SliderWdgt.coffee`, `SliderButtonWdgt.coffee`)
- Theme dials (`src/Theme.coffee`): `scrollBarsThickness = 12` (~:804, the FAT width),
  `scrollIndicatorThickness = 4` (~:977), `scrollIndicatorEdgeInset = 2` (~:982, one reader:
  `ViewportWdgt._indicatorEdgeInset`).
- `_indicatorThickness` (~:551) and `_indicatorEdgeInset` (~:563): fat = `@scrollBarsThickness` and 0; thin = the
  two theme dials.
- `_barFrameAt: (bar, thickness, edgeInset = 0)` (~:648): the vertical bar is `(right − inset − thickness, top)` to
  `(right − inset, bottom − reserve)`; the horizontal one `(left, bottom − inset − thickness)` to
  `(right − reserve, bottom − inset)`. Four callers: the arrange, twice (`_reLayoutScrollbars`, with the thin or fat
  thickness and inset), and `buttonScreenBoxOnArrival` / `barScreenFrameOnArrival` (~:709, ~:718; always the fat
  thickness, flush: where a press finds the bar).
- `_cornerReserveFor` (~:662): `max(scrollBarsThickness, resizer.cornerFootprint())` under a resizer, else
  `scrollBarsThickness` if the other bar crosses, else 0; when positive, `+ 2 * @padding`.
- `_barFrameHasRoomForThumb` (~:728): `length >= @scrollBarsThickness - bar.trackThumbInset`, asked of the frame the
  arrange is about to apply.
- `_reLayoutScrollbars` (~:732-835): per bar, guarded by `bar.isWiredTo? @`: frame from `_barFrameAt`; show, size
  and place through the non-notifying twins, `_reLayoutSelfAndButton`; else `hide()`. Then
  `_refreshScrollIndicators` (thin/fat), then `world.dataflow.markNonValueChange @` (THE announcement every scroll
  path ends at). Complexity 26, RECORDED (`buildSystem/check-complexity-ratchets.js` ~L144).
- The hover pass (~:594-608): `hoverMoved` / `hoverExited` → `_updatePointerInScrollBand`: in the band iff inside
  my bounds and within `scrollBarsThickness` of my right or bottom edge; a flip calls `_reLayoutScrollbars`.
- A bar asks its PARENT two things through `?()`: `isMyScrollBar` (`SliderWdgt.excludedFromEditorFocusTracking`,
  and `_reactToBeingAdded`, which drops the indicator look on any parent that does not answer true) and
  `sliderTrackPressJumpsButton` (`SliderWdgt.pressBegan`). `MacroToolkit` asks `slider.parent` for
  `buttonScreenBoxOnArrival` and `barScreenFrameOnArrival` UNGUARDED (~:1494, ~:2232).
- **A bar pulls.** `ControllerWdgt.trackTarget: (theTarget, action)` (~:67) adds a wire, a forward edge and a
  reverse edge `target → bar, action: "reflectTarget", firesOnAnyChange: true`, then `reflectTarget()`.
  `SliderWdgt.reflectTarget` (~:302): `pin = wire.target.pinDrivenBy? wire.action`; needs `pin.getterName`; `range =
  wire.target.sliderRangeForPin? pin` (a `SliderRange start, stop, size`, or undefined); then `_updateSpecs
  range.start, range.stop, target[getter](), range.size`. The reverse edge fires when the target calls
  `world.dataflow.markNonValueChange @`, in the same cycle (drain-until-quiet).
- A thumb drag yields INTEGER values (`SliderWdgt.updateValue`: `Math.round relPos / @unitSize() + @start`), and the
  thumb is re-laid from the value the target answers back.
- The viewport's pins (~:469): `"scroll x"` / `"scroll y"`, `set: "setScrollX"`, `get: "getScrollX"`, `announces:
  true`; `sliderRangeForPin` (~:477) → `_scrollRangeAlong viewport, content` = `new SliderRange 0, content −
  viewport, viewport / content * stop` (undefined under `'never'` or with nothing to scroll).

### 2.2 The border a viewport paints over its edge
- `RectangularAppearance._borderColor` (~:132): `@widget.strokeColor ? @widget._surfaceStroke?()`; `_paintBorder`
  strokes 1 px inside the box when it is not undefined. `ClippingWdgt.fullPaintIntoAreaOrBlitFromBackBuffer` calls
  `paintStroke` AFTER the children, then the selection overlay.
- `ViewportWdgt._surfaceStroke` (~:211): a builder's role (`wearPaneRoles`), else `windowContentPanelStroke` as a
  window's whole content, else `panelStroke`. In `Theme`: `panelStroke = @line`; `windowContentPanelStroke`,
  `inspectorPaneStroke`, `codePaneStroke`, `folderViewportStroke` are all `undefined`. `DocumentViewportWdgt
  ._surfaceStroke` answers `undefined`. So a window's panes and a document paint no border; a plain panel on the
  desk, a stack sample and a patch node's text box do.
- `outlineIsStroked` exists on `BoxyAppearance` (~:264) and `MagnetAppearance` (~:53) and is read by
  `Widget._drawSelectionOverlay` (~:587, the ring's stroke half). `RectangularAppearance` does not answer it.

### 2.3 The window's gutter and the document
- `FrameWdgt._bodyMargin` (~:404): `theme.windowPageGutter` (8) while `_hostsAPage()`, else the frame body margin
  (0). `_hostsAPage` (~:412): `!!@contents?.wantsWindowPageGutter?()`. Four classes answer true:
  `DocumentViewportWdgt`, `StretchableWidgetContainerWdgt`, `FridgeMagnetsWdgt`, `SimpleSpreadsheetWdgt`.
- `FrameWdgt.pageGutterAround` (~:422) has two callers: `DocumentViewportWdgt._itemInset` and
  `StretchableWidgetContainerWdgt.standsInWindowPageGutter` (~:106). It stays.
- `DocumentViewportWdgt` (`src/authoring/`, whole file ~200 lines): `wantsWindowPageGutter` (~:22);
  `receiverOfDropsAroundMe` (~:29, its stack; asked only by `FrameWdgt.dropReceiverForPointsOnMyBody`, which asks it
  only of a page); `_takeItemSpacing` (~:87, at the top of every arrange: `@extraPadding = inset;
  @contents?.padding = inset`); `_itemInset` (~:96: `max 0, documentItemSpacing − parent.pageGutterAround`, so 0 in
  a window and 8 bare); `_reactToBeingAdded` (~:107, re-takes the inset when a re-parenting changes it);
  `setContents` (~:113: `super aWdgt, @_itemInset()`); `interElementGapOfPlane` (~:120); `_caretScrollMargin`
  (~:131: `@padding + documentItemSpacing`). `Theme.documentItemSpacing = 8`.
- The gutter's drops (`src/ActivePointerWdgt.coffee` ~:382-420): `_dropClimbStart` is
  `top.dropReceiverForPointsOnMyBody?() ? top` for the top widget under the pointer; `_targetReachedThroughAGutter`
  and `_moveGutterDropInsideTarget` move such a payload inside its receiver. `FrameWdgt` answers it for a page (~:439)
  and `StretchableWidgetContainerWdgt` for its own letterbox margin (~:94): the protocol is not the frame's alone.
- **`ViewportWdgt.padding`** (~:29, `0 # around the scrollable area`) is read at: `_cornerReserveFor` (~:668),
  `setContents` (~:902, `@position().add @padding + @extraPadding`), `_positionAndResizeChildren` (~:992, `padding =
  Math.floor @extraPadding + @padding`), `scrollCaretIntoView` (~:1541-1544, the visible window's "padded interior"),
  `_caretScrollMargin` (~:1571, `@padding + (@extraPadding ? 0)`), and `TextAreaWdgt` (~:80). No class, test or rig
  assigns it (grepped `src/`, the harness and every macro).

### 2.4 How a viewport clips
- Paint: `ViewportWdgt._fullPaintIntoAreaOrBlitFromBackBufferContentPotentiallyAsShadow` (~:385) and its shadow
  twin `…JustShadow` (~:410): at zero scroll translation both `return super` (`ClippingWdgt`'s body: every child
  painted inside `@boundingBox().intersect clippingRectangle`); else a hand-copied body that paints the contents
  child through the translation with `translatedCull = damagedPartOfFrame.translateBy t.neg()` and every other
  child in place. A widget paints only inside the rectangle it is handed.
- Everything else: `Widget.clipThrough` (~:1640-1676) and its uncached twin `SLOWclipThrough` (~:1472-1488), kept
  in lockstep and compared by the cache oracle (`world.doubleCheckCachedMethodsResults`). Both take the first
  clipping ancestor's `clipThrough()` and, when that ancestor answers `scrollTranslationOfChild?`, climb to the
  ancestor's DIRECT child on my chain (`edgeChild`) and translate the clip by that child's translation. Pointer
  targeting (`Widget.isPointerTargetAt`, ~:495: `@clippedThroughBounds().containsPoint aPoint`), damage and
  visible-box queries all read `clippedThroughBounds`, which is `@boundingBox().intersect @clipThrough()`.

### 2.5 The selection ring
- `WorldWdgt._updateEditorSelectionOverlay` (~:2071-2109), once per cycle before paint: `host =
  @_editorSelectionRingHostOf target`; `ringBox = host?.pageSelectionRingBox()`; on a change it tells the old and new
  host `notePageSelectionRingChanged()`. `_editorSelectionRingHostOf` (~:2115) climbs to the NEAREST ancestor that
  defines `hostsSelectionRingOf` and asks it; only `FrameWdgt` defines it today.
- `FrameWdgt.hostsSelectionRingOf` (~:2280): a page, a body margin at least the ring's reach
  (`_pageSelectionRingReach` = `theme.pageSelectionOutlineOffset` 2 + `selectionOutlineWidth` 2), and `aWdgt` filling
  the page's visible box. `pageSelectionRingBox` (~:2316): `@contents.clippedThroughBounds().expandBy reach`.
  `_paintPageSelectionRing` (~:2350), from `paintIntoAreaOrBlitFromBackBuffer`: over the window's fill, under its
  children.
- `Widget._paintEditorSelectionOverlayIfSelected` (~:3190): `return if world?.editorSelectionRingHost()? and
  world.isEditorSelected @` (a hosted widget draws no ring), else `_drawSelectionOverlay` inside its own box.
  `ClippingWdgt` calls it last, after its border.
- **An existing blemish, measured:** a selected plane taller than its viewport draws its ring inside its own box,
  which scrolls: a bare document scrolled shows the ring's two sides only, a plain panel window with overflow shows
  no bottom side (review page §B+ and §M).

### 2.6 The spreadsheet (`src/spreadsheet/SimpleSpreadsheetWdgt.coffee`, ~1360 lines; `class … extends ClippingWdgt`)
- It defines none of `pins`, `hoverMoved`, `hoverExited`, `isMyScrollBar`, `sliderTrackPressJumpsButton`.
- View origin: `viewOriginCol: 0`, `viewOriginRow: 0` (~:135; prototype defaults, document state). One mover,
  `_scrollByNoSettle: (colDelta, rowDelta)` (~:509: clamp to `sheetCols − _viewportColsFull()` and the row twin,
  then `_buildChromeNoSettle`, `_reconcileViewportNoSettle`, `_changed`), with two callers:
  `_scrollToShowSelectionNoSettle` (~:526) and `scrolledBy` (~:637, the wheel; it commits an open edit first, inside
  one `_settleLayoutsAfter`). The RANGE also changes on a resize (`_reLayout`, ~:495) and a zoom
  (`_setZoomFactorNoSettle`, which already calls `world.dataflow.markNonValueChange @`, ~:1097).
- Geometry: `_gridTop` (the formula bar's 44), `_headerW`, `_headerH`, `_colW`, `_rowH` (the sizes times the zoom),
  `_viewportColsFull` / `_viewportRowsFull` (whole columns and rows that fit), `sheetCols: 26`, `sheetRows: 100`.
  The data region is the cells panel's box: origin `(left + _headerW(), top + _gridTop() + _headerH())`, extent the
  rest (`_buildChromeNoSettle`, ~:357).
- `_buildChromeNoSettle` (~:341, complexity 13 of 15): builds what is missing, in this order on a fresh sheet: the
  cells panel, the formula bar, then header cells; every piece placed absolutely from `@position()` each pass. No
  explicit z-order: paint follows `@children`, and header cells built later are appended.
- Restore and copy: `_afterDeserialization` and `_reactToBeingCopied` → `_recommitAllCells` →
  `_reindexCellsNoSettle` (~:1298): rescues the cells, then `child._fullDestroyNoSettle() unless child instanceof
  CellWdgt or child is @_formulaBar`, then rebuilds chrome. The formula bar is adopted because its handle is not a
  transient, the sweep exempts it, and `_buildChromeNoSettle` builds it only `unless @_formulaBar?` (reason at
  ~:155: building its zoom button would open a settle inside those notifications).
- `SheetAppearance.paintStroke` fills a 1 px page edge on all four sides, after the children.
- `activated` (~:612) selects the cell under the click; a click on a slider's track escalates `activated` to its
  parent (`SliderWdgt` defines none), except a press that jump-drags the button.
- The serialization rig counts the sheet's direct children: `chromeCount = 1 + 1 + 1 + vCols + vRows` in
  `spreadsheet.roundtrip.grid` and `spreadsheet.roundtrip.midEditClean`
  (`Fizzygum-tests/scripts/serialization-roundtrip-headless.js` ~:636-640, ~:702-705).
- The pin sweep (`Fizzygum-tests/scripts/pin-sweep-headless.js`): a declaring pin with `announces` needs an entry in
  `FIXTURES` keyed `'<Class>.<pin label>'` returning `{ w, v }`; the sweep calls the setter with `v` and requires a
  `markStale` or `markNonValueChange` on `w` itself, synchronously (~:269-310).

### 2.7 Gate constraints that shape the edits
- **Method-count ceilings with zero headroom** (`check-complexity-ratchets.js` `METHOD_CEILINGS`): `Widget`
  394/394, `WorldWdgt` 129/129, `FrameWdgt` 173/173, `ActivePointerWdgt` 74/74. This plan ADDS NO METHOD to any of
  them (it edits bodies, renames, and deletes). `ViewportWdgt` (104), `SimpleSpreadsheetWdgt` (83),
  `DocumentViewportWdgt` (26) and `ClippingWdgt` (9) have no ceiling.
- **Complexity**: 15, except recorded functions. Recorded here: `ViewportWdgt#_reLayoutScrollbars` 26,
  `ViewportWdgt#_positionAndResizeChildren` 23, `FrameWdgt#_positionAndResizeChildren` 48,
  `WorldWdgt#_updateEditorSelectionOverlay` 16, `SimpleSpreadsheetWdgt#scrolledBy` 24. A recorded function that moves
  to another class changes its key: the old entry fails STALE and the new key fails above the ceiling.
- **Stinks at their baselines** (`check-stinks.js`): `instanceof-type-test` 64/64, `comment-narration` 82/82
  (comments must not say "used to", "no longer", "previously"), `raw-chrome-color` 0.
- **`check-call-separation` [U]**: self-only public QUERIES 103/103: a new query only `@`-called must be `_`-named.
  **`check-dead-methods`**: a new method needs a reader in the same change. **`identical-override`**: hard zero.
  **`widget-conformance`**: every instance field declared at class level.
- **Docs**: both `CLAUDE.md` files sit at their byte ceilings (no unit grows them); `docs/architecture/` takes no
  narration; a BACKLOG item is at most 325 characters.
- **Inspector churn**: no test inspects a viewport, a frame, a slider, a document or a sheet. Only
  `SystemTest_macroDuplicatedInspectorDrivesCopiedTargetOnly` lists `Widget`'s members; this plan adds none.

## 3. The distilled argument

- **Why derive the inset.** The inset exists to keep the thumb clear of a line. The line is the viewport's own
  border where it paints one and the edge itself where it does not, so the clearance is one number and the border's
  width is asked of the appearance that paints it. One dial per case would be the defect this plan removes.
- **Why the document keeps its own margin.** The gutter arc gave the window the space around a page because the
  ring needed room. For a page that SCROLLS, that puts the viewport's edge, and so its bar, 8 px inside the window
  for ever. The room belongs to the thing that scrolls: the viewport already has a field for it. The window then
  keeps a gutter only around pages that are framed sheets (a slide, a canvas, a board, the spreadsheet), which is
  what the gutter draws anyway: every one of them paints its own edge.
- **Why a crop, not a second layout.** The plane keeps including the margin as its own padding, exactly as a bare
  document's does today, so the scroll range, the clamps, the bar's ratio and the caret follow are untouched: at
  both extremes the content rests at the margin's inner edge. Only what SHOWS changes: the plane is cropped at the
  margin (two paint bodies, one clip-through edge), and the pointer and the damage follow because they read the
  same walk.
- **Why the viewport paints its plane's ring.** A plane is as tall as its content; a ring inside its box scrolls
  away. The viewport is the box that stays, and it already has the seat (a clipping widget paints its overlay last).
  With a margin that holds the ring, the ring stands where the window drew it; without one, at the viewport's box.
- **Why a base class for the presentation.** Two classes need the same forty lines of derivation and the same four
  answers to a bar; they are siblings; fields stay where files and tests read them. The base asks its subclass only
  where the two differ: the run the bars lie along, what overflows, and the pin a bar drives.
- **Why now, in this order.** U1 changes every indicator's pixels once. U2 lands the crop with nothing using it
  (the gutter arc's lesson: land a mechanism pixel-neutral, then flip). U3 flips the document. U4 lifts the code
  that U1–U3 just settled, so the spreadsheet inherits the final shape, not a moving one.

## 4. Units

### U-order
U1 → U1b → U2 → U2b → U3 → U4 → U4b → U4c → U4d → U4e → U5 → U6 → U7. U2b (added by the owner) stands before U3, which changes how a
document sits in its window. U1b needs U1 alone (it restores a step of U1's test) and nothing after
it needs it; it stands before U3 so that a document's way out of its window can be played in a test. U2 edits
`_barFrameAt` after U1 did. U3 needs U2's mechanism. U4 lifts what U1–U3
left (if U2 or U3 PARKED, U4 lifts the code as it stands). U4b and U4c (added by the owner) fix two defects of a
tilted window's content that U2b filed; they need no indicator unit and stand after U4, which was ready first. U4d
(added by the owner) needs U4b: the window keeps its size round a tilted content before it crops it. U4e (added by
the owner) is independent of every unit before it and stands after them. U5 is
independent of U1–U4: its range helper is its own (§U4's Landed paragraph). U6 needs U4 and U5.

---

### U1 — A thin indicator stands clear of the line at its viewport's edge, and short of its side's ends

**Ruling:** O1, P2. **Time box 3 h.**

**Fix (confirm each shape against the code).**
1. `Theme`: replace `scrollIndicatorEdgeInset = 2` with `scrollIndicatorEdgeClearance = 1` ("how far a THIN
   indicator stands clear of the line at its viewport's edge: the border the viewport paints over its edge, or the
   edge itself"), and add `scrollIndicatorEndInset = 3` ("how far a THIN indicator stops short of each end of its
   side"). Rewrite the comments at the three places that describe the old dial (grep `edge inset`).
2. `RectangularAppearance`: answer the existing question, `outlineIsStroked: -> @_borderColor()?`.
   ⚠ `Widget._drawSelectionOverlay` reads it to switch the ring's 1 px stroke half on. For a square-cornered box
   that stroke lands on pixels the ring's fill already covers in the same colour, so the prediction is NO pixel
   change. That is a hypothesis: the suite's failing set measures it. If a selected bordered rectangle changes, do
   not recapture it: name a separate public question on the appearance (`strokesItsEdge`) and leave the ring's
   alone.
3. `ViewportWdgt._indicatorEdgeInset`: fat → 0; thin → the clearance plus 1 when `@appearance.outlineIsStroked()`.
4. `ViewportWdgt._barFrameAt` gains a fourth parameter, `endInset = 0`, taken off both ends of the run after the
   corner reserve. The arrange passes an `_indicatorEndInset` (thin: the dial; fat: 0); the two "on arrival"
   callers keep passing nothing (a press meets the fat, full-length frame).
5. `_barFrameHasRoomForThumb` is asked of the frame the arrange applies, which is now 6 px shorter while thin. Its
   comment says the test is about "the look a press meets". Ask it of the FAT frame (`_barFrameAt bar,
   @scrollBarsThickness`), so a bar does not vanish at a viewport length where it showed before.

**Tests.**
- New `SystemTest_macroThinIndicatorStandsClearOfItsEdge` (values + two screenshots): a folder window made small
  enough to overflow both ways (no border: `vp.right() − vBar.right()` is 1, `vBar.top() − vp.top()` is 3, the
  horizontal twin likewise), and a plain panel on the desk with overflow (bordered: 2). With the pointer in the
  band: 0 and full length, and `buttonScreenBoxOnArrival` unchanged by the thin look.
- Re-read the two tests that aim at the thin bar AS DRAWN, and assert their premise where it is only a comment:
  `SystemTest_macroTrackPressInTheFatteningCycleStillPages` (`@screenPointAtFractionOf doc.vBar, [0.5, 0.5]`: the
  thin bar's centre must lie inside the fat frame) and `SystemTest_macroSliderTrackClickMovesButton`
  (`clickOnSliderTrackAtFraction`, a fraction of the thin bounds).
- Plants, one per door: the clearance forced to 2; the end inset forced to 0; the border term dropped.

**Predicted pixel set.** Every shot that shows a thin indicator. Forecast (plant `research/plants/forecast-A.js`, dpr 1
mouse): **71 tests, 202 shots**, listed in `research/forecast/forecast-A.tests.txt` and `.shots.txt`. The measured
failing set must equal it; the finger and dpr 2 references follow the same tests. In every changed shot the only
difference is a thin thumb one pixel nearer its edge (window panes, documents) and 3 px shorter at each end.

**Docs.** `viewports-and-planes.md` "Scroll indicators" (the sentence naming `scrollIndicatorEdgeInset`, and "the
thin one 2 px in, the fat one flush"); `visual-design-system.md` §1's METRICS row.

**If parked:** U2 and U3 go on with today's placement; U4 lifts it as it stands.

**Landed 2026-11-20.** `Theme.scrollIndicatorEdgeClearance` (1) replaces the edge-inset dial and
`scrollIndicatorEndInset` (3) is new. `ViewportWdgt._indicatorEdgeInset` is the clearance, plus 1 where the
viewport's appearance strokes a border along its outline (`RectangularAppearance.outlineIsStroked`, read through the
soft probe the selection ring uses). `_indicatorEndInsetFor bar` gives the end inset to a thin bar the viewport
presents, `_barFrameAt` takes it off both ends of the run, and `_barFrameHasRoomForThumb bar` asks the frame a press
meets. What research corrected in the fix as written above:
- step 3's read is the soft probe: the nine toolbar classes wear `SeamRulesAppearance`, which answers no
  `outlineIsStroked`, and an unguarded call throws at their first bar arrange;
- step 4's end inset is for a bar the viewport PRESENTS: the arrange still sizes a bar picked up off it, which keeps
  its run. It is asked per bar, in a helper, because written inline it took `_reLayoutScrollbars` from 26 to 30;
- step 2: `StretchablePanelAppearance` overrides `_paintBorder`, so it answers `outlineIsStroked` for the edges it
  paints (all four: a line along the whole outline);
- §2.7: `Widget`'s ceiling is 394/394; §2.1: three toolkit readers use the arrival frames (`_widgetAPressMeets`
  too); seven comment sites stated the old placement, not three.
Ruled here:
- **The bars follow a re-parenting.** The inset derives from the border, which derives from where the viewport
  stands, and not every re-parenting arranges a viewport. A re-parented viewport places its bars again
  (`ViewportWdgt._reactToBeingAdded`): a window that adopts a content whose layout is pending arranges it, the way
  back onto the desk keeps the extent and arranges nothing. That way out was MEASURED with the hook removed (a
  panel picked up off its window and dropped on the desk keeps its thumbs 1 px from its edge, on the pixel beside
  its border, where 2 is right) and had no standing test when this unit landed: the way a person takes a pane out
  of its window onto the hand is the "Pick up" row, and `Widget.pickUp` ran the window's `_beforeChildPickedUp`
  outside any settle, a careless end-of-cycle push the gauntlet's `capstone` leg holds at zero for every test.
  Unit U1b fixed that, and the standing test plays the way out again, with its plant.
- **A re-dress does not place the bars, and that is left so.** The border also derives from the roles a builder
  dresses the viewport in (`wearPaneRoles`), and every builder dresses an orphan, before the first arrange. Placing
  the bars from that public method was tried in two forms and withdrawn: applied directly it broke the layering
  gate's rule [F] (an off-settle apply), scheduled it was a careless end-of-cycle push the gauntlet's `capstone` leg
  holds at zero. The form that passes both is a self-settling setter over a no-settle core, for a path no product
  code takes.
- **For a thin indicator, the toolkit's `dragSliderButtonToFraction` measures both ends of its drag on the look a
  press meets** (the centre of the thumb a press meets, the fraction point of the frame a press meets); a plain
  slider keeps its two reads. Measured on the bar as drawn, `SystemTest_macroMenuPinnedInScrollPanel`'s content
  would have ended 7 to 11 px short: a changed shot that is not this unit's target. Every drag of the suite is
  unchanged along the run.
- **The new test plays under both pointers** and asserts the frames a press meets by value; the hovered look stays
  `SystemTest_macroScrollIndicatorFattensAndDrags`'s (mouse-only by meaning: a finger has no hover).
- `outlineIsStroked` keeps its name for both readers: on a square-cornered box the ring's stroke half is the
  border's own `strokeRect` over pixels the ring's fill already covers (a selected bordered canvas kept its pixels).
Evidence: `SystemTest_macroThinIndicatorStandsClearOfItsEdge` (an unbordered pane, a bordered panel, the frames a
press meets, both ends of the run, a 14 px tall viewport, the panel taken as a window's content; two shots) with
four plants, one per door (the clearance, the end inset, the border term, the room test), each biting under both
pointers; the premise of `SystemTest_macroTrackPressInTheFatteningCycleStillPages`
and of `SystemTest_macroSliderTrackClickMovesButton`'s first click is asserted. The measured failing set was the
corrected prediction exactly: 70 tests and 198 shots at dpr 1 under the mouse, every one a screenshot mismatch. That
is the forecast's 202 less the four of `SystemTest_macroInspectorScrollbarUnplugged`, whose detached bar the
forecast plant shortened; the forecast re-run's one assertion failure (a list click missing its row) was an artifact
of the same plant shortening the frames a press meets, and the fix does not fail it. Under a finger the same tests
fail less the six that are mouse-only, with three more shots where a tap leaves the bar thin and a mouse's resting
pointer keeps it fat. Every changed shot was measured at both densities (396 shots): the changed pixels of each
are strips at most 5 px wide, the thumbs, and nothing else moved.

---

### U1b — A pane picked up off its window leaves at its own size (the window's hook runs inside the pick-up's settle)

**Ruling:** the owner's, 2026-11-20 ("add the pickUp defect to the scope of this loop"). **Needs U1 CLOSED. Time
box 2 h.** Grouped with U1: the fix gives U1's re-parenting hook its standing way-out test back, and it lands
before U3, whose document can then be picked up off its window in a test.

**The defect (found by U1's gauntlet, probed).** `Widget.pickUp` dispatches its old parent's
`_beforeChildPickedUp` OUTSIDE any settle, while its own comment gives the dispatcher the callback's settle (the
layering gate's rule [J]) and it does settle `_reactToChildPickedUp`. `FrameWdgt._beforeChildPickedUp` rebuilds
the window's default payload when the child is its contents (`_resetToDefaultContents`: the bar's title string
destroyed and rebuilt, the frame re-titled and re-fitted), so each of those layout marks is a careless
end-of-cycle push, which the gauntlet's `capstone` leg holds at zero for the whole suite. A person reaches it by
the context menu's "Pick up" row on a window's content. No test took the path before U1's, so the zero held.

**Fix (confirm the shape against the code; the research report is `u1b/RESEARCH.md` in the loop's scratch).**
`pickUp` owns the settle of BOTH its callbacks. `Widget` sits at its method ceiling: a body edit, no method added.
Find every instance first: every implementer of `_beforeChildPickedUp`, every caller of `pickUp` in both repos
(some act on a detached widget), and every other dispatcher of a `_before…` hook (`_beforeChildClosed`,
`_beforeChildDestroyed`, `_beforeChildCollapsed`): a sibling with the same defect and a reach path is fixed
through the same door in this unit when the fix is the same line, and filed otherwise.

**Tests.**
- `SystemTest_macroThinIndicatorStandsClearOfItsEdge` gets its way out back: the panel picked up off its window
  and dropped on the desk strokes its border and its indicators lie 2 in again, the read the re-parenting hook
  alone answers for; the plant that removes the hook returns to the standing set.
- New `SystemTest_macroPanePickedUpOffItsWindowKeepsItsSize` (values): by the person's "Pick up" row and by the
  direct call, the window's hook runs inside a settle the pick-up opens (a spy), the pane rides the hand and lands
  at the extent it had, and the window shows its default payload. Both pointers. (As planned it read "the default
  payload laid out when the call returns", which the Landed paragraph below shows tells nothing.)
- Plant: the before-hook dispatched outside the settle again.

**Predicted pixel set:** EMPTY.

**Docs.** The architecture doc that states the dispatcher rule, if the fix changes what it says.

**If parked:** U1's hook keeps no standing way-out test; U2 goes on.

**Landed 2026-11-20.** One line: `Widget.pickUp` dispatches `oldParent?._beforeChildPickedUp? @` inside a
`_settleLayoutsAfter` of its own, the shape `ActivePointerWdgt.grab` gives `_beforeBeingGrabbed`; the settle round
the trailing `_reactToChildPickedUp` stays. What research corrected in the section above:
- the marks ARE flushed inside the call on the product before the fix, by `grab`'s first settle, so a plain window is
  laid out when `pickUp` returns either way and nothing is painted in between: "the default payload laid out when
  the call returns" tells nothing. What was wrong is that the hook ran in no settle's window;
- on a MAKER's window that had a cost a person sees, MEASURED: the fresh payload's constructors settle, and with no
  settle open to defer to each lays the world out in the middle of the rebuild, while the window still holds the
  departing payload and has already retired its toolbar band. A Docs Maker's document, 582×229 in its window, came
  away 582×295, taller by the band's room. With the fix it leaves at 582×229;
- `_beforeChildPickedUp` has one definer (`FrameWdgt`) and `_resetToDefaultContents` one override
  (`MakerDocumentWdgt`). Of the other `_before…` dispatchers, close, destroy, collapse, un-collapse and
  `_beforeBeingGrabbed` run inside a settle; `_beforeChildDropped` does not, and its two implementers schedule no
  layout (left). `_reactToChildPickedUp` has had no implementer since 2026-07-20 (left).
Evidence: `SystemTest_macroPanePickedUpOffItsWindowKeepsItsSize` (the new test's name: what it pins is the pane's
size and the settle, not "settles at once"): two plain windows, by the person's "Pick up" row and by the direct
call, and a Docs Maker in edit mode; a sanctioned spy on the window's hook reads the world's settle mark as the hook
runs. Run first against the product before the fix, it failed five reads under both pointers (the spy in each leg,
the Maker document's extent on the hand and on the desk), passed with the fix, and failed the same five under the
plant that runs the hook bare again. `SystemTest_macroThinIndicatorStandsClearOfItsEdge` plays the way out of the
window again, and the plant that removes U1's re-parenting hook fails that read alone. Both tests show zero
careless pushes under the production probe. Predicted pixel set EMPTY, met.
Filed on the way (this plan's BACKLOG section): a Maker whose payload leaves it shrinks to its fresh payload,
though `MakerDocumentWdgt._resetToDefaultContents` says its extent stays put. Measured on a Docs Maker whose
document is picked up: 600×400 to 68×211 round a 50×40 document (before the fix, to 68×145 round a 50×5 one: the
fix also changes what the Maker is left with). By reading, the same reset runs for every Maker kind and from the
"Destroy" row.

---

### U2 — A viewport's padding is a margin: its plane shows inside it (mechanism, dormant)

**Ruling:** P1. **Time box 3.5 h.** Nothing sets a viewport's `padding` yet, so this unit changes no pixel.

**Fix.**
1. `ViewportWdgt`: state the field for what it is ("`padding`: a fixed MARGIN between my edge and the box my plane
   shows through; my indicators and my plane's selection ring stand in it") and give the box ONE home, a private
   `_planeBox` (`@boundingBox()` itself while `@padding` is 0, so the dormant path hands back the same object; else
   inset by `@padding`).
2. **Paint**, both bodies (§2.4): the contents child is painted inside `damagedPartOfFrame ∩ _planeBox()`, then
   through the translation as today; every other child as today. They `return super` only while the translation is
   zero AND the padding is 0.
3. **Clip-through**, both twins in `Widget`, in lockstep: where they translate the upstream clip for the edge
   child, ask the clipping ancestor ONE public question that does both (crop to its plane box for that child, then
   translate), so `Widget` gains no branch and no method. Suggested: `ViewportWdgt.clipIntoPlaneOfChild: (clipSoFar,
   child)`, with `scrollTranslationOfChild` kept for its other readers (`cornerRadiiFollowingMyOutline`,
   `FrameWdgt._visibleBoxOnMyPage`). Keep the dormant returns: no crop and no translation hands the same object
   through. The cache oracle must stay silent (the gauntlet's `settle` leg rides it).
4. **The bars run along the plane box.** `_barFrameAt`: the run's end inset is the larger of the caller's
   `endInset` and `@padding` (a thin bar; a fat one keeps its full run). Then decide `_cornerReserveFor`'s `+ 2 *
   @padding` by reading what it would now do: the run already gives up the margin at both ends, so the term counts
   it twice; delete it unless a measured case needs it (it has never been non-zero).
5. **Drops in the margin**: `ViewportWdgt.dropReceiverForPointsOnMyBody` answers `@contents` while `@padding > 0`
   (the hand's existing protocol, §2.3), so a payload released in the margin goes to the plane and is moved inside.
6. **A press in the margin** must behave as a press on the window's gutter does today (D7: it moves the window).
   Measure it on the fixture below before deciding anything; if it does not, that is a finding for the unit.

**Tests.** New `SystemTest_macroViewportMarginCropsItsPlane`: a plain viewport on the desk whose macro gives it
`padding = 8` and content taller than it. Values: content scrolled into the margin is not shown there (a resident's
`clippedThroughBounds` stops at the plane box); a pointer over the margin targets the viewport, not the hidden
resident; a widget dropped in the margin lands in the plane, inside; the thin bar's top is the viewport's top + 8.
Screenshots: at rest and scrolled. Follower on both pointers.
Plants, one per door: the paint crop; the clip-through crop; the bar's run; the drop receiver.

**Predicted pixel set:** EMPTY (the new test's own references apart). Any failing test is a finding.

**Docs.** `viewports-and-planes.md`: a paragraph under "The three roles" for the margin (what shows, what stands in
it, that the plane still includes it as padding so no scroll arithmetic changes).

**If parked:** U3 parks with it.

**Landed 2026-11-20.** The viewport's field is `planeMargin` (see "Ruled here"), and `_planeBox` is its one home
(`@boundingBox().insetBy @planeMargin`, the same object at 0). Both paint bodies paint the contents child inside
the damage ∩ the plane box and take the stock path only at zero translation AND no margin. The clip-through edge
asks `ViewportWdgt.clipIntoPlaneOfChild (clipSoFar, child)` (crop to the plane box, then translate; the same
object through for another child, and for the contents with no margin and no translation), from both
`Widget.clipThrough` and `Widget.SLOWclipThrough`: `Widget` gained no method, and `clipThrough`'s recorded
complexity FELL from 20 to 17 (record lowered). `dropReceiverForPointsOnMyBody` names the plane while a margin is
kept. What research corrected in the fix as written above:
- step 4 cannot live in `_barFrameAt`: the two on-arrival readers ask it for the fat, whole-run frame and pass no
  end inset. The margin is folded into the thin end inset (`_indicatorEndInsetFor`: the larger of the theme's end
  inset and the margin), and `_cornerReserveFor` lost its `+ 2 * padding` term (pixel-neutral: it has never been
  non-zero; kept, it would open a 28 px corner hole at a margin of 8);
- §2.3 missed a reader that ACTS on the field: `HandleWdgt._cornerInsetFrom` reads `target.padding` off whatever a
  handle is attached to;
- a change of the margin on a LIVE viewport needs the clip caches broken (they are keyed by
  `WorldWdgt.geometryVersion`; precedent `_writeScrollOffset`). Nothing writes the field on a live viewport in this
  unit, and a method with no reader fails the dead-method gate, so the write door lands with its first caller in
  U3;
- the cache oracle compares the two twins by VALUE and is armed only in the gauntlet's `settle` leg;
  `scrollTranslationOfChild` keeps three readers (`cornerRadiiFollowingMyOutline`, `FrameWdgt._visibleBoxOnMyPage`,
  the viewport's own `add`);
- no fifth walk needs the crop: every hit, damage, visible-box, highlight and drop-clamp walk reads
  `clippedThroughBounds`. `scrollCaretIntoView` holds an agreeing copy of the plane box; `TransformFrameWdgt
  ._ancestorScreenClip` skips the edge step (unreachable while every plane clips).
Ruled here:
- **The field is renamed for what it is, `planeMargin`.** A handle seats itself by its target's `padding`, so a
  viewport whose margin kept that name would move a bare document's four halo handles from 2 px to 8 px in once U3
  gives it a margin: a look P1 does not picture. A handle reads no `padding` on a viewport and sits 2 px in, as
  before. (`Widget.setPadding` and its pin write `paddingTop/Bottom/Left/Right`, another family: one more reason not
  to share the word.) Every reader of the viewport's own field moved; no other class's `padding` did.
- **A bar needs room along the plane box** (`_barFrameHasRoomForThumb`: the pressed frame's run less the margin at
  both ends must hold the thumb a press meets). Without it a short viewport with a margin hands its thin bar a run
  shorter than a thumb, or a negative one. Identical at margin 0.
- **The margin's pointer behaviour with a mouse is the page's empty background's** (step 6, measured by reading the
  grab path and by the test's hit read): a press-drag there moves the window, or the bare viewport. Where a bar
  shows, the fat bar covers that side's margin. The click, the finger and the overlays are U3's, ruled by the owner.
Evidence: `SystemTest_macroViewportMarginCropsItsPlane` (a plain viewport given a margin of 8 as it is built: the
content rests at the margin's inner edge at both ends of the scroll; a resident's shown box stops at the plane box;
the pointer over the margin meets the viewport; a payload dropped in the margin lands in the plane, moved inside;
the thin bar runs along the plane box and the pressed frame stays whole; a 24 px tall viewport shows no bar and a
26 px one does; a viewport with no margin names no receiver; two shots) with five plants, one per door, each
biting under both pointers (the paint crop fails the two shots alone: no value sees paint). Predicted pixel set
EMPTY, met: the presuite and the finger suite changed no reference.
From the unit's review, for a viewport that KEEPS a margin: the two mimic relays repaint the viewport while it
keeps one (in a margin its own rect shows, and the plane's repaint stops at the plane box: a third shot and a
plant); only a bar the viewport presents gives up the margin in the room test; the deleted corner-reserve term
has its own leg and plant. Left unwitnessed: the shadow twin's crop line (no translucent, shadowed viewport keeps a
margin in the suite). The hand-off does not cover the side where a bar stands fat (a carry with no button held
fattens it): the release meets the bar. Filed on the way (this plan's BACKLOG section): a payload released over a
scrolled viewport's fat bar lands displaced by the scroll offset (`ViewportWdgt.add` forwards it to the plane
unmapped; a defect of the product before this unit, seen through this unit's plant 4).

---

### U2b — A window whose content leaves it keeps its size and shows its default content, by any door

**Ruling:** the owner's, 2026-11-20, "go" on the recommendation: research first, then ONE door for "my content
left" with the window keeping its size, or the narrow size fix with the rest filed. **Needs U2 CLOSED. Time box
3 h.** It took in the item U1b filed (a Maker shrinks to its fresh payload when its payload leaves it) and a
review's two unprobed reads of U1b's (content leaving by another door never reaches the window; a Maker reset in
view mode comes back in edit mode).

**Landed 2026-11-20.** A window hears its content leave in ONE seat, `FrameWdgt._reactToChildRemoved`, the generic
removal notification every door reaches (a pick-up, a drag, "Attach", a close into the bin, a destroy), after the
fact and inside the settle of the verb that took it (one exception: a "Pick up" of a tilted window's content
extracts it in the pick-up's declared deferred window, which the grab's first settle flushes), when the child is
its content and has really left it (`child is @contents and !@isAncestorOf(child)`, the predicate a stretchable
container's fresh-page seat uses). The three per-verb hooks `_beforeChildPickedUp`, `_beforeChildClosed`,
`_beforeChildDestroyed`, their dispatch lines in `Widget`, and both of `Widget.pickUp`'s settles are deleted
(`pickUp` is a grab that centres); `FrameWdgt` 173 → 170 methods, its ceiling lowered. Ruled here:
- **One seat, not three hooks.** Research found no plan that ruled the hooks: they are the 2018 window code, renamed
  twice, never re-decided, and the reset reads nothing of the departing content. A hook run before a verb answers
  an INTENT (a busy hand's `pickUp` emptied the window and took nothing); the removal notification answers a FACT.
  The precedent is a stretchable container's fresh page (`c7d6dfa4`, in the same notification).
- **A window keeps its size, plain, Maker or docked band.** A Maker's reset captures the fresh payload's placement at
  its mount, so the arrange fits the payload to the window instead of hugging it as a first placement (no arrange
  code changes); a plain window no longer snaps to 300×300 (the placeholder takes whatever room the window has: the
  owner saw the before/after of the one reference it changes and said "keep"; a narrow emptied window shows no
  title, the strip's own rule at that width); a docked band keeps its thickness
  (`EdgeDockLayoutSpec.notePayloadLeft`: without it a band whose toolbar left by "Attach" committed NaN heights,
  measured, a door this unit's one seat newly reaches).
- **A Maker keeps its mode**: read off the departing payload and put back through the frame's own mode core, so the
  strip's toggle and the docked bands follow.
- **"Delete" / "Move to trash" on a TILTED window content closes the window, as on an upright one**: the three
  content-to-frame redirects look through islands (`_parentThroughIslands`).
Evidence, MEASURED by the new test run first against the product before this unit (27 reads failing under both
pointers): after "Attach" a window kept the departed pane as its content and a grip resize pulled the pane back and
resized it (300×200 → 340×230); after "Pick up" in a tilted window, a drag of a tilted content and the "Close" of a
tilted nested window the window kept the departed figure; "Delete" on a tilted content sent the content to the bin
and left its window; a Docs Maker shrank 600×400 → 68×211 and a Generic panel 460×400 → 318×405; a Maker reset in
view mode came back in edit mode with its band engaged. `SystemTest_macroWindowWhoseContentLeavesShowsItsDefaultContent`
(twelve legs, values only) passes under both pointers with zero careless end-of-cycle pushes (the production audit
as a prelude), and nine plants (one per door: the hand, "Attach", the bin, destroy, the Maker's size, its mode, the
redirect, the band's thickness, the content that has not left) each fail their own legs. The one risk research
could not settle by reading, a nested window picked out of its window (the window is told only after the hand's
release flush), passed the `capstone`, `settle` and `revisits` gates on the test alone (under the mouse).
Recaptured: `SystemTest_macroClosingInnerWindowKeepsOuter` image_2 (mouse and finger, dpr 1 and 2), the emptied
outer window keeping its size; the suite changed nothing else.
`SystemTest_macroPanePickedUpOffItsWindowKeepsItsSize` keeps its subject: its spy moved to the new seat, and its
Maker leg now reads the Maker's extent.
Filed on the way (this plan's BACKLOG section): a tilted window content's window grows by the content's footprint
at the first hover highlight (measured: 249 → 311 px tall, on the product before this unit too); "Pick up" on the
payload of a TILTED Maker would run its reset outside a settle (the extraction is declared, not settled; settling
it changes every tilted drag's cadence); a tilted content that leaves its island leaves its window an empty island.

---

### U3 — The document keeps its margin itself; a viewport paints its plane's selection ring

**Ruling:** O2, O3, O4, P1, P3. **Needs U2 CLOSED. Time box 4 h.** This is the visible flip.

**Measured target (probe variant `margin`, review page §M).** Against today's renders, a Docs Maker window differs
ONLY in the bar's region in each of: at rest, scrolled, page selected, page selected and scrolled, view mode
scrolled (diff boxes 13 px wide at the bar, nothing else). First paragraph 8 px below the toolbar; scrolled content
cut 8 px below the toolbar and 8 px above the grip strip; the ring 2 px of air out from the page with 4 px left
before the window's border.

**Fix.**
1. `DocumentViewportWdgt` stops being a gutter page and keeps the spacing as its margin:
   - delete `wantsWindowPageGutter`, `receiverOfDropsAroundMe`, `_itemInset`, the `_reactToBeingAdded` override and
     the `_caretScrollMargin` override (the base answers `@padding + @extraPadding`, which is the same 8);
   - `_takeItemSpacing` reads `WorldWdgt.theme.documentItemSpacing` and assigns `@padding`, `@extraPadding = 0` and
     `@contents?.padding` from it (the same idiom, one dial, taken at the top of every arrange);
   - `setContents` takes the spacing first, then `super aWdgt` (the base seats content at `@padding +
     @extraPadding`; `VerticalStackViewportWdgt`'s constructor calls `setContents` during construction, before any
     arrange).
   A document in a window and one with no window are then the same thing.
   ⚠ The prototype cropped at the document's inset without moving the number between the two fields, so "`padding`
   8, `extraPadding` 0" is NOT yet measured. Every reader of their SUM is unchanged (`setContents`,
   `_positionAndResizeChildren`, `_caretScrollMargin`). The one reader of `@padding` ALONE is
   `scrollCaretIntoView`'s "padded interior": with the margin there, a windowed document's caret is followed from
   the page box's edge and lands 8 px inside it, where it lands today (`SystemTest_macroDocumentCaretBroughtIntoViewWhenMoved`
   is in the predicted set: its caret must not move); a document with no window follows 8 px further in than
   today, as a windowed one does.
2. `FrameWdgt` needs no new code: a document is no longer a page to it, so `_bodyMargin` is 0 and the viewport
   reaches its lines. `pageGutterAround`, `_hostsAPage`, the ring painter and `dropReceiverForPointsOnMyBody` stay
   for the framed pages. Do not simplify `_visibleBoxOnMyPage` unless a measurement shows its translation climb dead.
3. **The ring.** `ViewportWdgt` answers the host protocol for its plane (`hostsSelectionRingOf aWdgt` is
   `@isMyContentsPanel aWdgt`), answers the ring's box (its plane box grown by the ring's reach while `@padding`
   holds that reach; else its own box), repaints on the change notification, and draws the ring from the seat a
   clipping widget already has (`_showsSelectionOverlay` true while it hosts; a `_drawSelectionOverlay` that paints
   `HighlightOutlineAppearance.paintRing` at the hosted box, else `super`).
   - The protocol's two page-named members become role-neutral in the same change, in both hosts and in
     `WorldWdgt`: `pageSelectionRingBox` → `hostedSelectionRingBox`, `notePageSelectionRingChanged` →
     `noteHostedSelectionRingChanged` (renames: no method count moves).
   - The ring's reach has ONE home both hosts read (today `FrameWdgt._pageSelectionRingReach`, private): a derived
     `Theme` value beside `pageSelectionOutlineOffset` is the nearest precedent.
   - P3: the thumb is not moved for the ring.
4. Grep every reader of the deleted members and renamed names in BOTH repos, as strings too (`tests/`, `scripts/`,
   the harness).

**Tests.**
- `SystemTest_macroPageSelectionRingInWindowGutter`: its Docs Maker step now asserts the host is the document's
  viewport (`docs.contents`); its metadata says so; image_0 is expected to stay pixel-identical (measure it: if it
  changes, look before anything else). Its Drawings Maker step is unchanged.
- New `SystemTest_macroViewportPaintsItsPlanesRing`: a bare document scrolled and a plain panel window with
  overflow, plane selected: the host is the viewport, the ring is closed (screenshots).
- New `SystemTest_macroDocumentKeepsItsMargin` (values + screenshots): in a Docs Maker, edit and view mode: the
  viewport's edges are the window body's; the first paragraph's top is 8 below the toolbar band (edit) or the title
  rule (view); scrolled content shows no pixel in the margin; the thin bar's right edge is 1 px inside the window's
  inner line; a paragraph dropped in the margin lands in the document; a press-drag in the margin moves the window.
- Plants: the margin not taken (padding 0); the ring host removed; the ring's box at the viewport's own box.

**Predicted pixel set.** Forecast on today's placement (plant `research/plants/forecast-margin.js`, dpr 1 mouse, paint
only): **16 tests, 48 shots**, in `research/forecast/forecast-margin.tests.txt`. By kind:
- a document's bar moved to the window's edge and running along the plane box: `CollapsedBarHasTheWindowsWidth`,
  `DocumentCaretBroughtIntoViewWhenMoved`, `DocumentEditLayoutDropSlots`, `DocumentScrollsMixedTextAndClocks`,
  `NestedScrollPanelsRouteWheel`, `ResizingScrollFrameThenImmediatelyScrollingTheHandlesDontStickToScrollPanelContent`,
  `SimpleDocumentAllReflowsCorrectlyAsIChangeFontSize`, `SimpleDocumentHandlesOldInspector`,
  `SimpleDocumentManualBuildAndScroll`, `SimpleDocumentProgrammaticBuildAndScroll`,
  `SimpleDocumentRemovingLastParagraphUpdatesScrollbarAndLeavesViewportAtEndOfDocument`,
  `SliderTrackClickMovesButton`, `SuperToolbarOpensEveryToolbar` (a bare document's content is also cropped at its
  margin where one is scrolled);
- a selected plain panel's ring, now whole and over its border: `NoSpuriousScrollbarsOnScrollPanelResize`,
  `ScrollPanelMergesChildMenu`;
- `PageSelectionRingInWindowGutter` (its host assertion; see Tests).
Re-measure after U1 and U2 are in: the set must be explained test by test against these kinds.

**Docs.**
- `visual-design-system.md` §4.10, rewritten in the present tense: a window keeps the gutter around a page that is
  a framed sheet; a document is the window's own paper, reaches its lines and keeps `documentItemSpacing` as its
  viewport's margin; where the ring stands and who paints it (the window in its gutter, a viewport in its margin or
  at its box); drops and presses in a margin. Also its §5 rows "Selection outline", "Document paragraph items" and
  "Embedded toolbar with its title strip", and §6 item 9.
- `viewports-and-planes.md` (the ring; the document as the margin's first user), `regularity-principles.md` "The
  frame model" (page or pane), `appearance-paint-convention.md` (the ring's two painters),
  `docs/specs/drag-embed-interaction-spec.md` (§2's table and §5: who names a drop receiver).
- Source comments that state the old rule: `FrameWdgt` (the "body edges" header, the page-ring header),
  `VerticalStackPanelWdgt` (~:12-16, ~:226), `Widget` (~:560-567), `WorldWdgt` (~:323, ~:2048, ~:2112), `Theme`
  (the `windowPageGutter`, `documentItemSpacing` and `pageSelectionOutlineOffset` comments), `ActivePointerWdgt`
  (~:374), `DocumentViewportWdgt`'s header.

**If parked:** documents keep today's look; U4 goes on.

**Landed 2026-11-21.** The document is a PANE: it keeps `documentItemSpacing` as its viewport's `planeMargin`, written
through the margin's one door, `ViewportWdgt._writePlaneMargin` (compare, assign, bump the geometry version,
repaint), windowed or bare alike; `wantsWindowPageGutter`, `receiverOfDropsAroundMe`, `_itemInset`, the
`_reactToBeingAdded` override and the `_caretScrollMargin` override are deleted (the base's caret margin reads the
plane margin), and so is `FrameWdgt._visibleBoxOnMyPage`'s translation climb (dead by structure: no page a window
keeps a gutter round scrolls). A viewport hosts and paints its plane's selection ring (`hostsSelectionRingOf`,
`hostedSelectionRingBox`, `noteHostedSelectionRingChanged`, the names the window's page ring now shares; the ring's
reach one derived theme value, `pageSelectionOutlineReach`). The owner's rulings, as built: Q1 a click in the margin
selects the page (`ViewportWdgt.resolvesEditorSelectionToContent` while a margin is kept); Q3 every overlay laid
over a widget frames the box it presents (`boxPresentedToOverlays`: a document's plane box; the hover wash, both drag
outlines, the lock badge, and the dev pinout label), so their pixels are today's; Q4 the window's grip floor counts
its content's margin (a Docs Maker's floor stays 171 px); D7 a drop on a document window's own body (its grip strip,
the surround of its band) goes to the page, the window forwarding what its content's margin names (a window whose
content is itself a window forwards nothing: a release on its body lands where it does today, measured).
`FrameWdgt` 170 → 168 methods, its ceiling lowered; no ratchet raised. Corrections to the Fix text above, measured: the base's caret margin is the plane margin (no `@padding` or
`@extraPadding` is read); a BARE document changes beyond its bar (its margin's crop shows at rest as well as
scrolled, and `SystemTest_macroDocumentCaretBroughtIntoViewWhenMoved`'s caret lands 8 px further in: image_4);
`FrameWdgt` needed the two body edits (Q4, D7). The predicted set held: 15 tests under the mouse, all screenshots
(the eleven bare-document tests, the two windowed ones by their bar alone, the two selected plain panels by their closed
ring); under a finger the same less the two mouse-only tests, plus three scroll panels a finger's drag leaves
selected, their ring now closed at the viewport's box (O4; the forecast ran the mouse only). The owner saw the
pictures that differ from the review page's (a bare document's margin, a coloured document, the three finger rings)
and said "go": the 15 and the 16 are recaptured at dpr 1 and 2, complete. One existing test
changed its aim: `SystemTest_macroSimpleDocumentAllReflowsCorrectlyAsIChangeFontSize` right-clicked 8 px inside the
top of a paragraph standing at the foot of the view, which is now the margin; it right-clicks the middle of what
shows of the paragraph. Proof: `SystemTest_macroDocumentKeepsItsMargin` (ten legs, three shots) and
`SystemTest_macroViewportPaintsItsPlanesRing` (two fixtures, four shots) pass under both pointers with zero careless
end-of-cycle pushes; ten plants (one per door) each fail their own legs under both pointers; followers clean. Filed
on the way (this plan's BACKLOG section): a finger's scroll that starts on ANOTHER text of a document being edited
ends the edit (the press is read as acting elsewhere before it turns into a scroll; probed).

---

### U4 — The indicator presentation gets a home both scrollers extend (a lift, pixel-neutral)

**Ruling:** P4. **Time box 3 h.**

**Fix.** New `src/basic-widgets/ScrollIndicatorHostWdgt.coffee`, `class ScrollIndicatorHostWdgt extends
ClippingWdgt`; `ViewportWdgt extends ScrollIndicatorHostWdgt` (the file must say so literally: load order is read
from the source text).
- **Moves up, unchanged in behaviour:** the fields `vBar`, `hBar`, `scrollBarsThickness`, `_pointerInScrollBand`
  (and its transient entry); `isMyScrollBar`, `sliderTrackPressJumpsButton`, `_barIsMineToPresent`,
  `_indicatorThickness`, `_indicatorEdgeInset`, the end inset, `_refreshScrollIndicators`, `hoverMoved`,
  `hoverExited`, `_updatePointerInScrollBand`, `_barFrameAt`, `_cornerReserveFor`, `_otherBarCrossesMyCorner`,
  `_resizerOverMyCorner`, `noteCornerResizerChanged`, `buttonScreenBoxOnArrival`, `barScreenFrameOnArrival`,
  `_barFrameHasRoomForThumb`, the bar arrange, and `_scrollRangeAlong`.
- **Asked of the subclass**, each a `_`-named hook the base calls: the box the bars run along (a viewport: its plane
  box); whether an axis overflows under its policy (a viewport: today's `@scrollPolicy isnt 'never' and
  @contents.width() >= @width() + 1` and the height twin); the action a bar drives (`"setScrollX"`,
  `"setScrollY"`), used by one builder that makes the two bars, adds them and `trackTarget`s them. The fat width
  falls back to the theme's when the field is undefined.
- **`_reLayoutScrollbars` is split as it moves**: one per-bar arrange called twice, so no function of the base
  exceeds 15, and the `RECORDED` entry for `ViewportWdgt#_reLayoutScrollbars` is DELETED (a moved function's old key
  fails STALE). This is a record removed, not a raise.
- A member the base reads that only a viewport has becomes a hook answered with today's expression; nothing in the
  base names `@contents` or a scroll offset.

**Proof.** A base-class move is right exactly when every member of every class still resolves to the same code
(`widget-authoring-guidelines.md` §16). Run `Fizzygum-tests/.scratch/cleanups-loop-4/resolution-map.js --out=<dir>`
before the first edit and after the build, and diff: `resolved.txt` may change only in the split arrange and the new
class's own lines; `homes.txt` shows the members leaving `ViewportWdgt` for the new home. Then the suite.

**Predicted pixel set:** EMPTY, the inspector churn included (§2.7: no test inspects a class in this chain).

**Docs.** `viewports-and-planes.md`: the indicator section names the base and what a subclass answers.

**If parked:** U6 parks with it (the sheet must not get a second copy of the derivation).

**Landed 2026-11-21.** `ScrollIndicatorHostWdgt extends ClippingWdgt` (core) holds the presentation;
`ViewportWdgt extends` it. Moved: the fields `scrollBarsThickness`, `vBar`, `hBar`, `_pointerInScrollBand` (and its
transient), with `sliderColor` now declared on the base, and 19 methods, `_reLayoutScrollbars` among them, split as
it moved into a per-bar `_reLayoutBar` (complexity 8; the arrange 0), so `ViewportWdgt#_reLayoutScrollbars`'s
complexity record is deleted. What only a viewport knows is asked: the bars' two actions are the parameters of the one
builder (`_buildScrollBarsNoSettle hAction, vAction`); `_scrollAxisOverflows bar` (the scroll policy and the overflow
test); `_scrollBarRunMargin` (the plane margin, a scalar); `_scrollBarRunBox` (the host's own box, inherited);
`_fullBarThickness` (the field, else the theme's). The base names no `@contents`, scroll policy, plane margin or scroll
offset. Corrections to the Fix text above, ruled before the first edit: `_scrollRangeAlong` and `_reactToBeingAdded`
STAY in `ViewportWdgt` (they read its scroll state and its border rule), so U5 takes its own range helper and no
longer needs U4; the run box is the host's own box and the margin a scalar hook (the "plane box" reading would have
moved the bars 8 px in); `hoverMoved`'s warning comment was false and states the mechanism. `ViewportWdgt` 116 → 99
methods, the base 25; `Fizzygum-tests/scripts/aim-census.js` keys the two bars to the base. Proof: the resolution
map before and after differs on each of the 16 chain classes in exactly the 11 names whose text changed and the 7
added, plus the new class's own lines, nothing else in 545 classes (the research's prediction); every class's
merged transient list is unchanged (a statics probe, the one fact the map cannot see); the suite and the finger
suite changed nothing. The layering gate's rule [F] names the split's new apply door, `_reLayoutBar`, beside
`_reLayoutScrollbars`. One visible effect, in the dev tools only (`widget-authoring-guidelines.md` §16(b)): an
inspector's default property list for this family no longer shows `sliderColor` (now declared) nor, on a viewport,
`vBar`, `hBar` and `scrollBarsThickness`, which now live on the base; no test inspects one.

---

### U4b — A tilted window content's window keeps its size at its next arrange

**Added by the owner 2026-11-21** ("add the (proper, clean, architecture-compliant) fixings of these two to the
loop"), from U2b's filing. **Time box 3 h.** Research first: `Fizzygum-tests/.scratch/scroll-indicators-loop/u4b/`.

**The defect, as read (to be measured before the fix).** When a window's content is tilted, an island
(`TrackingTransformFrameWdgt`) takes the content's place as the window's content. The window's first placement
measures the island's untransformed box (a nested window's outer window: 252×249); every LATER arrange of the window
asks the island its height, and the island answers its claimed footprint (252×311). So any arrange after the tilt
grows the window, whatever starts it: the hover highlight a menu gesture adds (U2b's measurement), a grip resize
(`SystemTest_macroIslandLensWindowHeightLock` image_3 shows the window at the claim's height), a drag over it.
`layout.md` §4.3 (and the owner's 2026-07-17 correction it records): a window DICTATES its content's size; a
content's claim governs only the containers that ask for one.

**The owner's ruling (2026-11-21, fix A, after pictures of the options).** A window whose content is tilted keeps the
size it had round the upright content, at every arrange: the tilt is ink, never a claim on the window. An island
claims space only where it is asked for a claim; as a window's content it forwards the window's size to its content,
as its 'slot' mode already does: one private predicate on `TrackingTransformFrameWdgt` in place of three copies of the
gate. (The ink then overhangs the window's chrome as it does right after a tilt today: U4d's ruling crops it.) A
consequence derived from the same ruling: a tilted nested window hides its grip, as an upright one does — the outer window dictates
its size, so the grip would be a half-dead control (measured: a drag kept its height and lost its width).

**If parked:** today's growth stays, filed.

**Landed 2026-11-21.** `TrackingTransformFrameWdgt._claimsSpaceFromMyContainer` is the mode gate's one condition
(a coupled mode, and an ASKING container): as a window's content (its attachment frame-content-active) the island
forwards the stack-protocol trio to its content in every mode, so the window sizes the content's untransformed box at
every arrange; three copies of the gate are gone. The grip: `FrameWdgt.offersAResizeHandle` asks the attachment of
the figure the window really is, through the islands it is the sole content of (`_enclosingIslandFigure`), so a tilted
nested window hides its grip as an upright one does, and a tilted window on the desktop keeps it; an island re-homed
with a window inside re-asks its grip (`TransformFrameWdgt._reactToBeingAdded`, as the frame's own add does). The
measurement, on the product before this unit: every door read of the new test failed, under both pointers (the
window 252×249 → 252×311 after a menu row, 252×343 after a further turn). Corrections to the reading above: the
highlight was one trigger among many — any arrange of the window after the tilt grew it (a grip tap, a widget
carried over, a further turn, a resize); the island's FIRST placement measured its slot, every later arrange its
claim. One reference moved, predicted and accepted with the ruling: `SystemTest_macroIslandLensWindowHeightLock`
image_3, the window resized while wrapped now locked to the clock's own square (251×288) as the control image_1,
where it showed the claim's height with an empty band (251×365); recaptured, mouse and finger, dpr 1 and 2.
`SystemTest_macroWindowWhoseContentLeavesShowsItsDefaultContent` L11 tilted reads the outer window's extent with no
menu open again. Proof: `SystemTest_macroWindowKeepsItsSizeRoundATiltedContent` (seven legs, one door each, every
expected value the chrome read on the UPRIGHT fixture; the grip's visibility against the upright one's, with a
desktop twin) passes under both pointers with zero careless end-of-cycle pushes; six plants each fail their own legs;
the capstone, settle and revisit gates pass on it, its host and the lens test; followers clean. Filed (this plan's
BACKLOG section): an inert child added inside a tracking island re-lays every tracking ancestor; a tilted nested
window is not height-stretchable by its outer window's grip where an upright one is.

### U4c — "Pick up" on a tilted Maker's payload resets the Maker inside a settle

**Added by the owner 2026-11-21**, with U4b. **Time box 3 h.** Research first:
`Fizzygum-tests/.scratch/scroll-indicators-loop/u4c/`.

**The defect, as read (never played).** "Pick up" on the content of a tilted window extracts it from its island
through a DECLARED settle, not a settled one, so the window's removal seat (`FrameWdgt._reactToChildRemoved`, U2b's
one seat) runs outside any settle; for a Maker that seat resets it to a fresh payload, whose constructors then lay
the world out mid-reset. U2b's note: settling the extraction changes every tilted drag's cadence, so the fix's seat
is weighed against that.

**If parked:** filed, as U2b left it.

**Landed 2026-11-21.** `Widget._resolvePickUpFigure` settles the EXTRACTION: `figure ?= @_settleLayoutsAfter =>
@_pickOutRotatedFigureNoSettle()`. A genuine sub-part of a tilted figure is re-homed out of its attached holder inside a
settle of the resolution's own, so the holder's removal notification (a Maker's reset) builds inside it and each fresh
constructor defers its settle to that one; a reused figure's transform fold keeps its declaration (the claimsSpace
arc gave the declaration that reason, and the Bug-F ruling keeps one-shot structural mutations out of declarations).
The resolver that answers the standing figure or none is renamed to say so, `_resolvePickOutFigureNoSettle` →
`_resolveStandingFigureNoSettle` (the owner granted the inspector recapture the rename needs: an inspector's member
list shows it). The layering doc's second sanctioned settle shape names the pick-up's resolution; `layout.md` §2.3 states
that a declaration is no settle. Measured on the product before this unit: a tilted Docs Maker's "Pick up" ran 7
layout flushes inside the removal notification and the Maker shrank 600×400 → 52×129 (its fresh document 50×5),
the picked-up payload's window spec re-armed, the capstone blind (every mark declared). Correction to U2b's caveat:
settling the extraction changes the cadence of exactly the three tests that take that branch, not every tilted drag
(a census of every resolution in the suite, both pointers; settling the whole resolution showed no jump either). No
pixel moved. Proof: `SystemTest_macroTiltedMakerKeepsItsSizeWhenItsPayloadIsPickedUp` (L0–L4) failed exactly its
twelve door reads on the unfixed product, both pointers, and passes with zero careless end-of-cycle pushes; two plants
(the extraction declared again; a flush inside the notification) each trip exactly their reads; the capstone, settle
and revisit gates pass on it and the four tests whose cadence moves; followers clean. Filed (this plan's BACKLOG
section): a part picked out of a figure whose tilts cancel (a widget tilted −θ inside a panel tilted +θ) leaves an
empty orphan island alive — the extraction builds an identity island, and the dissolve skips it while it has no
parent (`Widget._dematerializeSugarIslandIfIdentityNoSettle`'s early return); the same before and after this unit.

### U4d — A window shows its content only inside its body

**Added by the owner 2026-11-21**, after U4b's options picture
(`Fizzygum-tests/.scratch/scroll-indicators-loop/u4b/options-tilted-content-in-a-window.png`: today, A, C, D, E, F at
15° and 45°). **Needs U4b CLOSED. Time box 3 h.** Research first: `Fizzygum-tests/.scratch/scroll-indicators-loop/u4d/`.

**The defect.** A window clips its content only at its own bounds, so a tilted content's ink paints over the window's
title and grip strips, over its own close and collapse buttons, and takes the clicks there. A window keeps its size
round a tilted content (U4b), so the overhang stays.

**The owner's ruling (option F; the options weighed for architecture fit).** The window shows its CONTENT only inside
its BODY, the box an upright content is given, and its chrome in place: the same per-child crop a viewport makes of
its plane (`ViewportWdgt.clipIntoPlaneOfChild`, U2's), which painting, damage and hit-testing all read, so a click on
the cut ink reaches the chrome. An upright content is exactly its body, so nothing upright changes. Weighed and set
aside: C (the window grows to the tilted footprint: against a window DICTATING its content's size, `layout.md` §4.3,
and possible only for a window on the desktop); D (the content shrinks until its footprint fits: FORBIDDEN by the
affine plan §4.9, the cyclic constraint); E (the picture scaled to fit: a container-imposed transform, against the
affine plan's per-widget knob; banked as a per-widget opt-in if ever wanted); A alone (the chrome stays covered).
Its cost: a tilted content's corners are cut where they cross the strips, its own controls included.

**The halo (the owner's ruling, after a picture at 15° and 45°).** A tilted window content's own halo is cut with it
where it crosses: a halo is the target's children, painted into its island (the affine plan's halo model), and every
clipping container already cuts a child's halo; a world-level halo was weighed and set aside (it re-does the in-plane
mapping by hand and paints a back widget's halo over the windows in front). Measured: the rotate handle stays
reachable at 15° and 45° (its centre included); at 45° the move and corner-resize handles cannot be pressed; and a
dragged-out content's halo is whole on the desktop. The content keeps its own halo handles (the owner chose this over
offering an upright content's none); their resize half works under its window's dictation, filed.

**If parked:** the overhang stays, filed.

**Landed 2026-11-21.** The per-child crop is ONE question every clipping widget answers,
`ClippingWdgt._clipThroughForChild` (pass-through by default; a viewport crops its plane to its plane box and
translates it, U2's answer under its role-neutral name; a window crops its content to the box it gives its content,
`FrameWdgt._clipThroughForChild`), reached by ONE climb, `ClippingWdgt.clipThroughForDescendant` (and its SLOW twin),
which `Widget.clipThrough`, its oracle and the island's two screen clips all take; FrameWdgt's two paint overrides are
deleted (ClippingWdgt's bodies paint a child through the hook). Two gaps a tilted content opened are closed: the
island's screen clip (`_ancestorScreenClip`) now climbs through every ancestor's crop, so U2's record that it "skips
the edge step (unreachable)" no longer holds; and a widget inside an island is hit only where the island SHOWS
(`Widget.isPointerTargetAt` tests the point, carried into the island's plane, against its `clippedThroughBounds`),
which also fixes a defect older than this plan: a tilted widget's hidden part took presses under any clip.
`FrameWdgt` 168 → 167 methods (its ceiling lowered); `Widget#clipThrough`'s complexity record (17) deleted, the
method now 7; no raise. Measured before the change: the new test's twelve reads failed under both pointers. The one
reference that moved, predicted and shown to the owner, who accepted it: `SystemTest_macroStretchChildHandleResizeSurvivesReflow`
(two shots, mouse and finger, dpr 1 and 2): in the "Plots and maps" dashboard's squeezed plot windows the function and
bar plots lose the x-axis they draw 13 px below their own box, and a 3D plot window squeezed below its own chrome (79
px against 89) shows no content; both causes filed. Proof: `SystemTest_macroWindowShowsItsContentOnlyInItsBody` (six
legs) passes under both pointers with zero careless end-of-cycle pushes; six plants each break their own reads; the
capstone, settle (cached-vs-SLOW armed) and revisit gates and the paint audit pass; followers clean. Corrections to the
reading above: no tilted reference moved (the predicted kind was wrong; one upright case moved), and the two reads
meant to compare an incremental paint with a whole one were removed (the crop cannot make them differ).

### U4e — A stretchable panel's arrange places a child whose spec owns its placement

**Added by the owner 2026-11-21**, from U4b's gauntlet. **Needs U4d CLOSED or PARKED.** Research first:
`Fizzygum-tests/.scratch/scroll-indicators-loop/u4e/`.

**The defect, as read (seen once, never reproduced).** In U4b's gauntlet the menu sweep, running beside eight other
legs, logged `LAYOUT_ERROR: … w.layoutSpec.grantedBoundsWithin is not a function` in a stretchable panel's arrange; it
passed on the serial retry, and four sweeps alone were clean (the log:
`Fizzygum-tests/.scratch/scroll-indicators-loop/u4b/menusweep-inwave-layout-error.log`). `StretchablePanelWdgt._reLayout`
(`src/authoring/StretchablePanelWdgt.coffee` ~:129-136) asks `_rememberFractionalSituationInHoldingPanel` for a stretch
record and then grants `w.layoutSpec.grantedBoundsWithin`; the recorder (`Widget.coffee` ~:2443) refuses a spec that
OWNS placement (a corner-armed piece, "the one owning kind a CONSUMING holder can host"), so the grant meets a spec with
no `grantedBoundsWithin`, and the throw aborts the panel's whole pass. The recorder's own comment says the arrange
places such a widget FROM its spec. To find: the door that puts an owning child in a stretchable panel, and why only
under load (a deterministic reproduction comes before any fix).

**Found by the research (read; phase 2 measures).** The door is "Test menu" → "Attach with horizontal layout" onto a
stretchable container, which hands its page the child with a division box; the throw is DETERMINISTIC, and only its
REPORT depends on load: a settle that throws stashes its error, and the `LAYOUT_ERROR` line is printed at the start of
the NEXT world cycle; the menu sweep does all its work in one synchronous page evaluate and closes the browser as soon
as it returns, so alone it never saw the line, and under a loaded wave its close was slow enough for a cycle to run.

**Widened by the owner (2026-11-21):** "Can you fix / improve the mechanism in this loop so that doesn't happen
again." So U4e also makes a caught error's report independent of any later cycle and of load — for the product's
stash-then-report and for every rig that closes after a synchronous evaluate — with a bite-proof that plants an error
just before a close and must see it, and with everything that turns red once errors are always reported fixed or
ruled in the same unit. **Time box 4 h.**

**If parked:** filed, with the log.

**Landed 2026-11-21.** The page: a consuming holder (the desktop, a stretchable page) consumes only FREE-FLOATING
children (`consumesFractionalGeometryOf` asks `isFreeFloating`), so a child whose spec owns its placement (a division
cell attached "with horizontal layout", a corner-armed piece) is placed by its own spec by the holder's arrange (a lone
cell fills the page); the recorder's now-unreachable `ownsPlacement` gate is deleted. Measured before: the menu sweep
ALONE threw the page's two layout errors on every run (its Duplicate's copy, through the container's and the page's
rows), unseen because the line came a cycle later; the new test failed 16 reads. The mechanism, three parts:
- **Every catch speaks at once.** A settle's, a paint's, a step's and an input event's catch each write their gated
  line where they catch (`LAYOUT_ERROR`, `PAINT_ERROR`, `STEP_ERROR`, `INPUT_ERROR`; one helper,
  `reportOfThrownValue`, gives the message and the stack on every engine; a paint report prints once per world,
  counted); before, a layout line waited a cycle and paint, step and input printed NONE (only the in-world console,
  which no runner reads). The in-world console stays deferred (it cannot be built inside a pass). The dataflow drain
  reports its stashed formula errors in its `finally`; the one silent SWCanvas catch speaks
  (`SWCANVAS_TEXT_BOOKKEEPING_FAILED`).
- **Every error reaches the test that caused it.** Every test prints start and end markers; one judge
  (`scripts/lib/gate-tokens.js` `caughtErrorsWindow`) files each line under the test whose window it falls in, in every
  runner (suite, single, sequence, paint audit), replacing the suite's polled "current test".
- **A test that throws on purpose declares it** (`expectsCaughtErrors` + `caughtErrorsReason`, validated like
  `pointerKinds`; `LAYOUT_ERROR` is never declarable): only its declared tokens are excused, in its own window, and a
  declared error that never comes fails. The four deliberate throwers declare theirs.
And a rig that drives the world in one synchronous evaluate runs a fixed two world cycles before it reads its verdict
and closes (`headless-driver.js` `cycledBeforeClose`: the menu and pin sweeps, the census, the graph rig, both
serialization rigs, the apps smoke), so whether a step or paint error OCCURS no longer depends on load either. The
bite-proofs plant CAUGHT errors (a settle throw and a throwing stepper in the menu sweep; the pin sweep, the census; the
suite gate's declared, stale and last-step cases, the last-step line filed under its own test with a test after it; the
single, sequence and paint-audit runners). With the closing cycles they prove a DETERMINISTIC report, not the catch's
own timing (a line deferred one cycle would reach them too). What the new reporting surfaced, across every suite and
rig: one hidden error, a detached `BouncerWdgt` stepped by the world (fixed: its step does nothing with no parent; the
world's stepping of detached widgets is filed). No pixel moved; no method added; `__reLayoutOneSettleNode` at its record.

---

### U5 — The spreadsheet's scroll is two pins

**Ruling:** O5, P6. **Time box 2 h.** No pixels.

**Fix.** Read `widget-authoring-guidelines.md` §11 (the pin-setter contract) first.
- `SimpleSpreadsheetWdgt.pins: -> super().concat [...]` with `new PinSpec "scroll column", "numerical", set:
  "setViewOriginCol", get: "getViewOriginCol", announces: true` and the `"scroll row"` twin.
- The setters are PUBLIC and self-settling like `scrolledBy`: round to an integer, commit an open edit first, then
  `_scrollByNoSettle` by the difference (its clamp is the clamp). They must mark the sheet synchronously (the pin
  sweep's rule).
- **One announcement, at the funnel every origin or range change passes.** `_scrollByNoSettle` covers the origin;
  a resize and a zoom change the range without touching it. Find the one place all of them reach (by reading,
  `_reconcileViewportNoSettle`: `_scrollByNoSettle`, `_reLayout`, the zoom, the restore and the constructor all end
  there) and announce there with `world.dataflow.markNonValueChange @`, then delete the zoom's own call if it is
  made redundant. Precedent for announcing inside an arrange: `ScrollIndicatorHostWdgt._reLayoutScrollbars`.
- `sliderRangeForPin: (pin)`: by label, U4's `_scrollRangeAlong` with whole columns or rows as its two arguments
  (`_viewportColsFull()`, `sheetCols`; the row twin), so the stop is the greatest origin and the size the shown
  share; undefined when everything fits.
- `Fizzygum-tests/scripts/pin-sweep-headless.js` `FIXTURES`: `'SimpleSpreadsheetWdgt.scroll column'` and
  `'…scroll row'`, each building a sheet and returning a value that really moves it (the default sheet shows 5 × 10
  of 26 × 100).

**Tests.** New `SystemTest_macroSheetScrollPins` (values): a slider on the desk bound to a sheet with
`slider.trackTarget sheet, "setViewOriginRow"`: dragging it moves the origin by whole rows and its thumb rests where
the sheet answers; a wheel over the sheet moves the slider; an edit open in a cell is committed by a pin-driven
scroll; at the last row the setter clamps. Plants: the announcement removed (the slider stops following); the
range answer removed (the bind refuses).
Check the predicted set by grep: a test whose screenshot shows a connection menu ON a sheet would gain two rows
(none found by the research's reading; confirm).

**Predicted pixel set:** EMPTY.

**If parked:** U6 parks with it.

---

### U6 — The spreadsheet presents its scroll indicators

**Ruling:** O5, P5. **Needs U4 and U5 CLOSED. Time box 4 h.**

**Target look.** Review page §C, "Mock, inset 1, ends 3", with one correction the mock could not show: the sheet
paints a 1 px page edge over its children, so by U1's rule its thin bars stand 2 px in (1 clear of that line).

**Fix.**
- `class SimpleSpreadsheetWdgt extends ScrollIndicatorHostWdgt`; it answers the base's hooks: the run box is the data
  region (§2.6); an axis overflows while `sheetCols > _viewportColsFull()` (the row twin); the bars drive
  `"setViewOriginCol"` and `"setViewOriginRow"`. `SheetAppearance` answers `outlineIsStroked: -> true`.
- The two bars are built by the base's builder from `_buildChromeNoSettle`, only `unless @vBar?`, AFTER the cells
  panel (they lie over the data region; later header cells do not overlap them). Watch that function's complexity
  (13 of 15): the build belongs in the base's builder, one guarded call here.
- The base's bar arrange runs from the same places the chrome is placed: the `_reLayout` arrange and after a
  scroll or a zoom (U5's funnel is the natural seat; one call, not three).
- **Restore and copy: ADOPT.** `_reindexCellsNoSettle`'s sweep exempts the two bars (`@isMyScrollBar child`), their
  fields ride the file, and nothing builds a slider inside the two notifications. The tracking edges of a joined
  subtree are re-declared by the generic path (`Widget` ~:3915, `_ensureTrackingEdges`).
- **A click on a bar selects no cell.** The sheet's `activated` receives a track click's escalation. Decide by a
  failing test first: the smallest true guard is the sheet ignoring an `activated` whose pointer is over one of its
  bars; a viewport needs none because its own `activated` does nothing with a position.
- `Fizzygum-tests/scripts/serialization-roundtrip-headless.js`: `chromeCount` gains the two bars in
  `spreadsheet.roundtrip.grid` and `…midEditClean`; add `spreadsheet.roundtrip.scrollBarsFollow` (a restored and a
  duplicated sheet each hold exactly two bars, wired to it, whose values equal its origin after a scroll), with its
  `EXPECTATIONS` line.

**Tests.** New `SystemTest_macroSheetScrollIndicators`, both pointers: at rest both thin bars show over the data
region and not over the frozen headers; a wheel moves the vertical thumb; the pointer in the band fattens both; a
thumb drag scrolls by whole rows; a track press pages and selects no cell; a sheet that shows everything (made
large) shows none; zoomed, the bars keep their width. Plants, one per door: the overflow answer; the run box; the
adoption (bars destroyed by the sweep); the click guard.

**Predicted pixel set.** Every shot with a sheet's data region in frame: at most the 29 spreadsheet tests that take
screenshots (`research/forecast/sheet-tests.txt` lists the 37 that name a sheet class with their shot counts;
`DesktopShortcutIcons` builds no grid), plus any document test hosting a sheet. In each the only change is two thin
thumbs at the data region's right and bottom edges. Measure, and explain every test outside the list.

**Docs.** `src/spreadsheet/CLAUDE.md`: "F1 decisions" (the indicators are no longer banked: say what the sheet
answers and that it is still not a viewport), the class list entry, and two facts the research found false there
(a fresh sheet is 5 × 10, not 6 × 14; the least extent is one cell plus the headers and the formula bar, not
102 × 40). The class header (~:41). `viewports-and-planes.md`: the second user of the base. BACKLOG's "finger
scrolling for the spreadsheet" stays open (a drag-scroll), reworded only if it has become false.

---

### U7 — Close

Every unit CLOSED or PARKED. `git mv` this plan to `docs/archive/`, stamp its status, add its `INDEX.md` line, move
its closed BACKLOG lines into its ledger (README rules 2 and 5), leave the open ones under its section. Update the
loop's memory note. **Time box 1 h.**

## 5. Central risks

- **The crop is in the clip machinery** (U2): two paint bodies and two lockstep twins. Guards: dormant by
  construction (padding 0 hands the same objects through), the cache oracle, the paint audit, and U2 landing with
  an EMPTY predicted set before anything uses it.
- **"Pixel-identical but for the bar" is a measurement at dpr 1 on four scenes** (U3). Dpr 2, WebKit and the finger
  suite are the gauntlet's; a difference there that is not the bar is a finding.
- **A selected page's ring and its thumb share one pixel column** (P3). The owner has seen the picture (review page
  §M, "Page selected, scrolled").
- **A document saved before this plan** restores its bounds as saved and re-lays nothing until something re-lays
  it (an open BACKLOG observation of the gutter plan): a loaded old document may show its old geometry until then.
  Not this plan's to fix; note it if a test meets it.
- **The lift can move a `super`** (U4): prove it with the resolution map, not the suite.
- **Bars inside a sheet are children the sheet's code does not expect**: the sweep, the child counts of the
  serialization rig, a click's escalation, paint order. Each is named in U6; find the fifth by reading every
  `@children` walk in the class.
- **Time**: U3 and U6 are the long ones. A unit that has not reached its gauntlet inside its box PARKS.

## 6. Verification protocol

Per unit, in this order (the BRIEF's §2 has the full cycle): `fg build` after each step; the new test and each
plant's bite under both pointers; the follower; `fg presuite` and the dpr 1 finger suite; failing set equal to the
predicted set; `fg diffpage <names> --dprs=1,2`, every changed shot LOOKED at against the review page; `fg
recapture --auto --dprs=1,2` then `--pointer=finger`; docs; `node Fizzygum/buildSystem/check-doc-narration.js`; the
review agent; `fg gauntlet`. U4 adds the resolution-map diff. U5 and U6 add `fg pinsweep` and both serialization
rigs to what is read before the gauntlet (they are gauntlet legs too).

## 7. Rejected alternatives (do not re-attempt)

- **The document flush, with a docked band keeping `dockedBandInset` toward the payload** (the first variant the
  owner approved from pictures). At rest the first paragraph stands 16 px below the toolbar (measured: probe variant
  `proposal`, review page §M's third card); the suite plant moved 25 document tests at rest
  (`research/forecast/forecast-B-doc-only.tests.txt`) against the margin design's 16 that move only a bar. The band
  rule itself touched one test (`SystemTest_macroDockAnyFrame`) and is not needed by anything in this plan.
- **The document flush with no gap** (review page §B1): scrolled content is cut at the toolbar's edge. Owner-rejected
  (O3).
- **The ring at the viewport's own box for a document**: it lies against the window's border, the look the gutter
  arc removed (§1). It remains the right answer for a viewport with no margin (a plain panel).
- **The bar drawn in the window's gutter by the window** (review page §B2): the bars are the viewport's children
  and the whole indicator derivation would have to exist twice, or the viewport's children would paint outside its
  bounds, breaking what a clipping widget is.
- **A framed document** (review page §B3: the document paints its page edge and insets its items): the bar is still
  11 px from the window's edge.
- **Per-side insets** (the document's top inset yielding to a gap under the toolbar): a vertical stack's and a
  viewport's padding are one number at twelve and six sites, and the ring would need two painters.
- **Moving the thumb while a ring shows**: selection would feed layout (P3).
- **An indicator-presenting collaborator object** instead of a base class (P4).
- **The sheet as a `ViewportWdgt`**: F1's decision stands (frozen headers, whole-cell steps, the virtualised cells).
- **Recapturing a change of `outlineIsStroked` on a selected bordered rectangle** (U1): give the border question its
  own name instead.

## 8. References

- `docs/architecture/viewports-and-planes.md`, `visual-design-system.md` §4.10 and §5, `regularity-principles.md`
  "The frame model", `widget-authoring-guidelines.md` §11 and §16, `lint-and-static-checks.md`.
- `docs/archive/window-page-gutter-plan.md` (the rulings §1 quotes; its §7), `docs/archive/frames-input-touch-program.md`
  (ruling G4), `docs/archive/paint-time-scroll-translation-plan.md` (the clip-through translation edge),
  `src/spreadsheet/CLAUDE.md`.
- `Fizzygum-tests/.scratch/scrollbar-placement/` (review page, probe) and
  `Fizzygum-tests/.scratch/scroll-indicators-loop/` (BRIEF, LEDGER, research).

## Start prompt for a fresh session

The loop's prompt is `Fizzygum-tests/.scratch/scroll-indicators-loop/LOOP-PROMPT.md`. To run one unit by hand
instead: "Read `/Users/davidedellacasa/code/Fizzygum-all/Fizzygum-tests/.scratch/scroll-indicators-loop/BRIEF.md`,
then `Fizzygum/docs/plans/scroll-indicators-plan.md`; run `fg status`; execute unit U<N> by the BRIEF's cycle and
stop at its commit, which you propose and do not make."

## BACKLOG ledger (closed items, moved from docs/BACKLOG.md)

- [x] U1: a thin scroll indicator stands 2 px inside its viewport's edge whatever is there, and touches both ends of its side; it is to stand 1 px clear of the line at that edge and 3 px short of each end. — CLOSED 2026-11-20 (scroll-indicators loop, U1): the inset across is derived (the theme's clearance, plus the border where the viewport's appearance strokes one: `outlineIsStroked`), the end inset comes off both ends of the run of a thin bar the viewport presents, and the bars follow a re-parenting; `SystemTest_macroThinIndicatorStandsClearOfItsEdge`.
- [x] U1b: `Widget.pickUp` runs its parent's `_beforeChildPickedUp` outside any settle, so a window whose content is picked up (the "Pick up" row) rebuilds its payload as a careless end-of-cycle push and no test can take a pane out of its window; it is to settle both its callbacks. — CLOSED 2026-11-20 (scroll-indicators loop, U1b): `pickUp` opens a settle round the before-hook, as `grab` does round `_beforeBeingGrabbed`; a Docs Maker's document no longer comes away 66 px taller; `SystemTest_macroPanePickedUpOffItsWindowKeepsItsSize`, and the way out restored in `SystemTest_macroThinIndicatorStandsClearOfItsEdge`.
- [x] U2: a viewport's `padding` ("around the scrollable area") is read in six places and crops nothing; it is to be a margin the plane shows inside. A mechanism, dormant until U3. — CLOSED 2026-11-20 (scroll-indicators loop, U2): the field is `planeMargin`; the plane is cropped to `_planeBox` in both paint bodies and at the clip-through edge (`clipIntoPlaneOfChild`), the thin bars run along the plane box, a drop in the margin goes to the plane; dormant (nothing gives a viewport a margin); `SystemTest_macroViewportMarginCropsItsPlane`.
- [x] **A window's content moved out by "Attach" stays its `@contents`** — `FrameWdgt._reactToChildRemoved` frees dock slots but keeps the pointer (only pick-up, destroy and close rebuild), so the window's arrange moves the departed widget back (read; dev menu: the content's row → Attach → Desktop; H3d) — reachable, low. — CLOSED 2026-11-20 (scroll-indicators loop, U2b; filed under `archive/editing-residue-plan.md`): the window shows its default content in `_reactToChildRemoved`, the one seat every door reaches; `SystemTest_macroWindowWhoseContentLeavesShowsItsDefaultContent`.
- [x] A Maker whose payload leaves it (the "Pick up" row; by reading "Destroy" too, any Maker kind) shrinks to its fresh payload: a Docs Maker goes 600×400 to 68×211 (measured), though `MakerDocumentWdgt._resetToDefaultContents` says its extent stays put. Reachable, medium. Detail: the plan's §U1b. — CLOSED 2026-11-20 (scroll-indicators loop, U2b): the Maker's reset captures the fresh payload's placement, and keeps its mode; `SystemTest_macroWindowWhoseContentLeavesShowsItsDefaultContent`.
- [x] U3: a document's scroll indicator lies 11 px from its window's edge, over its items' right edge; the document is to keep its 8 px as its viewport's margin, and a viewport is to paint its plane's selection ring. — CLOSED 2026-11-21 (scroll-indicators loop, U3): the document is a pane keeping `documentItemSpacing` as its `planeMargin`, bare or windowed; a viewport hosts and paints its plane's ring; a margin click selects the page; `SystemTest_macroDocumentKeepsItsMargin`, `SystemTest_macroViewportPaintsItsPlanesRing`.
- [x] U4: the scroll-indicator presentation lives in `ViewportWdgt` alone; it is to move to a base class both scrollers extend, pixel-neutral. — CLOSED 2026-11-21 (scroll-indicators loop, U4): `ScrollIndicatorHostWdgt extends ClippingWdgt` holds it, `ViewportWdgt` extends it and answers two hooks and the builder's two actions; proven by the resolution map and a statics probe; no pixel moved.
- [x] U4b: a tilted window content's window grows to the content's footprint at its next arrange (a hover highlight, a grip resize; measured 249 → 311 px tall); a window is to keep its size. Added to the loop by the owner. — CLOSED 2026-11-21 (scroll-indicators loop, U4b): an island claims space only from an asking container; as a window's content it forwards to its content in every mode, and a tilted nested window hides its grip as an upright one; `SystemTest_macroWindowKeepsItsSizeRoundATiltedContent`.
- [x] U4c: "Pick up" on the payload of a TILTED Maker would run the Maker's reset outside a settle (the extraction is declared, not settled), so its payload's constructors lay the world out mid-reset. Read, unplayed. Added to the loop by the owner. — CLOSED 2026-11-21 (scroll-indicators loop, U4c): the pick-up's resolution settles the extraction (measured before: the Maker 600×400 → 52×129); the reuse branch keeps its declaration; `SystemTest_macroTiltedMakerKeepsItsSizeWhenItsPayloadIsPickedUp`.
- [x] U4d: a window clips its content only at its own bounds, so a tilted content's ink covers the window's title and grip strips and takes their clicks; the window is to show its content only inside its body (owner's ruling). Detail: the plan's §U4d. — CLOSED 2026-11-21 (scroll-indicators loop, U4d): one per-child crop question on `ClippingWdgt`, answered by the viewport (its plane box) and the window (the box it gives its content), one climb for every clip-through; a hit inside an island lands only where the island shows; `SystemTest_macroWindowShowsItsContentOnlyInItsBody`.
- [x] U4e: a stretchable panel's arrange throws (`grantedBoundsWithin is not a function`) on a child whose spec owns its placement: the recorder refuses such a spec, the grant assumes a stretch one. Seen once, in a gauntlet's menu sweep under load. Added to the loop by the owner. Detail: the plan's §U4e. — CLOSED 2026-11-21 (scroll-indicators loop, U4e; widened by the owner to the mechanism): a consuming holder consumes only free-floating children; every catch prints its line at once, filed under the test that caused it, a deliberate thrower declares it, and a synchronous rig cycles the world before its verdict; `SystemTest_macroStretchablePagePlacesAChildByItsOwnSpec`.

## BACKLOG detail (open items, moved from docs/BACKLOG.md)

(none yet)
