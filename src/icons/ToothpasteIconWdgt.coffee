class ToothpasteIconWdgt extends IconWdgt

  createAppearance: -> new ToothpasteIconAppearance @

  constructor: (@color) ->
    super
    @toolTipMessage = "toothpaste"
