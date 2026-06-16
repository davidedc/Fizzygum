class HeartIconWdgt extends IconWdgt

  colloquialName: ->
    "Heart icon"

  constructor: (@color) ->
    super
    @appearance = new HeartIconAppearance @
