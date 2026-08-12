# sends a message to a target object when pressed.
# takes a rectangular shape, and can host
# a widget to be used as "face"

class SimpleRectangularButtonWdgt extends ButtonWdgt

  # The ctor params are identical to ButtonWdgt's, so we drop the re-declared signature: bare
  # `super` forwards `arguments` and the base assigns every @param onto this same instance —
  # byte-identical (the SimpleButtonWdgt precedent).
  constructor: ->

    super

    @appearance = new RectangularAppearance @
    @strokeColor = Color.create 196,195,196

