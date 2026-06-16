class FloraIconWdgt extends IconWdgt

  colloquialName: ->
    "Flora icon"

  constructor: (@color) ->
    super
    @appearance = new FloraIconAppearance @
