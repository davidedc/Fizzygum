class BrushIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new BrushIconAppearance @
    @toolTipMessage = "brush"
