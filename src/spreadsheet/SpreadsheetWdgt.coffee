# SpreadsheetWdgt — the spreadsheet's painted grid (spec docs/specs/dataflow-engine-spec.md
# §9.1). "Painted chrome, widgetized contents": the widget's own paint draws the gridlines,
# the lettered column headers / numbered row headers, the selection, and the plain cell VALUES
# DIRECTLY — no widget-per-cell (that would defeat the framework's lack of widget
# virtualization). A live child widget (the socket) exists only for a cell being EDITED (the
# overlay editor, Phase 2b) or, later, holding/presenting a rich widget (Phase 4).
#
# The data lives in @model (a SheetModel, sparse Map keyed "A1"); each cell is a SheetCellRecord
# — a dataflow NODE. Committing an edit compiles the source once (FormulaCompiler) and marks the
# cell stale (world.dataflow.markStale); the once-per-cycle dataflow drain then recomputes it and
# the grid repaints — the engine's FIRST live client. This widget is also the formula SCOPE (`@`
# inside a formula is this SpreadsheetWdgt: full world access, no sandbox — spec §9.2).
#
# SCOPE + DEVIATIONS (recorded in the plan's Phase-2a/2b notes):
#   - DIRECT-PAINT, no ScrollPanelWdgt yet (2a). Fixed viewport; scroll deferred until the model
#     exceeds it. The paint + hit-test math transplant into a scroll-child unchanged.
#   - Values hand-painted with 12px Arial (SWCanvas ships Arial/Times/Courier atlases only —
#     src/boot/extensions/SWCanvasElement-extensions.coffee), left-aligned; centring / per-cell
#     clipping are later polish. No overflow clipping in v1 (test values are short).
#   - EDITING (2b) drives a plain edit BUFFER from this widget's own processKeyDown (append /
#     Backspace / Enter-commits / Escape-cancels) and mirrors it into a live overlay StringWdgt.
#     This is a deliberate deviation from reusing the caret: the framework provides NO built-in
#     "Enter commits / Escape reverts" (no accept/cancel handlers exist; text live-updates as you
#     type), and a live caret is a keyboard receiver that BLINKS (non-deterministic under a
#     screenshot). The buffer gives exact, deterministic commit/cancel and keeps THIS widget the
#     sole keyboard receiver throughout (no caret juggling). Rich editing (cursor, selection,
#     multi-line) stays the deferred CodePromptWdgt path (spec §9.1).
#
# Custom paint follows the AnalogClockWdgt model (paintIntoAreaOrBlitFromBackBuffer). Keyboard
# selection + editing use the standard receiver path (world.keyboardEventsReceivers +
# processKeyDown), focus-on-click; never a DOM listener.

