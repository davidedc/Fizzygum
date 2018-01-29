# HeartIconMorph //////////////////////////////////////////////////////


class HeartIconMorph extends Morph

  #constructor: ->
  #  super()
  #  @setColor new Color 0, 0, 0

  widthWithoutSpacing: ->
    Math.min @width(), @height()

  rawResizeToWithoutSpacing: ->
    @rawSetExtent new Point @widthWithoutSpacing(), @widthWithoutSpacing()

  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    @rawSetExtent new Point newWidth, newWidth

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
        return nil

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

  oval: (context, x, y, w, h) ->
    context.save()
    context.beginPath()
    context.translate x, y
    context.scale w / 2, h / 2
    context.arc 1, 1, 1, 0, 2 * Math.PI
    context.closePath()
    context.restore()
    return

  arc: (context, x, y, w, h, startAngle, endAngle, isClosed) ->
    context.save()
    context.beginPath()
    context.translate x, y
    context.scale w / 2, h / 2
    context.arc 1, 1, 1, Math.PI / 180 * startAngle, Math.PI / 180 * endAngle
    if isClosed
      context.lineTo 1, 1
      context.closePath()
    context.restore()
    return

  drawingIconInSquare: (context) ->
    #// Color Declarations
    colorString = 'rgba(0, 0, 0)'

    context.strokeStyle = colorString
    context.fillStyle = colorString

    #// Oval Drawing
    @arc context, 11, 21, 99, 99, 136, 326, false
    context.lineWidth = 8
    context.stroke()
    #// Oval 2 Drawing
    @arc context, 91, 21, 99, 99, 214, 46, false
    context.lineWidth = 8
    context.stroke()
    #// Oval 3 Drawing
    @oval context, 98, 41, 4, 4
    context.fill()
    context.lineWidth = 1
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 23, 103
    context.lineTo 93, 178
    context.lineWidth = 8
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 178, 103
    context.lineTo 107, 179
    context.lineWidth = 8
    context.stroke()
    #// Oval 4 Drawing
    @arc context, 87.5, 154.5, 26, 26, 26, 143, false
    context.lineWidth = 7.5
    context.stroke()
    #// Oval 5 Drawing
    @arc context, 33.5, 44, 53, 54, 181, 273, false
    context.lineWidth = 10
    context.stroke()
    #// Oval 6 Drawing
    @oval context, 57, 40, 8.5, 8.5
    context.fill()
    context.lineWidth = 1
    context.stroke()
    #// Oval 7 Drawing
    @oval context, 29.5, 66, 8.5, 8.5
    context.fill()
    context.lineWidth = 1
    context.stroke()
