# The look of the layout-editing chrome family (LayoutSpacerWdgt, LayoutElementAdderOrDropletWdgt,
# StackElementsSizeAdjustingWdgt), the handles' look (HandleAppearance) at the sizes the chrome's boxes
# keep:
#   the PLATE  my widget's _plateFillForMyState inside a 1 px _plateStrokeForMyState border over its
#              WHOLE box (layoutChromePlateFill / Stroke at rest, layoutChromePlateHoverFill hovered,
#              layoutChromePlatePressFill / Stroke pressed), rounded at layoutChromePlateRadius -- at
#              half the short side of a strip narrower than twice that -- painted by the shared
#              Appearance._paintPlate
#   the MARK   my widget's, the same in every state: its _gripDotsOnMyPlate inside the plate (an
#              adjuster's grip dots, the house's, Appearance._paintGripDots), clear of the plate's
#              border and of its rounded ends, then its _glyphOnMyPlate centred on the plate (an
#              adder's plus, a spacer's double arrow), a size-aware icon in layoutChromeGlyph
# A transparent spacer (thisSpacerIsTransparent) paints nothing at all. Every value is my widget's
# state, its box or a Theme role or metric, read as I paint, so a saved or copied piece of chrome
# wears the look of the world it is shown in.
#
# My SHAPE is my widget's whole box (the base answer): the plate's rounded corners are the chrome's
# too, so a press at a strip's very corner still lands on it. My SILHOUETTE is the plate, on every
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
      @_paintMyWidgetsGripDots ctx, radius

    # the glyph over the plate, on the normal pass only: the plate is the whole silhouette
    return undefined if appliedShadow?
    [glyph, side] = @widget._glyphOnMyPlate()
    glyph?.paintAsMarkInSquare aContext, clippingRectangle, side
    return undefined

  # MY WIDGET'S GRIP DOTS (_gripDotsOnMyPlate: an adjuster's) inside my plate, rounded at `radius` as
  # _plateRadius clamps it: kept layoutChromeGripDotsInset in from the plate's edge across my
  # widget's short side (its border and one clear pixel) and the plate's rounding off its rounded
  # ends along the long one, as many as fit across and at most the count my widget names along,
  # centred (Appearance._paintGripDots). A plate squeezed too thin for a dot clear of its border
  # shows none. Which side is long is read off my widget's box: a strip standing between a row's
  # cells runs down, one lying between a column's runs across. None where my widget names none.
  _paintMyWidgetsGripDots: (ctx, radius) ->
    [ink, mostAlong] = @widget._gripDotsOnMyPlate()
    return unless ink?
    w = @widget.width()
    h = @widget.height()
    edge = WorldWdgt.theme.layoutChromeGripDotsInset
    ends = @_plateRadius radius
    box = new Rectangle 0, 0, w, h
    if h >= w
      @_paintGripDots ctx, box.insetBy(new Point edge, ends), ink, mostRows: mostAlong
    else
      @_paintGripDots ctx, box.insetBy(new Point ends, edge), ink, mostColumns: mostAlong
