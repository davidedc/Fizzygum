# Paints the plot/chart family (GraphsPlotsChartsWdgt and its concrete plots — bar,
# function, scatter — which inherit this via the base): background rect in ACTUAL
# pixels, then the widget's own drawPlot tail (the per-plot drawing body, PUBLIC and
# subclass-polymorphic — the drawLayoutChrome precedent) in LOGICAL pixels with the
# origin translated to the widget position. (Example3DPlotWdgt keeps its own separate
# appearance copy — see Example3DPlotAppearance's header for why.)

class GraphsPlotsChartsAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @widget.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @widget.backgroundTransparency

    # paintRectangle here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called before the scaling.
    @widget.paintRectangle aContext, al, at, w, h, @widget.backgroundColor
    aContext.useLogicalPixelsUntilRestore()

    widgetPosition = @widget.position()
    aContext.translate widgetPosition.x, widgetPosition.y

    @widget.drawPlot aContext, Color.WHITE, appliedShadow

    aContext.restore()

    # _drawHighlightOverlay here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called outside the effect of the scaling
    # (after the restore).
    @_drawHighlightOverlay aContext, al, at, w, h
