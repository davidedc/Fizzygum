class DestroyIconWdgt extends IconWdgt

  colloquialName: ->
    "\"Destroy\" icon"

  constructor: (@color) ->
    super
    @appearance = new DestroyIconAppearance @
    @toolTipMessage = "explosion"
