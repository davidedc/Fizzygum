# A SPLIT GRIP: the FINGER's way to size what an inspector browser's divider sizes (InspectorDividerWdgt).
# I am a TAB on the divider that stands before an inspector, at the left end of that inspector's header
# band, a piece of layout chrome whose AXIS is my identity (my one parameter: the divider's splitAxis,
# given me by the inspector that builds me):
#   ACROSS ('x'), the divider between two columns of the browser's set: splitButtonWidth wide and a
# chrome target's side tall, flush right of the divider, which sizes the column on its left;
#   TURNED a quarter ('y'), the divider between the browser's set and its body below: a chrome target's
# side wide and splitButtonWidth tall, flush under the divider, hanging from the TOP of the body's header
# band (crossAlignInABand), which sizes the strip of lists above it.
# Either way the divider and I make one piece a chrome target's side along my axis at the header, as I
# am a chrome target's side across it (12 + 32 = 44: the 44 rule, visual-design-system §4.2: a target
# that must be big is drawn big), and a finger landing anywhere on it, on the divider beside me as on
# me, sizes what the divider sizes. The divider alone is the mouse's way; we are both always there,
# since a device can have both. A drag on me sizes it exactly as a drag on the divider does: the solve
# is the divider's own, its seam of three queries (dragPlane, dragAnchorAt, sizeDraggedTo), which its
# own drag asks too, and I map my own pointer, keep my own drag's anchor and make the cell's write
# myself (nonFloatDragging). A press on me is kept where it lands (LayoutChromeWdgt.pressBegan), so the
# pane the set scrolls in never scrolls under my drag.
#   I hold no divider: I ask the inspector I stand in which divider I drag, as I am dragged and as I
# am painted (InspectorWdgt.splitterMovedBy, read off its holder's children), and it answers only while
# I am its own split button and lead its header: a copy of me, my inspector taken out of its holder, a
# button a person put after a title or into another inspector's header, or one on the desktop drags
# nothing.
#   My look is a split's piece (SplitPieceAppearance): one flat plate, and on it a field of the
# divider's own grip dots. Joined to that divider (we hold each other: LayoutChromeWdgt.joinedPiece,
# whose rule says when we join and part) we are painted as one piece: my corners against it square, my
# two free ones rounded (across: my right side's; turned: my bottom side's), the field centred on the
# whole piece, and a hover or a press on either of us lights both. Alone, my four corners are rounded and
# the field is centred on me. A drop on me is refused, as on every plain widget.
class SplitGripWdgt extends LayoutChromeWdgt

  # THE AXIS I split along, the divider's I was built for ('x' across, 'y' turned; anything but 'y'
  # reads as across): my identity, written as I am built and never after, so a copy and a save carry it.
  # The inspector whose header I lead builds a fresh one whenever the divider before it splits along
  # another axis (InspectorWdgt._reconcileSplitGripNoSettle).
  axis: undefined

  # WHERE MY DRAG BEGAN, as one number along the divider's axis in its drag plane (the divider's
  # dragAnchorAt, asked at my drag's first move), or undefined at rest: cleared at my drag's end
  # (endOfNonFloatDrag), a moment of one stroke, which neither a copy nor a save carries
  _dragAnchor: undefined
  @serializationTransients: ["_dragAnchor"]
  @copyTransients: ["_dragAnchor"]

  # `axis` is my identity, my one positional parameter. My box is fixed, my band holding me at my own
  # size: splitButtonWidth along my axis by a chrome target's side across it -- across, 32 wide and 44
  # tall; turned, 44 wide and 32 tall.
  constructor: (@axis) ->
    super()
    theme = WorldWdgt.theme
    across = theme.splitButtonWidth
    along = theme.minimumTargetSize
    extent = if @_isTurned() then new Point along, across else new Point across, along
    @__commitExtent extent
    @setMinAndMaxBoundsAndSpreadability extent, extent, 0

  # am I TURNED a quarter, splitting heights under a divider that lies across ('y')?
  _isTurned: ->
    @axis is 'y'

  # WHERE I STAND DOWN A BAND (BandWdgt._pieceFor asks): turned, I hang from its TOP, so my top meets the
  # divider above my band's inspector with no gap, my band being taller than me; across, I am as tall as
  # my band and stand centred in it as any control does
  crossAlignInABand: ->
    if @_isTurned() then "start" else "center"

  # my look: a split's piece, one flat plate (LayoutChromeWdgt.createAppearance)
  createAppearance: -> new SplitPieceAppearance @

  # I am CHROME, as the divider is: a drag that starts on me sizes what the divider sizes, at once, for
  # a finger as for a mouse (ActivePointerWdgt._touchPressArmsAtOnce), and it never lifts me, nor my
  # inspector, out of where we stand
  ownsDragsStartingOnMe: -> true
  detachesWhenDragged: -> false
  grabsToParentWhenDragged: -> false

  # my hover shows the cursor my divider shows (LayoutChromeWdgt.hoverEntered): across a column
  # divider's split, down the strip's
  _resizeCursor: ->
    if @_isTurned() then "row-resize" else "col-resize"

  # the divider I drag: the nearest container of mine that can say (an inspector) says, or none
  _mySplitter: ->
    holder = @parent
    holder = holder.parent  until !holder? or holder.splitterMovedBy?
    holder?.splitterMovedBy @

  # the part joined to me (LayoutChromeWdgt._myJoinedPiece): the divider I hold, while it is the
  # divider I drag -- taken out of my header, or put after my title, I stand alone, though my
  # inspector introduced us (LayoutChromeWdgt.noteJoinedBy) and we part only by its rule
  _myJoinedPiece: ->
    @joinedPiece  if @joinedPiece? and @_mySplitter() is @joinedPiece

  # MY TEARDOWN: the divider joined to me must not name me once I am gone, so I tell it, and we part
  # (LayoutChromeWdgt.joinedPiece's rule), while I am still standing where I stood. In the core, not
  # the public destroy(): a bulk teardown (my inspector's, my window's) recurses core to core.
  _destroyNoSettle: ->
    @joinedPiece?.notePartedFrom @
    super

  # MY PLATE'S CORNERS (SplitPieceAppearance), at layoutChromePlateRadius, in the order top-left,
  # top-right, bottom-right, bottom-left: joined, the two against the divider square, so its edge runs
  # into mine with no step, and my two free ones -- across, my right side's; turned, my bottom side's --
  # rounded; alone, all four rounded
  _plateCornerRadii: ->
    radius = WorldWdgt.theme.layoutChromePlateRadius
    return radius  unless @_myJoinedPiece()?
    if @_isTurned() then [0, 0, radius, radius] else [0, radius, radius, 0]

  # MY MARK (SplitPieceAppearance paints it, in the divider's own ink): a field of the divider's grip
  # dots, at most splitButtonGripDots each way, centred on me across my axis and, along it, on the
  # WHOLE piece -- from the leading edge of the divider joined to me, its thickness before mine, to my
  # far edge: across, the field reaches the divider's width left of my left edge and is centred down my
  # height; turned, it reaches the divider's height above my top edge and is centred across my width. I
  # stand flush after the divider (I am my header's first piece, my header my inspector's first cell, my
  # inspector the divider's next cell, and the division stack gives the divider's far edge and my
  # inspector's near edge one boundary; turned, my band hangs me from its top). That thickness is the one
  # the divider's division box states (getDesiredDim), never the one it was laid out at: a division
  # stack rounds each boundary on its own, so a divider can lay out a px thicker or thinner by the
  # fraction its leading edge fell on, while the box's size is a FIELD, the same at every pass. So the
  # field stands where the piece's two sizes put it, whatever the rounding, and at these sizes I paint
  # all of it: four dots are 20 px (three pitches of 6 and a dot of 2), centred in the 44 px of the
  # divider's 12 and my 32 they start 12 px in, exactly at my near edge -- across, my left; turned, my
  # top -- and end 20 px into me. Alone, it is centred on me. Answered as [the field, the most dots
  # across and down] (Appearance._paintGripDots's field and opts).
  _gripDotFieldOnMyPlate: ->
    most = WorldWdgt.theme.splitButtonGripDots
    splitter = @_myJoinedPiece()
    if @_isTurned()
      reach = if splitter? then splitter.getDesiredDim().y else 0
      field = new Rectangle 0, (-reach), @width(), @height()
    else
      reach = if splitter? then splitter.getDesiredDim().x else 0
      field = new Rectangle (-reach), 0, @width(), @height()
    [field, {mostColumns: most, mostRows: most}]

  # A DRAG ON ME: the divider I drag sizes the cell before it (a column, or the strip of lists), by the
  # seam's solve, the one its own drag asks (InspectorDividerWdgt.nonFloatDragging): my drag's first
  # move, and any move while I hold no anchor, takes the anchor from the divider and moves nothing; every
  # later move hands the cell the size the divider's solve answers. The pointer the hand gives me is the
  # raw SCREEN point, mapped into the divider's drag plane on the line that reads it, and where I was
  # grabbed is no input (the solve counts travel), so the divider's drag and mine size the cell by the
  # same travel. The divider reads the point along its own axis, which is mine. A drag on me while I drag
  # no divider moves nothing.
  nonFloatDragging: (ignored_grabPointInMe, pos, deltaDragFromPreviousCall) ->
    divider = @_mySplitter()
    plane = divider?.dragPlane()
    return unless plane?
    point = plane.screenPointToMyPlane pos
    unless deltaDragFromPreviousCall? and @_dragAnchor?
      @_dragAnchor = divider.dragAnchorAt point
      return
    sized = divider.sizeDraggedTo @_dragAnchor, point
    # drag-move STREAM, as the divider's own: the _-private deferred-settle entrypoint check-layering [O]
    # restricts to stream handlers like this one, its layout flush riding the one end-of-cycle settle
    sized?.cell._setStatedSizeDeferredSettle sized.size

  # my drag is over: its anchor goes, and my base restores the cursor
  endOfNonFloatDrag: ->
    @_dragAnchor = undefined
    super
