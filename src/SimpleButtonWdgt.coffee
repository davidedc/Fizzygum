# The design's BUTTON (visual-design-system §4.3, "a bordered rounded rectangle means press me"):
# sends a message to a target object when pressed, wears a rounded box, and can host a widget as
# its "face" -- most often a line of text.
#
# MY LOOK is a pure function of two things, and every value in it is a Theme role or metric:
#   my STATE    HighlightableMixin's: at rest, under the pointer (hovered), pressed
#   my ENABLED  flag (setEnabled)
# At rest I paint buttonFill inside a 1 px buttonStroke border at buttonCornerRadius, hovered
# buttonHoverFill, pressed buttonPressFill inside the darker buttonPressStroke. Disabled I keep my
# shape and lose contrast: no fill (whatever is behind me shows), a buttonDisabledStroke border,
# and no hover or pressed look. The look is re-derived from the state at EVERY transition
# (_updateColor), for the mouse and the finger alike, so no transition can leave a colour of its
# own behind. ⚠ That is also why I do not wear the MIXIN's colours (color_normal / color_hover /
# color_pressed): a live edit of them reaches a plain ButtonWdgt and not me, so
# SystemTest_macroMixinEditDonorAndOverride and its field sibling prove a live mixin edit on a
# plain ButtonWdgt.
#
# A LINE OF TEXT as my face (a string face, which ButtonWdgt builds, or a StringWdgt a host built
# itself) gets three things more:
#   its ink    buttonText while I am enabled, buttonDisabledText while I am not
#   its place  a box one line tall, centred in my box (draft-exact: _faceBoundsIn)
#   my size    preferredExtent: buttonHeight tall, the label plus my horizontal padding at each
#              side plus my border wide, never narrower than minimumTargetSize
# Any other face (an icon, a raster image) fills my box inset by my padding, as ButtonWdgt places
# it, and I answer ButtonWdgt's preferredExtent. Without a face I have no child at all.
#
# A PRIMARY action (opts.primary) is the same button with the wider primaryButtonPaddingX: same
# colours, since the accent marks focused, selected and "on" only (visual-design-system §4.8).

