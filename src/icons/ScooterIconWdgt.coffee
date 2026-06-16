class ScooterIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new ScooterIconAppearance @
