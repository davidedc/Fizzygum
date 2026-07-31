class Pencil2IconWdgt extends IconWdgt

  createAppearance: -> new Pencil2IconAppearance @

  constructor: (@color) ->
    super
    @toolTipMessage = "pencil"

