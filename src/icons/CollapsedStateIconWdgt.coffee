class CollapsedStateIconWdgt extends IconWdgt

  colloquialName: ->
    "\"Collapsed state\" icon"

  constructor: (@color) ->
    super
    @appearance = new CollapsedStateIconAppearance @

