# Base for the small icon buttons of chrome: a window strip's close, collapse, un-collapse and
# edit pieces, and a toolbar strip's overflow chevron.
#
# Each sends a message to a target object when pressed and draws its MARK -- the glyph -- through
# an IconAppearance rather than through a label or a face widget. The glyph is painted in my
# colour, so the hover/press state machine (HighlightableMixin) recolours it. What a pointer hits
# is my whole box, never the glyph's outline: an icon appearance keeps the base box test
# (Appearance.shapeContainsPoint), because the box is the target and the glyph only the mark drawn
# inside it (ruling G3).
#
# A subclass supplies only what differs from this base:
#   createAppearance   -> new <Foo>IconAppearance @   (the glyph's shape)
#   toolTipMessage     :  "…"                          (hover tooltip)
#   actOnClick         -> …                            (what the press does)
#   iconHoverColor     :  <Color>                      (only if not the default orange)
# A frame's strip inks the pieces it carries itself (setGlyphInk, below), so on a frame strip a
# piece wears the strip's ink whatever those defaults say.

class IconButtonWdgt extends ButtonWdgt

  # the hover / press colour (orange) of a button no frame strip inks -- the toolbar's overflow
  # chevron, a close button standing on its own; a subclass overrides this field if it wants a
  # different one (e.g. CloseIconButtonWdgt → red).
  iconHoverColor: Color.create 255, 153, 0

  # THE SIDE MY MARK IS DRAWN AT inside my box, read by IconAppearance.calculateRectangleOfIcon.
  # A chrome button is a TARGET first (ruling G3), so a title strip sizes me to the whole slot it
  # reserved and names the smaller glyph here: what a finger can hit grows, the ink does not.
  # Whoever PLACES me writes it (FrameBarWdgt._layOutPieceInSlot); unset -- every button placed by
  # anything else -- my mark fills my box.
  glyphSize: undefined

  # Chrome, never editor content (§5.D D-3/D21 correction 1). Every IconButtonWdgt subclass is chrome:
  # a window bar's close / collapse / uncollapse / edit buttons, and a toolbar strip's overflow
  # chevron (OverflowChevronButtonWdgt). Clicking the
  # eye/pencil to toggle a frame's edit mode, or collapsing/closing it, must NOT set world.editorFocusWdgt
  # to the button (the SELECTED-ITEM overlay would then frame the button, since it sits inside an
  # editing-amenity frame) NOR end the ongoing content edit -- exactly the editor-chrome exemption
  # SimpleButtonWdgt gives its opt-in `actsAsEditorChrome` buttons, but unconditional here because every
  # icon button in this family is chrome. Honored by ancestry at ActivePointerWdgt's focus-set + caret
  # sites, so it also covers a click landing on the icon's shape.
  excludedFromEditorFocusTracking: -> true

  constructor: (@target) ->
    # can't set the parent as the target directly because this widget might
    # not have a parent yet, so the button targets ITSELF and routes the
    # press to its own actOnClick (see the super args: target = @).
    super @, 'actOnClick', face: new Widget
    @color_hover = @iconHoverColor
    @color_pressed = @color_hover
    # MY RESTING COLOUR IS THE ONE I AM BUILT AT. HighlightableMixin repaints me at color_normal
    # on every hoverExited and pressEnded, so leaving that at the mixin's generic default while my
    # own @color says something else means I change colour the first time a pointer visits me and
    # never change back -- a glyph whose shade records whether anyone ever hovered it. Stating the
    # two as one value is what makes a pointer visit round-trip to the same pixels. (The same
    # pairing OverflowChevronButtonWdgt writes out for its own dark mark.)
    @color_normal = @color
    @appearance = @createAppearance()

  # MY GLYPH'S INK, as the strip that carries me names it (FrameBarWdgt._inkGlyphButtons, from its
  # frame's look): `restInk` at rest, `activeInk` while I am hovered and while I am pressed. All the
  # state machine's colours move together, for the reason the constructor gives -- a bare @color
  # would last only until the first pointer visit -- and @color follows at once, in whatever state
  # I am in now. The same inks again are a no-op: a strip re-inks every piece it carries at each
  # derivation of its skin.
  setGlyphInk: (restInk, activeInk) ->
    unchanged = @color_normal?.equals(restInk) and @color_hover?.equals(activeInk) and
      @color_pressed?.equals(activeInk)
    return if unchanged
    @color_normal = restInk
    @color_hover = activeInk
    @color_pressed = activeInk
    @_updateColor()
