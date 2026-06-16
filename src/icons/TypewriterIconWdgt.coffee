class TypewriterIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new TypewriterIconAppearance @

