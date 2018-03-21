class ColorPalettePatchProgrammingIconWdgt extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new ColorPalettePatchProgrammingIconAppearance @

