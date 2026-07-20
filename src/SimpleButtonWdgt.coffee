# sends a message to a target object when pressed.
# takes a rounded box shape, and can host
# a widget to be used as "face"

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

  # The ctor params are identical to ButtonWdgt's, so we drop the re-declared 12-param signature: bare
  # `super` forwards `arguments` and the base assigns every @param onto this same instance — byte-identical.
  constructor: ->

    super

    @appearance = new BoxyAppearance @
    @strokeColor = Color.create 196,195,196
    @color = Color.create 245, 244, 245

