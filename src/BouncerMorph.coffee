# BouncerMorph ////////////////////////////////////////////////////////
# fishy constructor
# I am a Demo of a stepping custom Morph

class BouncerMorph extends Morph

  isStopped: false
  type: null
  direction: null
  speed: null

  constructor: (@type = "vertical", @speed = 1) ->
    super()
    @fps = 50
    # additional properties:
    if @type is "vertical"
      @direction = "down"
    else
      @direction = "right"
  
  
  # BouncerMorph moving:
  moveUp: ->
    @moveBy new Point(0, -@speed)
  
  moveDown: ->
    @moveBy new Point(0, @speed)
  
  moveRight: ->
    @moveBy new Point(@speed, 0)
  
  moveLeft: ->
    @moveBy new Point(-@speed, 0)
  
  
  # BouncerMorph stepping:
  step: ->
    unless @isStopped
      if @type is "vertical"
        if @direction is "down"
          @moveDown()
        else
          @moveUp()
        @direction = "down"  if @fullBounds().top() < @parent.top() and @direction is "up"
        @direction = "up"  if @fullBounds().bottom() > @parent.bottom() and @direction is "down"
      else if @type is "horizontal"
        if @direction is "right"
          @moveRight()
        else
          @moveLeft()
        @direction = "right"  if @fullBounds().left() < @parent.left() and @direction is "left"
        @direction = "left"  if @fullBounds().right() > @parent.right() and @direction is "right"
