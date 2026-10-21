# Paints a SheetHeaderCellWdgt: its header fill (spreadsheetHeaderFill), then the header's own
# top+left grid edges (F5 edge ownership — what each edge is gets decided here with the paint; the
# label is the header's StringWdgt child and paints itself).

class SheetHeaderCellAppearance extends Appearance

  # edge/ring chrome paints at the ambient alpha (see Appearance).
  alphaPolicy: "none"

  # F5 edge ownership (the edge kinds of SimpleSpreadsheetWdgt.paintGridEdges). The corner and
  # the row headers stand on the sheet's OUTER LEFT boundary, so their left edge is none; a column
  # header's left edge is the RULE right of the number column for the first column (slot 0), a
  # gridline for every other.
  _leftEdge: ->
    return undefined if @widget.kind is "row" or @widget.kind is "corner"
    if @widget.viewportSlot is 0 then "rule" else "gridline"

  # The corner and the column headers stand on the sheet's OUTER TOP boundary, so their top edge
  # is none; a row header's top edge is the RULE under the letter row for the first row (slot 0),
  # a gridline for every other.
  _topEdge: ->
    return undefined if @widget.kind is "column" or @widget.kind is "corner"
    if @widget.viewportSlot is 0 then "rule" else "gridline"

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    # shadow-pass paint contract (Widget.coffee "How the shadow painting works"): the
    # header fill + grid edges are interior chrome on the sheet's opaque panels, not
    # coverage (the panels beneath provide it) — the shadow pass skips them.
    return if appliedShadow?
    sheetWidget = @widget._sheetWidget
    return unless sheetWidget?
    # alpha "none": fill/edge chrome painted at the ambient alpha
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      # the header fill
      ctx.fillStyle = WorldWdgt.theme.spreadsheetHeaderFill.toString()
      ctx.fillRect 0, 0, @widget.width(), @widget.height()
      # the header's top+left grid edges (a gridline first, the rule last — the crossing rule).
      # The label is NOT painted here: it is the header's StringWdgt child (children paint after it).
      sheetWidget.paintGridEdges ctx, @widget.width(), @widget.height(), @_leftEdge(), @_topEdge()
