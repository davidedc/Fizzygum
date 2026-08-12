# Paints a SheetHeaderCellWdgt: the 236 header-strip fill, then the header's own
# top+left grid edges (F5 edge ownership — the dark-edge predicates live here with the
# paint; the label is the header's StringWdgt child and paints itself).

class SheetHeaderCellAppearance extends Appearance

  # F5 edge ownership: the LEFT edge is the DARK border colour when it sits on the sheet's
  # outer-left boundary (row headers, corner) or on the number-header separator (column 0);
  # the TOP edge is dark on the outer-top boundary (column headers, corner) or on the
  # under-letter-header separator (row 0). Everything else is the plain gridline colour.
  _leftEdgeIsDark: ->
    @widget.kind is "row" or @widget.kind is "corner" or (@widget.kind is "column" and @widget.index is 0)

  _topEdgeIsDark: ->
    @widget.kind is "column" or @widget.kind is "corner" or (@widget.kind is "row" and @widget.index is 0)

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    # shadow-pass paint contract (Widget.coffee "How the shadow painting works"): the
    # header fill + grid edges are interior chrome on the sheet's opaque panels, not
    # coverage (the panels beneath provide it) — the shadow pass skips them.
    return if appliedShadow?
    sheetWidget = @widget._sheetWidget
    return unless sheetWidget?
    # alpha "none": fill/edge chrome painted at the ambient alpha, as it always was
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, { alpha: "none" }, (ctx) =>
      # the header-strip fill
      ctx.fillStyle = sheetWidget.headerFillColor.toString()
      ctx.fillRect 0, 0, @widget.width(), @widget.height()
      # the header's top+left grid edges (grid-coloured first, dark last — the crossing rule).
      # The label is NOT painted here: it is the header's StringWdgt child (children paint after it).
      sheetWidget.paintGridEdges ctx, @widget.width(), @widget.height(), @_leftEdgeIsDark(), @_topEdgeIsDark()
