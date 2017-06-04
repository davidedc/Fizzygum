# RectangularAppearance //////////////////////////////////////////////////////////////

class RectangularAppearance extends Appearance
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

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
  #    "scale pixelRatio, pixelRatio", or
  #  * passing logical pixels, when used
  #    inside the effect of the scope of
  #    "scale pixelRatio, pixelRatio", or
  # Mostly, the first pattern is used.
  paintHighlight: (aContext, al, at, w, h) ->
    if !@morph.highlighted
      return

    # paintRectangle here is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels.
    @morph.paintRectangle \
      aContext,
      al, at, w, h,
      "orange",
      0.5,
      true # push and pop the context


  # This method only paints this very morph
  # i.e. it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer,
  # which eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle) ->

    if @morph.preliminaryCheckNothingToDraw false, clippingRectangle, aContext
      return null

    [area,sl,st,al,at,w,h] = @morph.calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return null

      @morph.justBeforeBeingPainted?()

      aContext.save()
      aContext.globalAlpha = @morph.alpha
      aContext.fillStyle = @morph.color.toString()

      if !@morph.color?
        debugger


      # paintRectangle is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio

      # paint the background
      toBePainted = new Rectangle al, at, al + w, at + h
      @morph.paintRectangle aContext, toBePainted.left(), toBePainted.top(), toBePainted.width(), toBePainted.height(), @morph.backgroundColor, @morph.backgroundTransparency

      # now paint the actual morph, which is a rectangle
      # (potentially inset because of the padding)
      toBePainted = toBePainted.intersect @morph.boundingBoxTight().scaleBy pixelRatio
      @morph.paintRectangle aContext, toBePainted.left(), toBePainted.top(), toBePainted.width(), toBePainted.height(), @morph.color

      aContext.restore()

      # paintHighlight is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio
      @paintHighlight aContext, al, at, w, h
