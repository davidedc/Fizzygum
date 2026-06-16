class ExternalIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new ExternalIconAppearance @
