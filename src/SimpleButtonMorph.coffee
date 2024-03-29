# sends a message to a target object when pressed.
# takes a rounded box shape, and can host
# a morph to be used as "face"

class SimpleButtonMorph extends EmptyButtonMorph

  constructor: (
      @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true,
      @target = nil,
      @action = nil,

      @faceMorph = nil,

      @dataSourceMorphForTarget = nil,
      @morphEnv,
      @toolTipMessage = nil,

      @doubleClickAction = nil,
      @argumentToAction1 = nil,
      @argumentToAction2 = nil,
      @representsAMorph = false,
      @padding = 0
      ) ->

    # additional properties:

    super

    @appearance = new BoxyAppearance @
    @strokeColor = Color.create 196,195,196
    @color = Color.create 245, 244, 245

