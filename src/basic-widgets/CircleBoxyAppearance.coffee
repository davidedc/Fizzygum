class CircleBoxyAppearance extends Appearance

  constructor: (widget) ->
    super widget

  autoOrientation: ->
    if @widget.height() > @widget.width()
      return "vertical"
    else
      return "horizontal"


  calculateKeyPoints: ->
    orientation = @autoOrientation()
    if orientation is "vertical"
      radius = @widget.width() / 2
      x = @widget.center().x
      center1 = new Point(x, @widget.top() + radius).round()
      center2 = new Point(x, @widget.bottom() - radius).round()
      rect = @widget.topLeft().add(
        new Point(0, radius)).corner(@widget.bottomRight().subtract(new Point(0, radius)))
    else
      radius = @widget.height() / 2
      y = @widget.center().y
      center1 = new Point(@widget.left() + radius, y).round()
      center2 = new Point(@widget.right() - radius, y).round()
      rect = @widget.topLeft().add(
        new Point(radius, 0)).corner(@widget.bottomRight().subtract(new Point(radius, 0)))
    return [radius,center1,center2,rect]

  isTransparentAt: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@widget.boundsContainPoint aPoint
      return true

    [radius,center1,center2,rect] = @calculateKeyPoints()

    if center1.distanceTo(aPoint) < radius or
    center2.distanceTo(aPoint) < radius or
    rect.containsPoint aPoint
      return false

    return true
  
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

    if appliedShadow?
      aContext.fillStyle = Color.BLACK.toString()
    else
      aContext.fillStyle = @widget.color.toString()

    # ONE stadium fill covering exactly the widget box, both orientations —
    # a single primitive rather than the old two-arcs+rectangle path, so the
    # shadow pass (which fills at globalAlpha < 1) blends every pixel once.
    # (calculateKeyPoints stays as the hit test's — isTransparentAt — geometry.)
    aContext.fillStadium 0, 0, @widget.width(), @widget.height()

    aContext.restore()

    # _drawHighlightOverlay is usually made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, so it's generally used
    # outside the effect of the scaling because
    # of the ceilPixelRatio (i.e. after the restore)
    @_drawHighlightOverlay aContext, al, at, w,
