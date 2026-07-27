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
    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return
    sheetWidget = @widget._sheetWidget
    return unless sheetWidget?
    [area, sl, st, al, at, w, h] = @widget.calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil
      aContext.save()
      aContext.clipToRectangle al, at, w, h
      aContext.useLogicalPixelsUntilRestore()
      widgetPosition = @widget.position()
      aContext.translate widgetPosition.x, widgetPosition.y
      # the header-strip fill (was the sheet's two strip fillRects)
      aContext.fillStyle = sheetWidget.headerFillColor.toString()
      aContext.fillRect 0, 0, @widget.width(), @widget.height()
      # the header's top+left grid edges (grid-coloured first, dark last — the crossing rule).
      # The label is NOT painted here: it is the header's StringWdgt child (children paint after it).
      sheetWidget.paintGridEdges aContext, @widget.width(), @widget.height(), @_leftEdgeIsDark(), @_topEdgeIsDark()
      aContext.restore()
