# THE SET'S VIEWPORT: an inspector browser's cell (InspectorBrowserWdgt) that holds its SET, the row of
# its columns (InspectorRowWdgt), as my PLANE, and scrolls it SIDEWAYS. My plane's measure is what I
# commit as its frame (InspectorRowWdgt.scrolledContentMeasure): every column at its own width, the
# last one taking whatever room the others leave, never narrower than I am, exactly as tall as I am --
# so there is nothing to scroll down, and no vertical bar of mine ever shows -- and, while the set is
# wider than I am, widened so that the end of its scroll is a column's left edge. A column never
# narrows to fit me: a set wider than I am overflows me, and my thin bar along my bottom shows while
# it does (my base's presentation, never hidden: a finger's drag scrolls me along the axis whose bar
# shows, ViewportWdgt._dragScrollsHorizontally).
#   With my browser's body below me I am the STRIP OF LISTS, and my division box, a leaf's, which my
# browser's division stack reads, pins my HEIGHT: my least, and a desired size my most equals, so no
# spare room of my browser's comes to me and the body below takes it all. My browser states it as it
# builds me, and the divider below me restates it as a person drags it (_setStatedSizeDeferredSettle),
# so the height a person gave me stands when the window is resized. With the body beside, my box is the
# plain one every part of the tool wears, its most unbounded (InspectorBrowserWdgt.
# _stateMyViewportBesideNoSettle), and I take the rest of my browser's box under its trail, every spare
# px of it. Either way I never squeeze a column of my set below
# its own least height: my least height is never less than my plane's, the tallest least of its
# columns, and my desired never less than my least (getMinDim, getDesiredDim), the one answer my
# browser's division stack and the divider's solve both read.
#   I scroll by REST POINTS: 0, the left edges of my set's columns short of the end of my scroll, and
# that end (_restOffsets). A sideways wheel notch moves me one rest point its way, and at my start or
# my end goes on to the pane around me; a stroke that scrolled me, and my bar's own write (a thumb
# drag, a track click), come to rest on the rest point nearest where they leave me, the stroke at its
# own ending; and after a choice my browser brings the column that choice shows whole into view, the
# least way, to a rest point (revealColumn), and nothing for a choice shown in its body below me. A
# press that leaves my offset where it found it -- a click, a tap, a stroke a pane inside me took --
# moves nothing at its ending, so where a change moved my columns' edges under a still offset (a
# column's width stated, my window resized) I stand off a rest point until a scroll of mine rests me.
#   A choice that removes columns of my set leaves my offset where it found it: my set holds that
# offset in its measure (InspectorRowWdgt._heldScrollOffset), at the width I stand at as it is held, so
# my clamp leaves it standing, and my next scroll, whatever moves me, lets go of it, settled with that
# scroll: a wheel notch, my bar's write and the reveal of a column as they move me (_scrollX,
# revealColumn), a STROKE where it comes to rest, at its ending (_restAfterAStroke). My next arrange
# then measures my set at its own width, and my clamp brings my offset back within it, to its end, a
# rest point. So under a finger the set moves with the finger through the room the hold keeps, and
# that room closes as the stroke comes to rest, never under the finger mid-stroke. Standing at another
# width than the hold was written at -- my window resized -- I measure my set past it, and the clamp
# closes that room the same way.
#   The rest of what I say is a DECLARATION a plain viewport answers wrongly for a set of columns: my
# plane holds the tool's own columns, not loose content; I take no drops, offer no crop or scroll
# toggle, hold no opinion on editing amenities and keep no glide; and I am my browser's internal
# structure, which the hierarchy menu passes over, as it passes over my plane. My look adds nothing
# to the tool's: no border, no fill and no margin of my own -- my browser paints the body my set's
# columns stand on, and it shows through me.
class InspectorRowViewportWdgt extends ViewportWdgt

  # MY OFFSET AS THE PRESS IN PROGRESS REACHED ME (pressBegan), or undefined between presses: what
  # tells, at that press's ending, a stroke that scrolled me from a press that did not
  # (_restAfterAStroke), and, while it stands, that a press is under way on me, whose scroll lets go of
  # my set's hold at that ending, never on its way (_scrollX). Set as the press reaches me and cleared
  # at its ending: a moment of one press, which neither a copy nor a save carries.
  _offsetWhenPressed: undefined
  @serializationTransients: ["_offsetWhenPressed"]
  @copyTransients: ["_offsetWhenPressed"]

  # `row` is my identity, my one positional parameter: the set I hold as my plane, built empty by my
  # browser. My look is pinned AFTER super, which builds my plane in and mimics its colour and alpha:
  # transparent, so the body my browser paints shows through me (alpha is paint, never hit-testing),
  # and dressed in the tool's pane border, which holds no colour, so no line runs round my set and my
  # thin bar stands only the theme's clearance in from my edge (ScrollIndicatorHostWdgt._indicatorEdgeInset).
  constructor: (row) ->
    super row
    @alpha = 0
    @wearPaneRoles stroke: "inspectorPaneStroke"

  # my plane's measure is the frame I commit for it (ViewportWdgt._positionAndResizeChildren)
  _isContentSizing: -> true

  # MY LEAST SIZE: my base's (my division box's least, a leaf's), but down never less than my plane's
  # least height, which Widget derives for a row from its cells' least sizes, fields all the way down
  # (getRecursiveMinDim: the tallest of them) -- the tallest least height of my set's columns, each its
  # own cells' (its header, its chooser where one stands, its view's bands and its list's least) -- so
  # the strip of lists is never squeezed below what a column of it needs, and with no column (a
  # browser opened on a member) my box's least stands alone. Read by my browser's division stack, in
  # each of its regimes, and by the divider below me as the floor of its solve
  # (InspectorDividerWdgt.sizeDraggedTo), so the two agree. Collapsed, my base's answer (nothing).
  getMinDim: ->
    least = super()
    return least  if @isInCollapsedSubtree()
    new Point least.x, Math.max least.y, @contents.getMinDim().y

  # MY DESIRED SIZE: my base's (my division box's, which my browser and the divider below me state),
  # but down never less than my least (getMinDim): a division stack hands a cell exactly its desired
  # size wherever it has room for every desired size, so a stated height below a column that needs more
  # would squeeze that column there. Collapsed, my base's answer (nothing).
  getDesiredDim: ->
    desired = super()
    return desired  if @isInCollapsedSubtree()
    new Point desired.x, Math.max desired.y, @getMinDim().y

  # MY MOVEMENT CORE, my base's (ViewportWdgt._scrollX), where every scroll of mine meets, and my clamp
  # never does (it writes my offset through my base's write funnel alone). A scroll that MOVES me lets go
  # of the offset my set holds (InspectorRowWdgt._heldScrollOffset): the arrange that follows measures my
  # set at its own width, and my clamp closes the room the hold kept. The release SETTLES WITH THE SCROLL
  # THAT MADE IT, and the scrolls that reach me here are of three kinds:
  #   a STREAM's while no press is under way on me -- a wheel notch (ViewportWdgt.scrolledBy), my bar's
  #   write (setScrollX, a wire's delivery, inside the dataflow drain's own settle: a press on my bar's
  #   thumb or track stops at my bar, SliderButtonWdgt.pressBegan, SliderWdgt.pressBegan, and never
  #   reaches me), an edge auto-scroll (ViewportWdgt._autoScroll, which my refusal of drops never
  #   starts), the rest at a press's ending (_restAfterAStroke), which clears that press's record first --
  #   whose release is a DECLARED deferral (_letGoOfMySetsHold): my set's re-measure rides the flush that
  #   follows the stream in its cycle, as the stream's own layout does (my base's door to a place,
  #   scrollTo, which no part of the tool asks of me, a script's alone, takes the same release, as my
  #   base's every scroll path applies itself and settles nothing);
  #   a STROKE's, while the press that reached me is under way (_offsetWhenPressed stands) -- its frames
  #   and the flush at its ending (ViewportWdgt.takeStrokeScrollFrom), and any other scroll of mine
  #   while the press lasts -- which lets go of nothing here: the stroke lets go of the hold where it
  #   comes to rest, at its ending (_restAfterAStroke), so my set keeps the room the hold kept for as long
  #   as the finger moves it, and its clamp never moves it under the finger;
  #   my one SETTLED verb's, the reveal of a column (revealColumn, after a choice or at a press on a step
  #   of my browser's trail), which lets go of the hold itself, a core inside its own settle, before its
  #   scroll reaches me, so here it finds none to let go of, and it returns with my set measured anew.
  # A scroll that moves nothing lets go of nothing.
  _scrollX: (steps) ->
    moved = super steps
    @_letGoOfMySetsHold()  if moved and !@_offsetWhenPressed?
    moved

  # MY SET'S HOLD LET GO OF, by a scroll of a stream (_scrollX) or a stroke come to rest
  # (_restAfterAStroke): the release as a DECLARED deferral (_deferredSettleDeclare), its re-measure
  # riding the flush that follows in the cycle. The one statement of that release.
  _letGoOfMySetsHold: ->
    @_deferredSettleDeclare => @contents._holdScrollAtNoSettle()

  # MY HEIGHT STATED, as the strip of lists, by a drag-move STREAM: the divider below me being dragged,
  # or the split button joined to it (InspectorDividerWdgt.nonFloatDragging,
  # SplitGripWdgt.nonFloatDragging: the stream handlers check-layering [O] lets call a *DeferredSettle
  # entrypoint). The one write every cell a divider sizes answers, a column's twin
  # (InspectorWdgt._setStatedSizeDeferredSettle). An entrypoint of the private deferred-settle family
  # Widget._setMaxDimDeferredSettle heads: my core's effect, its layout flush riding the one end-of-cycle
  # settle (world.deferredSettlingEnabled off: settled at each call), both branches reaching the core
  # directly.
  _setStatedSizeDeferredSettle: (height) ->
    if world?.deferredSettlingEnabled
      @_deferredSettleDeclare => @_setStatedSizeNoSettle height
    else
      @_settleLayoutsAfter => @_setStatedSizeNoSettle height

  # My division box's desired and most height written, both to `height`, through the box's own cores
  # (DivisionStackLayoutSpec: each along its axis, mine down my browser's stack, each a no-op when it
  # holds that size already, each invalidating my layout, which climbs to my browser). Both, since the
  # box's desired is read clamped to its most (Widget.getRecursiveDesiredDim): a most left below would
  # hold the desired down, one left above would hand me spare room. Settles nothing.
  _setStatedSizeNoSettle: (height) ->
    box = @_ensureDivisionBox()
    box._setMaxMainDimNoSettle height
    box._setDesiredMainDimNoSettle height

  # my plane holds the tool's own columns, not loose content: a mouse drag on a column moves the window
  contentsPanelHoldsLooseContent: -> false

  # a widget dropped on the set would join the inspector's own columns: the drop goes past me
  _acceptsDrops: false

  # cropping the set would hide columns with no cue: I always scroll (ViewportWdgt's own reason)
  offersScrollPolicyToggle: false

  # no opinion: the editor-focus walk passes through me (WorldWdgt._widgetBeingEdited)
  providesAmenitiesForEditing: undefined

  # no glide: a stroke that scrolls the set stops where it ends, never carried past a column
  hasVelocity: false

  # my browser's internal structure: the hierarchy menu lists my browser in my place
  hiddenFromHierarchyMenu: -> true

  # my name where a list names me (an inspector on a browser's children): my role, not "viewport"
  colloquialName: -> "inspector row viewport"

  # ── SCROLLING BY REST POINTS ──────────────────────────────────────────────────────────────

  # MY REST POINTS, the offsets my scroll comes to rest at, in order and each once: 0; every left edge
  # of my set's columns short of the end of my scroll (InspectorRowWdgt.columnLefts, read from fields);
  # and that end, my plane's width less mine, where my clamp keeps me at most
  # (ViewportWdgt._keepScrollOffsetInBounds). My plane's measure stands the end on a column's left edge
  # whenever my set's last column is no wider than I am; a wider one leaves the end where its right
  # edge meets mine; and while my set's hold shapes its measure (at the width I stood at as it was
  # held: InspectorRowWdgt.scrolledContentMeasure), the end is at least the held offset.
  _restOffsets: ->
    end = Math.max 0, @contents.width() - @width()
    points = [0]
    points.push left  for left in @contents.columnLefts() when 0 < left < end
    points.push end  if end > 0
    points

  # of `points`, offsets in order, the one nearest `offset`: the first of two as near
  _nearestOf: (points, offset) ->
    nearest = points[0]
    nearest = point  for point in points when Math.abs(point - offset) < Math.abs(nearest - offset)
    nearest

  # A SIDEWAYS NOTCH moves me ONE rest point its way, whatever its size: the travel to the next rest
  # point past my offset that way, in my movement core's steps (a positive step scrolls me back toward
  # my start: ViewportWdgt._scrollX). My base asks only while I can still move that way -- a notch at
  # my start or my end goes on to the pane around me (ViewportWdgt.scrolledBy) -- and those two are
  # rest points, so a next one always stands.
  _wheelTravelX: (x) ->
    points = @_restOffsets()
    if x > 0
      next = (point for point in points when point < @scrollOffsetX).pop()
    else
      next = (point for point in points when point > @scrollOffsetX)[0]
    @scrollOffsetX - (next ? @scrollOffsetX)

  # A STROKE THAT SCROLLED ME RESTS on the rest point nearest where it leaves me, at its own ending (my
  # base's two seats for it, pressEnded and pressCancelled: the hand tells one of them to every press
  # that reached me, ActivePointerWdgt's press lifecycle): my base pays the stroke's last travel first
  # (super), then I come to rest (_restAfterAStroke), before any later frame, letting go of my set's
  # hold there. The press records where it found me as it reaches me, so a press that leaves my offset
  # there moves nothing and lets go of nothing, wherever I stand -- on a rest point or off one.
  pressBegan: (pos) ->
    @_offsetWhenPressed = @scrollOffsetX
    super

  pressEnded: (pos) ->
    super
    @_restAfterAStroke()

  pressCancelled: ->
    super
    @_restAfterAStroke()

  # THE REST AT A PRESS'S ENDING, the one statement my two endings share: the press's record let go
  # of, and then, unless my offset is where the press found it, my set's hold let go of -- the stroke
  # moved me, and its scroll lets go of it here, where it comes to rest, never on its way (_scrollX) --
  # and my offset brought to the rest point nearest it (_comeToRestAt). The rest points are read off my
  # set as it stands, the hold's room still in it; the move to the one nearest re-measures my set at its
  # own width and my clamp brings my offset within it (_comeToRestAt's post-scroll pair), and a stroke
  # that ends on a rest point already has the release's deferral re-measure my set in its cycle. Either
  # way an offset past my set's own end comes to rest at that end. A press I have no record of moves
  # nothing, and lets go of nothing.
  _restAfterAStroke: ->
    offsetWhenPressed = @_offsetWhenPressed
    @_offsetWhenPressed = undefined
    return unless offsetWhenPressed? and @scrollOffsetX isnt offsetWhenPressed
    @_letGoOfMySetsHold()
    @_comeToRestAt @_nearestOf @_restOffsets(), @scrollOffsetX

  # MY OFFSET MOVED TO `rest`, one of my rest points, through my movement core (_scrollX) and its
  # post-scroll pair, as every scroll path of my base ends (scrollTo is that pair's public door): the one
  # statement the rest at a stroke's ending and the reveal of a column share. At `rest` already, I move
  # nothing, and my bar is laid out again all the same.
  _comeToRestAt: (rest) ->
    if @_scrollX @scrollOffsetX - rest
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  # MY SCROLL PIN'S SETTER RESTS TOO, as a sheet's comes to rest on a whole cell
  # (SimpleSpreadsheetWdgt._setViewOriginAlongNoSettle): an offset delivered goes to the rest point
  # nearest it, through my base's setter. It is where my own bar writes -- a thumb drag and a track
  # click are each a wire's delivery onto my "scroll x" pin (DataflowEngine._applyWireValue: I have no
  # connector lane), as any other wire's is -- and it is no step of any other scroll of mine: a stroke,
  # a notch and the reveal of a column each move me through my movement core (_scrollX), and my clamp
  # through my base's write funnel, so nothing rests twice. My bar follows the offset I rest on without writing it
  # back (SliderWdgt.reflectTarget), so nothing loops either.
  setScrollX: (num) ->
    num = parseFloat num  unless typeof num is "number"
    return  if isNaN num
    super @_nearestOf @_restOffsets(), num

  # `column`, one of my set's, brought WHOLE into my view the least way, to a rest point: of the rest
  # points that show it whole (at or before its left edge, my width from there reaching its right
  # edge), the one nearest my offset -- my offset itself while it is one of them, which moves nothing
  # (standing off a rest point, I come to rest on the nearest of them); with none, the column is wider
  # than I am, and I come to rest at its start, the last
  # rest point at or before its left edge. Its edges are read from fields, as my rest points are: its
  # left where my set says its columns stand (InspectorRowWdgt.columnLefts, in the order of its
  # columns), its right its own width on from there (InspectorWdgt.getDesiredDim: the spare room a last
  # column lies across is my set's, not the column's). My plane fills me, with no margin of mine. The
  # sideways sibling of ListWdgt.scrollRowIntoView; a column not of my set (my browser's body below me
  # among them) moves nothing. My browser asks it, of the inspector a choice shows, after that choice's
  # settle (InspectorBrowserWdgt.showChoice), and of the column a level of its trail was chosen in, at a
  # press on that level (InspectorBrowserWdgt.revealTrailLevel).
  #   A SETTLED verb, as every public one is: it returns with my set laid out at the offset it rests me
  # on. A reveal that moves me lets go of the offset my set holds (_scrollX says why every scroll does)
  # as a core inside this settle, just before it moves me (_comeToRestAt), so my set's re-measure and
  # its columns' re-lay settle with the scroll.
  revealColumn: (column) ->
    @_settleLayoutsAfter => @_revealColumnNoSettle column

  _revealColumnNoSettle: (column) ->
    left = @contents.columnLefts()[@contents.columns().indexOf column]
    return  unless left?
    right = left + column.getDesiredDim().x
    points = @_restOffsets()
    showingIt = (point for point in points when point <= left and point + @width() >= right)
    if showingIt.length > 0
      rest = @_nearestOf showingIt, @scrollOffsetX
    else
      rest = (point for point in points when point <= left).pop()
    return  if rest is @scrollOffsetX
    @contents._holdScrollAtNoSettle()
    @_comeToRestAt rest
