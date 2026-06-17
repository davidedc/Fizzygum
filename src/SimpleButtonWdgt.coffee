# sends a message to a target object when pressed.
# takes a rounded box shape, and can host
# a widget to be used as "face"

class SimpleButtonWdgt extends ButtonWdgt

  constructor: (
      @ifInsidePopUpThenClosesUnpinnedPopUpsWhenClicked = true,
      @target = nil,
      @action = nil,

      @faceWidget = nil,

      @dataSourceWidgetForTarget = nil,
      @widgetEnv,
      @toolTipMessage = nil,

      @doubleClickAction = nil,
      @argumentToAction1 = nil,
      @argumentToAction2 = nil,
      @representsAWidget = false,
      @padding = 0
      ) ->

    # additional properties:

    super

    @appearance = new BoxyAppearance @
    @strokeColor = Color.create 196,195,196
    @color = Color.create 245, 244, 245

