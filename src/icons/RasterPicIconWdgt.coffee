# this file is excluded from the fizzygum homepage build

class RasterPicIconWdgt extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new RasterPicIconAppearance @


