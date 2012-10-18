# BlinkerMorph ////////////////////////////////////////////////////////

# can be used for text cursors

class BlinkerMorph
  constructor: (rate) ->
    @init rate

# BlinkerMorph inherits from Morph:
BlinkerMorph:: = new Morph()
BlinkerMorph::constructor = BlinkerMorph
BlinkerMorph.uber = Morph::

# BlinkerMorph instance creation:
BlinkerMorph::init = (rate) ->
  BlinkerMorph.uber.init.call this
  @color = new Color(0, 0, 0)
  @fps = rate or 2
  @drawNew()


# BlinkerMorph stepping:
BlinkerMorph::step = ->
  @toggleVisibility()
