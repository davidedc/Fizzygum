class UncollapsedStateIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new UncollapsedStateIconAppearance @
