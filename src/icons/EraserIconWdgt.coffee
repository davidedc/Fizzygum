class EraserIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new EraserIconAppearance @
    @toolTipMessage = "eraser"

