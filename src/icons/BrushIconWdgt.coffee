class BrushIconWdgt extends IconWdgt

  createAppearance: -> new BrushIconAppearance @

  constructor: (@color) ->
    super
    @toolTipMessage = "brush"
