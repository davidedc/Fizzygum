# UnderCarpetIconMorph //////////////////////////////////////////////////////


class UnderCarpetIconMorph extends Morph

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
    colorString = 'rgba(0, 0, 0, 1)'
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 96.5, 32.5
    context.lineTo 304.5, 113.5
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Oval Drawing
    @arc context, 264, 112, 61, 61, 285, 21, false
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 252, 335
    context.lineTo 324, 150
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Oval 2 Drawing
    @arc context, 188, 297, 63, 63, 285, 86, false
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 22.5, 218.5
    context.lineTo 230.5, 299.5
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 108, 360
    context.lineTo 223, 360
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 142, 266
    context.lineTo 142, 360
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 108, 340
    context.lineTo 143, 340
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 108, 318
    context.lineTo 143, 318
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 108, 296
    context.lineTo 143, 296
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 9 Drawing
    context.beginPath()
    context.moveTo 108, 274
    context.lineTo 143, 274
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 128, 47
    context.lineTo 58, 226
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 12 Drawing
    context.beginPath()
    context.moveTo 32, 197
    context.lineTo 62, 209
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 13 Drawing
    context.beginPath()
    context.moveTo 41, 177
    context.lineTo 71, 189
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 11 Drawing
    context.beginPath()
    context.moveTo 48, 156
    context.lineTo 78, 168
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 14 Drawing
    context.beginPath()
    context.moveTo 57, 136
    context.lineTo 87, 148
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 15 Drawing
    context.beginPath()
    context.moveTo 64, 115
    context.lineTo 94, 127
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 16 Drawing
    context.beginPath()
    context.moveTo 73, 95
    context.lineTo 103, 107
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 17 Drawing
    context.beginPath()
    context.moveTo 80, 74
    context.lineTo 110, 86
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Bezier 18 Drawing
    context.beginPath()
    context.moveTo 89, 54
    context.lineTo 119, 66
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Oval 3 Drawing
    @oval context, 312, 275, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 4 Drawing
    @oval context, 332, 350, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 5 Drawing
    @oval context, 321, 324, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 6 Drawing
    @oval context, 302, 314, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 7 Drawing
    @oval context, 313, 300, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 8 Drawing
    @oval context, 342, 314, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 9 Drawing
    @oval context, 334, 286, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 10 Drawing
    @oval context, 353, 271, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 11 Drawing
    @oval context, 327, 262, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 12 Drawing
    @oval context, 341, 251, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 13 Drawing
    @oval context, 356, 243, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 14 Drawing
    @oval context, 322, 238, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 15 Drawing
    @oval context, 338, 224, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 16 Drawing
    @oval context, 361, 225, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 17 Drawing
    @oval context, 348, 206, 10, 9
    context.fillStyle = colorString
    context.fill()
    #// Oval 18 Drawing
    @oval context, 372, 198, 10, 9
    context.fillStyle = colorString
    context.fill()
