# A menu row's INDICATOR: a drawn mark a MenuItemWdgt shows beside its label about what the row
# DOES or what it SHOWS -- the submenu chevron (›) at its right edge, the tick (✓) in its leading
# column. Never typed into the label (redesign plan §3b: a symbol that stands on its own is an
# icon), so the label stays the row's plain wording and a size-aware icon appearance paints the
# mark at integer device-pixel geometry on both backends.
#   I am a PICTURE, never a target: `catchesPointerAt` answers false, so a tap on me is a tap on the
# row that carries me -- the role InertIconHolderWdgt states for the row's left icon slot, and for
# the same reason. I have no children, so nothing below me can take the tap either.
#   My box IS my glyph square (glyphSize on each side), and my ink is my @color, the theme role my
# row hands me (SizeAwareIconAppearance reads both). My row builds me, places me and decides when I
# exist (MenuItemWdgt._placeMyParts); I am a plain child of it, so a duplicated, lifted-out or
# saved row brings me along.

class MenuRowIndicatorWdgt extends Widget

  # the side of the square my mark is painted in, in logical px -- also my box's
  # (SizeAwareIconAppearance._paintBoxInDevicePx clips the art to it)
  glyphSize: undefined

  # POSITIONAL for the identity -- the appearance CLASS that draws my mark, a
  # SizeAwareIconAppearance (ChevronRightIconAppearance, TickIconAppearance) -- and the look rides
  # opts: `glyphSize`, the side of my square, and `color`, my ink.
  constructor: (markAppearance, opts = {}) ->
    super()
    @glyphSize = opts.glyphSize
    @color = opts.color
    @appearance = new markAppearance @
    @__commitExtent new Point @glyphSize, @glyphSize

  # THE ROLE (see the header): something to look at, never a pointer target.
  catchesPointerAt: (aPoint) ->
    false
