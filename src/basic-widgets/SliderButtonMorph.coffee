# This is the handle in the middle of any slider.
# Sliders (and hence this button)
# are also used in the ScrollPanelWdgts.

class SliderButtonMorph extends CircleBoxMorph

  # careful: Objects are shared with all the instances of this class.
  # if you modify it, then all the objects will get the change
  # but if you replace it with a new Color, then that will only affect the
  # specific object instance. Same behaviour as with arrays.
  # see: https://github.com/jashkenas/coffee-script/issues/2501#issuecomment-7865333
  highlightColor: new Color 110, 110, 110
  # see note above about Colors and shared objects
  pressColor: new Color 100, 100, 100
  normalColor: Color.BLACK

  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1
  STATE_PRESSED: 2

  constructor: ->
    super
    @isLockingToPanels = false
    @color = @normalColor
    @noticesTransparentClick = true
    @alpha = 0.4

  detachesWhenDragged: ->
    if @parent instanceof SliderMorph
      return false
    else
      return true

  reLayout: ->
    super()

    if @parent?

      sliderValue = @parent.value
      # notably, if you type "-2" as an input to the slider
      # then as you type the "-"
      # you get "-" as the value, which becomes NaN
      if isNaN sliderValue
        sliderValue = 0

      orientation = @parent.autoOrientation()
      if orientation is "vertical"
        bw = @parent.width() - 2
        bh = Math.max bw, Math.round @parent.height() * @parent.ratio()
        @silentRawSetExtent new Point bw, bh
        posX = 1
        posY = Math.max(0,Math.min(
          Math.round((sliderValue - @parent.start) * @parent.unitSize()),
          @parent.height() - @height()))
        if @parent.smallestValueIsAtBottomEnd
          posY = @parent.height() - (posY + @height()) 
      else
        bh = @parent.height() - 2
        bw = Math.max bh, Math.round @parent.width() * @parent.ratio()
        @silentRawSetExtent new Point bw, bh
        posY = 1
        posX = Math.max(0, Math.min(
          Math.round((sliderValue - @parent.start) * @parent.unitSize()),
          @parent.width() - @width()))

      @silentFullRawMoveTo new Point(posX, posY).add @parent.position()

      @notifyChildrenThatParentHasReLayouted()

  grabsToParentWhenDragged: ->
    if @parent instanceof SliderMorph
      return false
    return super

  nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->
    @offset = pos.subtract nonFloatDragPositionWithinWdgtAtStart
    if world.hand.mouseButton and
    @visibleBasedOnIsVisibleProperty() and
    !@isCollapsed()
      oldButtonPosition = @position()
      if @parent.autoOrientation() is "vertical"
        newX = @left()
        newY = Math.max(
          Math.min(@offset.y,
          @parent.bottom() - @height()), @parent.top())

      else
        newY = @top()
        newX = Math.max(
          Math.min(@offset.x,
          @parent.right() - @width()), @parent.left())

      newPosition = new Point newX, newY
      if !oldButtonPosition.equals newPosition
        @fullRawMoveTo newPosition
        @parent.updateValue()
  
  endOfNonFloatDrag: ->  
    if @state != @STATE_NORMAL
      @state = @STATE_NORMAL
      @color = @normalColor
      @changed()

  setHiglightedColor: ->
    if @state != @STATE_HIGHLIGHTED
      @state = @STATE_HIGHLIGHTED
      @color = @highlightColor
      @changed()

  setNormalColor: ->
    if @state != @STATE_NORMAL
      @state = @STATE_NORMAL
      @color = @normalColor
      @changed()

  setPressedColor: ->
    if @state != @STATE_PRESSED
      @state = @STATE_PRESSED
      @color = @pressColor
      @changed()

  mouseMove: ->
    # remember that a drag can start a few pixels after the
    # mouse button is pressed (because of de-noising), so
    # only checking for "isThisPointerDraggingSomething" is not going to be
    # enough since we receive a few moves without the "isThisPointerDraggingSomething"
    # being set. So we also check for the "pressed" state.
    if @state == @STATE_PRESSED or world.hand.isThisPointerDraggingSomething()
      return
    @setHiglightedColor()
  
  #SliderButtonMorph events:
  mouseEnter: ->
    if world.hand.isThisPointerDraggingSomething()
      return
    @setHiglightedColor()
  
  mouseLeave: ->
    if world.hand.isThisPointerDraggingSomething()
      return
    @setNormalColor()
  
  mouseDownLeft: (pos) ->
    @bringToForeground()
    @setPressedColor()

  mouseClickLeft: ->
    @bringToForeground()
    @setHiglightedColor()
  
