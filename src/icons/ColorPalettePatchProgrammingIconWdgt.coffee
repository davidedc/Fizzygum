class ColorPalettePatchProgrammingIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new ColorPalettePatchProgrammingIconAppearance @

