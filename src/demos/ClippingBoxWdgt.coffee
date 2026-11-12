# I can have an optionally rounded border, and I clip my children at my bounds

class ClippingBoxWdgt extends ClippingWdgt

  # a box's look, as BoxWdgt's: round-cornered unless told otherwise (`cornerRadius` and its setter
  # live on Widget; the default is a box's)
  constructor: (@cornerRadius = 4) ->
    super()
    @appearance = new BoxyAppearance @
