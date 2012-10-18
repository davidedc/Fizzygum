# ShadowMorph /////////////////////////////////////////////////////////

class ShadowMorph
  constructor: () ->
    @init()

# ShadowMorph inherits from Morph:
ShadowMorph:: = new Morph()
ShadowMorph::constructor = ShadowMorph
ShadowMorph.uber = Morph::
