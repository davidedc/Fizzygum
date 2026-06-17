# sends a message to a target object when pressed.
# takes a rectangular shape, and can host
# a widget to be used as "face"

class SimpleRectangularButtonWdgt extends ButtonWdgt

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
      @representsAWidget = false
      ) ->

    # additional properties:

    super

    @appearance = new RectangularAppearance @
    @strokeColor = Color.create 196,195,196

