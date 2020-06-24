# this file is excluded from the fizzygum homepage build

# for demo and debugging purposes only, to be removed later
class MouseSensorMorph extends BoxMorph

  constructor: (@cornerRadius = 4) ->
    super
    @color = Color.WHITE
    @isTouched = false
    @upStep = 0.05
    @downStep = 0.02
    @noticesTransparentClick = false
  
  touch: ->

    # don't animate anything if we are in an animation pacing control
    # situation.
    if Automator? and Automator.animationsPacingControl
      if Automator.state == Automator.RECORDING or Automator.state == Automator.PLAYING
        @alpha = 0.6
        @changed()
        return

    unless @isTouched
      @isTouched = true
      @alpha = 0.6
      @step = =>
        if @isTouched
          @alpha = @alpha + @upStep  if @alpha < 1
        else if @alpha > (@downStep)
          @alpha = @alpha - @downStep
        else
          @alpha = 0
          @step = nil
          world.steppingWdgts.delete @
        @changed()
      world.steppingWdgts.add @
  
  unTouch: ->
    @isTouched = false
  
  mouseEnter: ->
    @touch()
  
  mouseLeave: ->
    @unTouch()
  
  mouseDownLeft: ->
    @touch()
    super
  
  mouseClickLeft: ->
    @unTouch()
