# this file is excluded from the fizzygum homepage build

class UnderCarpetIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new UnderCarpetIconAppearance @

