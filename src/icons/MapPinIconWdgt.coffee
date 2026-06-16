class MapPinIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new MapPinIconAppearance @
    @toolTipMessage = "map pin"
