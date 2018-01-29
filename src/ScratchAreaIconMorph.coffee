# ScratchAreaIconMorph //////////////////////////////////////////////////////


# based on https://thenounproject.com/term/organization/153374/
class ScratchAreaIconMorph extends Morph

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
    color2 = 'rgba(0, 0, 0, 1)'
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 40.5, 118.5
    context.lineTo 40.5, 184.5
    context.lineTo 145.5, 184.5
    context.lineTo 145.5, 92.5
    context.lineTo 40.5, 92.5
    context.lineTo 67.5, 67.5
    context.lineTo 78.5, 67.5
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 146, 185
    context.lineTo 172.83, 159.74
    context.lineTo 172.29, 102.66
    context.lineTo 190, 87
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 172.5, 102.5
    context.lineTo 161.5, 112.5
    context.strokeStyle = color2
    context.lineWidth = 5.5
    context.stroke()
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 19.5, 117.5
    context.bezierCurveTo 127.5, 117.5, 127.5, 117.5, 127.5, 117.5
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Oval Drawing
    @arc context, 128.5, 94.5, 33, 49, 180, 273, false
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 2 Drawing
    @arc context, 22, 93, 33, 49, 180, 273, false
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 3 Drawing
    @arc context, 135, 93, 26, 49, 266, 355, false
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 4 Drawing
    @arc context, 162.5, 67.5, 26, 49, 266, 355, false
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 103.5, 67.5
    context.lineTo 172, 67.5
    context.lineTo 146, 92.5
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 5 Drawing
    @arc context, -9.5, 76, 51, 49, 254, 339, false
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 6 Drawing
    @arc context, 17, 52.5, 51, 49, 254, 339, false
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 10, 77
    context.lineTo 37, 53
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 65.5, 68
    context.lineTo 72, 56
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 89.5, 45.5
    context.lineTo 105.5, 45.5
    context.strokeStyle = color2
    context.lineWidth = 4
    context.stroke()
    #// Bezier 9 Drawing
    context.beginPath()
    context.moveTo 150.5, 45.5
    context.lineTo 188, 45
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.strokeStyle = color2
    context.lineWidth = 4
    context.stroke()
    #// Oval 7 Drawing
    @arc context, 171.5, 45.5, 33, 49, 180, 273, false
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 8 Drawing
    @arc context, 92, 80, 18, 18.5, 181, 0, false
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 83, 59.5
    context.lineTo 83.5, 73.5
    context.lineTo 98.5, 73.5
    context.lineTo 98, 58
    context.lineTo 83, 59.5
    context.closePath()
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Bezier 11 Drawing
    context.beginPath()
    context.moveTo 106.5, 39.5
    context.lineTo 117.5, 20.5
    context.lineTo 139.5, 20.5
    context.lineTo 149.5, 38.5
    context.lineTo 138.5, 57.5
    context.lineTo 116.5, 57.5
    context.lineTo 106.5, 39.5
    context.closePath()
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()
    #// Oval 9 Drawing
    @arc context, 64.5, 27, 22.5, 23.5, 181, 180, false
    context.strokeStyle = color2
    context.lineWidth = 4.5
    context.stroke()

