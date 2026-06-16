class GrayscalePalettePatchProgrammingIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new GrayscalePalettePatchProgrammingIconAppearance @

