# I am a rectangle that BLINKS: I toggle my visibility at my fps, and hold still (visible) while the
# Automator paces a test. I paint in the text caret's fill (Theme caretFill, the accent): the text
# caret (CaretWdgt) is the blinker I am for, and it decides its own extent and place.

class BlinkerWdgt extends Widget

  constructor: (@fps = 2) ->
    world.steppingWdgts.add @
    super()
    @appearance = new RectangularAppearance @
    @color = WorldWdgt.theme.caretFill
  
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
