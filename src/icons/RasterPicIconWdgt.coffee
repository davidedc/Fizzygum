# this file is excluded from the fizzygum homepage build

class RasterPicIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new RasterPicIconAppearance @


