# Paints a SimpleSpreadsheetWdgt's ONE pixel of its own: its PAGE EDGE, a 1 px line along each of its
# four sides in the stretchablePageEdge role — the line a Slides or Dashboards page and Draw's canvas
# draw in a window's page gutter (StretchablePanelWdgt._insetEdgeRects), because window body, gutter and
# page are all paper and a side without its edge would have no boundary at all. Everything else the
# sheet shows is a child's (its header cells, its cells, its formula bar).
#   The edge is painted AFTER the children (paintStroke, which the sheet's
# ClippingAtRectangularBoundsMixin calls once they have all painted), so a partial cell, a header's fill
# or a hosted widget reaching the sheet's edge never paints over it. The two vertical sides stop short
# of the horizontal ones, so no pixel is filled twice.

class SheetAppearance extends Appearance

  # chrome paints at the ambient alpha (see Appearance)
  alphaPolicy: "none"

  # the normal paint: nothing (the children paint the sheet)
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    return

  # the after-children paint: the four sides
  paintStroke: (aContext, clippingRectangle) ->
    @_paintInUnshadowedScope aContext, clippingRectangle, (ctx) =>
      w = @widget.width()
      h = @widget.height()
      ctx.fillStyle = WorldWdgt.theme.stretchablePageEdge.toString()
      ctx.fillRect 0, 0, w, 1
      ctx.fillRect 0, h - 1, w, 1
      ctx.fillRect 0, 1, 1, h - 2
      ctx.fillRect w - 1, 1, 1, h - 2
      return
    return
