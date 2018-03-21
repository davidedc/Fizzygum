class GrayscalePalettePatchProgrammingIconWdgt extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new GrayscalePalettePatchProgrammingIconAppearance @

