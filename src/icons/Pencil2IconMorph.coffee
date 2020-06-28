class Pencil2IconMorph extends IconMorph

  constructor: (@color) ->
    super
    @appearance = new Pencil2IconAppearance @
    @toolTipMessage = "pencil"

