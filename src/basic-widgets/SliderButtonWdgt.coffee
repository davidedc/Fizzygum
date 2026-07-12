# This is the handle in the middle of any slider.
# Sliders (and hence this button)
# are also used in the ScrollPanelWdgts.

class SliderButtonWdgt extends CircleBoxWdgt

  highlightColor: Color.create 110, 110, 110
  pressColor: Color.create 100, 100, 100
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

  # Derive the button's colour states from one base colour: resting = base,
  # highlight/press progressively bluer. (Used by the prompter slider.)
  setColorScheme: (base) ->
    @color = base
    @highlightColor = base.bluerBy 100
    @pressColor = base.bluerBy 150

  detachesWhenDragged: ->
    if @parent instanceof SliderWdgt
      return false
    else
      return true

  _reLayoutSelf: ->
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
        @__commitExtent new Point bw, bh
        posX = 1
        posY = Math.max(0,Math.min(
          Math.round((sliderValue - @parent.start) * @parent.unitSize()),
          @parent.height() - @height()))
        if @parent.smallestValueIsAtBottomEnd
          posY = @parent.height() - (posY + @height())
      else
        bh = @parent.height() - 2
        bw = Math.max bh, Math.round @parent.width() * @parent.ratio()
        @__commitExtent new Point bw, bh
        posY = 1
        posX = Math.max(0, Math.min(
          Math.round((sliderValue - @parent.start) * @parent.unitSize()),
          @parent.width() - @width()))

      @__commitMoveTo new Point(posX, posY).add @parent.position()

  grabsToParentWhenDragged: ->
    if @parent instanceof SliderWdgt
      return false
    return super

  nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->
    # Affine transforms (§6 4A-2): map the drag pointer into MY plane before differencing the
    # grab-start offset — the SAME fix HandleWdgt.nonFloatDragging has. ActivePointerWdgt captures
    # nonFloatDragPositionWithinWdgtAtStart in the widget's (virtual) plane but passes `pos` RAW (screen);
    # for a slider inside a non-identity island the two live in different planes, so the un-mapped
    # difference — and the clamp against the slider's VIRTUAL @parent.top()/bottom()/left()/right() below —
    # drifts with rotation and pins the value to an extreme near 45° (owner report: the C<->F converter's
    # sliders). Mapping both operands into MY plane makes @offset a virtual-plane position, consistent with
    # the clamp bounds. Off every island screenPointToMyPlane returns the same point ⇒ byte-identical (dormant).
    @offset = (@screenPointToMyPlane pos).subtract nonFloatDragPositionWithinWdgtAtStart
    if world.hand.mouseButton and
    @visibleBasedOnIsVisibleProperty() and
    !@isInCollapsedSubtree()
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
        @_applyMoveTo newPosition
        # pass the just-applied clamped position so updateValue derives the value
        # from it rather than reading the thumb's geometry back (byte-identical; the
        # precondition for deferring this move later — see SliderWdgt.updateValue).
        @parent.updateValue newPosition
  
  endOfNonFloatDrag: ->
    if @state != @STATE_NORMAL
      @state = @STATE_NORMAL
      @color = @normalColor
      @changed()

  _setHighlightedColor: ->
    if @state != @STATE_HIGHLIGHTED
      @state = @STATE_HIGHLIGHTED
      @color = @highlightColor
      @changed()

  _setNormalColor: ->
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
    @_setHighlightedColor()
  
  #SliderButtonWdgt events:
  mouseEnter: ->
    if world.hand.isThisPointerDraggingSomething()
      return
    @_setHighlightedColor()
  
  mouseLeave: ->
    if world.hand.isThisPointerDraggingSomething()
      return
    @_setNormalColor()
  
  mouseDownLeft: (pos) ->
    @bringToForeground()
    @setPressedColor()

  mouseClickLeft: ->
    @bringToForeground()
    @_setHighlightedColor()
  
