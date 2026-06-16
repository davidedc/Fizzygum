class VaporwaveBackgroundIconWdgt extends IconWdgt

  constructor: (@color) ->
    super
    @appearance = new VaporwaveBackgroundIconAppearance @

