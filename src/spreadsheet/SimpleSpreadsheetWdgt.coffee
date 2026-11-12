# SimpleSpreadsheetWdgt — the spreadsheet's grid (spec docs/specs/dataflow-engine-spec.md §9.1; Phase 8
# "widgetise the grid" + follow-on F5; the page, the formula bar, zoom, formatting and the keys are
# docs/archive/spreadsheet-ux-plan.md). Every visible thing but my page edge is a real child widget:
# the FORMULA BAR across my top (SheetFormulaBarWdgt: the selected cell's address and source, an
# error's message, the zoom control); the data cells (CellWdgt, one per cell of the viewport,
# DERIVED from my extent: a bigger window shows more cells, the last column/row possibly partial —
# each the VIEW of its SheetCellRecord) inside a SheetCellsPanelWdgt; the header cells
# (SheetHeaderCellWdgt: column letters, row numbers, the corner) as direct children, kept OUTSIDE
# the panel so a scroll clip can never touch the frozen headers. Each widget paints its own fill,
# its own TOP+LEFT grid edges (edge-ownership + the crossing rule — see paintGridEdges) and — the
# selected cell — its own selection ring; every label/value is a CHILD widget (hosted value /
# presenter / passive StringWdgt text — "scalar text is a StringWdgt child, period", owner
# direction 2026-07-24). I am a PAGE in my window (wantsWindowPageGutter), and my own paint is only
# the page's edge, over my children (SheetAppearance). I am the model owner, the formula scope,
# the editor focus for every click in me (focusesAsAWhole) and, while I am it, the keyboard's
# receiver, and the geometry authority (the sizes below, times my zoom).
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
#     sub-cell) and scrolls by WHEEL (the `scrolledBy` entry below, with the ViewportWdgt-style
#     at-limit escalation) and by KEYBOARD scroll-follow (arrows past the viewport edge shift
#     the origin minimally). Deliberately NOT a ViewportWdgt: frozen headers, the origin-0
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
#   - EDITING is STANDARD CARET editing (the 2026-07-24 standard-caret arc, replacing 2b's
#     buffer-driven v1): the editing cell mounts a real editable overlay StringWdgt
#     (isEditable + alwaysEditsInline, at the resting scalar-text inset) and the sheet
#     enters it via world._editNoSettle — the standard CaretWdgt does ALL the text work
#     (typing, click-positioning, arrows, selection). The sheet keeps the EDIT STATE and the
#     grid semantics: type-to-edit replace / Enter / F2 / double-click-at-slot start an
#     edit; Enter commits and Escape reverts via the caret's accept/cancel escalations
#     (fired from the editor, landing on the CellWdgt, forwarded to acceptCellEdit /
#     cancelCellEdit); acting elsewhere commits (the pointer funnel accepts, wheel commits
#     before scrolling, and a DANGLING edit — a caret torn down by a path that fires no
#     escalation — self-heals by committing on the sheet's next key/click). While the caret
#     edit is live this widget's processKeyDown IGNORES keys (the caret owns them; the
#     receivers-Set dispatch snapshot in KeydownInputEvent keeps the edit-starting key from
#     double-delivering into the fresh caret); Tab is swallowed at the cell. Multi-line
#     editing stays the deferred CodePromptWdgt path (spec §9.1).
#
# Keyboard selection + editing use the standard receiver path (world.keyboardEventsReceivers, which
# I join when built, + processKeyDown, which acts while I am the editor focus); never a DOM listener.

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
  @serializationTransients: ["_editing", "_editCol", "_editRow", "_editInBar", "_cells", "_cellsPanel", "_headerCells", "_fillPickAddress"]

  # the grid's geometry at 100% (no column resize in v1): the sizes below are what ZOOM multiplies
  # (zoomFactor, and the _colW / _rowH / _headerW / _headerH readers every placement goes through),
  # so nothing reads them directly to place a pixel. The VIEWPORT — how many cell widgets are
  # materialised + visible at once — is DERIVED from the sheet's applied extent (F6, the
  # _viewportCols/Rows* derivations below): a bigger window shows MORE of the sheet, the last
  # visible column/row possibly PARTIAL (clipped). defaultViewportCols/Rows only size the
  # DEFAULT fresh-sheet extent (defaultExtent). sheetCols/sheetRows are the LOGICAL sheet the
  # viewport scrolls over (F1 — still far under the address grammar's ZZ9999 ceiling). Cells are
  # CONTENT, not chrome targets (visual-design-system §4.2): a finger is served by the formula bar
  # and by zoom, never by 44-tall rows.
  headerColWidth: 48     # the left row-number header column
  headerRowHeight: 36    # the top column-letter header row
  colWidth: 104
  rowHeight: 36
  textInset: 4           # a cell's or a header's text stands this far in from its left edge
  defaultViewportCols: 5   # the default open size's viewport columns…
  defaultViewportRows: 10  # …and rows
  sheetCols: 26          # logical columns A..Z
  sheetRows: 100         # logical rows 1..100

  # ZOOM: the sheet is laid out again at its sizes times this factor — never scaled as a picture,
  # which blurs the text — so the cells, the headers, their text and its inset grow or shrink while
  # every hairline (gridlines, the page edge, the selection ring) keeps its width, and the formula
  # bar, the toolbar and the window keep theirs (they are the controls, at the size a finger needs).
  # A hosted widget grows with its cell, which sizes it. One of ZOOM_LEVELS. The smallest is where
  # the 16 px text reaches 9.6 px, over the 9 px the software renderer can draw. A PROTOTYPE
  # default, own-only-when-zoomed (the viewOrigin idiom below), and DOCUMENT state: a saved zoomed
  # sheet restores zoomed.
  zoomFactor: 1
  ZOOM_LEVELS: [0.6, 0.75, 1, 1.25, 1.5, 2]

  # the view origin (F1): the sheet-space col/row of the viewport's top-left cell. PROTOTYPE
  # defaults, own-only-when-scrolled (the 6a idiom): an unscrolled sheet serializes byte-for-byte
  # as before F1, and a pre-F1 snapshot deserializes to origin 0 through the prototype (the
  # deserialize path skips the constructor). DOCUMENT state — a saved scrolled sheet restores
  # scrolled — so deliberately NOT in @serializationTransients.
  viewOriginCol: 0
  viewOriginRow: 0

  # the selection: a single cell (0-based col/row); v1 always has one selected
  selectedCol: undefined
  selectedRow: undefined

  # the sparse data model — this widget owns it and is its formula scope
  model: undefined

  # editing state: which cell is being edited, and whether the caret is in the formula bar's text
  # (_editInBar) or in the editor WIDGET the editing cell holds. Either way the other one shows the
  # same text, kept in step as it is typed (reactToKeystroke).
  _editing: undefined
  _editCol: undefined
  _editRow: undefined
  _editInBar: undefined

  # the cell index (address → its CellWdgt) and the chrome handles: the data-cells container and
  # the header-cell index ("kind:index" → SheetHeaderCellWdgt), TRANSIENT — rebuilt on restore by
  # _reindexCellsNoSettle, never adopted from a snapshot — and the formula bar, which IS adopted:
  # it rides a snapshot or a copy as my child and is re-attached and re-synced, never rebuilt there
  # (building its zoom button would open a settle inside the copy and restore notifications).
  _cells: undefined
  _cellsPanel: undefined
  _headerCells: undefined
  _formulaBar: undefined
  # the cell the fill tool's colour prompt is choosing for (pickFillFor → setFillOfSelection)
  _fillPickAddress: undefined

  constructor: ->
    super()
    # selection is a single cell (0-based col/row); v1 always has one selected
    @selectedCol = 0
    @selectedRow = 0
    # the sparse data model — this widget owns it and is its formula scope (see FormulaCompiler)
    @model = new SheetModel @
    # editing state (which cell is being edited; the editor WIDGET lives on the editing
    # cell, and the standard caret types straight into it); undefined / false until an edit begins
    @_editing = false
    @_editCol = undefined
    @_editRow = undefined
    @_editInBar = false
    # the page's edge, painted over my children (SheetAppearance); otherwise I paint nothing
    @appearance = new SheetAppearance @
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
    @_cellsPanel = undefined
    @_headerCells = new Map
    @_formulaBar = undefined
    # the formula bar + headers + one cell — the smallest extent at which the viewport
    # derivations still answer a 1×1 viewport (F6; the __commitExtent leaf enforces this floor on
    # every commit). An OWN field, set after super: the Widget constructor sets its own 5,5, so a
    # prototype default here would be shadowed. (An older snapshot restores its saved floor —
    # harmless: the derivations' Math.max 1 floor degrades gracefully below one cell.)
    @minimumExtent = @_leastExtent()
    @_applyExtent @defaultExtent()
    # materialise the widget chrome, then the viewport's grid of cell widgets (NoSettle: the
    # enclosing openFrameWith settles once — the DegreesConverterApp orphan-construction idiom;
    # a deserialize/duplicate skips the constructor and restores/copies the cells instead, which
    # _reindexCellsNoSettle then adopts through the same two calls — no double grid).
    @_buildChromeNoSettle()
    @_reconcileViewportNoSettle()
    # I hear the keyboard from the start and act on it while I am the editor focus (processKeyDown),
    # as a video player hears it and acts while it is in front. A copy and a restore are receivers
    # through the membership they carry (Widget's copy hook, the serializer's marker).
    world.keyboardEventsReceivers.add @
    return

  colloquialName: -> "spreadsheet"

  # I am a PAGE, a surface you work on (visual-design-system §4.10): a window keeps its page gutter
  # around me on every side and between me and a docked toolbar, and I draw my own edge
  # (SheetAppearance), because the window's lines do not run along mine.
  wantsWindowPageGutter: -> true

  # A click anywhere in me makes ME the editor focus, not the cell or label it hit: what the
  # editing tools act on is my SELECTION, whichever way it moved (a click, the arrows, Enter, Tab),
  # and I hand them my selected cell's style (textStyleSubject). WorldWdgt._setEditorFocusNoSettle
  # asks this of the widget a click or drop names and of its ancestors.
  focusesAsAWhole: -> true

  # ...and, being the focus, I show my selection myself (the selected cell's ring), so I opt out of
  # the editor-focus outline explicitly (WorldWdgt._widgetBeingEdited); my window shows no edit
  # toggle either way (FrameWdgt asks this too).
  providesAmenitiesForEditing: false

  # ── geometry at the current zoom: every placement reads these, never the 100% sizes above ──
  _colW: -> Math.round @colWidth * @zoomFactor
  _rowH: -> Math.round @rowHeight * @zoomFactor
  _headerW: -> Math.round @headerColWidth * @zoomFactor
  _headerH: -> Math.round @headerRowHeight * @zoomFactor
  textInsetPx: -> Math.round @textInset * @zoomFactor
  # the formula bar's height: where the column headers start. It does not zoom.
  _gridTop: -> WorldWdgt.theme.spreadsheetFormulaBarHeight

  # the font a cell's text wears at the current zoom: the theme's cell role, its size (the cell's
  # own, from its format, or the role's) times the zoom, its weight, slant and family from the
  # cell's format where it sets them. A fresh object each time: a role is read by the text built
  # from it, never mutated.
  _cellFontRole: (format) ->
    base = WorldWdgt.theme.fonts.spreadsheetCell
    role = {family: base.family, size: base.size, bold: base.bold, italic: false}
    if format?
      role.size = format.fontSize if format.fontSize?
      role.bold = format.bold if format.bold?
      role.italic = format.italic if format.italic?
      role.family = format.fontName if format.fontName?
    role.size = role.size * @zoomFactor
    role

  # the font a header's label wears at the current zoom
  headerFontRole: ->
    base = WorldWdgt.theme.fonts.spreadsheetHeader
    {family: base.family, size: base.size * @zoomFactor, bold: base.bold}

  # the smallest extent: the formula bar, the headers and one cell
  _leastExtent: ->
    new Point (@_headerW() + @_colW()), (@_gridTop() + @_headerH() + @_rowH())

  # the picture a filed or aliased sheet wears (the generic object frame around it), and the one
  # its launcher wears through AppCatalog: the spreadsheet's own icon. The window (SpreadsheetWdgt)
  # answers through FrameWdgt's representativeIcon, which asks its content -- me.
  representativeIcon: ->
    new SpreadsheetIconWdgt

  # FILL-class window content (F6 — this DELETED the pre-F6 fixed-size overrides: the
  # initialiseDefaultFrameContentLayoutSpec grow-0/height-frozen flip, the fixed
  # preferredExtentForWidth and _setWidthSizeHeightAccordingly, and _gridWidth/_gridHeight).
  # The sheet now takes whatever extent the window grants — the default
  # FrameContentLayoutSpec is already grow 1 + canSetHeightFreely true, and the BASE Widget
  # protocol is exactly the fill-content protocol (V1): _setWidthSizeHeightAccordingly
  # applies the granted width and hands the height back, _applyHeight grants the free height,
  # preferredExtent answers the applied extent (which feeds the first-placement window hug
  # with defaultExtent below). The viewport DERIVES from that extent; a resize re-derives
  # chrome + viewport in _reLayout below. The default open size is SpreadsheetApp's: it opens
  # its window around defaultExtent. The pre-F6 AnalogClockWdgt fixed-size pattern (chosen in
  # Phase 2a for one-cycle settle determinism) is retired: the arrange below is idempotent and
  # settles in the same one pass.

  # the DEFAULT (fresh-sheet) extent: the formula bar over the exact default grid — the
  # construction extent, and what the first-placement window hug reads back through the base
  # preferredExtent. PUBLIC: SpreadsheetApp opens its window around it.
  defaultExtent: ->
    new Point (@_headerW() + @defaultViewportCols * @_colW()),
      (@_gridTop() + @_headerH() + @defaultViewportRows * @_rowH())

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
  _viewportColsPartial: -> Math.max 1, Math.min @sheetCols, Math.ceil((@width() - @_headerW()) / @_colW())
  _viewportRowsPartial: -> Math.max 1, Math.min @sheetRows, Math.ceil((@height() - @_gridTop() - @_headerH()) / @_rowH())
  _viewportColsFull: -> Math.max 1, Math.min @sheetCols, Math.floor((@width() - @_headerW()) / @_colW())
  _viewportRowsFull: -> Math.max 1, Math.min @sheetRows, Math.floor((@height() - @_gridTop() - @_headerH()) / @_rowH())

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
    # the formula bar spans my top, the full width, and does not zoom (SheetFormulaBarWdgt)
    unless @_formulaBar?
      bar = new SheetFormulaBarWdgt
      bar.attachSheet this
      @_addNoSettle bar
      @_formulaBar = bar
    @_formulaBar._applyBounds @position(), new Point @width(), @_gridTop()
    @_formulaBar.syncNoSettle()
    # the data region spans from the headers to my bottom-right corner (F6 — pre-F6 this was
    # the fixed grid size, set once at build)
    gridTop = @_gridTop()
    @_cellsPanel._applyBounds (@position().add new Point @_headerW(), gridTop + @_headerH()), new Point (@width() - @_headerW()), (@height() - gridTop - @_headerH())
    @_cells.forEach (cell) =>
      @_cellsPanel._addNoSettle cell unless cell.parent is @_cellsPanel
    # (kind, topLeftOffset, extent, viewportSlot): the four loose geometry numbers are the two Point
    # tuples they always were, and `viewportSlot` moved to the TAIL because the corner header has none
    # -- with it in slot 2 the corner call had to write `undefined` past it to reach the
    # geometry (R3). Allocation is unchanged: the two Points were already being minted here.
    buildHeader = (kind, topLeftOffset, extent, viewportSlot) =>
      key = kind + ":" + (viewportSlot ? "")
      unless @_headerCells.has key
        header = new SheetHeaderCellWdgt kind, viewportSlot
        header.attachSheet this
        @_addNoSettle header
        @_headerCells.set key, header
      header = @_headerCells.get key
      header._applyBounds (@position().add topLeftOffset), extent
      # label child sync (create/retext/place) — every chrome-ensure path (build, scroll,
      # resize, restore) funnels here, so the origin-derived labels stay current in place
      header._syncLabelNoSettle()
      return
    visibleCols = @_visibleCols()
    visibleRows = @_visibleRows()
    headerW = @_headerW()
    headerH = @_headerH()
    colW = @_colW()
    rowH = @_rowH()
    buildHeader "corner", (new Point 0, gridTop), (new Point headerW, headerH)
    col = 0
    while col < visibleCols
      buildHeader "column", (new Point (headerW + col * colW), gridTop), (new Point colW, headerH), col
      col += 1
    row = 0
    while row < visibleRows
      buildHeader "row", (new Point 0, (gridTop + headerH + row * rowH)), (new Point headerW, rowH), row
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
    cell._applyBounds (@position().add new Point rect.x, rect.y), new Point rect.w, rect.h
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
  # NoSettle core: runs inside the settle its public caller (scrolledBy / processKeyDown / the
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
        # bounds, not just a move: a zoom resizes every cell, and its children follow
        cellWdgt._applyBounds (@position().add new Point rect.x, rect.y), new Point rect.w, rect.h
        cellWdgt.placeChildrenNoSettle @textInsetPx()
      else
        record = @model.cellAt address
        # the exemption predicate: the hosted widget IS the record's value (branch 1). On the
        # RESTORE path, and on the COPY path, the record's derived @value is still undefined (a
        # serialization transient, and a copy transient -- the recommit + drain re-derive it AFTER
        # this reconcile), so an adopted already-hosting cell keeps its exemption through the
        # undefined disjunct: a snapshot or a copy only ever carries off-viewport cells for
        # widget-VALUED records (this very invariant at save and copy time).
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
          @_presentCellNoSettle record, record.value if record?
        slotCol += 1
      slotRow += 1
    @_reflowSpillOfRowNoSettle slotRow for slotRow in [0...visibleRows]
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
    @_applyGrantedBounds newBoundsForThisLayout
    @_buildChromeNoSettle()
    @_reconcileViewportNoSettle()
    # super: the move/extent re-applies no-op via the equal-guards (bounds already applied);
    # corner-internal children (handles) re-place; _markLayoutAsFixed.
    super

  # Shift the view origin by whole columns/rows (cell-quantized — the sheet never scrolls
  # sub-cell), clamped to the logical sheet, then reconcile the viewport and repaint (one
  # sheet-level _changed() covers the moved cells and the relabelled frozen headers — the
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
    @_changed()
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

  # ── painting: the sheet paints only its PAGE EDGE (SheetAppearance, over its children) ──
  # Everything else is a child's: the cells panel spans the data region, the header cells fill
  # their strips, the formula bar draws its field, and every widget strokes its own top+left
  # edges + its own text/value/ring. (The old one-pass _paintGrid died here — plan §3-F F5, byte-identical
  # by the segmentation receipt, EXCEPT the selection ring which deliberately moved inside the
  # cell, the budgeted F2 recapture.)

  # PUBLIC (F5): stroke a grid widget's OWN top+left edges into its local, already-translated
  # coordinate space — the ONE home for the edge paint CellWdgt and SheetHeaderCellWdgt share
  # (the sheet is the geometry authority; the colours are the theme's spreadsheet roles, read
  # here at paint time). `leftEdge` and `topEdge` each name what that edge is:
  #   "rule"     — the header rule (spreadsheetHeaderRule): an edge on the line under the letter
  #                row or on the line right of the number column;
  #   "gridline" — a gridline (spreadsheetGridline): any other edge between two cells or headers;
  #   undefined  — no line: the edge lies on the sheet's OUTER left boundary, where the sheet's
  #                own page edge is the line (SheetAppearance paints it over every child), or
  #                under the formula bar, whose bottom rule is the line (a second one there would
  #                double it), so that pixel row or column shows the widget's own fill.
  # THE CROSSING RULE (F5 receipt A): a gridline strokes BEFORE the rule, so the rule wins every
  # pixel where the two cross. Left edge = a vertical at x 0.5 (rasterises into the widget's
  # FIRST pixel column); top edge = a horizontal at y 0.5. Each runs the widget's whole side, so
  # an inner line meets the outer boundary flush. Nobody strokes right or bottom: a neighbour
  # strokes that line as its own left or top, and along the sheet's outer right and bottom the
  # page edge is the line.
  paintGridEdges: (aContext, width, height, leftEdge, topEdge) ->
    theme = WorldWdgt.theme
    edgeColorString = (edge) ->
      (if edge is "rule" then theme.spreadsheetHeaderRule else theme.spreadsheetGridline).toString()
    aContext.lineWidth = 1
    strokeLeftEdge = ->
      return unless leftEdge?
      aContext.strokeStyle = edgeColorString leftEdge
      aContext.beginPath()
      aContext.moveTo 0.5, 0
      aContext.lineTo 0.5, height
      aContext.stroke()
    strokeTopEdge = ->
      return unless topEdge?
      aContext.strokeStyle = edgeColorString topEdge
      aContext.beginPath()
      aContext.moveTo 0, 0.5
      aContext.lineTo width, 0.5
      aContext.stroke()
    if leftEdge is "rule" and topEdge isnt "rule"
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

  # click a cell -> select it (the click has already made me the editor focus, so the keys are
  # mine: ActivePointerWdgt writes the focus before it dispatches the click). The dispatcher hands every click
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
  activated: (pos) ->
    @_settleLayoutsAfter =>
      @_commitEditNoSettle() if @_editing
      localPos = pos.subtract @position()
      cell = @_cellAtLocal localPos
      if cell?
        @selectedCol = @viewOriginCol + cell.col
        @selectedRow = @viewOriginRow + cell.row
        @_noteSelectionMovedNoSettle()
    return

  # F1 scroll: the sheet is a wheel surface (ActivePointerWdgt.processWheel climbs from the
  # widget under the pointer to the FIRST `scrolledBy` implementor — CellWdgt and the cells panel
  # deliberately DON'T implement it, so a wheel anywhere over the grid lands here; a hosted
  # value-widget that ever implements `scrolledBy` swallows the scroll over its cell, same as any
  # nested scroll surface — the escalation chain is the general answer). Follows the
  # ViewportWdgt.scrolledBy model: dominant-axis suppression, the invertWheel* prefs, per-axis
  # at-limit ESCALATION (a sheet inside a future scroll surface must not swallow its wheel) —
  # but QUANTIZED to whole rows/cols (the cell-quantized deviation from its pixel model): the
  # delta maps to pixels via wheelScale*, then to at least one whole cell step. POST-inversion
  # sign convention (matches ViewportWdgt.scrollY, where positive steps move the CONTENT
  # down): y > 0 scrolls the view UP (origin decreases), y < 0 down; x likewise left/right —
  # so a raw POSITIVE deltaY (invertWheelY on) scrolls the view DOWN, as documented on
  # MacroToolkit.wheelOn_InputEvents. An in-progress edit COMMITS first (commit-before-scroll,
  # see the header). PUBLIC event entry: opens the ONE settle around the NoSettle cores.
  scrolledBy: (xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg) ->
    x = xArg
    y = yArg
    # if we don't destroy the resizing handles, they'll follow the contents being moved
    # (the ViewportWdgt.scrolledBy opening move — a hosted value-widget can have handles up)
    world.hand.destroyTemporaryHandlesAndLayoutAdjustersIfHandHasNotActionedThem @
    # squelch the minor axis + apply the invert preferences (shared with ViewportWdgt)
    [x, y] = WorldWdgt.preferencesAndSettings.normalizedWheelDeltas x, y
    colDelta = 0
    rowDelta = 0
    escalate = false
    if y isnt 0
      steps = Math.max 1, Math.round((Math.abs(y) * WorldWdgt.preferencesAndSettings.wheelScaleY) / @_rowH())
      delta = if y > 0 then -steps else steps
      # already at the travel limit in the requested direction ⇒ this axis escalates
      # (FULL counts, F6 — the same expressions as _scrollByNoSettle's clamps)
      if (delta < 0 and @viewOriginRow <= 0) or (delta > 0 and @viewOriginRow >= @sheetRows - @_viewportRowsFull())
        escalate = true
      else
        rowDelta = delta
    if x isnt 0
      steps = Math.max 1, Math.round((Math.abs(x) * WorldWdgt.preferencesAndSettings.wheelScaleX) / @_colW())
      delta = if x > 0 then -steps else steps
      if (delta < 0 and @viewOriginCol <= 0) or (delta > 0 and @viewOriginCol >= @sheetCols - @_viewportColsFull())
        escalate = true
      else
        colDelta = delta
    if escalate
      @escalateEvent 'scrolledBy', xArg, yArg, zArg, altKeyArg, buttonArg, buttonsArg
    if colDelta isnt 0 or rowDelta isnt 0
      @_settleLayoutsAfter =>
        @_commitEditNoSettle() if @_editing
        @_scrollByNoSettle colDelta, rowDelta
    return

  _cellAtLocal: (localPos) ->
    x = localPos.x
    y = localPos.y
    gridY = y - @_gridTop()
    return undefined if x < @_headerW() or gridY < @_headerH()
    return undefined if x >= @width() or y >= @height()
    col = Math.floor (x - @_headerW()) / @_colW()
    row = Math.floor (gridY - @_headerH()) / @_rowH()
    # backdrop past the last visible/logical column-row is NOT a cell (F6). A click on a
    # PARTIAL edge cell selects it — v1: NO auto-scroll on click (arrows/edit follow, clicks
    # don't; the plan's recorded deviation-point, no deviation taken).
    return undefined if col < 0 or col >= @_visibleCols() or row < 0 or row >= @_visibleRows()
    {col: col, row: row}

  # local {x,y,w,h} rect of a viewport SLOT (relative to the widget top-left; sheet-space maps
  # in as address − view origin, F1 — at origin 0 slot == sheet coords). A slot outside the
  # viewport yields the notional off-screen rect (integer; used only for hidden rich cells,
  # never painted).
  _cellRectLocal: (col, row) ->
    x: @_headerW() + col * @_colW()
    y: @_gridTop() + @_headerH() + row * @_rowH()
    w: @_colW()
    h: @_rowH()

  # a single character that should type INTO a cell (starts / extends an edit); Arrow/Enter/etc.
  # are multi-character key names, so length-1 excludes them. Ctrl/Cmd chords are not text.
  _isPrintable: (key, ctrlKey, metaKey) ->
    key? and key.length is 1 and not ctrlKey and not metaKey

  # standard keyboard path (§1.17): the keys are mine while I am the EDITOR FOCUS — the thing the
  # user works on, which a click in me, or my window's opening, makes me (WorldWdgt.openFrameWith) —
  # and no caret is live. A live caret owns every key, whether it edits me (in a cell or the formula
  # bar: Enter / Escape / Tab come back through the accept / cancel / nextTab handlers holding the
  # editor) or any other text; and once the user works on something else, keys reach me and I let
  # them pass. So of several sheets, only the focused one acts (a duplicate carries its original's
  # membership and never edits in lockstep), and a sheet clicked earlier never takes the keys typed
  # into another text. In SELECTION mode I drive the grid keys (arrows / Tab / Enter / F2 / Delete /
  # type-to-edit). PUBLIC event entry: it opens the ONE settle; the mode handler + edit lifecycle
  # below are NoSettle cores (mount/teardown of the overlay editor mutate the tree, so they run
  # inside this settle — the layering discipline).
  processKeyDown: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->
    # early-return-sanctioned: every key reaches every receiver, and a key that is not mine must
    # not open a settle.
    return unless world.editorFocusWdgt is @ and not world.caret?
    @_settleLayoutsAfter =>
      # a DANGLING edit — the caret was torn down by a path that fires no accept/cancel (a mid-edit
      # grab, a subtree teardown) — self-heals: commit what was typed, then handle this key normally
      # in selection mode (click-away-commits semantics).
      @_commitEditNoSettle() if @_editing
      @_processKeyWhileSelectingNoSettle key, code, shiftKey, ctrlKey, altKey, metaKey
    return

  # the text widget the caret edits for this sheet: the formula bar's text when the edit is in the
  # bar, else the editing cell's editor (read-only)
  _liveEditorWdgt: ->
    if @_editInBar then @_formulaBar?.textWdgt else @_editingCellWdgt()?._editorWdgt

  # is the standard caret currently editing THIS sheet's edit, in the cell or in the bar?
  # (read-only predicate; the caret is world chrome, so this is a world read, not a layout mutation)
  _isCaretEditLive: ->
    editor = @_liveEditorWdgt()
    editor? and world.caret? and world.caret.target is editor

  # selection mode: arrows move the single-cell selection over the LOGICAL sheet (clamped to
  # sheetCols/sheetRows — F1) and scroll-follow (past a viewport edge the origin shifts
  # minimally to keep the selection in view); Tab / Shift+Tab move right / left as they do out of
  # an edit; Enter/F2 edit the existing source; Delete and Backspace CLEAR the cell (its content,
  # never its format); a printable key begins an edit seeded with that character (Excel-style
  # type-to-edit).
  _processKeyWhileSelectingNoSettle: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->
    switch key
      when "ArrowRight" then @_moveSelectionNoSettle 1, 0
      when "ArrowLeft" then @_moveSelectionNoSettle -1, 0
      when "ArrowDown" then @_moveSelectionNoSettle 0, 1
      when "ArrowUp" then @_moveSelectionNoSettle 0, -1
      when "Tab" then @_moveSelectionNoSettle (if shiftKey then -1 else 1), 0
      when "Enter", "F2" then @_startEditNoSettle @_currentCellSource()
      when "Delete", "Backspace" then @_clearSelectedCellNoSettle()
      else
        @_startEditNoSettle key if @_isPrintable key, ctrlKey, metaKey
    return

  # THE one move of the selection: by (dCol, dRow), clamped to the logical sheet, the view
  # following it, and the move told to whatever mirrors my selection — the editing tools (their
  # active looks read my selected cell's style through the world's style announcement, which only
  # reaches them while I am the editor focus) and my formula bar.
  _moveSelectionNoSettle: (dCol, dRow) ->
    @selectedCol = Math.max 0, Math.min @sheetCols - 1, @selectedCol + dCol
    @selectedRow = Math.max 0, Math.min @sheetRows - 1, @selectedRow + dRow
    @_scrollToShowSelectionNoSettle()
    @_noteSelectionMovedNoSettle()
    return

  _noteSelectionMovedNoSettle: ->
    @_formulaBar?.syncNoSettle()
    world.noteStyleChanged @
    @_changed()
    return

  # clear the selected cell: a blank commit through the ordinary path (which also drops a dropped
  # widget entry), keeping the record and so its format
  _clearSelectedCellNoSettle: ->
    address = @model.addressFor @selectedCol, @selectedRow
    cell = @model.cellAt address
    return unless cell? and (cell.source isnt "" or cell.widgetEntry?)
    cell.widgetEntry = undefined if cell.widgetEntry?
    FormulaCompiler.commit cell, ""
    world.dataflow.markStale cell
    @_formulaBar?.syncNoSettle()
    return

  # ── editing: the edit lifecycle + its live overlay editor (the socket precursor) ──────────
  # All NoSettle: they run inside the ONE settle opened by the public event entry above.

  _currentCellSource: ->
    @model.cellAt(@model.addressFor @selectedCol, @selectedRow)?.source ? ""

  # Start an edit of the selected cell, its text `seedText`, with the caret in the cell's editor —
  # or, `inBar`, in the formula bar's text. Both show the text either way: the cell's editor is
  # mounted in both cases and the bar takes the same text, and whichever does not hold the caret
  # follows it as it is typed (reactToKeystroke).
  _startEditNoSettle: (seedText, inBar = false) ->
    return if @_editing
    # F1: the selection can sit OFF-viewport (wheel-scrolled away); editing it needs its
    # CellWdgt on screen for the overlay editor — scroll-follow first (Excel: typing jumps
    # the view back to the active cell). A no-op when the selection is already visible.
    @_scrollToShowSelectionNoSettle()
    @_editing = true
    @_editCol = @selectedCol
    @_editRow = @selectedRow
    @_editInBar = inBar
    @_editingCellWdgt()?._mountEditorNoSettle (seedText ? ""), (@_editorLookFor())
    @_reflowSpillOfAddressNoSettle @model.addressFor @_editCol, @_editRow
    @_formulaBar?.beginEditNoSettle (seedText ? ""), inBar
    # enter the STANDARD caret edit on the editor that takes the caret (the NoSettle twin — we
    # are inside this event's settle): the caret mounts as a child of the editor's parent with
    # its slot at the text end — right for both a type-to-edit seed char and an Enter/F2
    # edit-of-existing-source. The dispatch snapshot (KeydownInputEvent) guarantees this new
    # caret does NOT also receive the very key that started the edit.
    editor = @_liveEditorWdgt()
    world._editNoSettle editor if editor?
    return

  # the CellWdgt of the cell being edited, or undefined when not editing
  _editingCellWdgt: ->
    return undefined unless @_editCol? and @_editRow?
    @_cells.get @model.addressFor @_editCol, @_editRow

  # commit: compile the source ONCE (FormulaCompiler) and mark the cell stale; the once-per-cycle
  # dataflow drain (this same doOneCycle) recomputes the value and the grid repaints. The
  # source is what the user typed = the TEXT of the editor holding the caret (there is no
  # separate buffer). A blank text is a legitimate commit (it EMPTIES the cell); an UNREACHABLE
  # editor (its cell vanished under the edit — not a known path, the edit commits before any
  # scroll) must NOT masquerade as one: abandon instead of blanking. An error never blocks a
  # commit: a #SYNTAX, #ERR or #LOOP is the cell's VALUE (spec §9.6), shown in the cell and
  # explained in the formula bar.
  _commitEditNoSettle: ->
    return unless @_editing
    source = @_liveEditorWdgt()?.text
    unless source?
      @_teardownEditorNoSettle()
      return
    cell = @model.getOrCreateCellAt @model.addressFor @_editCol, @_editRow
    # F4: typed content of ANY kind — including blank — REPLACES a dropped widget-entry (the
    # gestures own the entry lifecycle, commit stays pure source machinery). The ex-entry
    # widget is destroyed by the drain's reconcile (the unhost), its engine edges by
    # Widget._destroyNoSettle. (Eject-to-world instead of destroying was considered and
    # rejected for v1 — see src/spreadsheet/CLAUDE.md.)
    cell.widgetEntry = undefined if cell.widgetEntry?
    FormulaCompiler.commit cell, source
    world.dataflow.markStale cell
    @_teardownEditorNoSettle()
    return

  _cancelEditNoSettle: ->
    return unless @_editing
    @_teardownEditorNoSettle()
    return

  # PUBLIC event entry (standard-caret editing): DOUBLE-CLICKING a cell edits its existing
  # source with the caret AT THE CLICKED SLOT (Excel-style; the click-on-already-selected
  # variant was considered and left out — double-click is the standard gesture). The cell
  # forwards its dispatcher-passed plane-mapped pos verbatim (cell/panel/sheet share one
  # island plane — the 4A convention; never world.hand.position(), the raw-pointer gate
  # bans it). Opens the ONE settle for the select + edit mount; the caret's move to the
  # clicked slot is the caret's own PUBLIC self-settling gotoSlot — a discrete event-time
  # entry exactly like a click on any editing text — so it runs AFTER this settle.
  startEditAtPointer: (address, pos) ->
    # early-return-sanctioned: an address that resolves to no cell has nothing to edit, and this is a
    # pointer-event path — opening a settle to discover that is churn, not thinness.
    colRow = @model.colRowFor address
    return unless colRow?
    @_settleLayoutsAfter =>
      @_commitEditNoSettle() if @_editing
      @selectedCol = colRow.col
      @selectedRow = colRow.row
      @_noteSelectionMovedNoSettle()
      @_startEditNoSettle @_currentCellSource()
    editor = @_liveEditorWdgt()
    world.caret.gotoSlot editor.slotAt pos if editor? and world.caret?
    return

  # PUBLIC event entry: a click on the formula bar's text edits the selected cell THERE, the caret
  # at the clicked slot (the bar forwards its plane-mapped pos, as a cell does). An edit already
  # live in the bar keeps going — the click just places the caret, which is the caret's own
  # business; an edit live in the cell commits first (acting elsewhere commits).
  editInFormulaBarAtPointer: (pos) ->
    # early-return-sanctioned: a click in the bar's text while the bar already holds the caret is
    # the caret's own placement, nothing for me to settle.
    return if @_editing and @_editInBar and @_isCaretEditLive()
    @_settleLayoutsAfter =>
      @_commitEditNoSettle() if @_editing
      @_startEditNoSettle @_currentCellSource(), true
    editor = @_liveEditorWdgt()
    world.caret.gotoSlot editor.slotAt pos if editor? and world.caret?
    return

  # PUBLIC (standard-caret editing): the accept/cancel handlers of the editing cell or of the
  # formula bar forward here — the caret's escalation fires at event time OUTSIDE any settle
  # (world.stopEditing already self-settled the caret teardown inside CaretWdgt.accept/cancel), so
  # these open the ONE settle for the commit/cancel work, exactly like processKeyDown /
  # activated. `how` is the key that ended the edit: Enter moves the selection down, Shift+Enter
  # up, and an edit ended by acting elsewhere (no key) leaves the selection where it is. Guarded:
  # an accept escalated by an unrelated nested editable text is a no-op.
  acceptCellEdit: (how) ->
    # early-return-sanctioned: an ESCALATION handler — an accept raised by an unrelated nested
    # editable text reaches us too, and for that case this method is the documented no-op above.
    # A no-op must not open a settle.
    return unless @_editing
    @_settleLayoutsAfter =>
      @_commitEditNoSettle()
      switch how
        when "Enter" then @_moveSelectionNoSettle 0, 1
        when "Shift+Enter" then @_moveSelectionNoSettle 0, -1
    return

  cancelCellEdit: ->
    # early-return-sanctioned: the cancel twin of acceptCellEdit's guard — same unrelated-escalation
    # no-op, same reason not to open a settle for it.
    return unless @_editing
    @_settleLayoutsAfter => @_cancelEditNoSettle()
    return

  # PUBLIC: Tab (direction 1) or Shift+Tab (-1) pressed in the editor of the cell or the bar —
  # commit, then move the selection right or left: Enter's verb on the other axis.
  tabFromEdit: (direction) ->
    # early-return-sanctioned: the escalation twin of acceptCellEdit's guard.
    return unless @_editing
    @_settleLayoutsAfter =>
      @_commitEditNoSettle()
      @_moveSelectionNoSettle direction, 0
    return

  # PUBLIC: a keystroke the caret just handled in a text inside me (CaretWdgt escalates it from
  # its target). While I am editing, the view that does not hold the caret takes the text the
  # one that does now shows, so the cell and the formula bar always agree. A keystroke in any
  # other text (a hosted widget's field) is none of my business.
  reactToKeystroke: ->
    # early-return-sanctioned: an escalation from an unrelated nested text reaches me too.
    return unless @_editing and @_isCaretEditLive()
    text = @_liveEditorWdgt().text
    @_settleLayoutsAfter =>
      if @_editInBar
        @_editingCellWdgt()?.mirrorEditTextNoSettle text
      else
        @_formulaBar?.mirrorEditTextNoSettle text
    return

  _teardownEditorNoSettle: ->
    editingCell = @_editingCellWdgt()
    # a caret still LIVE on the mounted editor (a commit reached from the wheel-scroll
    # commit-before-scroll or the dangling-edit self-heal — not from the caret's own
    # accept/cancel, which tear the caret down first) must die WITH the editor: the caret
    # is the editor's PARENT's child, not the editor's, so destroying the editor alone would
    # orphan the caret targeting a dead widget (its paint-time re-sync reads the target).
    world._stopEditingNoSettle() if @_isCaretEditLive()
    @_editing = false
    @_editCol = undefined
    @_editRow = undefined
    @_editInBar = false
    editingCell?._teardownEditorNoSettle()
    @_reflowSpillOfAddressNoSettle editingCell.address if editingCell?
    @_formulaBar?.endEditNoSettle()
    @_formulaBar?.syncNoSettle()
    @_changed()
    return

  # ── what a cell looks like: its text's font, alignment and inset at the current zoom ──────

  # the look of a cell's resting text, from its format and its value (CellWdgt.showScalarNoSettle):
  # numbers stand right and everything else left unless the format says otherwise
  _textLookFor: (cell, value) ->
    format = cell?.format
    alignment = if format?.align?
      AlignmentSpecHorizontal[format.align]
    else if typeof value is "number"
      AlignmentSpecHorizontal.RIGHT
    else
      AlignmentSpecHorizontal.LEFT
    {fontRole: (@_cellFontRole format), alignment: alignment, inset: @textInsetPx(), isError: (@isErrorValue value)}

  # the look of the editor an edit mounts on the editing cell (CellWdgt._mountEditorNoSettle)
  _editorLookFor: ->
    cell = @model.cellAt @model.addressFor @_editCol, @_editRow
    {fontRole: (@_cellFontRole cell?.format), inset: @textInsetPx()}

  # a value as its cell shows it: a number to the format's decimal places when the format sets
  # them, anything else as its own text
  _displayTextFor: (cell, value) ->
    return undefined unless value?
    decimals = cell?.format?.decimals
    if typeof value is "number" and decimals?
      value.toFixed decimals
    else
      value.toString()

  # PUBLIC: is `value` an error (a SheetError: #SYNTAX, #ERR, #LOOP)? The ONE place that asks, for
  # my cells' ink and my formula bar's message.
  isErrorValue: (value) ->
    value instanceof SheetError

  # PUBLIC: the fill a cell's format sets, or undefined (CellAppearance paints it under its edges)
  fillOfAddress: (address) ->
    @model.cellAt(address)?.format?.fill

  # ── the selected cell's STYLE, for the editing tools (R4/R5 of docs/archive/spreadsheet-ux-plan.md) ──

  # PUBLIC: what the editing tools act on while I am the editor focus — my selected cell's style
  # (EditorContentPropertyChangerButtonWdgt._styleSubject asks it). A fresh SheetCellStyle each time,
  # its fields read from the cell's format as it stands.
  textStyleSubject: ->
    new SheetCellStyle @, @model.addressFor @selectedCol, @selectedRow

  # PUBLIC (SheetCellStyle): change the format of the cell at `address` — `change` mutates a
  # format object, a copy of the cell's (or a fresh one) — then show the cell in it and tell the
  # tools. Formatting an empty cell gives it a record (blank source) to hold the format.
  restyleCell: (address, change) ->
    cell = @model.getOrCreateCellAt address
    format = Object.assign {}, (cell.format ? {})
    change format
    cell.format = format
    @_settleLayoutsAfter =>
      @_reconcileCellNoSettle cell, cell.value
      @_cells.get(address)?.noteFormatChanged()
    world.noteStyleChanged @
    return

  # PUBLIC (SheetCellStyle): enter `source` in the cell at `address` through the ordinary commit
  # path, as if typed (the slider-in-cell tool)
  enterSource: (address, source) ->
    @_settleLayoutsAfter =>
      @_commitEditNoSettle() if @_editing
      cell = @model.getOrCreateCellAt address
      cell.widgetEntry = undefined if cell.widgetEntry?
      FormulaCompiler.commit cell, source
      world.dataflow.markStale cell
      @_formulaBar?.syncNoSettle()
    return

  # PUBLIC (SheetCellStyle): the fill tool's colour prompt, for the cell at `address`; the
  # prompt's choice comes back through setFillOfSelection
  pickFillFor: (address) ->
    @_fillPickAddress = address
    @pickColor "fill:", "setFillOfSelection", (@fillOfAddress(address) ? WorldWdgt.theme.paper)

  # the colour prompt's callback (Widget.pickColor)
  setFillOfSelection: (aColor) ->
    address = @_fillPickAddress ? @model.addressFor @selectedCol, @selectedRow
    @restyleCell address, (format) -> format.fill = aColor
    return

  # ── zoom (R3) ───────────────────────────────────────────────────────────────────────────

  # PUBLIC: lay me out again at `factor` times my sizes (one of ZOOM_LEVELS): chrome, viewport
  # and every visible cell's look re-derive, and the selection stays in view
  setZoomFactor: (factor) ->
    @_settleLayoutsAfter => @_setZoomFactorNoSettle factor

  _setZoomFactorNoSettle: (factor) ->
    return if factor is @zoomFactor
    @_commitEditNoSettle() if @_editing
    @zoomFactor = factor
    @minimumExtent = @_leastExtent()
    @_buildChromeNoSettle()
    @_reconcileViewportNoSettle()
    @_cells.forEach (cellWdgt, address) =>
      record = @model.cellAt address
      @_reconcileCellNoSettle record, record.value if record? and cellWdgt.isVisible
    @_scrollToShowSelectionNoSettle()
    @_changed()
    # ANNOUNCE it, so every open zoom menu re-ticks — this one, a pinned copy, or one left open while
    # a script zoomed. markNonValueChange: my zoom is not a value I deliver.
    world.dataflow.markNonValueChange @
    return

  # the zoom menu's row action (SheetFormulaBarWdgt.openZoomMenu): slot 1 is the menu item,
  # slot 2 the subject, slot 3 the level
  setZoomFromMenu: (ignored1, ignored2, factor) ->
    @setZoomFactor factor

  # what a zoom menu row reads to decide whether it is the ticked one (MenuRowReflectionSpec.readerName)
  currentZoomFactor: -> @zoomFactor

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
  #   branch 3 — scalar / error / undefined → no hosted widget: the cell PAINTS toString() (or clears if undefined).
  _reconcileCellNoSettle: (cell, value) ->
    presented = @_presentCellNoSettle cell, value
    @_reflowSpillOfAddressNoSettle cell.address if cell?
    presented

  _presentCellNoSettle: (cell, value) ->
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
    # hosted widget: a hidden cell whose value just became scalar/presenter/undefined loses the
    # exemption and recycles now (F1 — the viewport invariant; a re-entry rebuilds from the
    # record like any off-screen cell)
    if not cellWdgt.isVisible and not (value instanceof Widget)
      cellWdgt._fullDestroyNoSettle()
      @_cells.delete cell.address
      return value
    # branch 1 — a live Widget value
    if value instanceof Widget
      if cellWdgt.hostedWidget? and cellWdgt.hostedWidget.constructor is value.constructor
        # RETAIN discards the recompute's just-constructed throwaway -- destroy it, or the
        # instances registry keeps one full widget assembly alive PER RECOMPUTE, forever
        # (never mounted, never wired: a pure orphan). NEVER on the F4 widget-entry path,
        # where the value IS the mounted instance itself (identity match, not a throwaway).
        value._fullDestroyNoSettle() unless value is cellWdgt.hostedWidget
        return cellWdgt.hostedWidget               # RETAIN (drag/restore keep the live instance)
      cellWdgt.hostNoSettle value
      cellWdgt.wireValueWidget value
      @_changed()
      return value
    # branch 2 — a value that presents as a widget
    if value? and typeof value.cellPresenter is "function"
      return value if cellWdgt.hostedWidget? and @_presentedValuesEqual cellWdgt.presentedValue, value
      presenter = value.cellPresenter()
      if presenter?
        cellWdgt.hostNoSettle presenter
        cellWdgt.presentedValue = value
        @_changed()
        return value
      # a value class may answer cellPresenter yet decline (undefined) → fall through to branch 3
    # branch 3 — scalar / error / undefined: the cell presents the text via its scalar StringWdgt
    # child (dropping any hosted widget)
    cellWdgt.showScalarNoSettle (@_displayTextFor cell, value), (@_textLookFor cell, value)
    @_formulaBar?.syncNoSettle() if @isSelectedAddress cell.address
    value

  # ── TEXT SPILL (docs/archive/spreadsheet-ux-plan.md R12) ──────────────────────────────────────
  # Left-aligned TEXT runs on into EMPTY cells to its right, stopping at the first cell with content
  # (or the viewport's edge); a covered cell strokes no left edge, so no gridline cuts through the
  # text. Numbers never spill (a number cut short would read as a different number), nor errors, nor
  # right- or centre-aligned text. A row's spill depends on every cell in it, so it is reflowed WHOLE
  # whenever one of its cells is presented, and every visible row after the viewport changes. The
  # editing cell counts as having content: its neighbour's text stops at it.

  _reflowSpillOfAddressNoSettle: (address) ->
    colRow = @model.colRowFor address
    return unless colRow?
    slotRow = colRow.row - @viewOriginRow
    @_reflowSpillOfRowNoSettle slotRow if slotRow >= 0 and slotRow < @_visibleRows()
    return

  _reflowSpillOfRowNoSettle: (slotRow) ->
    row = @viewOriginRow + slotRow
    cols = @_visibleCols()
    inset = @textInsetPx()
    colW = @_colW()
    cellAtSlot = (slotCol) => @_cells.get @model.addressFor (@viewOriginCol + slotCol), row
    spill = []
    covered = []
    slotCol = 0
    while slotCol < cols
      cellWdgt = cellAtSlot slotCol
      need = if @_spillsItsText cellWdgt then cellWdgt.textNeedsWidth inset
      if need? and need > colW
        reach = colW
        next = slotCol + 1
        while reach < need and next < cols and @_isEmptyForSpill cellAtSlot next
          covered[next] = true
          reach += colW
          next += 1
        spill[slotCol] = reach if reach > colW
        slotCol = next
      else
        slotCol += 1
    for slotCol in [0...cols]
      cellAtSlot(slotCol)?.setSpillNoSettle spill[slotCol], (covered[slotCol] is true), inset
    return

  # does this cell's resting text spill? Left-aligned text that is not a number nor an error, shown
  # by a cell that is not being edited
  _spillsItsText: (cellWdgt) ->
    return false unless cellWdgt?._scalarTextWdgt? and cellWdgt.isVisible and not cellWdgt._editorWdgt?
    record = @model.cellAt cellWdgt.address
    value = record?.value
    return false if typeof value is "number" or @isErrorValue value
    (@_textLookFor record, value).alignment is AlignmentSpecHorizontal.LEFT

  # can a neighbour's text run over this cell? Only when it shows nothing at all and is not being
  # edited
  _isEmptyForSpill: (cellWdgt) ->
    return false unless cellWdgt?
    not cellWdgt._scalarTextWdgt? and not cellWdgt.hostedWidget? and not cellWdgt._editorWdgt?

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
  # presenter (branch 2, a swatch), or undefined for a scalar / empty cell. The public reach into a
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
  # value is still undefined here — the predicate's undefined disjunct covers it), anything else recycles,
  # and every on-screen gap fills. The transient edit state resets.
  _reindexCellsNoSettle: ->
    @_editing = false
    @_editCol = undefined
    @_editRow = undefined
    @_cells = new Map
    @_cellsPanel = undefined
    @_headerCells = new Map
    # the formula bar is ADOPTED, like the cells: a copy or a snapshot carries it as my child (and
    # my handle to it), so it is re-attached and kept by the sweep below, and the chrome ensure
    # re-syncs it
    @_formulaBar?.attachSheet this
    # rescue the data cells out of any snapshot chrome, up to direct children
    for child in @children.slice()
      if child instanceof SheetCellsPanelWdgt
        for inner in child.children.slice()
          @_addNoSettle inner if inner instanceof CellWdgt
    # destroy everything that isn't a data cell or the adopted formula bar: old chrome (now empty
    # of cells) + strays
    for child in @children.slice()
      child._fullDestroyNoSettle() unless child instanceof CellWdgt or child is @_formulaBar
    # adopt + index the snapshot's cells; sweep their stray children (a mid-edit editor)
    for child in @children.slice()
      if child instanceof CellWdgt
        child.attachSheet this
        child._editorWdgt = undefined
        child._scalarTextWdgt = undefined
        child._scalarLookKey = undefined
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

  # NODE DEATH on every cell: drop its edges from the shared engine (the Phase-1 removeAllEdgesOf
  # API) — a destroyed sheet's cells are gone, so leaving their edges is a leak and a ghost
  # recompute. This belongs in the CORE, not on the public destroy() wrapper: bulk teardown
  # (fullDestroyChildren / _fullDestroyNoSettle / resetWorld) recurses core-to-core and never
  # touches the public verb, so cleanup hung there is skipped in exactly the case that needs it —
  # a whole subtree containing a sheet going away. Same rule, same reason, as
  # ShortcutWdgt's tracker cleanup.
  # The @model? guard covers the deserialization path, where an Object.create'd instance can be
  # destroyed before its model lands; forEachCell over an empty Map is a no-op, and
  # removeAllEdgesOf is cheap for a cell that was never a node.
  # My keyboard membership needs no line here — the base core drops me from world.keyboardEventsReceivers
  # itself, and the whole subtree (panel, headers, cells, any live editor on a cell) goes down with
  # super's child destruction.
  _destroyNoSettle: ->
    super
    @model?.forEachCell (cell) -> world.dataflow?.removeAllEdgesOf cell
