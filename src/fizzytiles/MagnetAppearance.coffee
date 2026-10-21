# The look of a Fizzytiles MAGNET (MagnetWdgt): the design's button over my widget's whole box
# (visual-design-system §4.3) -- filled and bordered with my widget's state look
# (MagnetWdgt._fillForMyState / _strokeForMyState: paper inside a 1 px line border at rest), rounded
# at magnetCornerRadius. Every value is my widget's state, its box or a Theme role or metric, read
# as I paint: I hold nothing of my own. The magnet's label is a child StringWdgt and paints itself,
# over me.
#
# My SHAPE is the rounded box, by pixel centre (BoxyAppearance's one rounded-box test), so a press
# or a drop in a corner notch reaches whatever lies behind the magnet. My SILHOUETTE is the same
# rounded box: on the shadow pass I fill it in shadowColor and nothing else, so the magnet casts its
# own shape, at rest and as the drag lift.

class MagnetAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    # unconditional, as LabelButtonAppearance's: a hidden or collapsed magnet skips even scratch
    # renders
    if !@widget.visibleBasedOnIsVisibleProperty() or @widget.isInCollapsedSubtree()
      return undefined

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      theme = WorldWdgt.theme
      # the box's geometry comes from my widget, never from the scope's damage box (the law on
      # Appearance._paintInLocalScope); the scope has clipped to the damage already
      w = @widget.width()
      h = @widget.height()
      radius = theme.magnetCornerRadius

      if appliedShadow?
        ctx.fillStyle = theme.shadowColor.toString()
        ctx.fillRoundRect 0, 0, w, h, radius
        return

      ctx.fillStyle = @widget._fillForMyState().toString()
      ctx.fillRoundRect 0, 0, w, h, radius
      # the 1 px border, the house crisp spelling: the ring just inside the fill, at its radius
      ctx.lineWidth = 1
      ctx.strokeStyle = @widget._strokeForMyState().toString()
      ctx.strokeRoundRect 0.5, 0.5, w - 1, h - 1, radius

  # The rounded box, by pixel centre. TOTAL (see Appearance): nothing outside my widget's bounds is
  # mine.
  shapeContainsPoint: (aPoint) ->
    return false unless @widget.boundsContainPoint aPoint
    radius = WorldWdgt.theme.magnetCornerRadius
    BoxyAppearance.roundedBoxContainsPixelCentreOf (aPoint.subtract @widget.position()), @widget.width(), @widget.height(), [radius, radius, radius, radius]
