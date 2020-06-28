class ToothpasteIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new ToothpasteIconAppearance @
    @toolTipMessage = "toothpaste"
