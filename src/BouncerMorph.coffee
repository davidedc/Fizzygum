# BouncerMorph ////////////////////////////////////////////////////////
# fishy constructor
# I am a Demo of a stepping custom Morph
# Bounces vertically or horizontally within the parent

class BouncerMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

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

    # @updateBackingStore() not needed, probably
    # because it's repainted in the
    # next frame since it's an animation?
    #@updateBackingStore()

  resetPosition: ->
    if @type is "vertical"
      @direction = "down"
    else
      @direction = "right"
    @setPosition new Point(@parent.position().x, @parent.position().y)
  
  
  # BouncerMorph moving.
  # We need the silent option because
  # we might move the bouncer many times
  # consecutively in the case we tie
  # the animation to the test step.
  # The silent option avoids too many
  # broken rectangles being pushed
  # so it makes the whole thing smooth
  # even with many movements at once.
  moveUp: (silently) ->
    if silently
      @silentMoveBy new Point(0, -@speed)
    else
      @moveBy new Point(0, -@speed)
  
  moveDown: (silently) ->
    if silently
      @silentMoveBy new Point(0, @speed)
    else
      @moveBy new Point(0, @speed)
  
  moveRight: (silently) ->
    if silently
      @silentMoveBy new Point(@speed, 0)
    else
      @moveBy new Point(@speed, 0)
  
  moveLeft: (silently) ->
    if silently
      @silentMoveBy new Point(-@speed, 0)
    else
      @moveBy new Point(-@speed, 0)

  moveAccordingToBounce: (silently) ->
    if @type is "vertical"
      if @direction is "down"
        @moveDown(silently)
      else
        @moveUp(silently)
      @direction = "down"  if @boundsIncludingChildren().top() < @parent.top() and @direction is "up"
      @direction = "up"  if @boundsIncludingChildren().bottom() > @parent.bottom() and @direction is "down"
    else if @type is "horizontal"
      if @direction is "right"
        @moveRight(silently)
      else
        @moveLeft(silently)
      @direction = "right"  if @boundsIncludingChildren().left() < @parent.left() and @direction is "left"
      @direction = "left"  if @boundsIncludingChildren().right() > @parent.right() and @direction is "right"
  
  
  # BouncerMorph stepping:
  step: ->
    unless @isStopped
      # if we are recording or playing a test
      # then there is a flag we need to check that allows
      # the world to control all the animations.
      # This is so there is a consistent check
      # when taking/comparing
      # screenshots.
      # So we check here that flag, and make the
      # animation is exactly controlled
      # by the test step count only.
      #console.log "AutomatorRecorderAndPlayer.animationsPacingControl: " + AutomatorRecorderAndPlayer.animationsPacingControl
      #console.log "state: " + AutomatorRecorderAndPlayer.state
      if AutomatorRecorderAndPlayer.animationsPacingControl
        if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.RECORDING
          @resetPosition()
          for i in [0... window.world.systemTestsRecorderAndPlayer.automatorCommandsSequence.length]
            @moveAccordingToBounce(true)
          @parent.changed()
          return
        if AutomatorRecorderAndPlayer.state == AutomatorRecorderAndPlayer.PLAYING
          @resetPosition()
          for i in [0... window.world.systemTestsRecorderAndPlayer.indexOfTestCommandBeingPlayedFromSequence]
            @moveAccordingToBounce(true)
          @parent.changed()
          return

      @moveAccordingToBounce(false)
