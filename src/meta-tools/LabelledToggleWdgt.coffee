# The design's TOGGLE (visual-design-system §4.3 and §4.8; the draft's UI-guidelines §7): ONE
# bordered rounded control with a FIXED label -- "Methods", never "Methods: on" -- whose look says
# whether it is ON. A press-me button in every other respect (I am a SimpleButtonWdgt): a click
# dispatches my one action at my target, handing me in slot 1, and a disabled toggle catches the
# press and does nothing.
#
# MY STATE IS MY HOST'S. My isOn is what my host last told me to show (setOn); a click never flips
# it. The host's action decides the new state, keeps it where the truth lives (the Object
# Inspector: its showing* fields) and shows it on me through setOn, so the two cannot disagree
# however the click is reached. A copy or a restored world carries my isOn as an own field beside
# the host's, both copied from the one consistent state.
#
# MY LOOK is a pure function of three things, every value a Theme role or metric: my isOn, my
# HighlightableMixin state (at rest, hovered, pressed) and my enabled flag. It is re-derived at every
# transition (SimpleButtonWdgt._updateColor), so no transition leaves a colour behind:
#   OFF   no fill (toggleOffFill) inside a 1 px toggleOffStroke border, the label toggleOffText;
#         hovered the toggleOffHoverFill, pressed the toggleOffPressFill inside the darker
#         toggleOffPressStroke -- the button's feedback, so a press on a toggle reads as a press
#   ON    the toggleOnFill inside a toggleOnStroke border, the label toggleOnText, in EVERY state:
#         the accent says "on" and nothing else (§4.8), and its fill is the accent's TRANSLUCENT
#         tint, so a hover or press plate would have to replace the "on" look or stack a second
#         translucent layer over it; the click itself shows at once, as the host turns me off
#   DISABLED  the button's disabled look, on or off (§4.3: no fill, a chrome outline, disabled text)
# My box is rounded at toggleCornerRadius, and my label is a string face in fonts.buttonLabel,
# centred in a box one line tall (SimpleButtonWdgt._faceBoundsIn).
#
# MY SIZE (preferredExtent): toggleHeight tall, and as wide as my label plus togglePaddingX at each
# side plus my 1 px border at each side, never narrower than a chrome target (§4.2). My label never
# changes, so my size never does.
#
# I declare no pins: a toggle whose state is its host's has no value of its own to export.
class LabelledToggleWdgt extends SimpleButtonWdgt

  # ON or OFF, as my host last set it (setOn). The constructor sets it from opts.on, so it is an own
  # field a copy and a saved world keep.
  isOn: false

  # SimpleButtonWdgt's head (target, action) and its opts, plus one key of my own, read guarded:
  #   on  (default false)  my initial isOn
  # isOn is assigned before super: the base constructor derives my look (_inkMyFace, _updateColor),
  # and my look reads it.
  constructor: (target, action, opts = {}) ->
    @isOn = !!(opts.on ? false)

    super target, action, opts

    @cornerRadius = WorldWdgt.theme.toggleCornerRadius

  # Show me ON or OFF. My host calls this, with the state it decided: my click never does. Only my
  # look changes -- my label, and so my size, stay -- so I repaint myself and nothing re-lays; my
  # label recolours itself.
  setOn: (flag) ->
    newState = !!flag
    return if newState is @isOn
    @isOn = newState
    @_inkMyFace()
    @_updateColor()

  _fillForMyState: ->
    return super() unless @isEnabled
    theme = WorldWdgt.theme
    return theme.toggleOnFill if @isOn
    switch @state
      when @STATE_PRESSED then theme.toggleOffPressFill
      when @STATE_HIGHLIGHTED then theme.toggleOffHoverFill
      else theme.toggleOffFill

  _strokeForMyState: ->
    return super() unless @isEnabled
    theme = WorldWdgt.theme
    return theme.toggleOnStroke if @isOn
    if @state is @STATE_PRESSED then theme.toggleOffPressStroke else theme.toggleOffStroke

  # My label's ink follows my isOn and my enabled flag, never a hover or a press: the constructor,
  # setOn and setEnabled write it.
  _inkMyFace: ->
    return super() unless @isEnabled
    return unless @_faceIsALineOfText()
    theme = WorldWdgt.theme
    @faceWidget.setColor (if @isOn then theme.toggleOnText else theme.toggleOffText)

  # The extent I would take given my druthers (see the header). A pure measure, as the button's: my
  # construction extent stays the generic one, and a set extent is never clamped to this. For a face
  # that is not a line of text, the button's answer.
  preferredExtent: ->
    return super() unless @_faceIsALineOfText()
    theme = WorldWdgt.theme
    face = @faceWidget
    labelWidth = Math.ceil face.measureText (face.transformTextOneToOne face.text), face.originallySetFontSize
    new Point (Math.max theme.minimumTargetSize, labelWidth + 2 * theme.togglePaddingX + 2), theme.toggleHeight
