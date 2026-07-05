# SpreadsheetWdgt — the spreadsheet's painted grid (spec docs/specs/dataflow-engine-spec.md
# §9.1). "Painted chrome, widgetized contents": the widget's own paint draws the gridlines,
# the lettered column headers / numbered row headers, the selection, and the plain cell VALUES
# DIRECTLY — no widget-per-cell (that would defeat the framework's lack of widget
# virtualization). A live child widget exists only for a cell being EDITED (the overlay editor,
# Phase 2b) or presenting a RICH value — a CellSocketWdgt (Phase 4) that hosts a cell's live
# value-widget (a `new SliderWdgt`, branch 1) or presenter (a Color → a swatch, branch 2).
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

  # transient UI state (rebuilt by interaction, never document data): the in-progress edit and its
  # live overlay editor are dropped from a snapshot (a mid-edit save restores to a settled,
  # not-editing sheet). The cell-socket INDEX (@_cellSockets: address → CellSocketWdgt) is transient
  # too — but note the socket WIDGETS themselves are ordinary children and DO ride the tree, so a
  # widget-valued cell's live widget (a dragged slider's position) survives save/load (spec §13
  # retain-and-remount). On restore the index is rebuilt from those socket children
  # (_reindexCellSocketsNoSettle → recommitAllCells → drain → reconcile): a DERIVED presenter (a
  # Color's swatch, spec §9.4 "one-way glass") is rebuilt from the value, a state-bearing value-widget
  # is RETAINED. @model / @selected* ARE document state and serialize normally.
  @serializationTransients: ["_editing", "_editBuffer", "_editCol", "_editRow", "_editor", "_cellSockets"]

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
    # cell-socket index (spec §9.3/§9.4 classify→present): a cell whose value IS a Widget (branch 1)
    # or answers cellPresenter() (branch 2) mounts a CellSocketWdgt in its rect, hosting that widget.
    # Maps the cell address → its socket. Scalars paint directly (no socket). TRANSIENT (the socket
    # widgets themselves ride the tree as children; this index is rebuilt from them on restore by
    # _reindexCellSocketsNoSettle, and grown by the drain — see _reconcileCellSocketNoSettle).
    @_cellSockets = new Map
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
    # are visited; a value being edited is shown by its live overlay editor, and a value HOSTED in a
    # socket — a widget-valued cell (branch 1) or a value that presents as a widget (a Color → a
    # swatch, branch 2, spec §9.4) — is drawn by that mounted widget, so both are skipped here. A
    # SheetError paints in the error colour as its badge ("#SYNTAX"). No overflow clipping in v1
    # (values are short) — a later polish, with centring.
    aContext.font = @_gridFont()
    @model.forEachCell (cell, address) =>
      cr = @model.colRowFor address
      return unless cr?
      return if cr.col >= @numCols or cr.row >= @numRows
      return if @_editing and cr.col is @_editCol and cr.row is @_editRow
      return if @_cellSockets.has address
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

  # single-sheet keyboard focus: the sheet the user is typing into is the ONLY sheet receiving
  # keys. Other sheets stay rendered but inactive — WITHOUT this, a DUPLICATED sheet (the copier's
  # alignCopiedWidgetToKeyboardEventsReceiversSet inherits the original's keyboard-receiver
  # membership) would sit in the receivers set too and edit in LOCKSTEP with this one. Non-sheet
  # receivers (carets, …) are untouched. (Full multi-sheet focus was deferred in 2a; this is the
  # minimal single-focus the multi-sheet case needs to behave.)
  _takeKeyboardFocus: ->
    return unless world?.keyboardEventsReceivers?
    world.keyboardEventsReceivers.forEach (r) =>
      world.keyboardEventsReceivers.delete r if (r isnt @) and (r instanceof SpreadsheetWdgt)
    world.keyboardEventsReceivers.add @   # a Set — idempotent

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

  # ── cell sockets: classify → present (spec §9.3/§9.4) ────────────────────────────────────
  # Called from SheetCellRecord._cacheValue right after a cell recomputes, so it runs INSIDE the
  # dataflow drain's layout settle (DataflowEngine._drainOnePass wraps the pass in
  # world._settleLayoutsAfter) — hence every helper here is a NoSettle core, exactly like the editor.
  #
  # RETURNS the value to CACHE on the record: normally `value` unchanged, but for a widget-valued cell
  # that keeps its existing widget the RETAINED instance (so the record's @value IS the mounted
  # widget). The fallback chain (spec §9.4):
  #   branch 1 — value IS a Widget → host it live in a CellSocketWdgt (a slider, a picker). RETAIN an
  #     existing hosted widget of the SAME class: its runtime state IS the cell's live state (a dragged
  #     slider's position; a restored widget's saved position — spec §13 retain-and-remount), so the
  #     just-constructed throwaway is discarded and the live one kept. This is exactly what lets a
  #     widget-valued cell be marked stale by its OWN widget's interaction (cellInput → markStale)
  #     WITHOUT the recompute resetting the widget being dragged. (Re)build only on first mount / class
  #     change. The socket wires the widget so its firings mark the cell stale (interactivity in).
  #   branch 2 — value answers cellPresenter() (a Color → a swatch) → host that presenter. Lifecycle
  #     (spec §13): REBUILD on value change; a churn-skip keeps an unchanged value's presenter, so a
  #     steady cell rebuilds nothing. No reuse-and-update — keeps the sheet value-class-agnostic (it
  #     just calls cellPresenter() again). A presenter is "one-way glass": it is NOT wired.
  #   branch 3 — scalar / error / nil → no widget: drop any socket; the grid paints toString().
  _reconcileCellSocketNoSettle: (cell, value) ->
    return value unless cell?
    address = cell.address
    socket = @_cellSockets.get address
    # branch 1 — a live Widget value
    if value instanceof Widget
      if socket?.hostedWidget? and socket.hostedWidget.constructor is value.constructor
        return socket.hostedWidget                 # RETAIN (drag/restore keep the live instance)
      socket = @_ensureCellSocketNoSettle address
      return value unless socket?                   # off-viewport guard (v1: every cell is on-screen)
      socket.hostNoSettle value
      socket.wireValueWidget value
      @changed()
      return value
    # branch 2 — a value that presents as a widget
    if value? and typeof value.cellPresenter is "function"
      return value if socket?.hostedWidget? and @_presentedValuesEqual socket.presentedValue, value
      presenter = value.cellPresenter()
      if presenter?
        socket = @_ensureCellSocketNoSettle address
        return value unless socket?
        socket.hostNoSettle presenter
        socket.presentedValue = value
        @changed()
        return value
      # a value class may answer cellPresenter yet decline (nil) → fall through to branch 3
    # branch 3 — scalar / error / nil
    @_disposeCellSocketNoSettle address if socket?
    value

  # a.equals?(b) when the value defines it (Color does), else identity — mirrors the engine's cutoff.
  _presentedValuesEqual: (a, b) ->
    if a?.equals? then a.equals b else a is b

  # the socket for an address, creating + attaching + positioning it if absent (repositioning an
  # existing one too — cheap, keeps a rebuilt cell correct). A freefloating child at the cell's
  # absolute rect, inset by the gridline so header/gridlines/selection stay visible (the _addNoSettle
  # + _apply* idiom the overlay editor uses). Returns nil for a cell outside the fixed viewport (v1
  # has none — every cell is on-screen; Phase 8's viewport-bounded materialisation is where that bites).
  _ensureCellSocketNoSettle: (address) ->
    cr = @model.colRowFor address
    return nil unless cr?
    return nil if cr.col >= @numCols or cr.row >= @numRows
    socket = @_cellSockets.get address
    unless socket?
      socket = new CellSocketWdgt address
      socket.attachSheet this
      @_addNoSettle socket
      @_cellSockets.set address, socket
    rect = @_cellRectLocal cr.col, cr.row
    inset = 2
    socket._applyExtent new Point rect.w - 2 * inset, rect.h - 2 * inset
    socket._applyMoveTo @position().add new Point rect.x + inset, rect.y + inset
    socket

  _disposeCellSocketNoSettle: (address) ->
    socket = @_cellSockets.get address
    return unless socket?
    @_cellSockets.delete address
    socket._fullDestroyNoSettle()
    @changed()
    return

  # the connection target a hosted interactive value-widget fires into (via CellSocketWdgt.cellInput):
  # mark the cell STALE so the drain recomputes its dependents (spec §9.3 — a drag = a per-cycle
  # recompute of the closure). A pooled dataflow mark, NOT a layout settle, so no settle is opened here
  # (the drain owns any settle for the recompute).
  _markCellStaleFromSocketNoSettle: (address) ->
    cell = @model.cellAt address
    world.dataflow?.markStale cell if cell?
    return

  # PUBLIC: the live widget a cell currently hosts — its value-widget (branch 1, a slider) or
  # presenter (branch 2, a swatch), or nil for a scalar / empty cell. The public reach into a
  # mounted cell widget (a macro drags `sheet.hostedWidgetAt "A1"`, never the private socket index).
  hostedWidgetAt: (address) -> @_cellSockets.get(address)?.hostedWidget

  # ── serialization / duplication (spec §2: the engine index is derived + disposable) ──────────

  # Rebuild every cell's DERIVED state (compiledFn / value / edges) from its persisted @source,
  # then mark all stale so the next drain recomputes the whole sheet in dependency order. A
  # RESTORED (deserialize) or DUPLICATED (deep-copy) sheet re-declares its OWN edges here rather
  # than serializing/copying the shared engine — the two hooks below call this.
  # NoSettle core (not a self-settling wrapper): the notification hooks below call it directly, and
  # the copy/deserialize gesture owns the enclosing settle (layering rule [J]); both hooks fire on a
  # DETACHED sheet (orphan). First RE-INDEX the cell sockets (below) from the restored/copied socket
  # children, so the recompute RETAINS a widget-valued cell's live widget instead of rebuilding it
  # (spec §13); presenters (derived) rebuild from values.
  recommitAllCells: ->
    return unless @model?
    @_reindexCellSocketsNoSettle()
    @model.forEachCell (cell) -> FormulaCompiler.commit cell, cell.source
    @model.forEachCell (cell) -> world.dataflow?.markStale cell
    return

  # After restore/duplicate the transient @_cellSockets index is empty, but the socket WIDGETS rode
  # the tree as this sheet's children — each carrying its @address and its hosted value/presenter
  # widget (a restored slider keeps its dragged position, spec §13). Rebuild the address→socket index
  # from them and re-attach the back-ref, so the recompute above RETAINS a widget-valued cell's
  # restored widget (class match) rather than rebuilding it — a DERIVED presenter is rebuilt from the
  # value (its churn-skip @presentedValue is nil after restore, which forces the rebuild), a
  # state-bearing value-widget is kept. DESTROY any non-socket stray child (a mid-edit overlay editor
  # that rode a subtree snapshot) and reset the transient edit state.
  _reindexCellSocketsNoSettle: ->
    @_editing = false
    @_editor = nil
    @_editBuffer = ""
    @_editCol = nil
    @_editRow = nil
    @_cellSockets = new Map
    for child in @children.slice()
      if child instanceof CellSocketWdgt
        child.attachSheet this
        @_cellSockets.set child.address, child
      else
        child._fullDestroyNoSettle()
    return

  # after a deep-copy (the duplicate gesture → fullCopy → deepCopy): the copier runs this once the
  # whole subtree — model + records — is cloned, so the copy's fresh records wire THEIR OWN edges
  # (independent of the original's), and a subsequent edit to the original leaves the copy alone.
  _reactToBeingCopied: ->
    @recommitAllCells()

  # after deserialize (loading a saved world/sheet): the same source-driven rebuild.
  _afterDeserialization: ->
    @recommitAllCells()

  # drop keyboard focus + any live editor when this sheet goes away, so a dead widget never
  # receives keys (the editor child is also torn down by super's child destruction). Also perform
  # NODE DEATH on every cell: drop its edges from the shared engine (the Phase-1 removeAllEdgesOf
  # API) — a destroyed sheet's cells are gone, so leaving their edges would leak and could
  # ghost-recompute.
  destroy: ->
    @_editor = nil
    world?.keyboardEventsReceivers?.delete @
    @model?.forEachCell (cell) -> world.dataflow?.removeAllEdgesOf cell
    super()
