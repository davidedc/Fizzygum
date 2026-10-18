# The design's CHIP (visual-design-system §4.3 and §4.8; the draft's UI-guidelines §7, "Chip"): a
# pill-shaped label control, one of a ROW of alternatives, whose look says which one is CURRENT -- a
# class of the Object Inspector's breadcrumb. A press-me button in every other respect (I am a
# SimpleButtonWdgt): a click dispatches my one action at my target, handing me in slot 1, the
# current chip as much as any other, and a disabled chip catches the press and does nothing.
#
# WHETHER I AM CURRENT is my builder's to say, once (opts.current): it is a fact about the row I
# stand in, so nothing about a click changes it.
#
# MY LOOK is a pure function of three things, every value a Theme role or metric: whether I am
# current, my HighlightableMixin state (at rest, hovered, pressed) and my enabled flag. It is
# re-derived at every transition (SimpleButtonWdgt._updateColor), so no transition leaves a colour
# behind:
#   ANY OTHER  no fill (chipFill) inside a 1 px chipStroke border, the label chipText; hovered the
#              chipHoverFill, pressed the chipPressFill inside the darker chipPressStroke -- the
#              button's feedback, so a press on a chip reads as a press
#   CURRENT    the chipCurrentFill inside a chipCurrentStroke border, the label chipCurrentText, in
#              EVERY state: the accent says "selected" and nothing else (§4.8), and its fill is the
#              accent's TRANSLUCENT tint, so a hover or press plate would have to replace the current
#              look or stack a second translucent layer over it -- the toggle's ON look
#              (LabelledToggleWdgt), for the same reason
#   DISABLED   the button's disabled look, current or not (§4.3: no fill, a chrome outline, disabled
#              text)
# My box is a full pill (chipCornerRadius, half my height), and my label is a string face in
# fonts.buttonLabel, centred in a box one line tall (SimpleButtonWdgt._faceBoundsIn).
#
# MY SIZE (preferredExtent): chipHeight tall, and as wide as my label plus chipPaddingX at each side
# plus my 1 px border at each side, never narrower than a chrome target (§4.2). The 44 rule lets a
# smaller control stand in a row at least 44 tall, and that is what my height leans on (the
# Object Inspector's breadcrumb band is 44 tall for one row of chips); nothing stands in for my
# WIDTH, so a label under 22 px ("Map", "Set") is padded out to 44 rather than drawn as a narrower
# target. No label in the draft is that short, so the floor moves none of its pixels. My label never
# changes, so my size never does.
#
# I declare no pins: what I stand for is my action's payload, not a value of my own to export.
class ChipWdgt extends SimpleButtonWdgt

  # am I the current one of my row? Set by the constructor from opts.current, so it is an own field
  # a copy and a saved world keep.
  isCurrent: false

  # SimpleButtonWdgt's head (target, action) and its opts, plus one key of my own, read guarded:
  #   current  (default false)  isCurrent
  # isCurrent is assigned before super: the base constructor derives my look (_inkMyFace,
  # _updateColor), and my look reads it.
  constructor: (target, action, opts = {}) ->
    @isCurrent = !!(opts.current ? false)

    super target, action, opts

    @cornerRadius = WorldWdgt.theme.chipCornerRadius

  _fillForMyState: ->
    return super() unless @isEnabled
    theme = WorldWdgt.theme
    return theme.chipCurrentFill if @isCurrent
    switch @state
      when @STATE_PRESSED then theme.chipPressFill
      when @STATE_HIGHLIGHTED then theme.chipHoverFill
      else theme.chipFill

  _strokeForMyState: ->
    return super() unless @isEnabled
    theme = WorldWdgt.theme
    return theme.chipCurrentStroke if @isCurrent
    if @state is @STATE_PRESSED then theme.chipPressStroke else theme.chipStroke

  # My label's ink follows whether I am current and my enabled flag, never a hover or a press: the
  # constructor and setEnabled write it.
  _inkMyFace: ->
    return super() unless @isEnabled
    return unless @_faceIsALineOfText()
    theme = WorldWdgt.theme
    @faceWidget.setColor (if @isCurrent then theme.chipCurrentText else theme.chipText)

  # The extent I would take given my druthers (see the header). A pure measure, as the button's: my
  # construction extent stays the generic one, and a set extent is never clamped to this. For a face
  # that is not a line of text, the button's answer.
  preferredExtent: ->
    return super() unless @_faceIsALineOfText()
    theme = WorldWdgt.theme
    face = @faceWidget
    labelWidth = Math.ceil face.measureText (face.transformTextOneToOne face.text), face.originallySetFontSize
    new Point (Math.max theme.minimumTargetSize, labelWidth + 2 * theme.chipPaddingX + 2), theme.chipHeight
