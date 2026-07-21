class UpperRightTriangleAppearance extends Appearance

  positionWithinParent: nil

  constructor: (widget, @positionWithinParent = "topRight") ->
    super widget

  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    keyValues = @_calculateKeyValuesOrNil aContext, clippingRectangle
    return nil unless keyValues?
    [area,sl,st,al,at,w,h] = keyValues

    @_beginLogicalPixelsBox aContext, appliedShadow, al, at, w, h

    @_renderingHelper aContext, @widget.color

    aContext.restore()

    # _drawHighlightOverlay is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @_drawHighlightOverlay aContext, al, at, w, h

  _renderingHelper: (context, color) ->
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
    if @positionWithinParent == "topRight"
      context.moveTo 0, 0
      context.lineTo @widget.width(), @widget.height()
      context.lineTo @widget.width(), 0
    else if @positionWithinParent == "topLeft"
      context.moveTo 0, 0
      context.lineTo 0, @widget.height()
      context.lineTo @widget.width(), 0
    context.closePath()
    context.fill()

    context.restore()

  isTransparentAt: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@widget.boundsContainPoint aPoint
      return true
 
    thisWidgetPosition = @widget.position()
 
    relativePoint = new Point aPoint.x - thisWidgetPosition.x, aPoint.y - thisWidgetPosition.y

    if relativePoint.x / relativePoint.y < @widget.width()/@widget.height()
      return true


    return false

