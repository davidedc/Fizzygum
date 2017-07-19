# HeartIconMorph //////////////////////////////////////////////////////


class HeartIconMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  #constructor: ->
  #  super()
  #  @setColor new Color 0, 0, 0


  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return null

      aContext.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      aContext.clipToRectangle al,at,w,h

      aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha

      aContext.scale pixelRatio, pixelRatio

      morphPosition = @position()
      aContext.translate morphPosition.x, morphPosition.y

      height = @height()
      width = @width()

      squareDim = Math.min width, height

      if width > height
        aContext.translate (width-squareDim)/2,0
      else
        aContext.translate 0,(height-squareDim)/2

      squareSize = 200
      aContext.scale squareDim/squareSize, squareDim/squareSize

      ## at this point, you draw in a squareSize x squareSize
      ## canvas, and it gets painted in a square that fits
      ## the morph, right in the middle.
      @drawingIconInSquare aContext

      aContext.restore()

      # paintHighlight is usually made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, so it's generally used
      # outside the effect of the scaling because
      # of the pixelRatio (i.e. after the restore)
      @paintHighlight aContext, al, at, w, h

  oval = (context, x, y, w, h) ->
    context.save()
    context.beginPath()
    context.translate x, y
    context.scale w / 2, h / 2
    context.arc 1, 1, 1, 0, 2 * Math.PI, false
    context.closePath()
    context.restore()
    return

  arc = (context, x, y, w, h, startAngle, endAngle, isClosed) ->
    context.save()
    context.beginPath()
    context.translate x, y
    context.scale w / 2, h / 2
    context.arc 1, 1, 1, Math.PI / 180 * startAngle, Math.PI / 180 * endAngle, false
    if isClosed
      context.lineTo 1, 1
      context.closePath()
    context.restore()
    return

  drawingIconInSquare: (context) ->
    #// Color Declarations
    color = 'rgba(226, 0, 75, 1)'
    color2 = 'rgba(0, 0, 0, 1)'
    #// Oval Drawing
    arc context, 11, 21, 99, 99, 136, 326, false
    context.strokeStyle = color2
    context.lineWidth = 8
    context.stroke()
    #// Oval 2 Drawing
    arc context, 91, 21, 99, 99, 214, 46, false
    context.strokeStyle = color2
    context.lineWidth = 8
    context.stroke()
    #// Oval 3 Drawing
    oval context, 98, 41, 5, 5
    context.fillStyle = color
    context.fill()
    context.strokeStyle = color2
    context.lineWidth = 1
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 23, 103
    context.lineTo 93, 178
    context.strokeStyle = color2
    context.lineWidth = 8
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 178, 103
    context.lineTo 107, 179
    context.strokeStyle = color2
    context.lineWidth = 8
    context.stroke()
    #// Oval 4 Drawing
    arc context, 87.5, 154.5, 26, 26, 26, 143, false
    context.strokeStyle = color2
    context.lineWidth = 7.5
    context.stroke()
    #// Oval 5 Drawing
    arc context, 33.5, 44, 53, 54, 181, 273, false
    context.strokeStyle = color2
    context.lineWidth = 10
    context.stroke()
    #// Oval 6 Drawing
    oval context, 56, 39, 10, 10
    context.fillStyle = color
    context.fill()
    context.strokeStyle = color2
    context.lineWidth = 1
    context.stroke()
    #// Oval 7 Drawing
    oval context, 29, 66, 10, 10
    context.fillStyle = color
    context.fill()
    context.strokeStyle = color2
    context.lineWidth = 1
    context.stroke()
