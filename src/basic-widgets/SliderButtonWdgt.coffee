# This is the handle in the middle of any slider.
# Sliders (and hence this button)
# are also used in the ViewportWdgts.

class SliderButtonWdgt extends CircleBoxWdgt

  # The slider knob is CHROME -- the interactive handle of a slider/scrollbar, never editor content.
  # Dragging or clicking it must NOT make it world.editorFocusWdgt: framing the little knob is pure visual
  # noise (there is nothing a user acts on about the knob itself). Same exemption as the other affordances
  # (handles, scrollbars, layout chrome); honored by ancestry at ActivePointerWdgt's focus-set sites.
  excludedFromEditorFocusTracking: -> true

  highlightColor: Color.create 110, 110, 110
  pressColor: Color.create 100, 100, 100
  normalColor: Color.BLACK

  state: 0
  STATE_NORMAL: 0
  STATE_HIGHLIGHTED: 1
  STATE_PRESSED: 2

  # The whole thumb box grabs, not just the stadium my CircleBoxyAppearance draws inside it: a
  # slider you have to hit on the rounded cap is a slider that slips out of your hand.
  #   UNLESS my slider is a thin scroll INDICATOR, which is not a target at all (ruling G3): the
  # pointer passes through to the content under the band until a hover fattens the bar.
  catchesPointerAt: (aPoint) ->
    return false if @parent?.indicatorIsIntangible?()
    @boundsContainPoint aPoint

  # My slider hands me the alpha its indicator presentation puts me at (see
  # SliderWdgt.showAsScrollIndicator). Colour and state are untouched — only how strongly I show.
  showAsScrollIndicatorThumb: (alpha) ->
    return if @alpha == alpha
    @alpha = alpha
    @_changed()

  # the thumb's grab-corrected target POSITION (pointer mapped into my plane, minus the
  # within-thumb grab point), held for the duration of a knob drag — plane-local, so it
  # stays consistent with my own plane under a (possibly rotated) island
  dragTargetPosition: undefined

  constructor: ->
    super
    @isLockingToPanels = false
    @color = @normalColor
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
      # how much of my track's cross axis the surround takes — 2 (1px each side) on an ordinary
      # slider, 0 on a thin scroll indicator, which paints no track for me to sit inside.
      # Capability via ?(), so any other parent keeps the surround.
      surround = @parent.thumbInsetInTrack?() ? 2
      edge = Math.round surround / 2
      if orientation is "vertical"
        bw = @parent.width() - surround
        bh = Math.max bw, Math.round @parent.height() * @parent.ratio()
        @__commitExtent new Point bw, bh
        posX = edge
        posY = Math.max(0,Math.min(
          Math.round((sliderValue - @parent.start) * @parent.unitSize()),
          @parent.height() - @height()))
        if @parent.smallestValueIsAtBottomEnd
          posY = @parent.height() - (posY + @height())
      else
        bh = @parent.height() - surround
        bw = Math.max bh, Math.round @parent.width() * @parent.ratio()
        @__commitExtent new Point bw, bh
        posY = edge
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
    # sliders). Mapping both operands into MY plane makes @dragTargetPosition a virtual-plane position, consistent with
    # the clamp bounds. Off every island screenPointToMyPlane returns the same point ⇒ byte-identical (dormant).
    @dragTargetPosition = (@screenPointToMyPlane pos).subtract nonFloatDragPositionWithinWdgtAtStart
    if world.hand.mouseButton and
    @visibleBasedOnIsVisibleProperty() and
    !@isInCollapsedSubtree()
      oldButtonPosition = @position()
      if @parent.autoOrientation() is "vertical"
        newX = @left()
        newY = Math.max(
          Math.min(@dragTargetPosition.y,
          @parent.bottom() - @height()), @parent.top())

      else
        newY = @top()
        newX = Math.max(
          Math.min(@dragTargetPosition.x,
          @parent.right() - @width()), @parent.left())

      # Integer placement (Layer A): @dragTargetPosition is a plane-local position mapped through the (possibly rotated)
      # island's inverse transform, so it is fractional; the thumb's committed @bounds must be integer -- round
      # the target once, and hand the SAME rounded point to updateValue so the derived value stays consistent
      # with what was applied. docs/archive/fractional-widget-bounds-investigation-plan.md (Path 2).
      newPosition = (new Point newX, newY).round()
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
      @_changed()

  _setHighlightedColor: ->
    if @state != @STATE_HIGHLIGHTED
      @state = @STATE_HIGHLIGHTED
      @color = @highlightColor
      @_changed()

  _setNormalColor: ->
    if @state != @STATE_NORMAL
      @state = @STATE_NORMAL
      @color = @normalColor
      @_changed()

  setPressedColor: ->
    if @state != @STATE_PRESSED
      @state = @STATE_PRESSED
      @color = @pressColor
      @_changed()

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
  
