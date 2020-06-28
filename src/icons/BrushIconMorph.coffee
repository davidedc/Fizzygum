class BrushIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new BrushIconAppearance @
    @toolTipMessage = "brush"
