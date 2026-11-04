# Paints a SheetFormulaBarWdgt's own pixels: its field's WELL (the text field's look, StringFieldWdgt's:
# a borderless rounded box in the textFieldFill role at textFieldCornerRadius) at the bar's fieldRect, and
# the 1 px RULE along its bottom in spreadsheetHeaderRule, the line the column headers stand under (their
# own top edges are none there). The address, the source, an error's message and the zoom button are the
# bar's children and paint over this. No fill of its own: the paper of the window shows through, as it
# does under the cells.

class SheetFormulaBarAppearance extends Appearance

  # chrome paints at the ambient alpha (see Appearance)
  alphaPolicy: "none"

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    # shadow-pass paint contract (Widget.coffee "How the shadow painting works"): the well and the
    # rule are interior chrome on the sheet's page, not coverage — the shadow pass skips them
    return if appliedShadow?
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      theme = WorldWdgt.theme
      field = @widget.fieldRect
      if field? and field.width() > 0 and field.height() > 0
        ctx.fillStyle = theme.textFieldFill.toString()
        ctx.fillRoundRect field.left(), field.top(), field.width(), field.height(), theme.textFieldCornerRadius
      ctx.fillStyle = theme.spreadsheetHeaderRule.toString()
      ctx.fillRect 0, @widget.height() - 1, @widget.width(), 1
      return
    return
