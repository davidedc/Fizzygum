# Paints a DividerWdgt: the band between two groups of a pop-up's rows, whose whole look is its own
# rule (redesign plan §2, rule D). The band has no fill, so whatever lies under it -- the pop-up's
# body -- shows above and below the rule; the rule is menuDividerRuleWidth thick, in my widget's
# colour, across my widget's whole width, centred down its height.
#   The rule is the band's only ink, so on the SHADOW pass its black version is the band's whole
# silhouette (Widget.coffee "How the shadow painting works").
#   I claim no opaque cover (Appearance.opaqueCoveredRect's default): most of the band is see-through,
# and the occlusion culler must keep painting what lies under it.

class DividerAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx, localDamageBox) =>
      ink = if appliedShadow? then WorldWdgt.theme.shadowColor else @widget.color
      return unless ink?
      ctx.fillStyle = ink.toString()
      # ⚠ The rule's geometry comes from MY WIDGET, never from the scope's `localDamageBox` (the
      # law is on Appearance._paintInLocalScope); the scope has already clipped to the damage box
      # (`clipsToDamageBox` is true here), so painting the whole rule is safe.
      ruleWidth = WorldWdgt.theme.menuDividerRuleWidth
      ruleTop = Math.floor (@widget.height() - ruleWidth) / 2
      @_fillLocalRectSnappedToDevicePixels ctx, new Rectangle 0, ruleTop, @widget.width(), ruleTop + ruleWidth
