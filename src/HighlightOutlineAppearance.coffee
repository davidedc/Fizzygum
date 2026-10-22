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
#   The ring is painted by ONE painter, HighlightOutlineAppearance.paintRing, which the editor-focus
# selection outline paints with too (Widget._drawSelectionOverlay): two surfaces, each with its own
# role and width, one ring.
class HighlightOutlineAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    # an ephemeral overlay casts no shadow -- nothing to draw on the shadow pass
    return undefined if appliedShadow?
    ringColor = @widget.strokeColor
    return undefined unless ringColor?

    # (the scope's default alpha reduces to plain @widget.alpha here -- no shadow pass reaches this)
    # a drop target is outlined as a STROKED body is (the windows, cards and menus the outline is
    # designed around draw their own 1 px border): the ring's stroke half is always on
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      HighlightOutlineAppearance.paintRing ctx, @widget.width(), @widget.height(),
        WorldWdgt.theme.dropOutlineWidth, @_outlineRadii(), ringColor, true
      return

  # THE RING, painted inside an open scope whose matrix is in logical pixels with its origin at the
  # top-left of the w x h box the ring lies in: `ringWidth` thick, wholly inside the box, in
  # `ringColor`, its outer corners rounded at `radii` (per corner, [topLeft, topRight, bottomRight,
  # bottomLeft]: the corners of what it outlines, Widget.cornerRadiiFollowingMyOutline) and its inner
  # ones concentric with them. It is the even-odd fill of the region between the two edges -- whose
  # outer edge lands on exactly the pixels the outlined body's rounded FILL covers -- and, when
  # `outlinesAStroke` (the outlined body draws a 1 px border along its outline), the crisp 1 px
  # stroke of the outer edge over it, which covers the corner pixels that border reaches and the fill
  # leaves out (see my header). Over a body with no border that stroke would land, at dpr 1, on a few
  # pixels at each rounded corner the body leaves to whatever is behind it, so it is left out there.
  # Asked of the CLASS, as BoxyAppearance's rounded hit test is: it needs only the box, never a widget
  # wearing me -- my own outline form calls it, and so does the selection outline a selected widget
  # draws over itself (Widget._drawSelectionOverlay).
  @paintRing: (ctx, w, h, ringWidth, radii, ringColor, outlinesAStroke) ->
    outerRadii = HighlightOutlineAppearance.ringEdgeRadii radii, 0
    ctx.fillStyle = ringColor.toString()
    ctx.beginPath()
    ctx.roundRect 0, 0, w, h, outerRadii
    # a box too small to hold the ring's inside is all ring
    if w > 2 * ringWidth and h > 2 * ringWidth
      ctx.roundRect ringWidth, ringWidth, w - 2 * ringWidth, h - 2 * ringWidth, HighlightOutlineAppearance.ringEdgeRadii radii, ringWidth
    ctx.fill "evenodd"
    return unless outlinesAStroke
    ctx.strokeStyle = ringColor.toString()
    ctx.lineWidth = 1
    ctx.strokeRoundRect 0.5, 0.5, w - 1, h - 1, outerRadii
    return

  # The radii roundRect takes for a ring's edge `inset` in from a box whose corners are rounded at
  # `radii` (per corner): each radius less the inset, never below 0 -- the outer edge at 0, the
  # concentric inner edge at the ring's width. A uniform radius goes as the SCALAR (SWCanvas's scalar
  # entry, as BoxyAppearance._roundRectRadii hands it), per-corner radii as the 4-array.
  @ringEdgeRadii: (radii, inset) ->
    edge = (Math.max(0, radius - inset) for radius in radii)
    if edge.every((radius) -> radius is edge[0]) then edge[0] else edge

  # My widget's outlineRadii, the corners of what it covers (square until coverBox sets them).
  _outlineRadii: ->
    @widget.outlineRadii ? [0, 0, 0, 0]

  # The radii roundRect takes for my ring's OUTER edge, the edge the fill form's wash fills
  # (HighlightWashAppearance).
  _ringRadii: ->
    HighlightOutlineAppearance.ringEdgeRadii @_outlineRadii(), 0
