# MouseSensorMorph ////////////////////////////////////////////////////

# for demo and debugging purposes only, to be removed later
class MouseSensorMorph extends BoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  constructor: (@edge = 4) ->
    super
    @color = new Color(255, 255, 255)
    @isTouched = false
    @upStep = 0.05
    @downStep = 0.02
    @noticesTransparentClick = false
  
  touch: ->

    # don't animate anything if we are in an animation pacing control
    # situation.
    if AutomatorRecorderAndPlayer.animationsPacingControl
      if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.RECORDING or AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.PLAYING
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
          @step = null
        @changed()
  
  unTouch: ->
    @isTouched = false
  
  mouseEnter: ->
    @touch()
  
  mouseLeave: ->
    @unTouch()
  
  mouseDownLeft: ->
    @touch()
  
  mouseClickLeft: ->
    @unTouch()
