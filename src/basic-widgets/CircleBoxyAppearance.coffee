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

  # The stadium: the middle rect plus the two semicircular caps. (No opaqueCoveredRect claim:
  # the inscribed rect is available from calculateKeyPoints, but the culler has never asked a
  # stadium and adding a claim is new behaviour, not a rename — left for whoever needs it.)
  shapeContainsPoint: (aPoint) ->
    # first quickly check if the point is even
    # within the bounding box
    if !@widget.boundsContainPoint aPoint
      return false

    [radius,center1,center2,rect] = @calculateKeyPoints()

    center1.distanceTo(aPoint) < radius or
      center2.distanceTo(aPoint) < radius or
      rect.containsPoint aPoint

  # The colour I fill my widget's stadium with, read as I paint: the fill its STATE shows, for a
  # widget whose look is a function of its state (a slider's thumb, SliderButtonWdgt._fillForMyState);
  # else its own colour; else, for a widget holding none because it wears a theme role until a
  # colour is set on it, that role (a slider's track, SliderWdgt._surfaceFill). So a saved or
  # duplicated widget wears the look of the world it is painted in.
  _fillColor: ->
    @widget._fillForMyState?() ? @widget.color ? @widget._surfaceFill?()

  # The colour of the 1 px border wall along the inside of my widget's stadium, when its state shows
  # one (a plain slider's thumb, in the button's look: SliderButtonWdgt._strokeForMyState); undefined
  # -- no border -- for every other widget.
  _borderColor: ->
    @widget._strokeForMyState?()

  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      w = @widget.width()
      h = @widget.height()

      # ONE stadium fill covering exactly the widget box, both orientations —
      # a single primitive rather than the old two-arcs+rectangle path, so the
      # shadow pass (which fills at globalAlpha < 1) blends every pixel once.
      # (calculateKeyPoints stays as the hit test's — shapeContainsPoint — geometry.)
      # The shadow pass fills the silhouette alone: a border lies inside it.
      if appliedShadow?
        ctx.fillStyle = WorldWdgt.theme.shadowColor.toString()
        ctx.fillStadium 0, 0, w, h
        return

      fill = @_fillColor()
      border = @_borderColor()

      # no border: the one stadium fill over the whole box
      unless border?
        ctx.fillStyle = fill.toString()
        ctx.fillStadium 0, 0, w, h
        return

      # a border: the stadium-border idiom of the size-aware icons (TypewriterIconAppearance's
      # carriage, DegreesConverterIconAppearance's tube) -- the whole stadium in the border colour,
      # then the stadium inset by 1 px on every side in the fill colour. Both are stadiums, so the
      # inner one is concentric with the outer and the wall is 1 px all round, round ends included,
      # with no pixel of the fill outside it. A box under 3 px across has no room for a fill inside
      # its wall: it is all border.
      ctx.fillStyle = border.toString()
      ctx.fillStadium 0, 0, w, h
      return if w < 3 or h < 3
      ctx.fillStyle = fill.toString()
      ctx.fillStadium 1, 1, w - 2, h - 2
