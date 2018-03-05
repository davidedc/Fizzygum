class DestroyIconMorph extends IconMorph

  colloquialName: ->
    "\"Destroy\" icon"

  constructor: (@color) ->
    super
    @appearance = new DestroyIconAppearance @
