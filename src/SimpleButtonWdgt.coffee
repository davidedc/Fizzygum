# sends a message to a target object when pressed.
# takes a rounded box shape, and can host
# a widget to be used as "face"

class SimpleButtonWdgt extends ButtonWdgt

  # The ctor params are identical to ButtonWdgt's, so we drop the re-declared 12-param signature: bare
  # `super` forwards `arguments` and the base assigns every @param onto this same instance — byte-identical.
  constructor: ->

    super

    @appearance = new BoxyAppearance @
    @strokeColor = Color.create 196,195,196
    @color = Color.create 245, 244, 245

