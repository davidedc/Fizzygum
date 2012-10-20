# MouseSensorMorph ////////////////////////////////////////////////////

# for demo and debuggin purposes only, to be removed later
class MouseSensorMorph extends BoxMorph
  constructor: (edge, border, borderColor) ->
    @init edge, border, borderColor

# MouseSensorMorph instance creation:
MouseSensorMorph::init = (edge, border, borderColor) ->
  super
  @edge = edge or 4
  @border = border or 2
  @color = new Color(255, 255, 255)
  @borderColor = borderColor or new Color()
  @isTouched = false
  @upStep = 0.05
  @downStep = 0.02
  @noticesTransparentClick = false
  @drawNew()

MouseSensorMorph::touch = ->
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

MouseSensorMorph::unTouch = ->
  @isTouched = false

MouseSensorMorph::mouseEnter = ->
  @touch()

MouseSensorMorph::mouseLeave = ->
  @unTouch()

MouseSensorMorph::mouseDownLeft = ->
  @touch()

MouseSensorMorph::mouseClickLeft = ->
  @unTouch()
