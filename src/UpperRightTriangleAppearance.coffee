# UpperRightTriangleAppearance //////////////////////////////////////////////////////////////

class UpperRightTriangleAppearance extends Appearance

  constructor: (morph) ->
    super morph

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @morph.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return nil

    [area,sl,st,al,at,w,h] = @morph.calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil

      aContext.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      aContext.clipToRectangle al,at,w,h

      aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @morph.alpha

      aContext.scale pixelRatio, pixelRatio
      morphPosition = @morph.position()
      aContext.translate morphPosition.x, morphPosition.y

      @renderingHelper aContext, @morph.color

      aContext.restore()

      # paintHighlight is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio (i.e. after the restore)
      @paintHighlight aContext, al, at, w, h

  renderingHelper: (context, color) ->
    context.lineWidth = 1
    context.lineCap = "round"

    # give it a good shadow so that
    # it's visible also when on light
    # background. Do that by painting it
    # twice, slightly translated, in
    # darker color.
    context.save()

    context.fillStyle = color.toString()

    context.beginPath()
    context.moveTo 0, 0
    context.lineTo @morph.width(), @morph.height()
    context.lineTo @morph.width(), 0
    context.closePath()
    context.fill()

    context.restore()

  isTransparentAt: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@morph.boundsContainPoint aPoint
      return true
 
    thisMorphPosition = @morph.position()
 
    relativePoint = new Point aPoint.x - thisMorphPosition.x, aPoint.y - thisMorphPosition.y

    if relativePoint.x / relativePoint.y < @morph.width()/@morph.height()
      return true


    return false

