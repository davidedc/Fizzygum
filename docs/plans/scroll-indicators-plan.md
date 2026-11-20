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
| U3 | The document keeps its margin itself; a viewport paints its plane's selection ring | open (§U3) |
| U4 | The indicator presentation gets a home both scrollers extend (a lift, pixel-neutral) | open (§U4) |
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
U1 → U1b → U2 → U3 → U4 → U5 → U6 → U7. U1b needs U1 alone (it restores a step of U1's test) and nothing after
it needs it; it stands before U3 so that a document's way out of its window can be played in a test. U2 edits
`_barFrameAt` after U1 did. U3 needs U2's mechanism. U4 lifts what U1–U3
left (if U2 or U3 PARKED, U4 lifts the code as it stands). U5 is independent of U1–U3 but uses U4's shared range
helper. U6 needs U4 and U5.

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
  made redundant. Precedent for announcing inside an arrange: `ViewportWdgt._reLayoutScrollbars`.
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

## BACKLOG detail (open items, moved from docs/BACKLOG.md)

(none yet)
