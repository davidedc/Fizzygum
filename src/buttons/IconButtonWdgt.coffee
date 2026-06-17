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
#   iconToolTipMessage :  "…"                          (hover tooltip)
#   actOnClick         -> …                            (what the press does)
#   iconHoverColor     :  <Color>                      (only if not the default orange)

class IconButtonWdgt extends ButtonWdgt

  # hover / press colour for the family (orange); a subclass overrides this
  # field if it wants a different one (e.g. CloseIconButtonWdgt → red).
  iconHoverColor: Color.create 255, 153, 0
  iconToolTipMessage: nil

  constructor: (@target) ->
    # can't set the parent as the target directly because this widget might
    # not have a parent yet, so the button targets ITSELF and routes the
    # press to its own actOnClick (see the super args: target = @).
    super true, @, 'actOnClick', new Widget
    @color_hover = @iconHoverColor
    @color_pressed = @color_hover
    @appearance = @createAppearance()
    # set AFTER super on purpose: ButtonWdgt's constructor has @toolTipMessage
    # as a parameter that defaults back to nil, so a plain toolTipMessage:
    # prototype-field override would be clobbered — hence the separate
    # iconToolTipMessage source copied across here.
    @toolTipMessage = @iconToolTipMessage
