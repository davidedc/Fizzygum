# UncollapsedStateIconMorph //////////////////////////////////////////////////////


class UncollapsedStateIconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new UncollapsedStateIconAppearance @
