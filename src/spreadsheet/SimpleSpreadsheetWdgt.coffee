# SimpleSpreadsheetWdgt — the spreadsheet's grid (spec docs/specs/dataflow-engine-spec.md §9.1; Phase 8
# "widgetise the grid" + follow-on F5 "the sheet paints NOTHING"). Every visible thing is a real
# child widget: the data cells (CellWdgt, one per cell of the viewport — 6×14 at the default
# open size, DERIVED from the sheet's extent since F6: a bigger window shows more cells, the
# last column/row possibly partial — each the
# VIEW of its SheetCellRecord) live inside a SheetCellsPanelWdgt whose fill is the data-region
# background; the 21 header cells (SheetHeaderCellWdgt: column letters, row numbers, the corner)
# are direct children, kept OUTSIDE the panel so a future scroll clip can never touch the frozen
# headers. Each widget paints its own fill, its own TOP+LEFT grid edges (edge-ownership + the
# crossing rule — see paintGridEdges), its own label/value, and — the selected cell — its own
# selection ring. This widget has NO paint of its own (nil appearance): it is the model owner,
# the formula scope, the keyboard receiver, and the geometry authority (the constants below).
#
# Widgetising is owner direction (2026-07-05 cells; 2026-07-17 headers + chrome — plan §3-F F5,
# with the byte-identity receipts): full Fizzygum composability — everything the user sees is a
# real, inspectable, live-editable widget, not a paint artifact. Widget count is bounded by the
# VIEWPORT, not the sparse model (an off-screen cell — Z99 in a formula — is still a live
# dataflow node whose record recomputes with NO widget; scroll — F1 — materialises/recycles
# the viewport's widgets, hiding-not-destroying the widget-VALUED ones). The dataflow layer
# operates on RECORDS, never widgets, so correctness is independent of what is materialised.
#
# The data lives in @model (a SheetModel, sparse Map keyed "A1"); each cell is a SheetCellRecord
# — a dataflow NODE. Committing an edit compiles the source once (FormulaCompiler) and marks the
# cell stale (world.dataflow.markStale); the once-per-cycle dataflow drain then recomputes it and
# the cell's CellWdgt repaints — the engine's FIRST live client. This widget is also the formula SCOPE
# (`@` inside a formula is this SimpleSpreadsheetWdgt: full world access, no sandbox — spec §9.2).
#
# SCOPE + DEVIATIONS (recorded in the plan's Phase-2a/2b/8 + §3-F F1/F6 notes):
#   - SCROLL (F1) + RESIZE (F6): the LOGICAL sheet (sheetCols×sheetRows, 26×100) is larger
#     than the viewport (DERIVED from the sheet's extent since F6 — default 6×14, partial
#     edge cells when the granted extent isn't cell-quantized, backdrop past the sheet edge);
#     the sheet owns its view origin (viewOriginCol/Row — cell-quantized, never
#     sub-cell) and scrolls by WHEEL (the `wheel` entry below, with the ScrollPanelWdgt-style
#     at-limit escalation) and by KEYBOARD scroll-follow (arrows past the viewport edge shift
#     the origin minimally). Deliberately NOT a ScrollPanelWdgt: frozen headers, the origin-0
#     byte-identity constraint (an unscrolled sheet renders pixel-for-pixel as pre-F1), and
#     cell-quantized steps don't fit its pixel model; scrollbar/indicator chrome stays banked.
#     THE VIEWPORT INVARIANT (maintained by _reconcileViewportNoSettle, re-established on
#     restore whatever mix the snapshot carried): exactly one VISIBLE CellWdgt per on-screen
#     address, at the viewport rect of (address − origin); exactly one HIDDEN CellWdgt per
#     OFF-screen widget-VALUED cell (the hidden-rich-cell exemption — its hosted widget keeps
#     riding the tree so its runtime state survives save/load, spec §13 retain-and-remount
#     extended to scroll); nothing else. @_cells indexes both. An in-progress edit COMMITS
#     before any scroll (the click-away-commits precedent), so the overlay editor never has to
#     move mid-edit.
#   - Cell text is 12px Arial (SWCanvas ships Arial/Times/Courier atlases only —
#     src/boot/extensions/SWCanvasElement-extensions.coffee), left-aligned; centring is later polish.
#     Each CellWdgt now clips to its own rect, so an over-long value no longer bleeds sideways.
#   - EDITING (2b) drives a plain edit BUFFER from this widget's own processKeyDown (append /
#     Backspace / Enter-commits / Escape-cancels) and mirrors it into a live overlay StringWdgt over
#     the editing cell. This is a deliberate deviation from reusing the caret: the framework provides
#     NO built-in "Enter commits / Escape reverts" (no accept/cancel handlers exist; text live-updates
#     as you type), and a live caret is a keyboard receiver that BLINKS (non-deterministic under a
#     screenshot). The buffer gives exact, deterministic commit/cancel and keeps THIS widget the sole
#     keyboard receiver throughout (no caret juggling). Rich editing (cursor, selection, multi-line)
#     stays the deferred CodePromptWdgt path (spec §9.1). The editor WIDGET lives on the editing
#     CellWdgt (F2, executed with F5): this sheet keeps the buffer + the keys and delegates
#     mount/update/teardown to the cell, which suppresses its own scalar text while it holds one.
#
# Keyboard selection + editing use the standard receiver path (world.keyboardEventsReceivers +
# processKeyDown), focus-on-click; never a DOM listener.