class SpreadsheetWdgt extends Widget

  # transient UI state (rebuilt by interaction, never document data): the in-progress edit and
  # its live overlay editor are dropped from a snapshot (a mid-edit save restores to a settled,
  # not-editing sheet). @model / @selected* ARE document state and serialize normally.
  @serializationTransients: ["_editing", "_editBuffer", "_editCol", "_editRow", "_editor"]

  # fixed grid geometry (no column resize in v1)
  headerColWidth: 34     # the left row-number header column
  headerRowHeight: 20    # the top column-letter header row
  colWidth: 68
  rowHeight: 20
  numCols: 6             # A..F
  numRows: 14            # 1..14

  constructor: ->
    super()
    # selection is a single cell (0-based col/row); v1 always has one selected
    @selectedCol = 0
    @selectedRow = 0
    # the sparse data model — this widget paints it and is its formula scope (see FormulaCompiler)
    @model = new SheetModel @
    # colours (immutable + LRU-cached via Color.create; computed once here, never at class
    # scope — class-level Color statics would run at class-definition time, before Color loads)
    @backgroundColorGrid = Color.WHITE
    @headerFillColor = Color.create 236, 236, 236
    @gridlineColor = Color.create 198, 198, 198
    @headerBorderColor = Color.create 150, 150, 150
    @headerTextColor = Color.create 90, 90, 90
    @selectionColor = Color.create 40, 110, 210
    @valueTextColor = Color.create 30, 30, 30
    @errorTextColor = Color.create 200, 40, 40
    # editing state (a live overlay editor is the only live child widget in v1 — the socket
    # precursor, spec §9.1); nil / false until an edit begins
    @_editing = false
    @_editor = nil
    @_editBuffer = ""
    @_editCol = nil
    @_editRow = nil
    @setColor @backgroundColorGrid
    @_applyExtent new Point @_gridWidth(), @_gridHeight()
    return

  colloquialName: -> "spreadsheet"

  # FIXED size (elasticity 0): the grid keeps its own size as window content — it does NOT stretch
  # to fill a larger window. Two payoffs: the window content settles in ONE cycle (no multi-cycle
  # stretch convergence, so a screenshot taken right after open is already the fixed point — a
  # deterministic capture), and the grid is never resized under its own paint. The AnalogClockWdgt
  # pattern. (Scroll for a grid larger than the window is the deferred ScrollPanelWdgt work.)
  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false
    @layoutSpecDetails.elasticity = 0

  preferredExtentForWidth: (availW) ->
    new Point @_gridWidth(), @_gridHeight()

  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_applyExtent new Point @_gridWidth(), @_gridHeight()
    @height()

  _gridWidth:  -> @headerColWidth + @numCols * @colWidth
  _gridHeight: -> @headerRowHeight + @numRows * @rowHeight

  # ── painting (AnalogClockWdgt model) ────────────────────────────────────────────────────

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return
    [area, sl, st, al, at, w, h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil
      aContext.save()
      aContext.clipToRectangle al, at, w, h
      aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @backgroundTransparency
      @paintRectangle aContext, al, at, w, h, @backgroundColor
      aContext.useLogicalPixelsUntilRestore()
      widgetPosition = @position()
      aContext.translate widgetPosition.x, widgetPosition.y
      @_paintGrid aContext
      aContext.restore()
      @paintHighlight aContext, al, at, w, h

  # everything here is in LOGICAL pixels relative to the widget's top-left (aContext translated)
  _paintGrid: (aContext) ->
    gw = @_gridWidth()
    gh = @_gridHeight()

    # header strip backgrounds (top row of letters, left column of numbers)
    aContext.fillStyle = @headerFillColor.toString()
    aContext.fillRect 0, 0, gw, @headerRowHeight
    aContext.fillRect 0, 0, @headerColWidth, gh

    # inner gridlines (crisp 1px on the half-pixel)
    aContext.strokeStyle = @gridlineColor.toString()
    aContext.lineWidth = 1
    col = 0
    while col <= @numCols
      x = @headerColWidth + col * @colWidth
      aContext.beginPath()
      aContext.moveTo x + 0.5, 0
      aContext.lineTo x + 0.5, gh
      aContext.stroke()
      col += 1
    row = 0
    while row <= @numRows
      y = @headerRowHeight + row * @rowHeight
      aContext.beginPath()
      aContext.moveTo 0, y + 0.5
      aContext.lineTo gw, y + 0.5
      aContext.stroke()
      row += 1

    # a slightly darker border around the whole grid + under/right-of the headers
    aContext.strokeStyle = @headerBorderColor.toString()
    aContext.beginPath()
    aContext.moveTo 0.5, 0 ; aContext.lineTo 0.5, gh                       # left edge
    aContext.moveTo 0, 0.5 ; aContext.lineTo gw, 0.5                       # top edge
    aContext.moveTo @headerColWidth + 0.5, 0 ; aContext.lineTo @headerColWidth + 0.5, gh  # right of number header
    aContext.moveTo 0, @headerRowHeight + 0.5 ; aContext.lineTo gw, @headerRowHeight + 0.5 # under letter header
    aContext.stroke()

    # header text
    aContext.fillStyle = @headerTextColor.toString()
    aContext.font = @_gridFont()
    col = 0
    while col < @numCols
      x = @headerColWidth + col * @colWidth + 4
      aContext.fillText @model.colToLetters(col), x, @headerRowHeight - 6
      col += 1
    row = 0
    while row < @numRows
      y = @headerRowHeight + row * @rowHeight + @rowHeight - 6
      aContext.fillText ("" + (row + 1)), 4, y
      row += 1

    # committed cell VALUES, painted directly (no widget-per-cell). Only stored cells (sparse)
    # are visited; a value being edited is shown by its live overlay editor, so it is skipped
    # here. A SheetError paints in the error colour as its badge ("#SYNTAX"). No overflow
    # clipping in v1 (values are short) — a later polish, with centring.
    aContext.font = @_gridFont()
    @model.forEachCell (cell, address) =>
      cr = @model.colRowFor address
      return unless cr?
      return if cr.col >= @numCols or cr.row >= @numRows
      return if @_editing and cr.col is @_editCol and cr.row is @_editRow
      return unless cell.value?
      text = cell.value.toString()
      return if text is ""
      aContext.fillStyle = (if cell.errorFlag then @errorTextColor else @valueTextColor).toString()
      vx = @headerColWidth + cr.col * @colWidth + 4
      vy = @headerRowHeight + cr.row * @rowHeight + @rowHeight - 6
      aContext.fillText text, vx, vy

    # selection rectangle (drawn last, on top)
    if @selectedCol? and @selectedRow?
      sx = @headerColWidth + @selectedCol * @colWidth
      sy = @headerRowHeight + @selectedRow * @rowHeight
      aContext.strokeStyle = @selectionColor.toString()
      aContext.lineWidth = 2
      aContext.strokeRect sx + 1.5, sy + 1.5, @colWidth - 2, @rowHeight - 2

  # 12px Arial — the SWCanvas-deterministic band (see header). No bold/italic.
  _gridFont: -> "12px Arial, sans-serif"

  # ── selection: pointer + keyboard ───────────────────────────────────────────────────────

  # click a cell -> select it and take keyboard focus. Reading world.hand.position() (absolute)
  # and subtracting @position() (absolute top-left) gives the local offset regardless of window
  # nesting. A click elsewhere COMMITS an in-progress edit first (click-away commits). PUBLIC
  # event entry: it opens the ONE layout settle for its work (the mount/teardown of the overlay
  # editor happens through NoSettle cores below — the layering discipline, like world.edit).
  mouseClickLeft: ->
    @_settleLayoutsAfter =>
      @_commitEditNoSettle() if @_editing
      localPos = world.hand.position().subtract @position()
      cell = @_cellAtLocal localPos
      if cell?
        @selectedCol = cell.col
        @selectedRow = cell.row
        @_takeKeyboardFocus()
        @changed()
    return

  _cellAtLocal: (localPos) ->
    x = localPos.x
    y = localPos.y
    return nil if x < @headerColWidth or y < @headerRowHeight
    return nil if x >= @_gridWidth() or y >= @_gridHeight()
    col = Math.floor (x - @headerColWidth) / @colWidth
    row = Math.floor (y - @headerRowHeight) / @rowHeight
    return nil if col < 0 or col >= @numCols or row < 0 or row >= @numRows
    {col: col, row: row}

  _takeKeyboardFocus: ->
    world?.keyboardEventsReceivers?.add @   # a Set — idempotent

  # local {x,y,w,h} rect of a cell (relative to the widget top-left).
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

  # selection mode: arrows move the single-cell selection; Enter/F2 edit the existing source; a
  # printable key begins an edit seeded with that character (Excel-style type-to-edit).
  _processKeyWhileSelectingNoSettle: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->
    moved = false
    switch key
      when "ArrowRight"
        @selectedCol = Math.min @numCols - 1, @selectedCol + 1
        moved = true
      when "ArrowLeft"
        @selectedCol = Math.max 0, @selectedCol - 1
        moved = true
      when "ArrowDown"
        @selectedRow = Math.min @numRows - 1, @selectedRow + 1
        moved = true
      when "ArrowUp"
        @selectedRow = Math.max 0, @selectedRow - 1
        moved = true
      when "Enter", "F2"
        @_startEditNoSettle @_currentCellSource()
        return
    if moved
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
    @_editing = true
    @_editCol = @selectedCol
    @_editRow = @selectedRow
    @_editBuffer = seedText ? ""
    @_mountEditorNoSettle()
    return

  # a plain StringWdgt shows the buffer over the editing cell. isEditable false: THIS widget owns
  # the keys (no caret is ever mounted on it), so it is a passive display driven by @_editBuffer.
  # A freefloating child positioned at the cell's absolute rect (the _addNoSettle + _apply* idiom).
  _mountEditorNoSettle: ->
    rect = @_cellRectLocal @_editCol, @_editRow
    editor = new StringWdgt @_editBuffer, 12
    editor.color = @valueTextColor
    editor.isEditable = false
    @_addNoSettle editor
    editor._applyExtent new Point rect.w, rect.h
    editor._applyMoveTo @position().add new Point rect.x, rect.y
    @_editor = editor
    editor.changed()
    return

  _updateEditorTextNoSettle: ->
    @_editor?._setTextNoSettle @_editBuffer
    return

  # commit: compile the source ONCE (FormulaCompiler) and mark the cell stale; the once-per-cycle
  # dataflow drain (this same doOneCycle) recomputes the value and the grid repaints.
  _commitEditNoSettle: ->
    return unless @_editing
    cell = @model.getOrCreateCellAt @model.addressFor @_editCol, @_editRow
    FormulaCompiler.commit cell, @_editBuffer
    world.dataflow.markStale cell
    @_teardownEditorNoSettle()
    return

  _cancelEditNoSettle: ->
    return unless @_editing
    @_teardownEditorNoSettle()
    return

  _teardownEditorNoSettle: ->
    editor = @_editor
    @_editing = false
    @_editor = nil
    @_editBuffer = ""
    @_editCol = nil
    @_editRow = nil
    editor?._fullDestroyNoSettle()
    @changed()
    return

  # drop keyboard focus + any live editor when this sheet goes away, so a dead widget never
  # receives keys (the editor child is also torn down by super's child destruction).
  destroy: ->
    @_editor = nil
    world?.keyboardEventsReceivers?.delete @
    super()
