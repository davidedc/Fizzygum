# SliderButtonMorph ///////////////////////////////////////////////////
# This is the handle in the middle of any slider.
# Sliders (and hence this button)
# are also used in the ScrollMorphs.

# this comment below is needed to figure out dependencies between classes
# REQUIRES globalFunctions

class SliderButtonMorph extends CircleBoxMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color(110, 110, 110)
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  pressColor: new Color(100, 100, 100)
  normalColor: new Color(0, 0, 0)
  is3D: false

  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1
  STATE_PRESSED: 2

  constructor: (orientation) ->
    super orientation
    @color = @normalColor.copy()
    @isfloatDraggable = false
    @noticesTransparentClick = true
    @alpha = 0.4

  autoOrientation: ->
      noOperation

  # HandleMorph floatDragging and dropping:
  rootForGrab: ->
    @

  reLayout: ->
    super()
    if @parent?
      @orientation = @parent.orientation
      if @orientation is "vertical"
        bw = @parent.width() - 2
        bh = Math.max(bw, Math.round(@parent.height() * @parent.ratio()))
        @silentSetExtent new Point(bw, bh)
        posX = 1
        posY = Math.min(
          Math.round((@parent.value - @parent.start) * @parent.unitSize()),
          @parent.height() - @height())
      else
        bh = @parent.height() - 2
        bw = Math.max(bh, Math.round(@parent.width() * @parent.ratio()))
        @silentSetExtent new Point(bw, bh)
        posY = 1
        posX = Math.min(
          Math.round((@parent.value - @parent.start) * @parent.unitSize()),
          @parent.width() - @width())
      @silentSetPosition new Point(posX, posY).add(@parent.position())
      @children.forEach (child) ->
        child.parentHasReLayouted()



  nonFloatDragging: (nonFloatDragPositionWithinMorphAtStart, pos) ->
    @offset = pos.subtract nonFloatDragPositionWithinMorphAtStart
    if world.hand.mouseButton and @checkVisibility()
      oldButtonPosition = @position()
      if @parent.orientation is "vertical"
        newX = @left()
        newY = Math.max(
          Math.min(@offset.y,
          @parent.bottom() - @height()), @parent.top())
      else
        newY = @top()
        newX = Math.max(
          Math.min(@offset.x,
          @parent.right() - @width()), @parent.left())
      newPosition = new Point(newX, newY)
      if !oldButtonPosition.eq newPosition
        @setPosition newPosition
        @parent.updateValue()
    
  
  #SliderButtonMorph events:
  mouseEnter: ->
    @state = @STATE_HIGHLIGHTED
    @color = @highlightColor.copy()
    @changed()
  
  mouseLeave: ->
    @state = @STATE_NORMAL
    @color = @normalColor.copy()
    @changed()
  
  mouseDownLeft: (pos) ->
    @state = @STATE_PRESSED
    @color = @pressColor.copy()
    @changed()
  
  mouseClickLeft: ->
    super()
    @state = @STATE_HIGHLIGHTED
    @color = @highlightColor.copy()
    @changed()
  
