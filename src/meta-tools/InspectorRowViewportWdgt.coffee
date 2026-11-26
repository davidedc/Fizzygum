# THE SET'S VIEWPORT: an inspector browser's cell (InspectorBrowserWdgt) that holds its SET, the row of
# its columns (InspectorRowWdgt), as my PLANE, and scrolls it SIDEWAYS. My plane's measure is what I
# commit as its frame (InspectorRowWdgt.scrolledContentMeasure): every column at its own width, the
# last one taking whatever room the others leave, never narrower than I am, exactly as tall as I am --
# so there is nothing to scroll down, and no vertical bar of mine ever shows -- and, while the set is
# wider than I am, widened so that the end of its scroll is a column's left edge. A column never
# narrows to fit me: a set wider than I am overflows me, and my thin bar along my bottom shows while
# it does (my base's presentation, never hidden: a finger's drag scrolls me along the axis whose bar
# shows, ViewportWdgt._dragScrollsHorizontally).
#   I scroll by REST POINTS: 0, the left edges of my set's columns short of the end of my scroll, and
# that end (_restOffsets). A sideways wheel notch moves me one rest point its way, and at my start or
# my end goes on to the pane around me; a stroke that scrolled me, and my bar's own write (a thumb
# drag, a track click), come to rest on the rest point nearest where they leave me, the stroke at its
# own ending; and after a choice my browser brings the column it shows whole into view, the least
# way, to a rest point (revealColumn). A press that leaves my offset where it found it -- a click, a
# tap, a stroke a pane inside me took -- moves nothing at its ending, so where a change moved my
# columns' edges under a still offset (a column's width stated, my window resized) I stand off a rest
# point until a scroll of mine rests me.
#   The rest of what I say is a DECLARATION a plain viewport answers wrongly for a set of columns: my
# plane holds the tool's own columns, not loose content; I take no drops, offer no crop or scroll
# toggle, hold no opinion on editing amenities and keep no glide; and I am my browser's internal
# structure, which the hierarchy menu passes over, as it passes over my plane. My look adds nothing
# to the tool's: no border, no fill and no margin of my own -- my browser paints the body my set's
# columns stand on, and it shows through me.
class InspectorRowViewportWdgt extends ViewportWdgt

  # MY OFFSET AS THE PRESS IN PROGRESS REACHED ME (pressBegan), or undefined between presses: what
  # tells, at that press's ending, a stroke that scrolled me from a press that did not
  # (_restAfterAStroke). Set as the press reaches me and cleared at its ending: a moment of one press,
  # which neither a copy nor a save carries.
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
  # edge meets mine.
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
  # (super), then I come to rest (_restAfterAStroke), before any later frame. The press records where
  # it found me as it reaches me, so a press that leaves my offset there moves nothing, wherever I
  # stand -- on a rest point or off one.
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
  # of, and then, unless my offset is where the press found it, my offset moved to the rest point
  # nearest it, through my base's movement core and its post-scroll pair, as every scroll path of my
  # base ends (scrollTo is that pair's public door). A press I have no record of moves nothing.
  _restAfterAStroke: ->
    offsetWhenPressed = @_offsetWhenPressed
    @_offsetWhenPressed = undefined
    return unless offsetWhenPressed? and @scrollOffsetX isnt offsetWhenPressed
    rest = @_nearestOf @_restOffsets(), @scrollOffsetX
    if @_scrollX @scrollOffsetX - rest
      @_positionAndResizeChildren()
    @_reLayoutScrollbars()

  # MY SCROLL PIN'S SETTER RESTS TOO, as a sheet's comes to rest on a whole cell
  # (SimpleSpreadsheetWdgt._setViewOriginAlongNoSettle): an offset delivered goes to the rest point
  # nearest it, through my base's setter. It is where my own bar writes -- a thumb drag and a track
  # click are each a wire's delivery onto my "scroll x" pin (DataflowEngine._applyWireValue: I have no
  # connector lane), as any other wire's is -- and it is no step of any other scroll of mine: a stroke,
  # a notch, scrollTo and my clamp each move me through my base's movement core (ViewportWdgt._scrollX),
  # so nothing rests twice. My bar follows the offset I rest on without writing it back
  # (SliderWdgt.reflectTarget), so nothing loops either.
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
  # sideways sibling of ListWdgt.scrollRowIntoView, through scrollTo; a column not of my set moves
  # nothing. My browser asks it after a choice's settle (InspectorBrowserWdgt.revealLastColumn).
  revealColumn: (column) ->
    left = @contents.columnLefts()[@contents.columns().indexOf column]
    return  unless left?
    right = left + column.getDesiredDim().x
    points = @_restOffsets()
    showingIt = (point for point in points when point <= left and point + @width() >= right)
    if showingIt.length > 0
      rest = @_nearestOf showingIt, @scrollOffsetX
    else
      rest = (point for point in points when point <= left).pop()
    @scrollTo new Point rest, @scrollOffsetY  unless rest is @scrollOffsetX
