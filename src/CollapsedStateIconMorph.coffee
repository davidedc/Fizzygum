# CollapsedStateIconMorph //////////////////////////////////////////////////////


class CollapsedStateIconMorph extends IconMorph

  colloquialName: ->
    "\"Collapsed state\" icon"

  constructor: (@color) ->
    super
    @appearance = new CollapsedStateIconAppearance @

