# The look of the "Edit layout" scaffold's layout chrome (LayoutSpacerWdgt,
# LayoutElementAdderOrDropletWdgt), the handles' look (HandleAppearance) at the sizes the chrome's boxes
# keep:
#   the PLATE  my widget's _plateFillForMyState inside a 1 px _plateStrokeForMyState border over its
#              WHOLE box (layoutChromePlateFill / Stroke at rest, layoutChromePlateHoverFill hovered,
#              layoutChromePlatePressFill / Stroke pressed), rounded at layoutChromePlateRadius -- at
#              half the short side of a box narrower than twice that -- painted by the shared
#              Appearance._paintPlate
#   the MARK   my widget's, the same in every state: its _glyphOnMyPlate centred on the plate (an
#              adder's plus, a spacer's double arrow), a size-aware icon in layoutChromeGlyph
# A transparent spacer (thisSpacerIsTransparent) paints nothing at all. Every value is my widget's
# state, its box or a Theme role or metric, read as I paint, so a saved or copied piece of chrome
# wears the look of the world it is shown in. (A split's divider and its tab wear a look of their own,
# SplitPieceAppearance.)
#
# My SHAPE is my widget's whole box (the base answer): the plate's rounded corners are the chrome's
# too, so a press at a plate's very corner still lands on it. My SILHOUETTE is the plate, on every
# shadow pass (my widget's own, as a free-floating piece of chrome, or an ancestor's): the plate is
# opaque, so its black version is the complete silhouette -- the chrome art drawn inside it adds no
# coverage and is skipped, like the hover highlight.

class LayoutChromeAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @widget.thisSpacerIsTransparent
      return

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      theme = WorldWdgt.theme
      radius = theme.layoutChromePlateRadius

      if appliedShadow?
        @_paintPlate ctx, radius, theme.shadowColor
        return

      @_paintPlate ctx, radius, @widget._plateFillForMyState(), @widget._plateStrokeForMyState()

    # the glyph over the plate, on the normal pass only: the plate is the whole silhouette
    return undefined if appliedShadow?
    [glyph, side] = @widget._glyphOnMyPlate()
    glyph?.paintAsMarkInSquare aContext, clippingRectangle, side
    return undefined
