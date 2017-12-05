# DestroyIconMorph //////////////////////////////////////////////////////


class DestroyIconMorph extends Morph
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

      squareSize = 100
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

    # colors
    blackColor = 'rgba(0, 0, 0, 1)'
    color = 'rgba(0, 0, 0, 1)'

    # the drawing
    # icon adapted from
    # https://thenounproject.com/term/explosion/1255/

    context.beginPath()
    context.moveTo 42.5, 4.5
    context.lineTo 53.5, 29.5
    context.lineTo 72.5, 9.5
    context.lineTo 65.5, 35.5
    context.lineTo 94.5, 34.5
    context.lineTo 70.5, 51.5
    context.lineTo 96.5, 72.5
    context.lineTo 65.5, 66.5
    context.lineTo 73.5, 87.5
    context.lineTo 55.5, 73.5
    context.lineTo 43.5, 96.5
    context.lineTo 36.5, 67.5
    context.lineTo 9.5, 77.5
    context.lineTo 24.5, 59.5
    context.lineTo 3.5, 56.5
    context.lineTo 25.5, 48.5
    context.lineTo 5.5, 25.5
    context.lineTo 37.5, 32.5
    context.lineTo 42.5, 4.5
    context.closePath()
    context.fillStyle = color
    context.fill()
    context.strokeStyle = blackColor
    context.lineWidth = 1
    context.stroke()


