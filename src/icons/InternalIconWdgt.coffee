class InternalIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new InternalIconAppearance @
