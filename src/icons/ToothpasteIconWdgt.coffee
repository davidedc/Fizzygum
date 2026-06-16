class ToothpasteIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new ToothpasteIconAppearance @
    @toolTipMessage = "toothpaste"
