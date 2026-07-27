# this file is excluded from the fizzygum homepage build

# Paints the layout-editing chrome family (LayoutSpacerWdgt,
# LayoutElementAdderOrDropletWdgt, StackElementsSizeAdjustingWdgt): a solid
# background box in ACTUAL pixels, then the widget's own drawLayoutChrome glyph
# tail in LOGICAL pixels with the origin translated to the widget position.
# The glyph tails stay subclass-polymorphic on the widgets; a transparent spacer
# (thisSpacerIsTransparent) paints nothing at all.

class LayoutChromeAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @widget.thisSpacerIsTransparent
      return

    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @widget.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @widget.alpha

    # paintRectangle here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called before the scaling.
    @widget.paintRectangle aContext, al, at, w, h, @widget.color
    aContext.useLogicalPixelsUntilRestore()

    widgetPosition = @widget.position()
    aContext.translate widgetPosition.x, widgetPosition.y

    @widget.drawLayoutChrome aContext

    aContext.restore()

    # _drawHighlightOverlay is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @_drawHighlightOverlay aContext, al, at, w, h
