# Paints a HighlighterWdgt in its OUTLINE form -- the drag-and-drop feedback around a receptive drop
# candidate, a view-mode target that declines the drop, and a dock band
# (HighlighterWdgt.applyHighlightStyle): a RING dropOutlineWidth thick lying wholly INSIDE my widget's
# box, in its strokeColor, its corners rounded at my widget's outlineRadii -- the corners of what it
# outlines where its box meets them (Widget.cornerRadiiFollowingMyOutline), so the ring follows a
# rounded window or card instead of standing off its corners. Nothing else: no fill, and no shadow
# (an ephemeral overlay casts none).
#   The ring is a FILL, not a stroke: the region between my widget's box rounded at those radii and
# the same box inset by the ring's width, each corner rounded at its radius less the width (the
# concentric inner edge -- the border idiom the size-aware icons use), filled even-odd. Its outer
# edge therefore lands on exactly the pixels a rounded fill of the box covers, which is how the
# outlined target's own body is filled (BoxyAppearance.fillOutline). Over it goes the crisp 1 px
# stroke of the same outline (BoxyAppearance.strokeOutline's spelling), the way the target's own
# border is stroked: on SWCanvas a stroked corner covers a pixel or two its fill leaves out, and
# without it the target's border would show outside the ring there. A 2 px stroke inset 1 px (a
# stroke centred on the ring) follows the corners less closely: it leaves the target's own border
# and fill showing outside it at every rounded corner, at dpr 1 and 2 alike.
class HighlightOutlineAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    # an ephemeral overlay casts no shadow -- nothing to draw on the shadow pass
    return undefined if appliedShadow?
    ringColor = @widget.strokeColor
    return undefined unless ringColor?

    # (the scope's default alpha reduces to plain @widget.alpha here -- no shadow pass reaches this)
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      w = @widget.width()
      h = @widget.height()
      ringWidth = WorldWdgt.theme.dropOutlineWidth
      radii = @_ringRadii()
      ctx.fillStyle = ringColor.toString()
      ctx.beginPath()
      ctx.roundRect 0, 0, w, h, radii
      # a box too small to hold the ring's inside is all ring
      if w > 2 * ringWidth and h > 2 * ringWidth
        ctx.roundRect ringWidth, ringWidth, w - 2 * ringWidth, h - 2 * ringWidth, @_ringRadii ringWidth
      ctx.fill "evenodd"
      ctx.strokeStyle = ringColor.toString()
      ctx.lineWidth = 1
      ctx.strokeRoundRect 0.5, 0.5, w - 1, h - 1, radii
      return

  # The radii roundRect takes for my ring's outer edge -- or, `inset` in, for the concentric edge
  # there: each of my widget's outlineRadii less the inset, never below 0. A uniform radius goes as
  # the SCALAR (SWCanvas's scalar entry, as BoxyAppearance._roundRectRadii hands it), per-corner radii
  # as the 4-array.
  _ringRadii: (inset = 0) ->
    radii = (Math.max(0, radius - inset) for radius in (@widget.outlineRadii ? [0, 0, 0, 0]))
    if radii.every((radius) -> radius is radii[0]) then radii[0] else radii
