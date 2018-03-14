class MapPinIconWdgt extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new MapPinIconAppearance @
    @toolTipMessage = "map pin"
