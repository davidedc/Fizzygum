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

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, undefined, (ctx) =>
      if appliedShadow?
        ctx.fillStyle = Color.BLACK.toString()
      else
        ctx.fillStyle = @widget.color.toString()

      # ONE stadium fill covering exactly the widget box, both orientations —
      # a single primitive rather than the old two-arcs+rectangle path, so the
      # shadow pass (which fills at globalAlpha < 1) blends every pixel once.
      # (calculateKeyPoints stays as the hit test's — isTransparentAt — geometry.)
      ctx.fillStadium 0, 0, @widget.width(), @widget.height()