class SimpleButtonWdgt extends ButtonWdgt

  # Editor CHROME opt-in (Frame-model plan §5.D D2a): a button whose action acts
  # ON the editor focus (the Console's "run selection", which reads the current
  # text selection) sets this so its press neither steals the focus pointer nor
  # ends the ongoing edit. Default false ⇒ ordinary buttons are unaffected
  # (they answer the same falsy the un-declared case did). Ancestry-honored at
  # ActivePointerWdgt's focus-set sites + caret-survival policy.
  actsAsEditorChrome: false
  excludedFromEditorFocusTracking: ->
    @actsAsEditorChrome

  # Do I act? A disabled button still CATCHES the press -- its shape does not change, so a press
  # aimed at it lands on it and goes no further -- and then does nothing at all: no action, no
  # pop-up dismissal, no escalation of the activation. The constructor sets it from opts.enabled
  # and setEnabled changes it, so it is an own field a copy and a saved world keep.
  isEnabled: true

  # Am I a primary action? It decides only my horizontal padding (preferredExtent). Set by the
  # constructor from opts.primary, so a copy keeps it.
  isPrimaryAction: false

  # ButtonWdgt's head (target, action) and its opts, plus two keys of my own, each read guarded:
  #   enabled  (default true)   the initial isEnabled
  #   primary  (default false)  isPrimaryAction
  constructor: (target, action, opts = {}) ->
    @isEnabled = opts.enabled ? true
    @isPrimaryAction = opts.primary ? false

    super target, action, opts

    @appearance = new BoxyAppearance @
    @cornerRadius = WorldWdgt.theme.buttonCornerRadius
    @_inkMyFace()
    @_updateColor()

  # Enable or disable me. My look follows at once, whatever state the pointer leaves me in: a
  # disabled button shows no hover or pressed look, and an enabled one shows the look of the state
  # it is in now. Only I repaint; my text face recolours itself.
  setEnabled: (flag) ->
    enabled = !!flag
    return if enabled is @isEnabled
    @isEnabled = enabled
    @_inkMyFace()
    @_updateColor()

  # A disabled button swallows the activation (see isEnabled).
  activated: ->
    return unless @isEnabled
    super

  doubleActivated: ->
    return unless @isEnabled
    super

  # HighlightableMixin's colour hook, which every one of its state transitions calls (hoverEntered,
  # hoverExited, pressBegan, pressEnded) after setting @state. I answer it with my whole box look
  # for the state I am in now, so the look is decided here and nowhere else.
  _updateColor: ->
    @color = @_fillForMyState()
    @strokeColor = @_strokeForMyState()
    @_changed()

  _fillForMyState: ->
    theme = WorldWdgt.theme
    return theme.buttonDisabledFill unless @isEnabled
    switch @state
      when @STATE_PRESSED then theme.buttonPressFill
      when @STATE_HIGHLIGHTED then theme.buttonHoverFill
      else theme.buttonFill

  _strokeForMyState: ->
    theme = WorldWdgt.theme
    return theme.buttonDisabledStroke unless @isEnabled
    if @state is @STATE_PRESSED then theme.buttonPressStroke else theme.buttonStroke

  # My text face's ink, which follows my enabled flag and nothing else: the constructor and
  # setEnabled write it, a hover or a press never does.
  _inkMyFace: ->
    return unless @_faceIsALineOfText()
    theme = WorldWdgt.theme
    @faceWidget.setColor (if @isEnabled then theme.buttonText else theme.buttonDisabledText)

  # Is my face ONE line of text I can measure and place by its line? A capability query: a
  # StringWdgt measures its own text and keeps it on one line; a TextWdgt breaks its text into
  # lines, and an icon or an image has no text to measure. A face something has taken out of me
  # is not my face to measure, place or ink.
  _faceIsALineOfText: ->
    @faceWidget?.parent is @ and @faceWidget.measureText? and !@faceWidget.breakTextIntoLines?

  # The box ButtonWdgt._reLayout grants my face inside `room` (my box inset by my padding). A line
  # of text gets a box one line tall -- its own line box, ceil(1.2 x its font size): 15 at 12 px --
  # across the whole room, floor((room height - line height) / 2) below the room's top: in a 36
  # tall button the cap ink of 12 px Arial lands on rows 13..21, on the draft's baseline 22. The
  # floor keeps the box at integer bounds, and in a room only one line tall it IS the room, so a
  # button sized to one line places its face exactly where it fills the room. A room shorter than
  # one line, and any other face, keep the whole room.
  _faceBoundsIn: (room) ->
    return room unless @_faceIsALineOfText()
    lineHeight = @faceWidget.fontHeight @faceWidget.originallySetFontSize
    return room if room.height() <= lineHeight
    top = room.top() + Math.floor (room.height() - lineHeight) / 2
    new Rectangle room.left(), top, room.right(), top + lineHeight

  # The extent I would take given my druthers: for a line of text, buttonHeight tall and as wide as
  # the label (its own measure, so the SWCanvas page's integer advances are what count) plus my
  # horizontal padding at each side plus my 1 px border at each side -- never narrower than a
  # chrome target (visual-design-system §4.2). For any other face, or none, what every widget
  # answers. A pure measure: my CONSTRUCTION extent stays the generic one, and a set extent is
  # never clamped to this.
  preferredExtent: ->
    return super() unless @_faceIsALineOfText()
    theme = WorldWdgt.theme
    paddingX = if @isPrimaryAction then theme.primaryButtonPaddingX else theme.buttonPaddingX
    face = @faceWidget
    labelWidth = Math.ceil face.measureText (face.transformTextOneToOne face.text), face.originallySetFontSize
    new Point (Math.max theme.minimumTargetSize, labelWidth + 2 * paddingX + 2), theme.buttonHeight
