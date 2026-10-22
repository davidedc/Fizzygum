# Paints a HighlighterWdgt in its FILL form -- the WASH a menu row that stands for a widget (a hierarchy
# menu's, a chooser's) lays over that widget while hovered (Widget.turnOnHighlight,
# HighlighterWdgt.applyHighlightStyle): my widget's box filled ONCE in its color, the hoverHighlightWash
# role, translucent by its own alpha, its corners rounded at my widget's outlineRadii -- the corners of
# what it covers where its box meets them (Widget.cornerRadiiFollowingMyOutline), so the wash lies on a
# rounded target's body and leaves the target's corner notches to whatever shows there. Nothing else:
# no stroke, and no shadow (an ephemeral overlay casts none).
#   I am the outline form's appearance with its ring filled solid: I take my rounding from
# HighlightOutlineAppearance's ring (its outer edge, _ringRadii), and I fill it with the call a rounded
# box's own body is filled with (BoxyAppearance.fillOutline: fillRoundRect over the whole box), so over
# a target whose corners are its own rounded outline, on SWCanvas the wash covers exactly the device
# pixels the target's rounded fill covers, at dpr 1 and 2. One fill, so no pixel is tinted twice.
class HighlightWashAppearance extends HighlightOutlineAppearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    # an ephemeral overlay casts no shadow -- nothing to draw on the shadow pass
    return undefined if appliedShadow?
    washColor = @widget.color
    return undefined unless washColor?

    # (the scope's default alpha reduces to plain @widget.alpha here -- no shadow pass reaches this)
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      ctx.fillStyle = washColor.toString()
      ctx.fillRoundRect 0, 0, @widget.width(), @widget.height(), @_ringRadii()
      return
