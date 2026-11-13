# A CanvasWdgt's appearance. A canvas IS its raster, so it answers the three questions a raster
# decides -- its paint, where it takes the pointer, what it covers -- from its widget's BackBuffer,
# and keeps every other answer of the rectangular panel appearance it extends: above all its
# BORDER, which the clipping paint tail strokes after my widget's children have painted
# (ClippingWdgt.fullPaintIntoAreaOrBlitFromBackBuffer → @paintStroke, RectangularAppearance's).

class CanvasAppearance extends RectangularAppearance

  # The raster is the surface: my widget's paint is the blit of its back buffer, and nothing more.
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    BackBuffer.blitOf @widget, aContext, clippingRectangle, appliedShadow

  # A click lands on my widget only where something is drawn: the shape is answered per pixel
  # (BackBuffer.isPaintedAt, TOTAL). A canvas whose raster is known to fill its box, or that must
  # take the pointer while it is clear (the paint glass), answers catchesPointerAt itself.
  shapeContainsPoint: (aPoint) ->
    BackBuffer.isPaintedAt @widget, aPoint

  # An offscreen raster has unknown per-pixel opacity, so I make no coverage claim to the occlusion
  # culler -- where RectangularAppearance would claim my widget's box, and the culler would drop
  # whatever lies under a see-through pixel of it.
  opaqueCoveredRect: ->
    undefined
