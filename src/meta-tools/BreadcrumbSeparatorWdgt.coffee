# The SEPARATOR of the Object Inspector's breadcrumb (InspectorWdgt): the › between two class chips,
# from a class to the class derived from it. Drawn, never typed (redesign plan §3b,
# visual-design-system §4.5: a symbol that stands on its own is an icon, and on the SWCanvas page a
# typed › paints a placeholder box): ChevronRightIconAppearance paints it in my glyph square, at
# integer device-pixel geometry, in my @color.
#   I am a PICTURE, never a target: `catchesPointerAt` answers false, so a press on me is a press on
# whatever lies under me -- the inspector's band -- and I can be neither pressed nor picked up. I
# have no children.
#   My box IS my glyph square (breadcrumbSeparatorSize on each side) and my ink is the
# inspectorBreadcrumbSeparator role. The inspector builds me, places me so that my INK -- not my
# square -- keeps the breadcrumb's gaps (ChevronRightIconAppearance.inkSpanX), and holds me as a
# child, so a duplicated or saved inspector brings me along.

class BreadcrumbSeparatorWdgt extends Widget

  # the side of the square my chevron is painted in, in logical px -- also my box's
  # (SizeAwareIconAppearance._paintBoxInDevicePx clips the art to it)
  glyphSize: undefined

  constructor: ->
    super()
    theme = WorldWdgt.theme
    @glyphSize = theme.breadcrumbSeparatorSize
    @color = theme.inspectorBreadcrumbSeparator
    @appearance = new ChevronRightIconAppearance @
    @__commitExtent new Point @glyphSize, @glyphSize

  # THE ROLE (see the header): something to look at, never a pointer target.
  catchesPointerAt: (aPoint) ->
    false
