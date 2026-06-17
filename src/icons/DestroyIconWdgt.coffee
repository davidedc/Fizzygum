class DestroyIconWdgt extends IconWdgt

  colloquialName: ->
    "\"Destroy\" icon"

  createAppearance: -> new DestroyIconAppearance @

  constructor: (@color) ->
    super
    @toolTipMessage = "explosion"
