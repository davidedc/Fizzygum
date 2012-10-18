# BlinkerMorph ////////////////////////////////////////////////////////

# can be used for text cursors

class BlinkerMorph extends Morph
  constructor: (rate) ->
    @init rate

# BlinkerMorph instance creation:
BlinkerMorph::init = (rate) ->
  super()
  @color = new Color(0, 0, 0)
  @fps = rate or 2
  @drawNew()


# BlinkerMorph stepping:
BlinkerMorph::step = ->
  @toggleVisibility()
