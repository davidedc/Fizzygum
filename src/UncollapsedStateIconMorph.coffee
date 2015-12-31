# UncollapsedStateIconMorph //////////////////////////////////////////////////////


class UncollapsedStateIconMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  #constructor: ->
  #  super()
  #  @setColor new Color(0, 0, 0)


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

      #@paintBackgroundRectangle aContext, al, at, w, h

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
      @paintHighlight aContext, al, at, w, h

  drawingIconInSquare: (context) ->
    #// Color Declarations
    color = 'rgba(51, 0, 0, 1)'
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 45.5, 137.5
    context.lineTo 200.93, 288.5
    context.lineTo 362.5, 133.5
    context.miterLimit = 30
    context.strokeStyle = color
    context.lineWidth = 30
    context.stroke()
