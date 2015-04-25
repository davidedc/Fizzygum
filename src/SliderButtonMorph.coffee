# SliderButtonMorph ///////////////////////////////////////////////////
# This is the handle in the middle of any slider.
# Sliders (and hence this button)
# are also used in the ScrollMorphs.

# this comment below is needed to figure our dependencies between classes
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
  highlightColor: new Color(90, 90, 140)
  # careful: this Color object is shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  pressColor: new Color(80, 80, 160)
  is3D: false

  constructor: (orientation) ->
    @color = new Color(80, 80, 80)
    super orientation
    @isfloatDraggable = false
    @noticesTransparentClick = true

  autoOrientation: ->
      noOperation

  # HandleMorph floatDragging and dropping:
  rootForGrab: ->
    @

  setLayoutBeforeUpdatingBackingStore: ->
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
      @silentSetPosition new Point(posX, posY).add(@parent.bounds.origin)

  # no changes of position or extent
  updateBackingStore: ->
    colorBak = @color.copy()
    super()
    @normalImage = @image
    @color = @highlightColor.copy()
    super()
    @highlightImage = @image
    @color = @pressColor.copy()
    super()
    @pressImage = @image
    @color = colorBak
    @image = @normalImage
    @changed()

  nonFloatDragging: (nonFloatDragPositionWithinMorphAtStart, pos, delta) ->
    @offset = pos.subtract nonFloatDragPositionWithinMorphAtStart
    if world.hand.mouseButton and @isVisible
      oldButtonPosition = @position()
      if @parent.orientation is "vertical"
        newX = @bounds.origin.x
        newY = Math.max(
          Math.min(@offset.y,
          @parent.bottom() - @height()), @parent.top())
      else
        newY = @bounds.origin.y
        newX = Math.max(
          Math.min(@offset.x,
          @parent.right() - @width()), @parent.left())
      newPosition = new Point(newX, newY)
      if !oldButtonPosition.eq newPosition
        @setPosition newPosition
        @parent.updateValue()
    
  
  #SliderButtonMorph events:
  mouseEnter: ->
    @image = @highlightImage
    @changed()
  
  mouseLeave: ->
    @image = @normalImage
    @changed()
  
  mouseDownLeft: (pos) ->
    @image = @pressImage
    @changed()
    return null
    #@escalateEvent "mouseDownLeft", pos
  
  mouseClickLeft: ->
    super()
    @image = @highlightImage
    @changed()
  
