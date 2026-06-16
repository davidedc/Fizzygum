class PencilIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new PencilIconAppearance @
