# BlinkerMorph ////////////////////////////////////////////////////////

# can be used for text cursors

class BlinkerMorph extends Morph
  constructor: (@fps = 2) ->
    super()
    @color = new Color(0, 0, 0)
    @drawNew()
  
  # BlinkerMorph stepping:
  step: ->
    @toggleVisibility()
