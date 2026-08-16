# Paints the plot/chart family (GraphsPlotsChartsWdgt and its concrete plots — bar,
# function, scatter — which inherit this via the base): background rect over the
# damage area, then the widget's own drawPlot tail (the per-plot drawing body, PUBLIC
# and subclass-polymorphic — the drawLayoutChrome precedent) — all in widget-local
# LOGICAL pixels through the ctx matrix. (Example3DPlotWdgt keeps its own separate
# appearance copy — see Example3DPlotAppearance's header for why.)

class GraphsPlotsChartsAppearance extends Appearance

  # in the shadow pass the body's simpleShadow sets its own alpha (see Appearance).
  alphaPolicy: "backgroundTransparencyNormalPass"

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    # alpha policy: the background fill AND drawPlot's opening background-clean fill run at
    # backgroundTransparency (drawPlot then sets its own working alpha). Shadow-pass paint
    # contract (Widget.coffee "How the shadow painting works"): in the shadow pass drawPlot's
    # simpleShadow fills the WHOLE box black at the shadow alpha, so the coloured background
    # underneath is skipped (painting it too would tint and double-darken through accumulation).
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx, localArea) =>
      # (backgroundColor is undefined unless the user sets one — the base Widget default — so this
      # fill is usually skipped; drawPlot's own background-clean fill paints the plot box)
      if !appliedShadow? and @widget.backgroundColor?
        ctx.fillStyle = @widget.backgroundColor.toString()
        @_fillLocalRectSnappedToDevicePixels ctx, localArea

      @widget.drawPlot ctx, Color.WHITE, appliedShadow
