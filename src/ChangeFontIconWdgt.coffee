class ChangeFontIconWdgt extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new ChangeFontIconAppearance @

