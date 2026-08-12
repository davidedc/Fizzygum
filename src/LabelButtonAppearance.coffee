# Paints the LabelButtonWdgt's flat state-fill: a filled rectangle in the widget's
# normal colour (the menu background), its highlightColor (SILVER) on hover or its
# pressColor (GRAY) while pressed — solid BLACK on the shadow pass. The @label text
# is a child StringWdgt and paints itself; this appearance draws only the fill.

class LabelButtonAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    # unconditional (unlike preliminaryCheckNothingToDraw's live-tree-conditioned twin gates):
    # a hidden/collapsed label button skips even scratch renders, as it always did
    if !@widget.visibleBasedOnIsVisibleProperty() or @widget.isInCollapsedSubtree()
      return nil

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, nil, (ctx, localArea) =>
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

      if color?
        ctx.fillStyle = color.toString()
        @_fillLocalRectSnappedToDevicePixels ctx, localArea
