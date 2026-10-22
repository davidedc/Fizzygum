# sends a message to a target object when pressed.
# takes a rectangular shape, and can host
# a widget to be used as "face"
#
# MY LOOK is the plain button's: my fill is HighlightableMixin's for my state (the plainButton*
# roles, re-derived at every state change), inside a square 1 px border in the rectangular button's
# role, read as my RectangularAppearance paints it (_surfaceStroke).

class SimpleRectangularButtonWdgt extends ButtonWdgt

  # ALL options, no operand. ButtonWdgt's head is `(target, action, opts)` and that is right for
  # buttons at large — but every DIRECT construction of this class is an unwired one: the three
  # demo sites want a button that merely looks like one, and were writing `undefined` through the
  # action operand to reach the face (R3). ButtonWdgt guards an absent action
  # (`if @action? and @action != ""`), so an unwired button is a supported state, not a broken one.
  # The operands those callers cannot fill become option keys — the PromptWdgt remedy — and the
  # class stays fully wireable: CodeInjectingSimpleRectangularButtonWdgt below supplies
  # `target:`/`action:` and behaves exactly as it did positionally.
  constructor: (opts = {}) ->

    super opts.target, opts.action, opts

    @appearance = new RectangularAppearance @

  # The colour my border is stroked with while I hold no stroke colour of my own
  # (RectangularAppearance._borderColor asks it as it paints).
  _surfaceStroke: ->
    WorldWdgt.theme.rectangularButtonStroke

