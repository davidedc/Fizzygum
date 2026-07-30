# Paints the PenWdgt TURTLE itself (the arrow/dart pointing along @widget.heading,
# white-then-black stroked and filled with the widget colour) — NOT the graphics the
# pen draws, which land on the canvas the pen is attached to.

class PenAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @widget.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = @widget.alpha

    aContext.useLogicalPixelsUntilRestore()
    widgetPosition = @widget.position()
    aContext.translate widgetPosition.x, widgetPosition.y

    direction = @widget.heading
    len = @widget.width() / 2
    start = @widget.center().subtract(@widget.position())

    if @widget.penPoint is "tip"
      dest = start.distanceAngle(len * 0.75, direction - 180)
      left = start.distanceAngle(len, direction + 195)
      right = start.distanceAngle(len, direction - 195)
    else # 'middle'
      dest = start.distanceAngle(len * 0.75, direction)
      left = start.distanceAngle(len * 0.33, direction + 230)
      right = start.distanceAngle(len * 0.33, direction - 230)

    aContext.fillStyle = @widget.color.toString()
    aContext.beginPath()

    aContext.moveTo start.x, start.y
    aContext.lineTo left.x, left.y
    aContext.lineTo dest.x, dest.y
    aContext.lineTo right.x, right.y

    aContext.closePath()
    aContext.strokeStyle = Color.WHITE.toString()
    aContext.lineWidth = 3
    aContext.stroke()
    aContext.strokeStyle = Color.BLACK.toString()
    aContext.lineWidth = 1
    aContext.stroke()
    aContext.fill()

    aContext.restore()

    # _drawHighlightOverlay is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @_drawHighlightOverlay aContext, al, at, w, h
