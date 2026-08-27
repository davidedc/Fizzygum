# Base for the small icon-shaped buttons that live in window / panel chrome
# (close, collapse, un-collapse, edit, make-internal, make-external, …).
#
# Each sends a message to a target object when pressed and takes its SHAPE
# from an IconAppearance rather than from a label/face widget. Driving the
# shape through the appearance (plus a hover/press colour) is currently the
# simplest way to give a NON-rectangular button its colour — recolouring a
# button's face widget isn't supported yet.
#
# A subclass supplies only what differs from this base:
#   createAppearance   -> new <Foo>IconAppearance @   (the icon shape)
#   toolTipMessage     :  "…"                          (hover tooltip)
#   actOnClick         -> …                            (what the press does)
#   iconHoverColor     :  <Color>                      (only if not the default orange)

class IconButtonWdgt extends ButtonWdgt

  # hover / press colour for the family (orange); a subclass overrides this
  # field if it wants a different one (e.g. CloseIconButtonWdgt → red).
  iconHoverColor: Color.create 255, 153, 0

  # THE SIDE MY MARK IS DRAWN AT inside my box, read by IconAppearance.calculateRectangleOfIcon.
  # A chrome button is a TARGET first (ruling G3), so a title strip sizes me to the whole slot it
  # reserved and names the smaller glyph here: what a finger can hit grows, the ink does not.
  # Whoever PLACES me writes it (FrameBarWdgt._layOutPieceInSlot); unset -- every button placed by
  # anything else -- my mark fills my box.
  glyphSize: undefined

  # Frame-bar chrome, never editor content (§5.D D-3/D21 correction 1). This whole family IS the window
  # chrome (close / collapse / uncollapse / edit — the only IconButtonWdgt subclasses). Clicking the
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
    # on every hoverExited and mouseUpLeft, so leaving that at the mixin's generic default while my
    # own @color says something else means I change colour the first time a pointer visits me and
    # never change back -- a glyph whose shade records whether anyone ever hovered it. Stating the
    # two as one value is what makes a pointer visit round-trip to the same pixels. (The same
    # pairing OverflowChevronButtonWdgt writes out for its own dark mark.)
    @color_normal = @color
    @appearance = @createAppearance()
