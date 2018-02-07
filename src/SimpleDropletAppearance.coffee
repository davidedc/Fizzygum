# SimpleDropletAppearance //////////////////////////////////////////////////////////////

class SimpleDropletAppearance extends RectangularAppearance

  # the "alreadyUsingCanvasClipping" flag is needed because when
  # drawing some fundamental shapes
  # (read: plain simple rectangles) we "clip by hand" the rectangle
  # (i.e. we clip the rectangle mathematically) rather
  # than using the actual canvas clipping functionality
  # (because we think it's just faster)
  # So, since such "by hand" clipping might not be
  # simple/feasible for arbitrary shapes, we pass here whether
  # the canvas clipping is in use (in which case we don't need
  # to do it here) or not (in which case we do need to do the
  # additional canvas clipping)
  #
  # similarly, the "alreadyUsingCanvasScaling" flag is needed because when
  # drawing some fundamental shapes
  # (read: plain simple rectangles) we "scale by hand" the rectangle
  # (i.e. we scale the rectangle mathematically) rather
  # than using the actual canvas scaling functionality
  # (because we think it's just faster)
  # So, since such "by hand" scaling might not be
  # simple/feasible for arbitrary shapes, we pass here whether
  # the canvas scaling is in use (in which case we don't need
  # to do it here) or not (in which case we do need to do the
  # additional canvas scaling)

  drawAdditionalParts: (alreadyUsingCanvasClipping, alreadyUsingCanvasScaling, appliedShadow, context, al, at, w, h) ->

    # we refuse to paint the shadow of the plus sign
    # in the middle of a black rectangle. Just, no.
    if appliedShadow?
      return

    height = @morph.height()
    width = @morph.width()

    squareDim = Math.min width/2, height/2

    # p0 is the origin, the origin being in the bottom-left corner
    p0 = @morph.bottomLeft()

    # now the origin if on the left edge, in the middle height of the morph
    p0 = p0.subtract new Point 0, Math.ceil height/2
    
    # now the origin is in the middle height of the morph,
    # on the left edge of the square incribed in the morph
    p0 = p0.add new Point (width -  squareDim)/2, 0

    
    plusSignLeft = p0.add new Point Math.ceil(squareDim/15), 0
    plusSignRight = p0.add new Point squareDim - Math.ceil(squareDim/15), 0
    plusSignTop = p0.add new Point Math.ceil(squareDim/2), -Math.ceil(squareDim/3)
    plusSignBottom = p0.add new Point Math.ceil(squareDim/2), Math.ceil(squareDim/3)

    color = new Color 255, 255, 255

    context.save()

    context.lineWidth = 1
    context.lineCap = "round"
    context.strokeStyle = color.toString()


    if !alreadyUsingCanvasClipping
      context.clipToRectangle al,at,w,h

    if !alreadyUsingCanvasScaling
      context.scale pixelRatio, pixelRatio

    context.beginPath()
    context.moveTo 0.5 + plusSignLeft.x, 0.5 + plusSignLeft.y
    context.lineTo 0.5 + plusSignRight.x, 0.5 + plusSignRight.y
    context.moveTo 0.5 + plusSignTop.x, 0.5 + plusSignTop.y
    context.lineTo 0.5 + plusSignBottom.x, 0.5 + plusSignBottom.y


    context.closePath()
    context.stroke()

    context.restore()

