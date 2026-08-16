class UpperRightTriangleAppearance extends Appearance

  positionWithinParent: undefined

  constructor: (widget, @positionWithinParent = "topRight") ->
    super widget

  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      # Shadow-pass paint contract (Widget.coffee "How the shadow painting works"): the art
      # colour goes BLACK under appliedShadow — the scope already applied the shadow's alpha.
      @_renderingHelper ctx, (if appliedShadow? then Color.BLACK else @widget.color)

  _renderingHelper: (context, color) ->
    context.save()

    # (no lineCap here: this paint only ever fill()s — caps affect strokes alone,
    # and a stray cap/width state is exactly what blocks the strokeLine/arc
    # direct fast paths, which are butt-cap-gated)
    context.lineWidth = 1

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

