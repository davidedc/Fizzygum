class ExternalIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new ExternalIconAppearance @
