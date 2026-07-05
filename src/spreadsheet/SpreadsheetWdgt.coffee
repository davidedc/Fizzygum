# SpreadsheetWdgt — the spreadsheet's painted grid (spec docs/specs/dataflow-engine-spec.md
# §9.1). "Painted chrome, widgetized contents": the widget's own paint draws the gridlines,
# the lettered column headers / numbered row headers, the selection, and (from Phase 2b) plain
# cell values DIRECTLY — no widget-per-cell (that would defeat the framework's lack of widget
# virtualization). A live child widget (the socket) will exist only for cells holding/presenting
# rich widgets or being edited (Phases 2b/4).
#
# v1 (Phase 2a) SCOPE + DEVIATIONS (recorded in the implementation plan's Phase-2a notes):
#   - DIRECT-PAINT, no ScrollPanelWdgt yet. The grid is a fixed viewport that fits the window;
#     scroll (the spec's ScrollPanelWdgt hosting) is deferred until the model exceeds the
#     viewport. The paint + hit-test math below transplant into a scroll-child unchanged.
#   - Text is hand-painted with 12px Arial — SWCanvas ships bitmap atlases for Arial/Times/
#     Courier ONLY (src/boot/extensions/SWCanvasElement-extensions.coffee), so 12px Arial is the
#     deterministic choice (StringWdgt renders it identically suite-wide). Left-aligned with a
#     small pad in v1 (centering needs measureText — a later polish).
#
# Custom paint follows the AnalogClockWdgt model (paintIntoAreaOrBlitFromBackBuffer). Keyboard
# selection uses the standard receiver path (world.keyboardEventsReceivers + processKeyDown),
# focus-on-click; never a DOM listener.

class SpreadsheetWdgt extends Widget

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
    # colours (immutable + LRU-cached via Color.create; computed once here, never at class
    # scope — class-level Color statics would run at class-definition time, before Color loads)
    @backgroundColorGrid = Color.WHITE
    @headerFillColor = Color.create 236, 236, 236
    @gridlineColor = Color.create 198, 198, 198
    @headerBorderColor = Color.create 150, 150, 150
    @headerTextColor = Color.create 90, 90, 90
    @selectionColor = Color.create 40, 110, 210
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

  # column index -> spreadsheet letters (0->A, 25->Z, 26->AA, …)
  _colToLetters: (col) ->
    s = ""
    n = col
    loop
      s = String.fromCharCode(65 + (n % 26)) + s
      n = Math.floor(n / 26) - 1
      break if n < 0
    s

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
      aContext.fillText @_colToLetters(col), x, @headerRowHeight - 6
      col += 1
    row = 0
    while row < @numRows
      y = @headerRowHeight + row * @rowHeight + @rowHeight - 6
      aContext.fillText ("" + (row + 1)), 4, y
      row += 1

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
  # nesting.
  mouseClickLeft: ->
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

  # standard keyboard path (§1.17): arrows move the single-cell selection.
  processKeyDown: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->
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
    @changed() if moved
    return

  # drop keyboard focus when this sheet goes away, so a dead widget never receives keys
  destroy: ->
    world?.keyboardEventsReceivers?.delete @
    super()
