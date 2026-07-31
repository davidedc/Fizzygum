class EraserIconWdgt extends IconWdgt

  createAppearance: -> new EraserIconAppearance @

  constructor: (@color) ->
    super
    @toolTipMessage = "eraser"

