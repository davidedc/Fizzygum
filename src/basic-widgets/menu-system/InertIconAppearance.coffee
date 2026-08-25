# Paints an InertIconHolderWdgt: one blit of the raster the holder took at derive time, and
# nothing else. No art of its own, no state, no reading of the widget beyond its picture and its
# box -- the holder IS its picture.

class InertIconAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    return undefined unless @widget.raster?

    # THE SHADOW PASS DRAWS NOTHING. A picture of this kind sits on the opaque body of a menu row,
    # whose own black box is already the complete silhouette over my area, so my art adds no
    # coverage to it -- the LayoutChromeAppearance reasoning ("the chrome art drawn inside it adds
    # no coverage and is skipped, like the hover highlight"). A holder placed somewhere that casts
    # a shadow of its OWN would want a blackened twin of the raster here instead.
    return undefined if appliedShadow?

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      # The raster is DEVICE-sized (fullImage builds it at extent x ceilPixelRatio) while the scope
      # draws in LOGICAL pixels, so handing drawImage my logical extent maps it back one device
      # pixel to one: a blit, not a resample. Art geometry comes from the WIDGET (origin 0,0, my
      # own extent) and never from the damage box, which the scope has already clipped to.
      ctx.drawImage @widget.raster, 0, 0, @widget.width(), @widget.height()
      return
