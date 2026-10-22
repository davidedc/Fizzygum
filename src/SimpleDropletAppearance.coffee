# The look of an empty icon holder's drop placeholder (SimpleDropletWdgt):
#   the WELL  dropletWellFill over my widget's whole box, rounded at dropletWellRadius (at half the
#             short side of a box narrower than twice that), with no border: a placeholder, not a
#             button (visual-design-system §4.3: what nothing presses drops the border), painted by
#             the shared Appearance._paintPlate
#   the PLUS  in dropletGlyph, centred on the well at dropletGlyphSize (PlusIconAppearance, built
#             for each paint)
# the same in every pointer state. Every value is a Theme role or metric read as I paint, so a saved
# or copied placeholder wears the look of the world it is shown in.
#
# My SHAPE is my widget's whole box (the base answer): a drop anywhere on it reaches the
# placeholder, the well's rounded corners included. My SILHOUETTE is the well: on a shadow pass I
# fill it in shadowColor, and the plus inside it adds no coverage.

class SimpleDropletAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    theme = WorldWdgt.theme

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      fill = if appliedShadow? then theme.shadowColor else theme.dropletWellFill
      @_paintPlate ctx, theme.dropletWellRadius, fill

    return undefined if appliedShadow?
    (new PlusIconAppearance @widget, theme.dropletGlyph).paintAsMarkInSquare aContext, clippingRectangle, theme.dropletGlyphSize
    return undefined

