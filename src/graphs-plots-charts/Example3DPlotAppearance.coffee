# Paints the Example3DPlotWdgt: background rect in ACTUAL pixels, then the widget's
# drawPlot tail (the 3D mesh drawing) in LOGICAL pixels with the origin translated to
# the widget position.
#
# NB: this is the SAME paint scaffold the plot family shares in
# GraphsPlotsChartsAppearance, but Example3DPlotWdgt extends Widget directly --
# reparenting it onto the plot base would also pull in that base's constructor +
# KeepsRatioWhenInVerticalStackMixin (a behaviour change), so this appearance copy is
# kept deliberately rather than deduplicated.

class Example3DPlotAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @widget.calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    # Shadow-pass paint contract (Widget.coffee "How the shadow painting works"): in the
    # shadow pass drawPlot fills the WHOLE box black at the shadow alpha, so the coloured
    # background underneath is skipped (painting it too would tint and double-darken
    # through accumulation).
    if !appliedShadow?
      aContext.globalAlpha = @widget.backgroundTransparency

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

    # skipped in the shadow pass: the hover highlight is not part of the caster's ink.
    return if appliedShadow?

    # _drawHighlightOverlay here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called outside the effect of the scaling
    # (after the restore).
    @_drawHighlightOverlay aContext, al, at, w, h
