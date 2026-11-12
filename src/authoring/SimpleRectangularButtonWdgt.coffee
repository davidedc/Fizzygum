# sends a message to a target object when pressed.
# takes a rectangular shape, and can host
# a widget to be used as "face"
#
# MY LOOK is the plain button's: my fill is the plainButton* role for the state I show
# (ButtonWdgt._fillForMyState), inside a square 1 px border in the rectangular button's role, both
# read as my RectangularAppearance paints me (_surfaceStroke).

class SimpleRectangularButtonWdgt extends ButtonWdgt

  # ALL options, no operand — ButtonWdgt's own shape, forwarded untouched. Every DIRECT construction
  # of this class is an unwired one (the demo sites want a button that merely looks like one), and
  # ButtonWdgt guards an absent action (`if @action? and @action != ""`), so an unwired button is a
  # supported state, not a broken one; CodeInjectingSimpleRectangularButtonWdgt below wires it with
  # `target:`/`action:`.
  constructor: (opts = {}) ->

    super opts

    @appearance = new RectangularAppearance @

  # The colour my border is stroked with while I hold no stroke colour of my own
  # (RectangularAppearance._borderColor asks it as it paints).
  _surfaceStroke: ->
    WorldWdgt.theme.rectangularButtonStroke