class SimpleSpreadsheetWdgt extends Widget

  # F6: the sheet CLIPS at its bounds — ONE clip for everything. Partial edge cells stick
  # past the cells panel's right/bottom edge and the panel's own clip crops them; but
  # partial-column/row HEADERS are direct sheet children OUTSIDE the panel (frozen), and
  # without a sheet-level clip they would paint past the sheet's edge into the window. At
  # the default size the clip crops nothing (chrome + cells tile the sheet rect exactly) —
  # byte-identity proven by the whole pre-F6 suite, not argued.
  @augmentWith ClippingAtRectangularBoundsMixin, @name

  # transient UI state (rebuilt by interaction or from the tree, never document data): the
  # in-progress edit is dropped from a snapshot (a mid-edit save restores to a settled,
  # not-editing sheet; the editor WIDGET lives on the editing cell, whose re-index sweep drops
  # it). The cell INDEX (@_cells: address → CellWdgt) and the CHROME handles (@_cellsPanel, the
  # @_headerCells map) are transient too — but note the widgets themselves are ordinary children
  # and DO ride the tree: a widget-valued cell's live widget (a dragged slider's position)
  # survives save/load (spec §13 retain-and-remount), while the CHROME (panel + header cells) is
  # DERIVED and is destroyed + rebuilt from the geometry constants on restore. On restore the
  # index is rebuilt from the snapshot's cells (_reindexCellsNoSettle → _recommitAllCells →
  # drain → reconcile): a DERIVED presenter (a Color's swatch, spec §9.4 "one-way glass") is
  # rebuilt from the value, a scalar repaints, a state-bearing value-widget is RETAINED.
  # @model / @selected* ARE document state and serialize normally.
  @serializationTransients: ["_editing", "_editBuffer", "_editCol", "_editRow", "_cells", "_cellsPanel", "_headerCells"]

  # fixed grid geometry (no column resize in v1). The VIEWPORT — how many cell widgets are
  # materialised + visible at once — is DERIVED from the sheet's applied extent (F6, the
  # _viewportCols/Rows* derivations below): a bigger window shows MORE of the sheet, the last
  # visible column/row possibly PARTIAL (clipped). defaultViewportCols/Rows only size the
  # DEFAULT fresh-sheet extent (_defaultExtent — the exact 6×14 grid, the pre-F6 fixed
  # viewport, preserved byte-for-byte as the open size). sheetCols/sheetRows are the LOGICAL
  # sheet the viewport scrolls over (F1 — still far under the address grammar's ZZ9999
  # ceiling).
  headerColWidth: 34     # the left row-number header column
  headerRowHeight: 20    # the top column-letter header row
  colWidth: 68
  rowHeight: 20
  defaultViewportCols: 6   # the default open size's viewport columns…
  defaultViewportRows: 14  # …and rows (⇒ the 442×300 default content extent)
  sheetCols: 26          # logical columns A..Z
  sheetRows: 100         # logical rows 1..100

  # the view origin (F1): the sheet-space col/row of the viewport's top-left cell. PROTOTYPE
  # defaults, own-only-when-scrolled (the 6a idiom): an unscrolled sheet serializes byte-for-byte
  # as before F1, and a pre-F1 snapshot deserializes to origin 0 through the prototype (the
  # deserialize path skips the constructor). DOCUMENT state — a saved scrolled sheet restores
  # scrolled — so deliberately NOT in @serializationTransients.
  viewOriginCol: 0
  viewOriginRow: 0

  constructor: ->
    super()
    # selection is a single cell (0-based col/row); v1 always has one selected
    @selectedCol = 0
    @selectedRow = 0
    # the sparse data model — this widget owns it and is its formula scope (see FormulaCompiler)
    @model = new SheetModel @
    # colours (immutable + LRU-cached via Color.create; computed once here, never at class
    # scope — class-level Color statics would run at class-definition time, before Color loads).
    # The child widgets read these — the sheet itself paints nothing (F5), and the data region
    # has NO background of its own (the cells panel is transparent too): the backdrop under
    # the sheet shows through, exactly as it always did.
    @headerFillColor = Color.create 236, 236, 236
    @gridlineColor = Color.create 198, 198, 198
    @headerBorderColor = Color.create 150, 150, 150
    @headerTextColor = Color.create 90, 90, 90
    @selectionColor = Color.create 40, 110, 210
    @valueTextColor = Color.create 30, 30, 30
    @errorTextColor = Color.create 200, 40, 40
    # editing state (the buffer + which cell; the editor WIDGET lives on the editing cell —
    # F2/F5); nil / false until an edit begins
    @_editing = false
    @_editBuffer = ""
    @_editCol = nil
    @_editRow = nil
    # cell index (spec §9.3/§9.4 classify→present): address → its CellWdgt. Every VISIBLE cell has one
    # (the viewport, materialised by _reconcileViewportNoSettle below — plus one HIDDEN one per
    # off-viewport widget-VALUED cell, F1); each renders its own value —
    # a hosted value-widget (branch 1) / presenter (branch 2) / painted scalar text (branch 3). TRANSIENT
    # (the CellWdgts themselves ride the tree as children; this index is rebuilt from them on restore by
    # _reindexCellsNoSettle, and the drain reconciles each — see _reconcileCellNoSettle).
    @_cells = new Map
    # chrome handles (F5): the data-cells container and the header-cell index ("kind:index" →
    # SheetHeaderCellWdgt). TRANSIENT + DERIVED: destroyed and rebuilt from the geometry
    # constants on restore (_reindexCellsNoSettle), never adopted from a snapshot.
    @_cellsPanel = nil
    @_headerCells = new Map
    # headers + one cell — the smallest extent at which the viewport derivations still answer
    # a 1×1 viewport (F6; the __commitExtent leaf enforces this floor on every commit). An
    # OWN field, set after super: the Widget constructor sets its own 5,5, so a prototype
    # default here would be shadowed. (A pre-F6 snapshot restores its saved 5,5 — harmless:
    # the derivations' Math.max 1 floor degrades gracefully below one cell.)
    @minimumExtent = new Point (@headerColWidth + @colWidth), (@headerRowHeight + @rowHeight)
    @_applyExtent @_defaultExtent()
    # materialise the widget chrome, then the viewport's grid of cell widgets (NoSettle: the
    # enclosing openFrameWith settles once — the DegreesConverterApp orphan-construction idiom;
    # a deserialize/duplicate skips the constructor and restores/copies the cells instead, which
    # _reindexCellsNoSettle then adopts through the same two calls — no double grid).
    @_buildChromeNoSettle()
    @_reconcileViewportNoSettle()
    return

  colloquialName: -> "spreadsheet"

  # FILL-class window content (F6 — this DELETED the pre-F6 fixed-size overrides: the
  # initialiseDefaultFrameContentLayoutSpec grow-0/height-frozen flip, the fixed
  # preferredExtentForWidth and _setWidthSizeHeightAccordingly, and _gridWidth/_gridHeight).
  # The sheet now takes whatever extent the window grants — the default
  # FrameContentLayoutSpec is already grow 1 + canSetHeightFreely true, and the BASE Widget
  # protocol is exactly the fill-content protocol (V1): _setWidthSizeHeightAccordingly
  # applies the granted width and hands the height back, _applyHeight grants the free height,
  # preferredExtent answers the applied extent (which feeds the first-placement window hug
  # with _defaultExtent below). The viewport DERIVES from that extent; a resize re-derives
  # chrome + viewport in _reLayout below. The default open size is pinned by SpreadsheetApp
  # (V4: window 452×336 − 36 chrome = 442×300 content, the exact 6×14 grid — the whole
  # pre-F6 reference set renders byte-identically). The pre-F6 AnalogClockWdgt fixed-size
  # pattern (chosen in Phase 2a for one-cycle settle determinism) is retired: the arrange
  # below is idempotent and settles in the same one pass.

  # the DEFAULT (fresh-sheet) extent: the exact default grid — the construction extent, and
  # what the first-placement window hug reads back through the base preferredExtent.
  _defaultExtent: ->
    new Point (@headerColWidth + @defaultViewportCols * @colWidth),
      (@headerRowHeight + @defaultViewportRows * @rowHeight)

  # ── F6: the viewport DERIVES from the applied extent — never stored ──────────────────────
  # TWO derivation pairs; every consumer routes to the right one:
  #   PARTIAL (ceil) — a partially-visible column/row counts as ON-SCREEN. Consumers:
  #     viewport MEMBERSHIP (the reconcile) and — via the origin-clamped _visibleCols/Rows
  #     below — the materialise loops, the header-chrome build/trim, and the hit-test.
  #   FULL (floor) — only WHOLE columns/rows count. Consumers: the SCROLL CLAMPS
  #     (_scrollByNoSettle), the wheel at-limit conditions, and scroll-follow
  #     (_scrollToShowSelectionNoSettle: the selection must end up FULLY visible, so the
  #     overlay editor never mounts on a clipped cell). At the max origin every remaining
  #     column is fully visible and residual pixels show BACKDROP (owner decision 2).
  # At the default size ceil == floor == 6/14 exactly (no residual pixels), so every
  # derivation answers the retired constants and the default render is byte-identical.
  # PURITY: these read APPLIED geometry (@width()/@height()) — legal at their call sites
  # (reconcile/clamps/arrange run after the extent is committed); they must never feed a
  # pure measure (preferredExtentForWidth stays the untouched base).
  _viewportColsPartial: -> Math.max 1, Math.min @sheetCols, Math.ceil((@width() - @headerColWidth) / @colWidth)
  _viewportRowsPartial: -> Math.max 1, Math.min @sheetRows, Math.ceil((@height() - @headerRowHeight) / @rowHeight)
  _viewportColsFull: -> Math.max 1, Math.min @sheetCols, Math.floor((@width() - @headerColWidth) / @colWidth)
  _viewportRowsFull: -> Math.max 1, Math.min @sheetRows, Math.floor((@height() - @headerRowHeight) / @rowHeight)

  # the partial viewport clamped to the LOGICAL REMAINDER at the current origin — the bound
  # the header build, the materialise loops and the hit-test share. Without the clamp, at the
  # max origin with residual pixels (there partial == full + 1) the partial count would
  # address a column/row PAST the sheet edge — those pixels are backdrop, not a 27th column.
  # (Found at implementation — recorded as an F6 landing deviation in the plan. For the
  # reconcile's pass-1 MEMBERSHIP test the clamp is a no-op — an indexed cell's address is
  # inside the logical sheet by construction — so one bound serves both passes.)
  _visibleCols: -> Math.min @_viewportColsPartial(), @sheetCols - @viewOriginCol
  _visibleRows: -> Math.min @_viewportRowsPartial(), @sheetRows - @viewOriginRow

  # ── the widgetised grid: panel + headers + one CellWdgt per visible cell (Phase 8 + F5/F1) ───

  # Materialise + RE-DERIVE the sheet's WIDGET CHROME from the current frame: the
  # SheetCellsPanelWdgt spanning the data region (extent follows the sheet's, F6) and one
  # SheetHeaderCellWdgt per VISIBLE column/row + the corner (direct children, OUTSIDE the
  # panel so the panel's scroll clip never touches the frozen headers). Headers are keyed by
  # viewport SLOT ("kind:index" — their LABELS derive from origin+slot at paint time, so a
  # scroll relabels them in place, F1; cell-quantized scroll means they never move). The
  # header COUNT is _visibleCols/Rows (F6): a resize builds/destroys the difference, and near
  # the sheet edge the count is ORIGIN-dependent too (no header over backdrop) — hence
  # _scrollByNoSettle re-runs this. Every piece is (re)PLACED absolutely from @position()
  # each pass (the _apply* equal-guards make the steady state free), which is what lets the
  # F6 _reLayout below subsume float-follow. Also re-homes every already-indexed cell into
  # the (fresh) panel — on the restore path the adopted cells (visible AND hidden rich, F1)
  # hang as direct children after the rescue, and the old panel is gone. The CELLS themselves
  # are materialised by _reconcileViewportNoSettle (F1 split this out of the old
  # _buildGridNoSettle: cells follow the view origin, chrome doesn't). IDEMPOTENT: every
  # piece is keyed (panel field / "kind:index") and only built when missing — never a double
  # grid. NoSettle: runs from the constructor before the sheet is placed (the enclosing
  # openFrameWith owns the one settle), inside the re-index's enclosing settle on
  # restore/duplicate, inside scroll's settle, and from the _reLayout arrange.
  _buildChromeNoSettle: ->
    unless @_cellsPanel?
      panel = new SheetCellsPanelWdgt
      @_addNoSettle panel
      @_cellsPanel = panel
    # the data region spans from the headers to my bottom-right corner (F6 — pre-F6 this was
    # the fixed grid size, set once at build)
    @_cellsPanel._applyExtent new Point (@width() - @headerColWidth), (@height() - @headerRowHeight)
    @_cellsPanel._applyMoveTo @position().add new Point @headerColWidth, @headerRowHeight
    @_cells.forEach (cell) =>
      @_cellsPanel._addNoSettle cell unless cell.parent is @_cellsPanel
    buildHeader = (kind, index, x, y, w, h) =>
      key = kind + ":" + (index ? "")
      unless @_headerCells.has key
        header = new SheetHeaderCellWdgt kind, index
        header.attachSheet this
        @_addNoSettle header
        @_headerCells.set key, header
      header = @_headerCells.get key
      header._applyExtent new Point w, h
      header._applyMoveTo @position().add new Point x, y
      return
    visibleCols = @_visibleCols()
    visibleRows = @_visibleRows()
    buildHeader "corner", nil, 0, 0, @headerColWidth, @headerRowHeight
    col = 0
    while col < visibleCols
      buildHeader "column", col, (@headerColWidth + col * @colWidth), 0, @colWidth, @headerRowHeight
      col += 1
    row = 0
    while row < visibleRows
      buildHeader "row", row, 0, (@headerRowHeight + row * @rowHeight), @headerColWidth, @rowHeight
      row += 1
    # TRIM (F6): headers beyond the current viewport (the window shrank, or the origin
    # reached the sheet edge and the ex-partial slot is backdrop now) are DERIVED chrome —
    # destroy them; a later grow rebuilds by key.
    @_headerCells.forEach (header, key) =>
      [kind, indexText] = key.split ":"
      index = parseInt indexText, 10
      if (kind is "column" and index >= visibleCols) or (kind is "row" and index >= visibleRows)
        header._fullDestroyNoSettle()
        @_headerCells.delete key
    return

  # Create + index + place ONE CellWdgt for `address` at viewport slot (slotCol, slotRow) —
  # the one birth site every cell goes through (the constructor-time grid, a scroll-in, and the
  # off-viewport widget-value mount all funnel here). The slot may be OUTSIDE the viewport (a
  # hidden rich cell's notional rect — integer, never painted while hidden); the caller hides
  # it in that case.
  _materialiseCellNoSettle: (address, slotCol, slotRow) ->
    cell = new CellWdgt address
    cell.attachSheet this
    @_cellsPanel._addNoSettle cell
    rect = @_cellRectLocal slotCol, slotRow
    cell._applyExtent new Point rect.w, rect.h
    cell._applyMoveTo @position().add new Point rect.x, rect.y
    @_cells.set address, cell
    cell

  # ── F1 scroll: the viewport reconcile (materialise / recycle) ────────────────────────────

  # Re-establish THE VIEWPORT INVARIANT (see the header) for the current view origin — called
  # after every origin change (wheel, keyboard scroll-follow), at construction (origin 0), and
  # on restore/duplicate for the RESTORED origin, whatever mix of visible + hidden-rich cells
  # the snapshot carried.
  #   pass 1 — every indexed cell: on-screen ⇒ show + place at the viewport rect of
  #     (address − origin); off-screen ⇒ the hidden-rich-cell EXEMPTION (a cell whose hosted
  #     widget IS the record's live value __hide()s in place — repaint-level, out of
  #     fullBounds/paint/hit-testing — so the widget's runtime state keeps riding the tree and
  #     survives save/load); everything else (scalar / presenter / empty) is destroyed — a
  #     presenter is DERIVED and rebuilds from the record on re-entry (spec §9.4).
  #   pass 2 — every on-screen address still missing a cell is materialised and the record's
  #     CURRENT value routed in (an off-screen record kept recomputing, so a scrolled-in cell
  #     is instantly correct, no catch-up).
  # NoSettle core: runs inside the settle its public caller (wheel / processKeyDown / the
  # constructor's enclosing openFrameWith / the restore gesture) owns.
  _reconcileViewportNoSettle: ->
    # ONE bound for membership AND the materialise loops (F6): the origin-clamped visible
    # counts. For pass-1 membership the origin clamp is a no-op (an indexed cell's address is
    # inside the logical sheet by construction), so this is the plan's PARTIAL derivation
    # there — a partially-visible cell counts as on-screen.
    visibleCols = @_visibleCols()
    visibleRows = @_visibleRows()
    @_cells.forEach (cellWdgt, address) =>
      colRow = @model.colRowFor address
      slotCol = colRow.col - @viewOriginCol
      slotRow = colRow.row - @viewOriginRow
      if slotCol >= 0 and slotCol < visibleCols and slotRow >= 0 and slotRow < visibleRows
        cellWdgt.show() unless cellWdgt.isVisible
        rect = @_cellRectLocal slotCol, slotRow
        cellWdgt._applyMoveTo @position().add new Point rect.x, rect.y
      else
        record = @model.cellAt address
        # the exemption predicate: the hosted widget IS the record's value (branch 1). On the
        # RESTORE path the record's derived @value is still nil (a serialization transient —
        # the recommit + drain re-derive it AFTER this reconcile), so an adopted already-hosting
        # cell keeps its exemption through the nil disjunct: a snapshot only ever carries
        # off-viewport cells for widget-VALUED records (this very invariant at save time).
        keepsWidgetAlive = cellWdgt.hostedWidget? and record? and
          ((record.value is cellWdgt.hostedWidget) or (not record.value?))
        if keepsWidgetAlive
          cellWdgt.__hide()
        else
          cellWdgt._fullDestroyNoSettle()
          @_cells.delete address
    slotRow = 0
    while slotRow < visibleRows
      slotCol = 0
      while slotCol < visibleCols
        address = @model.addressFor (@viewOriginCol + slotCol), (@viewOriginRow + slotRow)
        unless @_cells.has address
          @_materialiseCellNoSettle address, slotCol, slotRow
          record = @model.cellAt address
          @_reconcileCellNoSettle record, record.value if record?
        slotCol += 1
      slotRow += 1
    return

  # ── F6: the resize seam — the sheet's own children-arrange ───────────────────────────────
  # The window grants the sheet its extent (grow-1 width through the base
  # _setWidthSizeHeightAccordingly, free height through _applyHeight); _applyExtent's
  # schedule-valve then enqueues me (I have children) and the settle engine re-lays me HERE,
  # in the same flush, at final geometry. Bounds FIRST (the InspectorWdgt case-law, enforced
  # by check-relayout-bounds-first.js), then the whole chrome + viewport re-derive from the
  # just-applied frame — every child placed ABSOLUTELY from @position()/@width()/@height(),
  # which subsumes float-follow for any move that arrives here (a plain move that doesn't
  # goes through _applyMoveBy's subtree translate as always; a hidden rich cell's notional
  # off-screen rect is left stale — never painted/hit, re-placed on scroll-in). IDEMPOTENT
  # (the census arrange-twice gate) and visited at most once per flush (the revisits gate).
  # The seam is _reLayout — NOT _positionAndResizeChildren, which is a stack-family dispatch
  # (via _reLayoutChildren) that the plain-Widget _reLayout never calls; the container
  # precedent mirrored here is StretchableWidgetContainerWdgt._reLayout (bounds-first +
  # derive-children-from-own-frame + trailing super). V2 finding, recorded in the plan.
  _reLayout: (newBoundsForThisLayout) ->
    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout
    if @_handleCollapsedStateShouldWeReturn() then return
    @_applyBounds newBoundsForThisLayout
    @_buildChromeNoSettle()
    @_reconcileViewportNoSettle()
    # super: the move/extent re-applies no-op via the equal-guards (bounds already applied);
    # corner-internal children (handles) re-place; _markLayoutAsFixed.
    super

  # Shift the view origin by whole columns/rows (cell-quantized — the sheet never scrolls
  # sub-cell), clamped to the logical sheet, then reconcile the viewport and repaint (one
  # sheet-level changed() covers the moved cells and the relabelled frozen headers — the
  # sheet's own rect contains them all).
  _scrollByNoSettle: (colDelta, rowDelta) ->
    newCol = Math.min (@sheetCols - @_viewportColsFull()), Math.max 0, @viewOriginCol + colDelta
    newRow = Math.min (@sheetRows - @_viewportRowsFull()), Math.max 0, @viewOriginRow + rowDelta
    return if newCol is @viewOriginCol and newRow is @viewOriginRow
    @viewOriginCol = newCol
    @viewOriginRow = newRow
    # header VALIDITY is origin-dependent post-F6 (near the sheet edge a partial slot
    # gains/loses its column — no header over backdrop), so re-run the idempotent chrome
    # ensure/trim. At the default size the count is origin-invariant: a pure no-op pre-resize.
    @_buildChromeNoSettle()
    @_reconcileViewportNoSettle()
    @changed()
    return

  # F1 keyboard scroll-follow: shift the view origin MINIMALLY so the selected cell is inside
  # the viewport (Excel-style). A no-op while the selection is visible — in particular the
  # whole pre-F1 behaviour (origin 0, everything in view) reproduces exactly.
  _scrollToShowSelectionNoSettle: ->
    # FULL counts (F6): the selection must end up FULLY visible — never on a clipped partial
    # edge cell (this is also what keeps the overlay editor off clipped cells).
    colsFull = @_viewportColsFull()
    rowsFull = @_viewportRowsFull()
    colDelta = 0
    rowDelta = 0
    colDelta = @selectedCol - @viewOriginCol if @selectedCol < @viewOriginCol
    colDelta = @selectedCol - (@viewOriginCol + colsFull - 1) if @selectedCol > @viewOriginCol + colsFull - 1
    rowDelta = @selectedRow - @viewOriginRow if @selectedRow < @viewOriginRow
    rowDelta = @selectedRow - (@viewOriginRow + rowsFull - 1) if @selectedRow > @viewOriginRow + rowsFull - 1
    @_scrollByNoSettle colDelta, rowDelta if colDelta isnt 0 or rowDelta isnt 0
    return

  # ── painting: the sheet paints NOTHING (F5) — only the shared edge-stroke helper lives here ──
  # The sheet has a nil @appearance (the Widget default), so the base
  # paintIntoAreaOrBlitFromBackBuffer paints nothing: the cells panel fills the data region,
  # the header cells fill their strips, and every widget strokes its own top+left edges + its
  # own text/value/ring. (The old one-pass _paintGrid died here — plan §3-F F5, byte-identical
  # by the segmentation receipt, EXCEPT the selection ring which deliberately moved inside the
  # cell, the budgeted F2 recapture.)

  # PUBLIC (F5): stroke a grid widget's OWN top+left edges into its local, already-translated
  # coordinate space — the ONE home for the edge paint CellWdgt and SheetHeaderCellWdgt share
  # (the sheet stays the colour + geometry authority). THE CROSSING RULE (F5 receipt A): the
  # grid-coloured edge strokes BEFORE the dark edge, so dark wins every crossing pixel exactly
  # as the old one-pass paint's "gridlines first, darker borders last" order did —
  # byte-identical, proven at dpr1+dpr2. Left edge = a vertical at x 0.5 (rasterises into the
  # widget's FIRST pixel column); top edge = a horizontal at y 0.5. Nobody strokes
  # right/bottom: the old outermost strokes at gw+0.5/gh+0.5 rasterised one pixel past the
  # sheet and were clipped invisible (F5 receipt C) — drawing them now WOULD change pixels.
  paintGridEdges: (aContext, width, height, leftIsDark, topIsDark) ->
    aContext.lineWidth = 1
    strokeLeftEdge = =>
      aContext.strokeStyle = (if leftIsDark then @headerBorderColor else @gridlineColor).toString()
      aContext.beginPath()
      aContext.moveTo 0.5, 0
      aContext.lineTo 0.5, height
      aContext.stroke()
    strokeTopEdge = =>
      aContext.strokeStyle = (if topIsDark then @headerBorderColor else @gridlineColor).toString()
      aContext.beginPath()
      aContext.moveTo 0, 0.5
      aContext.lineTo width, 0.5
      aContext.stroke()
    if leftIsDark and not topIsDark
      strokeTopEdge()
      strokeLeftEdge()
    else
      strokeLeftEdge()
      strokeTopEdge()
    return

  # PUBLIC (F2/F5): is `address` the currently-selected cell? The cells ask this to render
  # their own selection ring — they never reach into @selectedCol/@selectedRow directly.
  isSelectedAddress: (address) ->
    @selectedCol? and @selectedRow? and (address is @model.addressFor @selectedCol, @selectedRow)

  # ── selection: pointer + keyboard ───────────────────────────────────────────────────────

  # click a cell -> select it and take keyboard focus. The dispatcher hands every click
  # handler the pointer position ALREADY inverse-mapped into the receiver's plane
  # (ActivePointerWdgt._pointerPositionInPlaneOf — the affine 4A convention; off any island it
  # IS the raw hand position, and the cell→panel→sheet escalation forwards it verbatim within
  # the one island plane), so subtracting @position() (plane-local top-left) gives the local
  # offset regardless of window nesting AND of tilt. ⚠ never re-read world.hand.position()
  # here — that is the SCREEN-plane point, and mixing it with plane geometry selects the wrong
  # cell under a tilt (the 2026-07-17 tilted-selection bug; the raw-pointer lint now bans it in
  # handler bodies). _cellAtLocal answers VIEWPORT coords, which the view origin maps to
  # sheet-space (@selectedCol/Row are sheet-space — at origin 0 the two coincide, F1). A click
  # elsewhere COMMITS an in-progress edit first (click-away commits). PUBLIC event entry: it
  # opens the ONE layout settle for its work (the mount/teardown of the overlay editor happens
  # through NoSettle cores below — the layering discipline, like world.edit).
  mouseClickLeft: (pos) ->
    @_settleLayoutsAfter =>
      @_commitEditNoSettle() if @_editing
      localPos = pos.subtract @position()
      cell = @_cellAtLocal localPos
      if cell?
        @selectedCol = @viewOriginCol + cell.col
        @selectedRow = @viewOriginRow + cell.row
        @_takeKeyboardFocus()
        @changed()
    return

  # F1 scroll: the sheet is a wheel surface (ActivePointerWdgt.processWheel climbs from the
  # widget under the pointer to the FIRST `wheel` implementor — CellWdgt and the cells panel
  # deliberately DON'T implement it, so a wheel anywhere over the grid lands here; a hosted
  # value-widget that ever implements `wheel` swallows the scroll over its cell, same as any
  # nested scroll surface — the escalation chain is the general answer). Follows the
  # ScrollPanelWdgt.wheel model: dominant-axis suppression, the invertWheel* prefs, per-axis
  # at-limit ESCALATION (a sheet inside a future scroll surface must not swallow its wheel) —
  # but QUANTIZED to whole rows/cols (the cell-quantized deviation from its pixel model): the
  # delta maps to pixels via wheelScale*, then to at least one whole cell step. POST-inversion
  # sign convention (matches ScrollPanelWdgt.scrollY, where positive steps move the CONTENT
  # down): y > 0 scrolls the view UP (origin decreases), y < 0 down; x likewise left/right —
  # so a raw POSITIVE deltaY (invertWheelY on) scrolls the view DOWN, as documented on
  # MacroToolkit.wheelOn_InputEvents. An in-progress edit COMMITS first (commit-before-scroll,
  # see the header). PUBLIC event entry: opens the ONE settle around the NoSettle cores.
  wheel: (xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg) ->
    x = xArg
    y = yArg
    # if we don't destroy the resizing handles, they'll follow the contents being moved
    # (the ScrollPanelWdgt.wheel opening move — a hosted value-widget can have handles up)
    world.hand.destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem @
    # prevent diagonal movement when the intention is clearly one axis (the ScrollPanelWdgt
    # paragraph, verbatim semantics)
    if Math.abs(y) < Math.abs(x)
      y = 0
    if Math.abs(x) < Math.abs(y)
      x = 0
    if WorldWdgt.preferencesAndSettings.invertWheelX
      x *= -1
    if WorldWdgt.preferencesAndSettings.invertWheelY
      y *= -1
    colDelta = 0
    rowDelta = 0
    escalate = false
    if y isnt 0
      steps = Math.max 1, Math.round((Math.abs(y) * WorldWdgt.preferencesAndSettings.wheelScaleY) / @rowHeight)
      delta = if y > 0 then -steps else steps
      # already at the travel limit in the requested direction ⇒ this axis escalates
      # (FULL counts, F6 — the same expressions as _scrollByNoSettle's clamps)
      if (delta < 0 and @viewOriginRow <= 0) or (delta > 0 and @viewOriginRow >= @sheetRows - @_viewportRowsFull())
        escalate = true
      else
        rowDelta = delta
    if x isnt 0
      steps = Math.max 1, Math.round((Math.abs(x) * WorldWdgt.preferencesAndSettings.wheelScaleX) / @colWidth)
      delta = if x > 0 then -steps else steps
      if (delta < 0 and @viewOriginCol <= 0) or (delta > 0 and @viewOriginCol >= @sheetCols - @_viewportColsFull())
        escalate = true
      else
        colDelta = delta
    if escalate
      @escalateEvent 'wheel', xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg
    if colDelta isnt 0 or rowDelta isnt 0
      @_settleLayoutsAfter =>
        @_commitEditNoSettle() if @_editing
        @_scrollByNoSettle colDelta, rowDelta
    return

  _cellAtLocal: (localPos) ->
    x = localPos.x
    y = localPos.y
    return nil if x < @headerColWidth or y < @headerRowHeight
    return nil if x >= @width() or y >= @height()
    col = Math.floor (x - @headerColWidth) / @colWidth
    row = Math.floor (y - @headerRowHeight) / @rowHeight
    # backdrop past the last visible/logical column-row is NOT a cell (F6). A click on a
    # PARTIAL edge cell selects it — v1: NO auto-scroll on click (arrows/edit follow, clicks
    # don't; the plan's recorded deviation-point, no deviation taken).
    return nil if col < 0 or col >= @_visibleCols() or row < 0 or row >= @_visibleRows()
    {col: col, row: row}

  # single-sheet keyboard focus: the sheet the user is typing into is the ONLY sheet receiving
  # keys. Other sheets stay rendered but inactive — WITHOUT this, a DUPLICATED sheet (the copier's
  # alignCopiedWidgetToKeyboardEventsReceiversSet inherits the original's keyboard-receiver
  # membership) would sit in the receivers set too and edit in LOCKSTEP with this one. Non-sheet
  # receivers (carets, …) are untouched. (Full multi-sheet focus was deferred in 2a; this is the
  # minimal single-focus the multi-sheet case needs to behave.)
  _takeKeyboardFocus: ->
    return unless world?.keyboardEventsReceivers?
    world.keyboardEventsReceivers.forEach (r) =>
      world.keyboardEventsReceivers.delete r if (r isnt @) and (r instanceof SimpleSpreadsheetWdgt)
    world.keyboardEventsReceivers.add @   # a Set — idempotent

  # local {x,y,w,h} rect of a viewport SLOT (relative to the widget top-left; sheet-space maps
  # in as address − view origin, F1 — at origin 0 slot == sheet coords). A slot outside the
  # viewport yields the notional off-screen rect (integer; used only for hidden rich cells,
  # never painted).
  _cellRectLocal: (col, row) ->
    x: @headerColWidth + col * @colWidth
    y: @headerRowHeight + row * @rowHeight
    w: @colWidth
    h: @rowHeight

  # a single character that should type INTO a cell (starts / extends an edit); Arrow/Enter/etc.
  # are multi-character key names, so length-1 excludes them. Ctrl/Cmd chords are not text.
  _isPrintable: (key, ctrlKey, metaKey) ->
    key? and key.length is 1 and not ctrlKey and not metaKey

  # standard keyboard path (§1.17): this widget is the sole keyboard receiver in BOTH selection
  # and editing modes (no caret — see the header). PUBLIC event entry: it opens the ONE settle;
  # the mode handlers + edit lifecycle below are NoSettle cores (mount/teardown of the overlay
  # editor mutate the tree, so they run inside this settle — the layering discipline).
  processKeyDown: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->
    @_settleLayoutsAfter =>
      if @_editing
        @_processKeyWhileEditingNoSettle key, code, shiftKey, ctrlKey, altKey, metaKey
      else
        @_processKeyWhileSelectingNoSettle key, code, shiftKey, ctrlKey, altKey, metaKey
    return

  # selection mode: arrows move the single-cell selection over the LOGICAL sheet (clamped to
  # sheetCols/sheetRows — F1) and scroll-follow (past a viewport edge the origin shifts
  # minimally to keep the selection in view); Enter/F2 edit the existing source; a printable
  # key begins an edit seeded with that character (Excel-style type-to-edit).
  _processKeyWhileSelectingNoSettle: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->
    moved = false
    switch key
      when "ArrowRight"
        @selectedCol = Math.min @sheetCols - 1, @selectedCol + 1
        moved = true
      when "ArrowLeft"
        @selectedCol = Math.max 0, @selectedCol - 1
        moved = true
      when "ArrowDown"
        @selectedRow = Math.min @sheetRows - 1, @selectedRow + 1
        moved = true
      when "ArrowUp"
        @selectedRow = Math.max 0, @selectedRow - 1
        moved = true
      when "Enter", "F2"
        @_startEditNoSettle @_currentCellSource()
        return
    if moved
      @_scrollToShowSelectionNoSettle()
      @changed()
      return
    @_startEditNoSettle key if @_isPrintable key, ctrlKey, metaKey
    return

  # editing mode: Enter commits, Escape cancels, Backspace deletes the last char, a printable key
  # appends. Arrows / navigation are ignored in v1 (no in-text cursor — the deferred rich path).
  _processKeyWhileEditingNoSettle: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->
    switch key
      when "Enter"
        @_commitEditNoSettle()
        return
      when "Escape"
        @_cancelEditNoSettle()
        return
      when "Backspace"
        @_editBuffer = @_editBuffer.slice 0, -1
        @_updateEditorTextNoSettle()
        return
    if @_isPrintable key, ctrlKey, metaKey
      @_editBuffer += key
      @_updateEditorTextNoSettle()
    return

  # ── editing: the buffer + its live overlay editor (the socket precursor) ──────────────────
  # All NoSettle: they run inside the ONE settle opened by the public event entry above.

  _currentCellSource: ->
    @model.cellAt(@model.addressFor @selectedCol, @selectedRow)?.source ? ""

  _startEditNoSettle: (seedText) ->
    return if @_editing
    # F1: the selection can sit OFF-viewport (wheel-scrolled away); editing it needs its
    # CellWdgt on screen for the overlay editor — scroll-follow first (Excel: typing jumps
    # the view back to the active cell). A no-op when the selection is already visible.
    @_scrollToShowSelectionNoSettle()
    @_editing = true
    @_editCol = @selectedCol
    @_editRow = @selectedRow
    @_editBuffer = seedText ? ""
    @_mountEditorNoSettle()
    return

  # the editor WIDGET lives on the editing CELL (F2, executed with F5): this sheet keeps the
  # buffer + the keys and delegates mount/update/teardown — the cell holds the StringWdgt and
  # suppresses its own scalar text while it does (its complete view state in one widget).
  _mountEditorNoSettle: ->
    @_editingCellWdgt()?._mountEditorNoSettle @_editBuffer
    return

  _updateEditorTextNoSettle: ->
    @_editingCellWdgt()?._updateEditorTextNoSettle @_editBuffer
    return

  # the CellWdgt of the cell being edited, or nil when not editing
  _editingCellWdgt: ->
    return nil unless @_editCol? and @_editRow?
    @_cells.get @model.addressFor @_editCol, @_editRow

  # commit: compile the source ONCE (FormulaCompiler) and mark the cell stale; the once-per-cycle
  # dataflow drain (this same doOneCycle) recomputes the value and the grid repaints.
  _commitEditNoSettle: ->
    return unless @_editing
    cell = @model.getOrCreateCellAt @model.addressFor @_editCol, @_editRow
    # F4: typed content of ANY kind — including blank — REPLACES a dropped widget-entry (the
    # gestures own the entry lifecycle, commit stays pure source machinery). The ex-entry
    # widget is destroyed by the drain's reconcile (the unhost), its engine edges by
    # Widget._destroyNoSettle. (Eject-to-world instead of destroying was considered and
    # rejected for v1 — see src/spreadsheet/CLAUDE.md.)
    cell.widgetEntry = nil if cell.widgetEntry?
    FormulaCompiler.commit cell, @_editBuffer
    world.dataflow.markStale cell
    @_teardownEditorNoSettle()
    return

  _cancelEditNoSettle: ->
    return unless @_editing
    @_teardownEditorNoSettle()
    return

  _teardownEditorNoSettle: ->
    editingCell = @_editingCellWdgt()
    @_editing = false
    @_editBuffer = ""
    @_editCol = nil
    @_editRow = nil
    editingCell?._teardownEditorNoSettle()
    @changed()
    return

  # ── cell reconcile: classify → present into the cell's CellWdgt (spec §9.3/§9.4) ─────────────
  # Called from SheetCellRecord._cacheValue right after a cell recomputes, so it runs INSIDE the
  # dataflow drain's layout settle (DataflowEngine._drainOnePass wraps the pass in
  # world._settleLayoutsAfter) — hence every helper here is a NoSettle core, exactly like the editor.
  # The cell's CellWdgt ALWAYS exists now (the full grid is materialised at construction), so this
  # routes the value into it — it never creates/destroys the cell widget (Phase 8; was the socket
  # create/dispose dance).
  #
  # RETURNS the value to CACHE on the record: normally `value` unchanged, but for a widget-valued cell
  # that keeps its existing widget the RETAINED instance (so the record's @value IS the mounted
  # widget). The fallback chain (spec §9.4):
  #   branch 1 — value IS a Widget → HOST it live in the cell (a slider, a picker). RETAIN an existing
  #     hosted widget of the SAME class: its runtime state IS the cell's live state (a dragged slider's
  #     position; a restored widget's saved position — spec §13 retain-and-remount), so the
  #     just-constructed throwaway is discarded and the live one kept. This is exactly what lets a
  #     widget-valued cell be marked stale by its OWN widget's interaction (cellInput → markStale)
  #     WITHOUT the recompute resetting the widget being dragged. (Re)build only on first mount / class
  #     change. The cell wires the widget so its firings mark the cell stale (interactivity in).
  #   branch 2 — value answers cellPresenter() (a Color → a swatch) → host that presenter. Lifecycle
  #     (spec §13): REBUILD on value change; a churn-skip keeps an unchanged value's presenter, so a
  #     steady cell rebuilds nothing. No reuse-and-update — keeps the sheet value-class-agnostic (it
  #     just calls cellPresenter() again). A presenter is "one-way glass": it is NOT wired.
  #   branch 3 — scalar / error / nil → no hosted widget: the cell PAINTS toString() (or clears if nil).
  _reconcileCellNoSettle: (cell, value) ->
    return value unless cell?
    cellWdgt = @_cells.get cell.address
    unless cellWdgt?
      # off-viewport, no widget (F1). A scalar/presenter/empty value needs none — the record
      # keeps recomputing and a scroll-in materialises + routes. But a value that IS a Widget
      # must mount SOMEWHERE or it would be lost on save (widgets ride the TREE, not the
      # model): materialise its CellWdgt right here, HIDDEN, at its notional off-screen slot —
      # the hidden-rich-cell exemption's other birth path (a formula committed to an
      # off-screen cell yielding `new SliderWdgt`).
      return value unless value instanceof Widget
      colRow = @model.colRowFor cell.address
      return value unless colRow?
      cellWdgt = @_materialiseCellNoSettle cell.address, (colRow.col - @viewOriginCol), (colRow.row - @viewOriginRow)
      cellWdgt.__hide()
    # an OFF-viewport (hidden) cell keeps its CellWdgt only while the record's value IS its
    # hosted widget: a hidden cell whose value just became scalar/presenter/nil loses the
    # exemption and recycles now (F1 — the viewport invariant; a re-entry rebuilds from the
    # record like any off-screen cell)
    if not cellWdgt.isVisible and not (value instanceof Widget)
      cellWdgt._fullDestroyNoSettle()
      @_cells.delete cell.address
      return value
    # branch 1 — a live Widget value
    if value instanceof Widget
      if cellWdgt.hostedWidget? and cellWdgt.hostedWidget.constructor is value.constructor
        return cellWdgt.hostedWidget               # RETAIN (drag/restore keep the live instance)
      cellWdgt.hostNoSettle value
      cellWdgt.wireValueWidget value
      @changed()
      return value
    # branch 2 — a value that presents as a widget
    if value? and typeof value.cellPresenter is "function"
      return value if cellWdgt.hostedWidget? and @_presentedValuesEqual cellWdgt.presentedValue, value
      presenter = value.cellPresenter()
      if presenter?
        cellWdgt.hostNoSettle presenter
        cellWdgt.presentedValue = value
        @changed()
        return value
      # a value class may answer cellPresenter yet decline (nil) → fall through to branch 3
    # branch 3 — scalar / error / nil: the cell paints the text (dropping any hosted widget)
    text = if value? then value.toString() else nil
    cellWdgt.showScalarNoSettle text, (value instanceof SheetError)
    value

  # a.equals?(b) when the value defines it (Color does), else identity — mirrors the engine's cutoff.
  _presentedValuesEqual: (a, b) ->
    if a?.equals? then a.equals b else a is b

  # the connection target a hosted interactive value-widget fires into (via CellWdgt.cellInput):
  # mark the cell STALE so the drain recomputes its dependents (spec §9.3 — a drag = a per-cycle
  # recompute of the closure). A pooled dataflow mark, NOT a layout settle, so no settle is opened here
  # (the drain owns any settle for the recompute).
  _markCellStaleFromHostedWidgetNoSettle: (address) ->
    cell = @model.cellAt address
    world.dataflow?.markStale cell if cell?
    return

  # PUBLIC: the live widget a cell currently hosts — its value-widget (branch 1, a slider) or
  # presenter (branch 2, a swatch), or nil for a scalar / empty cell. The public reach into a
  # mounted cell widget (a macro drags `sheet.hostedWidgetAt "A1"`, never the private cell index).
  hostedWidgetAt: (address) -> @_cells.get(address)?.hostedWidget

  # ── serialization / duplication (spec §2: the engine index is derived + disposable) ──────────

  # Rebuild every cell's DERIVED state (compiledFn / value / edges) from its persisted @source,
  # then mark all stale so the next drain recomputes the whole sheet in dependency order. A
  # RESTORED (deserialize) or DUPLICATED (deep-copy) sheet re-declares its OWN edges here rather
  # than serializing/copying the shared engine — the two hooks below call this.
  # NoSettle core (not a self-settling wrapper): the notification hooks below call it directly, and
  # the copy/deserialize gesture owns the enclosing settle (layering rule [J]); both hooks fire on a
  # DETACHED sheet (orphan). First RE-INDEX the cells (below) from the restored/copied cell children,
  # so the recompute RETAINS a widget-valued cell's live widget instead of rebuilding it (spec §13);
  # presenters (derived) rebuild from values, scalars repaint.
  _recommitAllCells: ->
    return unless @model?
    @_reindexCellsNoSettle()
    @model.forEachCell (cell) -> FormulaCompiler.commit cell, cell.source
    @model.forEachCell (cell) -> world.dataflow?.markStale cell
    return

  # After restore/duplicate the transient @_cells index + chrome handles are empty, but the
  # widgets rode the tree (the constructor — which would have built them — is SKIPPED on the
  # deserialize/duplicate path, so there is no double grid): the CellWdgts — each carrying its
  # @address and any hosted value/presenter widget (a restored slider keeps its dragged
  # position, spec §13) — inside the snapshot's cells panel (or as direct children in a pre-F5
  # snapshot), plus the DERIVED chrome (panel + header cells), which is DESTROYED and rebuilt
  # from the geometry constants — ONE path serves both snapshot generations. The cells are
  # rescued out of the old chrome first, adopted + re-indexed (back-ref re-attached, so the
  # recompute RETAINS a widget-valued cell's restored widget by class match — a DERIVED
  # presenter is rebuilt from the value, a scalar repaints), and any stray CELL child that is
  # not its hosted widget (a mid-edit overlay editor that rode a subtree snapshot) is
  # destroyed. Then _buildChromeNoSettle rebuilds the chrome + re-homes the adopted cells into
  # the fresh panel, and _reconcileViewportNoSettle re-establishes the viewport invariant for
  # the RESTORED view origin, whatever mix the snapshot carried (F1): visible cells re-place at
  # their slots, an off-viewport HIDDEN rich cell keeps its exemption (its record's derived
  # value is still nil here — the predicate's nil disjunct covers it), anything else recycles,
  # and every on-screen gap fills. The transient edit state resets.
  _reindexCellsNoSettle: ->
    @_editing = false
    @_editBuffer = ""
    @_editCol = nil
    @_editRow = nil
    @_cells = new Map
    @_cellsPanel = nil
    @_headerCells = new Map
    # rescue the data cells out of any snapshot chrome, up to direct children
    for child in @children.slice()
      if child instanceof SheetCellsPanelWdgt
        for inner in child.children.slice()
          @_addNoSettle inner if inner instanceof CellWdgt
    # destroy everything that isn't a data cell: old chrome (now empty of cells) + strays
    for child in @children.slice()
      child._fullDestroyNoSettle() unless child instanceof CellWdgt
    # adopt + index the snapshot's cells; sweep their stray children (a mid-edit editor)
    for child in @children.slice()
      if child instanceof CellWdgt
        child.attachSheet this
        child._editorWdgt = nil
        for grand in child.children.slice()
          grand._fullDestroyNoSettle() unless grand is child.hostedWidget
        @_cells.set child.address, child
    # rebuild chrome + re-home the adopted cells, then re-establish the viewport invariant
    # for the restored origin (see the method comment above)
    @_buildChromeNoSettle()
    @_reconcileViewportNoSettle()
    return

  # after a deep-copy (the duplicate gesture → fullCopy → deepCopy): the copier runs this once the
  # whole subtree — model + records — is cloned, so the copy's fresh records wire THEIR OWN edges
  # (independent of the original's), and a subsequent edit to the original leaves the copy alone.
  _reactToBeingCopied: ->
    @_recommitAllCells()

  # after deserialize (loading a saved world/sheet): the same source-driven rebuild.
  _afterDeserialization: ->
    @_recommitAllCells()

  # drop keyboard focus when this sheet goes away, so a dead widget never receives keys (the
  # whole widget subtree — panel, headers, cells, any live editor on a cell — is torn down by
  # super's child destruction). Also perform NODE DEATH on every cell: drop its edges from the
  # shared engine (the Phase-1 removeAllEdgesOf API) — a destroyed sheet's cells are gone, so
  # leaving their edges would leak and could ghost-recompute.
  destroy: ->
    world?.keyboardEventsReceivers?.delete @
    @model?.forEachCell (cell) -> world.dataflow?.removeAllEdgesOf cell
    super()
