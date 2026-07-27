# Paints the LabelButtonWdgt's flat state-fill: a filled rectangle in the widget's
# normal colour (the menu background), its highlightColor (SILVER) on hover or its
# pressColor (GRAY) while pressed — solid BLACK on the shadow pass. The @label text
# is a child StringWdgt and paints itself; this appearance draws only the fill.

class LabelButtonAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if !@widget.visibleBasedOnIsVisibleProperty() or @widget.isInCollapsedSubtree()
      return nil

    [area,sl,st,al,at,w,h] = @widget.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    if appliedShadow?
      color = Color.BLACK
    else
      color = switch @widget.state
        when @widget.STATE_NORMAL
          @widget.color
        when @widget.STATE_HIGHLIGHTED
          @widget.highlightColor
        when @widget.STATE_PRESSED
          @widget.pressColor

    # paintRectangle works in actual (not logical) pixels, outside the
    # ceilPixelRatio scaling.
    @widget.paintRectangle \
      aContext,
      al, at, w, h,
      color,
      @widget.alpha,
      true, # push and pop the context
      appliedShadow

    @_drawHighlightOverlay aContext, al, at, w, h
