# MenuAppearance //////////////////////////////////////////////////////////////

class MenuAppearance extends BoxyAppearance
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  
  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @morph.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @morph.calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return null

      aContext.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      aContext.clipToRectangle al,at,w,h

      aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @morph.alpha

      aContext.scale pixelRatio, pixelRatio
      morphPosition = @morph.position()
      aContext.translate morphPosition.x, morphPosition.y
      aContext.fillStyle = @morph.color.toString()

      if appliedShadow?
        aContext.fillStyle = "black"
      
      aContext.beginPath()
      @outlinePath aContext, Math.max @getCornerRadius(), 0
      aContext.closePath()
      aContext.fill()

      aContext.restore()

      # paintHighlight is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio (i.e. after the restore)
      @paintHighlight aContext, al, at, w, h
