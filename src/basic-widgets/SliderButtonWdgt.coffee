# This is the handle in the middle of any slider.
# Sliders (and hence this button)
# are also used in the ViewportWdgts.

class SliderButtonWdgt extends CircleBoxWdgt

  # what a person calls me; without it the chain answers my base's "circle-box"
  colloquialName: ->
    "slider knob"

  # The slider knob is CHROME -- the interactive handle of a slider/scrollbar, never editor content.
  # Dragging or clicking it must NOT make it world.editorFocusWdgt: framing the little knob is pure visual
  # noise (there is nothing a user acts on about the knob itself). Same exemption as the other affordances
  # (handles, scrollbars, layout chrome); honored by ancestry at ActivePointerWdgt's focus-set sites.
  excludedFromEditorFocusTracking: -> true

  # my FILL overrides as a PLAIN slider's thumb: at rest, under a pointer, and pressed. One left
  # undefined is the theme's slider thumb fill for that state (Theme.sliderThumbFill,
  # sliderThumbHoverFill, sliderThumbPressFill), read each time I am painted; my border is always
  # the theme's (sliderThumbStroke, sliderThumbPressStroke while pressed). While my slider wears an
  # indicator presentation the indicator's colours stand in for all three and I draw no border
  # (_fillForMyState, _strokeForMyState), and these wait, untouched, for the presentation to end.
  normalColor: undefined
  highlightColor: undefined
  pressColor: undefined

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

  # My slider has just put on, changed or taken off its indicator presentation (see
  # SliderWdgt.showAsScrollIndicator) and hands me the alpha that presentation shows me at. My look
  # follows from the presentation and my state together, read as I am painted (_fillForMyState,
  # _strokeForMyState), so a new presentation is a new look: I keep the alpha and repaint. My state
  # is untouched.
  showAsScrollIndicatorThumb: (alpha) ->
    @alpha = alpha
    @_changed()

  # My look, read by my appearance as it paints me (CircleBoxyAppearance._fillColor / _borderColor):
  # a function of my slider's indicator presentation and my state, and, while it wears none, of my
  # fill overrides. A THIN indicator's thumb is not a control (ruling G3) and shows the scrollbar
  # colour in every state; a FAT one shows it at rest and darkens under a pointer and while
  # pressed; neither draws a border. A thumb whose slider is no indicator wears the button's look
  # (visual-design-system §4.3): its fill for my state (an override of mine, else the theme's
  # role) inside a 1 px border, the darker one while pressed. Every colour is the theme's or an
  # override's, never one copied into me, so a thumb saved, loaded or duplicated wears the look of
  # the world it is shown in. My own `color` is not my look: a colour set on me paints nothing.
  _fillForMyState: ->
    theme = WorldWdgt.theme
    switch @parent?.indicatorMode
      when 'thin'
        theme.scrollIndicatorThumb
      when 'fat'
        switch @state
          when @STATE_PRESSED then theme.scrollIndicatorThumbPress
          when @STATE_HIGHLIGHTED then theme.scrollIndicatorThumbHighlight
          else theme.scrollIndicatorThumb
      else
        switch @state
          when @STATE_PRESSED then @pressColor ? theme.sliderThumbPressFill
          when @STATE_HIGHLIGHTED then @highlightColor ? theme.sliderThumbHoverFill
          else @normalColor ? theme.sliderThumbFill

  _strokeForMyState: ->
    return undefined if @parent?.indicatorMode?
    theme = WorldWdgt.theme
    if @state is @STATE_PRESSED then theme.sliderThumbPressStroke else theme.sliderThumbStroke

  # the thumb's grab-corrected target POSITION (pointer mapped into my plane, minus the
  # within-thumb grab point), held for the duration of a knob drag — plane-local, so it
  # stays consistent with my own plane under a (possibly rotated) island
  dragTargetPosition: undefined

  constructor: ->
    super
    @isLockingToPanels = false
    # I hold no colour of my own: my look is my state's, read as I am painted (_fillForMyState), and
    # I am opaque (Widget's alpha) until a presentation hands me another (showAsScrollIndicatorThumb).
    @color = undefined
    # my extent is my slider's to derive (boxInSliderFrame), and the generic 5px floor every
    # widget carries must not overrule it: a thin scroll indicator's bar is narrower than that,
    # and a thumb held at the floor would poke past its bar and the viewport's edge.
    @_setMinimumExtent new Point 1, 1

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
  
  # The state transitions. Each one sets my state and repaints me; what that state shows is read
  # as I am painted (_fillForMyState, _strokeForMyState), so the presentation my slider wears
  # decides the look together with the state, and no transition writes a colour.
  endOfNonFloatDrag: ->
    if @state != @STATE_NORMAL
      @state = @STATE_NORMAL
      @_changed()

  _setHighlightedColor: ->
    if @state != @STATE_HIGHLIGHTED
      @state = @STATE_HIGHLIGHTED
      @_changed()

  _setNormalColor: ->
    if @state != @STATE_NORMAL
      @state = @STATE_NORMAL
      @_changed()

  setPressedColor: ->
    if @state != @STATE_PRESSED
      @state = @STATE_PRESSED
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
  
