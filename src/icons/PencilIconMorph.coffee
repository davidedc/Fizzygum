class PencilIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new PencilIconAppearance @
