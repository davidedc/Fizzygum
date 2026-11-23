# The look of a TOOL CELL (GlassBoxBottomWdgt): a BoxyAppearance whose fill is the STATE PLATE, my
# widget's box toolCellPlateInset in on every side, rounded at the tool cell's radius. A band is as
# deep as its cells, so a plate painted over the whole cell would run into both of the band's border
# lines; inset, it keeps clear of them. Only what is PAINTED moves in: my shape (shapeContainsPoint)
# and the outline my widget's children are cut to (outlineCornerRadii) stay the inherited whole box,
# because the cell is the target and the plate only what its state paints (G3).

class ToolCellAppearance extends BoxyAppearance

  # my fill is the state plate
  fillOutline: (context) ->
    ToolCellAppearance.fillStatePlate context, @widget.width(), @widget.height()

  # THE PLATE for a `width` x `height` box the size of a tool cell, in the fill the context already
  # carries. ONE geometry for every wearer of the look: my cells, and the toolbar's overflow chevron,
  # which stands in no cell (OverflowChevronAppearance).
  @fillStatePlate: (context, width, height) ->
    theme = WorldWdgt.theme
    inset = theme.toolCellPlateInset
    context.fillRoundRect inset, inset, width - 2 * inset, height - 2 * inset, theme.toolCellCornerRadius

  # what my fill hides is inside the PLATE, never my whole box: the plate's inscribed box, its
  # rounding cut away as BoxyAppearance cuts its own
  opaqueCoveredRect: ->
    theme = WorldWdgt.theme
    (@widget.boundingBox().insetBy theme.toolCellPlateInset).insetBy theme.toolCellCornerRadius + 1
