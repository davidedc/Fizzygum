class MapPinIconWdgt extends IconWdgt

  createAppearance: -> new MapPinIconAppearance @

  constructor: (@color) ->
    super
    @toolTipMessage = "map pin"
