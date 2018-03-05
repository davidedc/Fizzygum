class UnderCarpetIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new UnderCarpetIconAppearance @

