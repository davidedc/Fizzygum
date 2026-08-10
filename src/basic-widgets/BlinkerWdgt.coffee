# can be used for text caret

class BlinkerWdgt extends Widget

  constructor: (@fps = 2) ->
    world.steppingWdgts.add @
    super()
    @appearance = new RectangularAppearance @
    @color = Color.BLACK
  
  step: ->
    # While the Automator is pacing animations mid-test (recording or playing),
    # stay visible instead of toggling -- so screenshots see a consistent
    # blinker state.
    if Automator? and
     Automator.animationsPacingControl and
     Automator.state != Automator.IDLE
      return
 
    # otherwise toggle visibility at the constructor's fps
    @toggleVisibility()
