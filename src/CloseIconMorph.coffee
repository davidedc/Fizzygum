# CloseIconMorph //////////////////////////////////////////////////////


class CloseIconMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  target: null

  constructor: (@target) ->
    super()

  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle) ->

    if @preliminaryCheckNothingToDraw false, clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return null

      aContext.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      aContext.clipToRectangle al,at,w,h

      aContext.globalAlpha = @alpha

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

      squareSize = 400
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

  drawingIconInSquare: (context) ->
    #// Color Declarations
    fillColor = 'rgba(0, 0, 0, 1)'
    color = 'rgba(0, 0, 0, 1)'
    #// Rectangle Drawing

    context.beginPath()
    context.moveTo 201.5, 393.5
    context.bezierCurveTo 307.78, 393.5, 394.5, 306.78, 394.5, 200.5
    context.bezierCurveTo 394.5, 94.22, 307.78, 7.5, 201.5, 7.5
    context.bezierCurveTo 95.22, 7.5, 8.5, 94.22, 8.5, 200.5
    context.bezierCurveTo 8.5, 306.78, 95.22, 393.5, 201.5, 393.5
    context.closePath()
    context.moveTo 201.5, 32.56
    context.bezierCurveTo 294.24, 32.56, 369.44, 107.76, 369.44, 200.5
    context.bezierCurveTo 369.44, 293.24, 294.24, 368.44, 201.5, 368.44
    context.bezierCurveTo 108.76, 368.44, 33.56, 293.24, 33.56, 200.5
    context.bezierCurveTo 33.56, 107.76, 108.76, 32.56, 201.5, 32.56
    context.closePath()
    context.fillStyle = fillColor
    context.fill()

    context.beginPath()
    context.moveTo 132.32, 269.68
    context.bezierCurveTo 134.83, 272.19, 137.84, 273.19, 141.34, 273.19
    context.bezierCurveTo 144.85, 273.19, 147.86, 272.19, 150.37, 269.68
    context.lineTo 201.5, 218.05
    context.lineTo 253.13, 269.68
    context.bezierCurveTo 255.64, 272.19, 258.65, 273.19, 262.16, 273.19
    context.bezierCurveTo 265.67, 273.19, 268.67, 272.19, 271.18, 269.68
    context.bezierCurveTo 276.19, 264.67, 276.19, 256.65, 271.18, 252.13
    context.lineTo 219.05, 200.5
    context.lineTo 270.68, 148.87
    context.bezierCurveTo 275.69, 143.85, 275.69, 135.83, 270.68, 131.32
    context.bezierCurveTo 265.67, 126.31, 257.65, 126.31, 253.13, 131.32
    context.lineTo 201.5, 182.95
    context.lineTo 149.87, 131.32
    context.bezierCurveTo 144.85, 126.31, 136.83, 126.31, 132.32, 131.32
    context.bezierCurveTo 127.31, 136.33, 127.31, 144.35, 132.32, 148.87
    context.lineTo 183.95, 200.5
    context.lineTo 132.32, 252.13
    context.bezierCurveTo 127.31, 256.65, 127.31, 264.67, 132.32, 269.68
    context.closePath()
    context.fillStyle = fillColor
    context.fill()

  mouseClickLeft: ->
    @target.close()
