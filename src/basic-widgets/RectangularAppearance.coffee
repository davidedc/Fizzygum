class RectangularAppearance extends Appearance

  isTransparentAt: (aPoint) ->
    if @morph.boundingBoxTight().containsPoint aPoint
      return false
    if @morph.backgroundTransparency? and @morph.backgroundColor?
      if @morph.backgroundTransparency > 0
        if @morph.boundsContainPoint aPoint
          return false
    return true

  # paintHighlight can work in two patterns:
  #  * passing actual pixels, when used
  #    outside the effect of the scope of
  #    "useLogicalPixelsUntilRestore()", or
  #  * passing logical pixels, when used
  #    inside the effect of the scope of
  #    "useLogicalPixelsUntilRestore()", or
  # Mostly, the first pattern is used.
  #
  # useful for example when hovering over references
  # to morphs. Can only modify the rendering of a morph,
  # so any highlighting is only visible in the measure that
  # the morph is visible (as opposed to HighlighterMorph being
  # used to highlight a morph)
  paintHighlight: (aContext, al, at, w, h) ->
    return
    
    #if !@morph.highlighted
    #  return
    #
    # paintRectangle here is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels.
    #@morph.paintRectangle \
    #  aContext,
    #  al, at, w, h,
    #  "orange",
    #  0.5,
    #  true # push and pop the context


  # This method only paints this very morph
  # i.e. it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer,
  # which eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @morph.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return nil

    [area,sl,st,al,at,w,h] = @morph.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    @morph.justBeforeBeingPainted?()

    aContext.save()
    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @morph.alpha
    if !@morph.color? then debugger
    aContext.fillStyle = @morph.color.toString()

    # paintRectangle is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio

    # paint the background
    toBePainted = new Rectangle al, at, al + w, at + h

    if @morph.backgroundColor?
      color = @morph.backgroundColor
      if appliedShadow?
        color = Color.BLACK
      @morph.paintRectangle aContext, toBePainted.left(), toBePainted.top(), toBePainted.width(), toBePainted.height(), color


    # now paint the actual morph, which is a rectangle
    # (potentially inset because of the padding)
    toBePainted = toBePainted.intersect @morph.boundingBoxTight().scaleBy ceilPixelRatio

    color = @morph.color
    if appliedShadow?
      color = Color.BLACK

    @morph.paintRectangle aContext, toBePainted.left(), toBePainted.top(), toBePainted.width(), toBePainted.height(), color

    @drawAdditionalPartsOnBaseShape? false, false, appliedShadow, aContext, al, at, w, h

    if !appliedShadow?
      @paintStroke aContext, clippingRectangle

    aContext.restore()

    # paintHighlight is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio
    @paintHighlight aContext, al, at, w, h

  paintStroke: (aContext, clippingRectangle) ->

    if @morph.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return nil

    [area,sl,st,al,at,w,h] = @morph.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    @morph.justBeforeBeingPainted?()

    aContext.save()

    toBePainted = new Rectangle al, at, al + w, at + h
    toBePainted = toBePainted.intersect @morph.boundingBoxTight().scaleBy ceilPixelRatio

    # Right now the stroke width is baked to 1, regardless of the ceilPixelRatio.
    #
    # Some notes / thoughts around that:
    #  1) for a stroke width of 1, the stroke is inset by half a pixel. This is needed because lines
    #     in HTML5 Canvas are centered on the coordinates, so we have to center them in the middle
    #     of the pixel to fill the full width of precisely one pixel.
    #  2) this means that the stroke is drawn inside the morph, so in rectangular morphs that clip at
    #     their bounds, the stroke will NOT be clipped
    #
    #  IF you'll want to make the stroke width arbitrary then...
    #
    #  3) in case the stroke width is even (which might depend on the ceilPixelRatio, see a TODO further below
    #     in the code), you don't need to inset by 0.5. TODO.
    #  4) in case the stroke is > 1, the question is where do we draw it? All inside so that it's not clipped?
    #     But then that eats into the morph's area... TODO.

    if @morph.strokeColor?

      aContext.beginPath()
      aContext.rect Math.round(toBePainted.left()),
        Math.round(toBePainted.top()),
        Math.round(toBePainted.width()),
        Math.round(toBePainted.height())
      aContext.clip()

      aContext.globalAlpha = @morph.alpha
      aContext.lineWidth = 1 # TODO might look better if * ceilPixelRatio
      aContext.strokeStyle = @morph.strokeColor.toString()
      # half-pixel adjustments are needed in HTML5 Canvas to draw
      # pixel-perfect lines. Also note how we have to multiply the
      # morph metrics to bring them to physical pixels coords.
      aContext.strokeRect  (Math.round(@morph.left() * ceilPixelRatio)+0.5),
          (Math.round(@morph.top() * ceilPixelRatio)+0.5),
          (Math.round(@morph.width() * ceilPixelRatio)-1),
          (Math.round(@morph.height() * ceilPixelRatio)-1)

    aContext.restore()

