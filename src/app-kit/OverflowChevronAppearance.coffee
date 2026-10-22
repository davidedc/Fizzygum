# The look of a toolbar's OVERFLOW CHEVRON (OverflowChevronButtonWdgt). The chevron takes a tool
# cell's slot but stands in no cell, so it wears a tool cell's look itself (GlassBoxBottomWdgt):
#   the PLATE  my widget's whole box rounded at toolCellCornerRadius, no border, in the cell's fill
#              for my widget's state (GlassBoxBottomWdgt.fillForToolState: none at rest, hovered,
#              pressed -- the chevron is never the active tool), read at every paint
#   the GLYPH  the double chevron over it (DoubleChevronRightIconAppearance, the draft's 16 px », in
#              the glyphSize square my widget's placer names), in my own colour, the toolbarGlyph
#              ink, in every state
# My SHAPE is the plate's, so a press in one of its corner notches reaches whatever lies behind my
# widget, as one in a tool cell's does. The plate is clear at rest, so I claim no opaque cover (the
# base answer), and on the shadow pass only the glyph casts.

class OverflowChevronAppearance extends DoubleChevronRightIconAppearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    plateFill = GlassBoxBottomWdgt.fillForToolState @widget, false
    if !appliedShadow? and plateFill._a > 0
      @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
        ctx.fillStyle = plateFill.toString()
        ctx.fillRoundRect 0, 0, @widget.width(), @widget.height(), WorldWdgt.theme.toolCellCornerRadius
    super

  # The plate, by pixel centre (BoxyAppearance's one rounded-box test). TOTAL: nothing outside my
  # widget's bounds is mine.
  shapeContainsPoint: (aPoint) ->
    return false unless @widget.boundsContainPoint aPoint
    radius = WorldWdgt.theme.toolCellCornerRadius
    BoxyAppearance.roundedBoxContainsPixelCentreOf (aPoint.subtract @widget.position()), @widget.width(), @widget.height(), [radius, radius, radius, radius]
