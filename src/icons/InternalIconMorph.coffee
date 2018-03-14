class InternalIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new InternalIconAppearance @
