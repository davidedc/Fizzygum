# ScooterIconMorph //////////////////////////////////////////////////////


class ScooterIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new ScooterIconAppearance @
