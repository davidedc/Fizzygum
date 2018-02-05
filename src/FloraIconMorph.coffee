# FloraIconMorph //////////////////////////////////////////////////////


class FloraIconMorph extends IconMorph

  colloquialName: ->
    "Flora icon"

  constructor: (@color) ->
    super
    @appearance = new FloraIconAppearance @
