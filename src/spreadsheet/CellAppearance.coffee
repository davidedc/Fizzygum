# Paints a CellWdgt's OWN pixels (F5 — every visible thing is a widget; the sheet paints
# nothing): the cell's top+left grid edges (ALWAYS — even when hosting/editing/empty; the F5
# edge-ownership convention, colours + crossing rule in SimpleSpreadsheetWdgt.paintGridEdges),
# then its selection ring when it is the selected cell (F2: drawn fully INSIDE — band [1,3),
# touching no edge pixel, under the cell's children since children paint after it — the
# scalar-text child included). Clipped to the cell. The cell's VALUE is not painted here: it
# is a child widget in every branch (hosted value / presenter / the scalar-text StringWdgt).

class CellAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    # shadow-pass paint contract (Widget.coffee "How the shadow painting works"): grid
    # edges and the selection ring are interior chrome on the sheet's opaque panels, not
    # coverage — they contribute nothing to a silhouette, so the shadow pass skips them.
    return if appliedShadow?
    sheetWidget = @widget._sheetWidget
    return unless sheetWidget?
    # alpha "none": edge/ring chrome painted at the ambient alpha, as it always was
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, { alpha: "none" }, (ctx) =>
      # dark edges sit on the header separators: the left edge of the viewport's FIRST visible
      # column and the top edge of its FIRST visible row (viewport-relative, F1 — at origin 0
      # that is sheet col/row 0, exactly the pre-scroll form)
      colRow = sheetWidget.model.colRowFor @widget.address
      sheetWidget.paintGridEdges ctx, @widget.width(), @widget.height(), (colRow?.col is sheetWidget.viewOriginCol), (colRow?.row is sheetWidget.viewOriginRow)
      # the cell's MODEL selection ring (F5 receipt B): drawn INLINE here, in the cell's own logical-pixel
      # scope, fully INSIDE it (band [1,3), under its hosted child). This is a distinct concern from the
      # editor-focus SELECTION overlay (Widget._drawSelectionOverlay): a cell is never world.editorFocusWdgt
      # (clicks escalate to the sheet; SheetCellsPanelWdgt opts its cells out of the editor-selection walk),
      # so the generic teal overlay never fires here -- the cell owns its selection look, the sheet the state.
      if sheetWidget.isSelectedAddress @widget.address
        ctx.strokeStyle = sheetWidget.selectionColor.toString()
        ctx.lineWidth = 2
        ctx.strokeRect 2, 2, @widget.width() - 4, @widget.height() - 4
