# A clipping widget that PRESENTS TWO SCROLL INDICATORS over what it shows: a vertical SliderWdgt bar
# along the right edge of the box my bars run along and a horizontal one along its bottom edge, each a
# child of mine wired to a scroll pin of mine. What lives here is the PRESENTATION,
# the same for every host: where a bar stands and how long it runs, how thick it is and when it shows,
# the hover pass that fattens it, and the frames a press meets. What scrolls, and by how much, is my
# subclass's (ViewportWdgt: its plane, through its stored offset; SimpleSpreadsheetWdgt: its view
# origin, by whole columns and rows, over its data region): it builds my bars with the two
# actions they drive (_buildScrollBarsNoSettle), answers whether its content overflows along a bar's
# axis (_scrollAxisOverflows), may narrow the box my bars run along (_scrollBarRunBox) and keep a
# margin from that run's ends (_scrollBarRunMargin), and answers the scale a bar's thumb lives on
# (sliderRangeForPin, which a bar asks of me for the pin it drives). My arrange is where every scroll
# path ends, so it is where I announce my scroll state (_reLayoutScrollbars).
class ScrollIndicatorHostWdgt extends ClippingWdgt

  # the thickness of my FAT bars, and the depth of my scroll band; undefined, the theme's
  # (_fullBarThickness)
  scrollBarsThickness: undefined
  # my bars' track colour, when my builder names one; undefined, each bar's track wears its
  # presentation's role, read as it paints (SliderWdgt._surfaceFill)
  sliderColor: undefined
  vBar: undefined
  hBar: undefined

  # ── THE SCROLL INDICATORS ─────────────────────────────────────────────────────────────────
  # My two bars are OVERLAY INDICATORS: THIN and untouchable while my content overflows, absent
  # when it does not, and fattened into real controls while a pointer hovers my scroll band.
  # Everything here is presentation — what can be SCROLLED is asked of my overflow, by my subclass's
  # own query (a viewport's isScrollableNow, a sheet's own clamp), never of a bar's visibility.
  #   Visibility is a pure DERIVATION from overflow: no activity stamps, no clock, nothing
  # time-driven on any path. An indicator on an overflowing pane is therefore the same pixels at
  # rest as it is a second after a scroll, which is what makes a capture of one reproducible and
  # what makes scrollability discoverable without a gesture.
  #
  # is a pointer hovering my scroll band right now (which fattens the indicators)
  _pointerInScrollBand: false

  # Hovering does not ride a file: a restored world wakes with no pointer in any band, exactly as
  # a freshly built one does. (The thin/absent state needs no transient — it is re-derived from
  # overflow at the first arrange.)
  @serializationTransients: [
    "_pointerInScrollBand"
  ]

  # Capability query: is aWdgt one of MY scrollbars? A SliderWdgt asks this of its parent to know whether
  # it is CHROME (a scrollbar → excluded from the editor-focus selection overlay, and its click its own)
  # or content (a dropped value control → framable). Only my actual bars match, so a content slider
  # dropped into my content stays framable. See SliderWdgt._isMyParentsScrollBar.
  isMyScrollBar: (aWdgt) ->
    aWdgt is @vBar or aWdgt is @hBar

  # Build my two bars and wire each to the scroll pin of mine it drives (`hAction`, `vAction`: the
  # names of those pins' setters), with no settle of my own: my subclass builds them inside its own
  # chrome build, which settles once around everything it builds. Each field is set before its bar
  # is added, because a bar asks its new parent whether it is one of its scrollbars as it lands
  # (SliderWdgt._reactToBeingAdded). Placing them is my arrange's (_reLayoutScrollbars), which my
  # subclass runs once what they scroll over is in place.
  _buildScrollBarsNoSettle: (hAction, vAction) ->
    # my bars hold a track colour of their own only when my builder names one (@sliderColor);
    # otherwise each bar's track wears its presentation's role, read as it paints
    # (SliderWdgt._surfaceFill): the scroll indicator's while I present it -- faint while fat, absent
    # while thin -- and a plain slider's groove once it is picked up off me
    @hBar = new SliderWdgt 1, 100, 50, 10, color: @sliderColor
    @hBar._applyHeight @_fullBarThickness()
    @_addNoSettle @hBar

    @vBar = new SliderWdgt 1, 100, 50, 10, color: @sliderColor
    @vBar._applyWidth @_fullBarThickness()
    @_addNoSettle @vBar

    # Bind each bar with the PUBLIC wire verb any other citizen would use — the RECIPROCAL one, since
    # a scrollbar both drives my scroll pin and must follow it. Both edges are then ordinary wires: my
    # own bars follow my scroll exactly as any other bar wired to me does, and nothing of mine writes
    # into a bar's fields. trackTarget also takes the initial value FROM me rather than pushing the
    # bar's constructed default at me.
    @hBar.trackTarget @, hAction
    @vBar.trackTarget @, vAction

  # The thickness of my FAT bars: my own when I hold one, else the theme's.
  _fullBarThickness: ->
    @scrollBarsThickness ? WorldWdgt.theme.scrollBarsThickness

  # THE BOX MY BARS RUN ALONG: the vertical one down its right edge, the horizontal one along its
  # bottom edge, my scroll band inside those two edges. My own box, unless a subclass's bars serve
  # only part of it.
  _scrollBarRunBox: ->
    @boundingBox()

  # How far in from each end of its run what I show stands, along a bar I present: a thin bar of
  # mine runs no further than that (_indicatorEndInsetFor), and a bar shows only while what is left
  # of its run holds a thumb (_barFrameHasRoomForThumb). None, unless a subclass keeps a margin there
  # (ViewportWdgt: its plane margin).
  _scrollBarRunMargin: ->
    0

  # Does my content overflow along `bar`'s axis, under whatever lets it scroll there? It decides
  # whether the bar shows (_reLayoutBar), and whether it crosses my corner (_otherBarCrossesMyCorner).
  # Not unless a subclass says so.
  _scrollAxisOverflows: (bar) ->
    false

  # ── the indicator derivation ──────────────────────────────────────────────────────────────

  # thin at rest, my full bar thickness once a hovering pointer has fattened the indicators
  _indicatorThickness: ->
    if @_pointerInScrollBand
      @_fullBarThickness()
    else
      WorldWdgt.theme.scrollIndicatorThickness

  # How far in from my edge the indicators lie. A thin one stands clear of the LINE at my edge by
  # the theme's clearance: where I paint a border over my edge, that border is the line and the
  # indicator stands its width further in (_borderWidthOverMyEdge); where I paint none the line is
  # my edge itself. A fat one lies flush, because its bar is my scroll band itself: the strip the
  # hover pass watches (_updatePointerInScrollBand) and the frame every press is aimed into
  # (buttonScreenBoxOnArrival). The inset moves the thin bar across its axis only, and a thin bar
  # is no target, so the corner reserve, the hover band and every hit area are unmoved by it.
  _indicatorEdgeInset: ->
    return 0 if @_pointerInScrollBand
    WorldWdgt.theme.scrollIndicatorEdgeClearance + @_borderWidthOverMyEdge()

  # THE BORDER I PAINT OVER MY OWN EDGE, its width across: the theme's border width where my
  # appearance strokes a line along my outline, over my children; none where it strokes none (a
  # window's pane, whose line is its window's border just past my edge; a document). Asked of my
  # appearance through the soft probe the selection ring asks (Widget._drawSelectionOverlay): an
  # appearance that does not answer strokes no outline. My thin indicators stand clear of it
  # (_indicatorEdgeInset), and so does the caret a viewport follows (ViewportWdgt.scrollCaretIntoView).
  _borderWidthOverMyEdge: ->
    if @appearance?.outlineIsStroked?() is true then WorldWdgt.theme.borderWidth else 0

  # How far a bar of mine stops short of each end of its run (_barFrameAt): a THIN indicator I
  # present, by the theme's end inset, and by the margin along my run where that is the larger
  # (_scrollBarRunMargin), so a thin bar runs along the side of what I show and never past its ends.
  # A fat one keeps its whole run (its frame is the one a press meets), and so does a bar picked up
  # off me, whose look is its own and whose length follows my side (_barIsMineToPresent).
  _indicatorEndInsetFor: (bar) ->
    if @_pointerInScrollBand or not @_barIsMineToPresent bar
      0
    else
      Math.max WorldWdgt.theme.scrollIndicatorEndInset, @_scrollBarRunMargin()

  # Hand the bars the presentation my state implies. _-tier: my own arrange is the only caller and
  # the only one there can be — the look is settled in the same pass that decided which bars show
  # at all, so there is nothing left for anyone else to advance and nothing steps.
  _refreshScrollIndicators: ->
    mode = if @_pointerInScrollBand then 'fat' else 'thin'
    for bar in [@hBar, @vBar]
      continue unless bar?.showAsScrollIndicator?
      continue unless @_barIsMineToPresent bar
      bar.showAsScrollIndicator mode
    return

  # Is this bar CHROME I present? My @hBar/@vBar fields deliberately survive the bar being picked
  # up off me (it keeps driving me from wherever it lands — that is the point of the dataflow
  # edge), so the field alone does not say. Parentage does: a bar outside my children is a plain
  # slider somebody put on the desktop, and its look and its thickness are its own business.
  _barIsMineToPresent: (bar) ->
    bar.parent is @

  # THE HOVER PASS. A thin indicator is not a target, so it can never notice the
  # pointer itself — I notice for it, and I can: I am in the hand's mouse-over ancestry for
  # anything I show, so I get the moves. A pointer within a fat bar's width of my scroll edges
  # (_updatePointerInScrollBand) fattens both indicators; anywhere else, or leaving me, thins them
  # again.
  #   The point I read is the one the hand hands me: it tells each widget of a hover move with the
  # pointer mapped into that widget's own plane (ActivePointerWdgt._dispatchEventsFollowingMouseMove),
  # and I read the hand's position through that same mapping (screenPointToMyPlane).
  hoverMoved: ->
    @_updatePointerInScrollBand @screenPointToMyPlane world.hand.position()

  hoverExited: ->
    @_updatePointerInScrollBand undefined

  # My scroll band: the strip a fat bar's width deep inside the right and bottom edges of the box my
  # bars run along (_scrollBarRunBox).
  _updatePointerInScrollBand: (pos) ->
    box = @_scrollBarRunBox()
    band = @_fullBarThickness()
    inBand = pos? and box.containsPoint(pos) and
      ((pos.x >= box.right() - band) or (pos.y >= box.bottom() - band))
    return if inBand is @_pointerInScrollBand
    @_pointerInScrollBand = inBand
    # the flip changes the bars' THICKNESS as well as their look, so it goes through the
    # arrange that owns their geometry rather than through _refreshScrollIndicators alone
    @_reLayoutScrollbars()

  # Pressing a slider's TRACK jump-drags the button to the press point when the slider is
  # chrome its parent owns (my scrollbars) — SliderWdgt.pressBegan asks its parent via ?().
  # A prompt's rows panel gives its input slider the same policy
  # (CommandPanelWdgt.sliderTrackPressJumpsButton).
  sliderTrackPressJumpsButton: ->
    true

  # Where I place a bar of mine at a given cross-axis THICKNESS, `edgeInset` in from my edge and
  # `endInset` short of each end of its run: the vertical one along the right edge and the
  # horizontal one along the bottom edge of the box my bars run along (_scrollBarRunBox). The run is
  # that box's side less what OCCUPIES my bottom-right corner needs (_cornerReserveFor) -- the side's
  # full length when nothing does -- and the end inset comes off both ends of the run that is left.
  # The edge inset moves a bar across its axis, the end inset shortens it along it. My arrange places
  # my bars from this, at the thickness and the insets of the look they wear (_indicatorThickness,
  # _indicatorEdgeInset, _indicatorEndInsetFor), and buttonScreenBoxOnArrival /
  # barScreenFrameOnArrival ask it for the look a pointer's arrival gives them: my full thickness,
  # flush, the run's whole length.
  _barFrameAt: (bar, thickness, edgeInset = 0, endInset = 0) ->
    box = @_scrollBarRunBox()
    spaceToLeaveOnOneSide = @_cornerReserveFor bar
    if bar is @vBar
      new Rectangle (new Point box.right() - edgeInset - thickness, box.top() + endInset), (new Point box.right() - edgeInset, box.bottom() - spaceToLeaveOnOneSide - endInset)
    else
      new Rectangle (new Point box.left() + endInset, box.bottom() - edgeInset - thickness), (new Point box.right() - spaceToLeaveOnOneSide - endInset, box.bottom() - edgeInset)

  # How far a bar of mine stops short of my bottom-right corner: as far as what sits there needs. A
  # resizer over the corner takes the room IT names (its cornerFootprint: a naked inspector's handle
  # its side; never less than a fat bar); failing that, my other bar takes its thickness where it
  # crosses; with neither, the corner is free and the bar runs right to it. Both are asked of
  # STRUCTURE, never of geometry or visibility, which the passes that read this are still laying
  # out: the other bar by the overflow its showing derives from, the resizer by climbing the corner
  # chain (_resizerOverMyCorner). The margin along my run is no part of the reserve: a thin bar gives
  # it up at both ends of its run (_indicatorEndInsetFor), and a fat one keeps the run a press meets,
  # so the two fat bars meet at my corner.
  _cornerReserveFor: (bar) ->
    resizer = @_resizerOverMyCorner()
    if resizer? then Math.max @_fullBarThickness(), resizer.cornerFootprint()
    else if @_otherBarCrossesMyCorner bar then @_fullBarThickness()
    else 0

  # Does my OTHER bar cross my bottom-right corner? Whenever it is mine to place and my content
  # overflows along its axis (_scrollAxisOverflows): the facts its showing derives from, read here
  # WITHOUT its room-for-thumb check, so neither bar's length waits on whether the other one shows.
  _otherBarCrossesMyCorner: (bar) ->
    other = if bar is @vBar then @hBar else @vBar
    return false  unless other? and other.parent is @ and other.isWiredTo?(@)
    @_scrollAxisOverflows other

  # The RESIZER that sits over my bottom-right corner, or undefined when none does. Every container
  # that runs a child out to its own bottom-right corner says which (bottomRightCornerReachedBy), so
  # I climb for as long as I am, or am inside, such a child, and the first container on the way whose
  # resizer would show answers with that resizer (HandleWdgt.wouldShow: what its showing derives
  # from, not whether it shows yet). A container that names nobody ends the climb. I name nobody
  # myself: what I show scrolls under my corner.
  _resizerOverMyCorner: ->
    child = @
    container = @parent
    while container?.bottomRightCornerReachedBy?(child)
      return container.resizer  if container.resizer?.wouldShow?()
      child = container
      container = container.parent
    undefined

  # What occupies a corner I reach may have changed -- its resizer came or went
  # (HandleWdgt.updateVisibility), which tells every host of scroll indicators down that corner chain
  # (Widget.noteCornerChainChanged) -- so my bars must re-lay to the reserve the corner now asks of
  # them: my arrange is where they are laid, so I schedule it.
  noteCornerResizerChanged: ->
    @_scheduleRelayoutRespectingPhase()

  # The SCREEN box in which a pointer ARRIVING at one of my bars finds that bar's button. A thin
  # indicator is intangible, and the arrival — a finger's own down, a mouse's approach — fattens it
  # before any press is dispatched (hoverMoved), so a press always meets THIS look and never the thin
  # one on screen: the bar at my full thickness, its thumb laid in that frame by the very derivation
  # its own arrange commits (SliderButtonWdgt.boxInSliderFrame). MacroToolkit.sliderButtonPressPoint
  # aims here.
  buttonScreenBoxOnArrival: (bar) ->
    frame = @_barFrameAt bar, @_fullBarThickness()
    box = (bar.button.boxInSliderFrame frame.extent(), bar.trackThumbInset).translateBy frame.origin
    new Rectangle (bar.localPointToScreen box.origin), (bar.localPointToScreen box.corner)

  # The SCREEN frame of one of my bars as a pointer ARRIVING at it finds it — at my full thickness,
  # the frame buttonScreenBoxOnArrival's box lies in. The button travels this frame's length less its
  # own, and a fat thumb can be longer than the thin one drawn at rest, so a drag that means to carry
  # the button a fraction of its way measures that way here and not on the bar as drawn.
  barScreenFrameOnArrival: (bar) ->
    frame = @_barFrameAt bar, @_fullBarThickness()
    new Rectangle (bar.localPointToScreen frame.origin), (bar.localPointToScreen frame.corner)

  # WHAT OF MY BARS A PRESS ARRIVING AT `screenPoint` MEETS: the button of the bar whose frame on
  # arrival holds the point, else that bar itself (its track), else undefined. Only a bar I present
  # (_barIsMineToPresent), that shows and that is intangible now — a THIN one, which the arrival
  # fattens before the press is dispatched (buttonScreenBoxOnArrival); a fat bar or a plain one is
  # met by the plain hit test. Asked in MY plane: the point is mapped into it (screenPointToMyPlane,
  # the mapping my hover pass reads the pointer through) and tested against the frame and the thumb
  # box my arrange derives there, so a tilted host answers for its bars' true footprint, where a
  # screen box built from two mapped corners would be the axis-aligned box around it.
  # MacroToolkit's aim check (_widgetAPressMeets) asks it of every host above a finger's press.
  barPartMetOnArrivalAt: (screenPoint) ->
    pos = @screenPointToMyPlane screenPoint
    met = undefined
    for bar in [@vBar, @hBar]
      continue unless bar? and (@_barIsMineToPresent bar) and bar.visibleBasedOnIsVisibleProperty() and bar.indicatorIsIntangible?()
      frame = @_barFrameAt bar, @_fullBarThickness()
      continue unless frame.containsPoint pos
      thumb = (bar.button.boxInSliderFrame frame.extent(), bar.trackThumbInset).translateBy frame.origin
      met = if thumb.containsPoint pos then bar.button else bar
    met

  # Does the frame a press meets one of my bars in have ROOM for the bar's thumb? That frame is the
  # bar at my full thickness, flush, the run's whole length (_barFrameAt), whatever look the bar
  # wears on screen: a thin indicator stops short of its side's ends, and the question is not asked
  # of that shorter frame. A thumb is never shorter than it is wide, and in the look a press meets
  # it is my full thickness less the track's inset, so a frame shorter than that holds none — in a
  # host shorter than the corner reserve _barFrameAt leaves, the frame's length is not even
  # positive. Such a bar is not shown: it would be a sliver no pointer can work. The overflow it
  # would stand for still scrolls, since every scroll gesture asks my subclass's own query (a
  # viewport's isScrollableNow, a sheet's own clamp), never a bar.
  #   For a bar I PRESENT the room is measured along what I show: that frame's run less the margin
  # along my run at both ends (_scrollBarRunMargin) must hold the thumb. A thin bar runs along what I
  # show (_indicatorEndInsetFor), so a host with a margin and too short for this would hand its thin
  # bar a run shorter than a thumb, or a negative one. A bar picked up off me (_barIsMineToPresent)
  # runs my side's whole length, as its end inset says, and is judged on that whole run. With no
  # margin every bar is.
  _barFrameHasRoomForThumb: (bar) ->
    frame = @_barFrameAt bar, @_fullBarThickness()
    length = if bar is @vBar then frame.height() else frame.width()
    length - (if @_barIsMineToPresent bar then 2 * @_scrollBarRunMargin() else 0) >= @_fullBarThickness() - bar.trackThumbInset

  # MY ARRANGE OF THE TWO BARS: each bar's own (_reLayoutBar), then their look, then the
  # announcement. A STRUCTURAL arrange: a bar's geometry is applied through the NON-notifying
  # arrange twins (_applyExtentBase / _applyMoveToBase), not the notifying setters -- the bars are
  # chrome I own and place from my own size, never affecting what I fit to, so notifying would only
  # trigger a redundant confirm pass (docs/archive/proper-layouts-4.2-structural-arrange-plan.md).
  _reLayoutScrollbars: ->
    @_changed()
    @_reLayoutBar @hBar
    @_reLayoutBar @vBar

    # the bars that show have just been sized and placed; give them the look that goes with the
    # state they show in (thin, or fat under a hovering pointer). A look that changes the thumb's
    # inset re-lays the thumb on its way in (SliderWdgt.showAsScrollIndicator).
    @_refreshScrollIndicators()

    # ── THE REVERSE EDGE ────────────────────────────────────────────────────────────────────────
    # (docs/archive/connector-ubiquity-and-reflection-plan.md, §P8.)
    # My scroll geometry just settled, so I ANNOUNCE it and whoever tracks me re-reads it. Everything
    # above this line is field business, and rightly: SHOWING, SIZING and PLACING the bars is chrome I
    # own, and only my own two are mine to place. The NUMBERS a thumb shows (its scale and its value)
    # are not chrome, they are my state, and any number of bars may want them — a duplicate, a bar
    # someone unplugged onto the desktop, one belonging to nobody — so I push them into none.
    #   markNonValueChange, not markStale: my scroll state is not my VALUE (a scroll offset is no
    # host's one number), and this wakes only the edges that asked to re-read me, so it is DARK when
    # nothing tracks me.
    # ⚠ This is a LAYOUT station marking DATAFLOW, which the engine's standing one-way law otherwise
    # forbids. It is deliberate: I announce here, and the drain runs whenever it next runs.
    # ⭐ MEASURED, because the objection to announcing here is that a tracking pair would SHEAR by a
    # frame under fast motion. It does not, and the reason is the CYCLE ORDER read the other way
    # round: doOneCycle plays input BEFORE the dataflow station, so a scroll driven by a wheel, a thumb
    # drag or a track click announces itself in time for the SAME cycle's drain — measured lag ZERO
    # frames, at every fling rate. The one-frame lag is real only for a change that originates INSIDE
    # recalculateLayouts (a content re-fit changing the bar's RANGE) — measured at exactly 1 frame —
    # which is the case with no motion to shear against. So a second drain+layout pass would buy
    # nothing on the only path that moves.
    world.dataflow.markNonValueChange @

  # ONE BAR'S ARRANGE: its cross axis, its frame, whether it shows. Its THICKNESS across and its
  # distance from my edge are its look's: thin and clear of the line at my edge at rest, my full bar
  # thickness and flush while a hovering pointer has fattened it back into a control; how far it
  # stops short of its side's ends is mine to answer per bar (_indicatorEndInsetFor).
  #   I touch only a bar that drives ME: a bar can survive detached from its original host A (it is
  # referenced as a property, not a child, so duplicating A into B does not retarget or duplicate the
  # bar), leaving B referencing A's bar. I ask the bar whether it drives me before touching it, so a
  # stray duplicate never resizes or hides a scrollbar that belongs to a different host. (`isWiredTo`:
  # a controller owns a LIST of wires, so "do you drive me" is a search, not a field comparison.)
  #   ⚠ SOAKED, and that is not decoration: this guard is the gate for everything below it, so it has
  # to answer for a bar that is not (yet) a live controller — mid-deserialization a widget reference
  # can still be unresolved, which is the same case SliderWdgt.unitSize guards for on its own @button.
  # A field comparison would be total by accident (`<anything>.target == @` is just false); asking a
  # METHOD is not, and a bar that cannot answer is exactly a bar I must not touch.
  _reLayoutBar: (bar) ->
    return unless bar.isWiredTo? @
    # the cross axis is INDICATOR presentation, so it is imposed only on a bar I still hold; one
    # picked up onto the desktop keeps the thickness it left with (_barIsMineToPresent), and its
    # place is not mine to decide (it is moved only while it is mine, below)
    thickness =
      if @_barIsMineToPresent bar then @_indicatorThickness()
      else if bar is @vBar then bar.width()
      else bar.height()
    frame = @_barFrameAt bar, thickness, @_indicatorEdgeInset(), @_indicatorEndInsetFor bar
    # a bar shows while my content overflows along its axis (_scrollAxisOverflows), and not when its
    # frame, as a press meets it, has no room for its thumb
    unless @_scrollAxisOverflows(bar) and @_barFrameHasRoomForThumb bar
      bar.hide()
      return
    bar.show()
    # chrome I own and place: applied through the non-notifying twin (see _reLayoutScrollbars).
    # _applyExtentBase == _applyWidth/Height minus the seam; it keeps the other axis by being passed
    # the current one.
    bar._applyExtentBase frame.extent()  unless bar.extent().equals frame.extent()
    # a bar picked up off me is sized along my side, never moved
    bar._applyMoveToBase frame.origin  if bar.parent == @
    # I placed and sized the bar through the NON-notifying twins, so re-laying it is MINE to do. A
    # slider's THUMB is derived from its frame (SliderButtonWdgt._reLayoutSelf reads its parent's
    # height and position), so a bar whose frame I just changed and whose thumb nobody re-lays is
    # left INTERNALLY INCONSISTENT -- which the arrange-idempotence census correctly reports as a
    # mover. It is a LAYOUT obligation, not a dataflow one, so it stays here where the frame changes.
    bar._reLayoutSelfAndButton()
