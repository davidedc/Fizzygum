class Pencil2IconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new Pencil2IconAppearance @
    @toolTipMessage = "pencil"

