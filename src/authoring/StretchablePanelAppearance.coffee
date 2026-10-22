# Paints a StretchablePanelWdgt, the PAGE of the Slides Maker, the Dashboards Maker, the Generic panel
# and Patch programming: the rectangular look of every panel -- its fill is the page's role, which the
# page answers while it holds no colour of its own (StretchablePanelWdgt._surfaceFill) -- with the
# page's own BORDER: a 1 px edge in the stretchablePageEdge role on all four sides while the page's
# container stands in a window's page gutter (paper meets paper there, so the edge is the only
# boundary), else along each side where its container letterboxes it and none along a side flush
# with its container, where what lies past the container's edge is the boundary
# (StretchablePanelWdgt._insetEdgeRects). Painted in paintStroke's place, so after the page's
# children too (ClippingAtRectangularBoundsMixin re-strokes a clipping panel's border over its
# children), as the outline of any other panel is.

class StretchablePanelAppearance extends RectangularAppearance

  # each edge filled over the part of it being repainted, the way a container fills its seams
  # (Appearance._paintSeamRules): whole logical pixels, so dpr 2 doubles each exactly
  _paintBorder: (ctx, localDamageBox) ->
    edges = @widget._insetEdgeRects()
    return if edges.length == 0
    ctx.fillStyle = WorldWdgt.theme.stretchablePageEdge.toString()
    for edge in edges
      toBePainted = edge.intersect localDamageBox
      if toBePainted.isNotEmpty()
        @_fillLocalRectSnappedToDevicePixels ctx, toBePainted
