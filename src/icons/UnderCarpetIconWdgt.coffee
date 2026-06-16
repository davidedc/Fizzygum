# this file is excluded from the fizzygum homepage build

class UnderCarpetIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new UnderCarpetIconAppearance @

