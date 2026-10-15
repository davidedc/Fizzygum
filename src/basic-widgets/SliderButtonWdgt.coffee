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
      # how much of my track's cross axis the surround takes — 2 (1px each side) on an ordinary
      # slider, 0 on a thin scroll indicator, which paints no track for me to sit inside.
      # Capability via ?(), so any other parent keeps the surround.
      box = @boxInSliderFrame @parent.extent(), (@parent.thumbInsetInTrack?() ? 2)
      @__commitExtent box.extent()
      @__commitMoveTo box.origin.add @parent.position()

  # My box inside a slider frame of `frameExtent` whose track takes `surround` of the cross axis,
  # relative to the frame's top-left. It reads my slider's value and range and NOT my slider's
  # current frame, so it answers for a frame my slider does not have yet as well as for the one it
  # has: my arrange commits it for the frame I am in, and a viewport asks it for the frame a
  # pointer's arrival gives its bar (ViewportWdgt.buttonScreenBoxOnArrival).
  boxInSliderFrame: (frameExtent, surround) ->
    sliderValue = @parent.value
    # notably, if you type "-2" as an input to the slider
    # then as you type the "-"
    # you get "-" as the value, which becomes NaN
    if isNaN sliderValue
      sliderValue = 0

    edge = Math.round surround / 2
    # the cross size is the frame's less the surround, and I am never shorter than I am wide. The
    # extent is the one my commit settles on — rounded, and held at my minimum — since my position
    # along the track is measured with it.
    if @parent.autoOrientation() is "vertical"
      bw = frameExtent.x - surround
      extent = (new Point bw, Math.max bw, Math.round frameExtent.y * @parent.ratio()).round().max @minimumExtent
      posX = edge
      posY = Math.max(0,Math.min(
        Math.round((sliderValue - @parent.start) * ((frameExtent.y - extent.y) / @parent.rangeSize())),
        frameExtent.y - extent.y))
      if @parent.smallestValueIsAtBottomEnd
        posY = frameExtent.y - (posY + extent.y)
    else
      bh = frameExtent.y - surround
      extent = (new Point (Math.max bh, Math.round frameExtent.x * @parent.ratio()), bh).round().max @minimumExtent
      posY = edge
      posX = Math.max(0, Math.min(
        Math.round((sliderValue - @parent.start) * ((frameExtent.x - extent.x) / @parent.rangeSize())),
        frameExtent.x - extent.x))

    new Rectangle (new Point posX, posY), (new Point posX + extent.x, posY + extent.y)

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

  # A pointer merely resting on me highlights me, so I take the HOVER move channel and no
  # other: a move under a live press is that press's business (a drag of me arrives as
  # nonFloatDragging), never a reason to light up.
  #   The two guards are about a stroke whose effects OUTLIVE the moves that started it: a
  # press state or a hand carrying something is still standing when the per-cycle hover
  # re-sync comes round, and neither may re-highlight me.
  hoverMoved: ->
    if @state == @STATE_PRESSED or world.hand.isThisPointerDraggingSomething()
      return
    @_setHighlightedColor()
  
  # The same two guards, because an ENTER can come after the press too: a finger's press on a thin
  # scroll indicator meets a thumb its arrival has only just fattened, so the thumb joins the
  # pointer's over-list at the next hover re-sync, under a press I am already showing.
  hoverEntered: ->
    if @state == @STATE_PRESSED or world.hand.isThisPointerDraggingSomething()
      return
    @_setHighlightedColor()

  hoverExited: ->
    if world.hand.isThisPointerDraggingSomething()
      return
    @_setNormalColor()
  
  pressBegan: (pos) ->
    @bringToForeground()
    @setPressedColor()

  activated: ->
    @bringToForeground()
    @_setHighlightedColor()
  
