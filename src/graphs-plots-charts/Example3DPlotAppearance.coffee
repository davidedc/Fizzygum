# Paints the Example3DPlotWdgt: background rect over the damage area, then the
# widget's drawPlot tail (the 3D mesh drawing) — all in widget-local LOGICAL pixels
# through the ctx matrix.
#
# NB: this is the SAME paint scaffold the plot family shares in
# GraphsPlotsChartsAppearance, but Example3DPlotWdgt extends Widget directly --
# reparenting it onto the plot base would also pull in that base's constructor +
# KeepsRatioWhenInVerticalStackMixin (a behaviour change), so this appearance copy is
# kept deliberately rather than deduplicated.

class Example3DPlotAppearance extends Appearance

  # in the shadow pass the body's simpleShadow sets its own alpha (see Appearance).
  alphaPolicy: "backgroundTransparencyNormalPass"

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    # alpha policy: the background fill runs at backgroundTransparency (drawPlot then sets its
    # own working alpha). Shadow-pass paint contract (Widget.coffee "How the shadow painting
    # works"): in the shadow pass drawPlot fills the WHOLE box black at the shadow alpha, so
    # the coloured background underneath is skipped (painting it too would tint and
    # double-darken through accumulation).
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx, localDamageBox) =>
      # (backgroundColor is undefined unless the user sets one — the base Widget default — so this
      # fill is usually skipped; drawPlot's own background-clean fill paints the plot box)
      if !appliedShadow? and @widget.backgroundColor?
        ctx.fillStyle = @widget.backgroundColor.toString()
        @_fillLocalRectSnappedToDevicePixels ctx, localDamageBox

      @widget.drawPlot ctx, Color.WHITE, appliedShadow
