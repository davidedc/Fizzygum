class EraserIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new EraserIconAppearance @
    @toolTipMessage = "eraser"

