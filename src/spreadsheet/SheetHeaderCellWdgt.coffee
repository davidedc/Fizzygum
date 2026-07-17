# SheetHeaderCellWdgt — one spreadsheet HEADER cell, as a real widget (plan §3-F F5, owner
# direction 2026-07-17: anything selectable/clickable should be a Widget). Three kinds share
# this class: the column-letter cells across the top, the row-number cells down the left, and
# the blank top-left corner. Headers are now inspectable, clickable widgets — a click
# escalates to the sheet exactly as a data-cell click does (today's behaviour, unchanged);
# column/row SELECTION semantics are a deliberate later arc, not part of the widgetisation.
#
# DERIVED chrome: carries no document state (@kind/@index are construction facts re-derivable
# from the sheet's geometry constants), so the restore/duplicate re-index DESTROYS and
# REBUILDS header cells rather than adopting them (SpreadsheetWdgt._reindexCellsNoSettle).
#
# It paints everything it shows (the F5 "the sheet paints nothing" flip):
#   - its header-strip fill (the sheet's headerFillColor — was the sheet's strip fillRects);
#   - its own TOP + LEFT grid edges via the sheet's paintGridEdges (the F5 edge-ownership
#     convention; the crossing rule lives there);
#   - its label at local (4, height − 6) — the exact offsets the sheet's deleted _paintGrid
#     used for header text, and the same ones CellWdgt uses for scalar text (the Phase-8
#     precedent that proved this text relocation byte-exact).

class SheetHeaderCellWdgt extends Widget

  # the back-ref would serialize a header→sheet→header cycle; it is re-set on build (and in
  # practice restored header cells are destroyed + rebuilt by the re-index, never adopted)
  @serializationTransients: ["_sheetWidget"]

  constructor: (kind, index) ->
    super()
    @kind = kind        # "column" | "row" | "corner"
    @index = index      # 0-based viewport SLOT index (the label = view origin + slot, F1); nil for the corner
    @_sheetWidget = nil
    # transparent by default — every visible pixel is painted explicitly below (the fill),
    # so there is no base-appearance paint to keep in sync
    @color = nil

  colloquialName: ->
    "header cell"

  # the owning sheet, set at build time (a transient back-ref — see @serializationTransients)
  attachSheet: (sheetWidget) ->
    @_sheetWidget = sheetWidget
    return

  # 12px Arial — the SWCanvas-deterministic band (Arial/Times/Courier atlases only); matches
  # the sheet's old header text and CellWdgt's scalar text. No bold/italic.
  _headerFont: -> "12px Arial, sans-serif"

  # @index is the viewport SLOT; the label derives from the sheet's view origin + slot at paint
  # time (F1) — scrolling relabels the frozen headers in place (cell-quantized scroll means they
  # never move; the sheet-level changed() repaints them). At origin 0 this is the identity.
  _labelText: ->
    switch @kind
      when "column" then @_sheetWidget.model.colToLetters (@_sheetWidget.viewOriginCol + @index)
      when "row"    then "" + (@_sheetWidget.viewOriginRow + @index + 1)
      else nil

  # F5 edge ownership: my LEFT edge is the DARK border colour when it sits on the sheet's
  # outer-left boundary (row headers, corner) or on the number-header separator (column 0);
  # my TOP edge is dark on the outer-top boundary (column headers, corner) or on the
  # under-letter-header separator (row 0). Everything else is the plain gridline colour.
  _leftEdgeIsDark: ->
    @kind is "row" or @kind is "corner" or (@kind is "column" and @index is 0)

  _topEdgeIsDark: ->
    @kind is "column" or @kind is "corner" or (@kind is "row" and @index is 0)

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return
    sheetWidget = @_sheetWidget
    return unless sheetWidget?
    [area, sl, st, al, at, w, h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil
      aContext.save()
      aContext.clipToRectangle al, at, w, h
      aContext.useLogicalPixelsUntilRestore()
      widgetPosition = @position()
      aContext.translate widgetPosition.x, widgetPosition.y
      # the header-strip fill, mine to paint now (was the sheet's two strip fillRects)
      aContext.fillStyle = sheetWidget.headerFillColor.toString()
      aContext.fillRect 0, 0, @width(), @height()
      # my top+left grid edges (grid-coloured first, dark last — the crossing rule)
      sheetWidget.paintGridEdges aContext, @width(), @height(), @_leftEdgeIsDark(), @_topEdgeIsDark()
      # my label (blank for the corner)
      label = @_labelText()
      if label?
        aContext.font = @_headerFont()
        aContext.fillStyle = sheetWidget.headerTextColor.toString()
        aContext.fillText label, 4, @height() - 6
      aContext.restore()
