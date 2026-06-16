class ChangeFontIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new ChangeFontIconAppearance @

