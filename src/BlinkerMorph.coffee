# BlinkerMorph ////////////////////////////////////////////////////////

# can be used for text cursors

class BlinkerMorph extends Morph
  constructor: (rate) ->
    super()
    @color = new Color(0, 0, 0)
    @fps = rate or 2
    @drawNew()

# BlinkerMorph stepping:
BlinkerMorph::step = ->
  @toggleVisibility()
