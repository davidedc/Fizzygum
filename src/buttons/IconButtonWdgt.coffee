# Base for the small icon buttons of chrome: a window strip's close, collapse, un-collapse and
# edit pieces, and a toolbar strip's overflow chevron.
#
# Each sends a message to a target object when pressed and draws its MARK -- the glyph -- through
# an IconAppearance rather than through a label or a face widget. The glyph is painted in my
# colour, so the hover/press state machine (HighlightableMixin) recolours it. What a pointer hits
# is my whole box, never the glyph's outline: an icon appearance keeps the base box test
# (Appearance.shapeContainsPoint), because the box is the target and the glyph only the mark drawn
# inside it (ruling G3). (The toolbar's overflow chevron re-answers both: it wears a tool cell's
# look, its state on a rounded plate that is also its shape, OverflowChevronButtonWdgt.)
#
# A subclass supplies only what differs from this base:
#   createAppearance   -> new <Foo>IconAppearance @   (the glyph's shape)
#   toolTipMessage     :  "…"                          (hover tooltip)
#   actOnClick         -> …                            (what the press does)
# My glyph's ink is the same for every subclass: a frame's strip inks the pieces it carries itself
# (setGlyphInk, below), and a piece no strip inks wears the icon button's roles (_updateColor).

class IconButtonWdgt extends ButtonWdgt

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
    @appearance = @createAppearance()

  # HighlightableMixin's colour hook, which every one of its state transitions calls after setting
  # @state (and ButtonWdgt's constructor, once): my glyph's ink for the state I am in now -- the
  # state machine's own field for it when the strip that carries me has set one (setGlyphInk), else
  # the icon button's role, read here: iconButtonGlyph at rest, iconButtonGlyphActive hovered and
  # pressed. The constructor and every transition derive it the same way, so a pointer visit
  # round-trips my glyph to the pixels it had.
  _updateColor: ->
    theme = WorldWdgt.theme
    @color = switch @state
      when @STATE_HIGHLIGHTED then @color_hover ? theme.iconButtonGlyphActive
      when @STATE_PRESSED then @color_pressed ? theme.iconButtonGlyphActive
      else @color_normal ? theme.iconButtonGlyph
    @_changed()

  # MY GLYPH'S INK, as the strip that carries me names it (FrameBarWdgt._inkGlyphButtons, from its
  # frame's look): `restInk` at rest, `activeInk` while I am hovered and while I am pressed. All the
  # state machine's colours move together, so every transition paints the strip's ink, and @color
  # follows at once, in whatever state I am in now. The same inks again are a no-op: a strip
  # re-inks every piece it carries at each derivation of its skin.
  setGlyphInk: (restInk, activeInk) ->
    unchanged = @color_normal?.equals(restInk) and @color_hover?.equals(activeInk) and
      @color_pressed?.equals(activeInk)
    return if unchanged
    @color_normal = restInk
    @color_hover = activeInk
    @color_pressed = activeInk
    @_updateColor()
