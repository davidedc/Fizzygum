# HeartIconMorph //////////////////////////////////////////////////////


class HeartIconMorph extends IconMorph

  colloquialName: ->
    "Heart icon"

  constructor: (@color) ->
    super
    @appearance = new HeartIconAppearance @
