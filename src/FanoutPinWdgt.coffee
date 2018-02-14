class FanoutPinWdgt extends Widget

  constructor: (@color) ->
    super
    @appearance = new FanoutPinAppearance @
