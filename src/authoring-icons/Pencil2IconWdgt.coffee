class Pencil2IconWdgt extends IconWdgt

  # stated rather than derived: the camelCase split leaves the digit glued to the word
  colloquialName: -> "pencil 2 icon"

  createAppearance: -> new Pencil2IconAppearance @

  constructor: (@color) ->
    super
    @toolTipMessage = "pencil"

