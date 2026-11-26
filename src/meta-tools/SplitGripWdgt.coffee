# A SPLIT GRIP: the FINGER's way to size a column. I am a TAB on the column divider that stands before
# an inspector in an inspector browser's set (InspectorColumnDividerWdgt): a piece of layout chrome
# splitButtonWidth wide and a chrome target's side tall, standing at the left end of that inspector's
# header band, flush right of the divider, so the divider and I make one piece a chrome target's side
# across at the header (the 44 rule, visual-design-system §4.2: a target that must be big is drawn
# big), and a finger landing anywhere on it, on the divider beside me as on me, sizes the column on the
# divider's left. The divider alone is the mouse's way; we are both always there, since a device can
# have both. A drag on me sizes that column exactly as a drag on the divider does: the solve is the
# divider's own, its seam of three queries (dragPlane, columnDragAnchorAt, columnWidthDraggedTo), which
# its own drag asks too, and I map my own pointer, keep my own drag's anchor and make the column's
# write myself (nonFloatDragging). A press on me is kept where it lands (LayoutChromeWdgt.pressBegan),
# so the pane the set scrolls in never scrolls under my drag.
#   I hold no divider: I ask the inspector I stand in which divider I drag, as I am dragged and as I
# am painted (InspectorWdgt.splitterMovedBy, read off its row's children), and it answers only while I
# am its own split button and lead its header: a copy of me, my inspector taken out of its row, a
# button a person put after a title or into another inspector's header, or one on the desktop drags
# nothing.
#   My look is a split's piece (SplitPieceAppearance): one flat plate, and on it a field of the
# divider's own grip dots. Joined to that divider (we hold each other: LayoutChromeWdgt.joinedPiece,
# whose rule says when we join and part) we are painted as one piece: my corners against it square, my
# two free ones rounded, the field centred on the whole piece, and a hover or a press on either of us
# lights both. Alone, my four corners are rounded and the field is centred on me. A drop on me is
# refused, as on every plain widget.
class SplitGripWdgt extends LayoutChromeWdgt

  # WHERE MY DRAG BEGAN, as one number along the divider's drag plane (the divider's
  # columnDragAnchorAt, asked at my drag's first move), or undefined at rest: cleared at my drag's end
  # (endOfNonFloatDrag), a moment of one stroke, which neither a copy nor a save carries
  _columnDragAnchor: undefined
  @serializationTransients: ["_columnDragAnchor"]
  @copyTransients: ["_columnDragAnchor"]

  # My box is splitButtonWidth by a chrome target's side, fixed: my band holds me at my own size.
  constructor: ->
    super()
    theme = WorldWdgt.theme
    extent = new Point theme.splitButtonWidth, theme.minimumTargetSize
    @__commitExtent extent
    @setMinAndMaxBoundsAndSpreadability extent, extent, 0

  # my look: a split's piece, one flat plate (LayoutChromeWdgt.createAppearance)
  createAppearance: -> new SplitPieceAppearance @

  # I am CHROME, as the divider is: a drag that starts on me sizes the divider's column, at once, for a
  # finger as for a mouse (ActivePointerWdgt._touchPressArmsAtOnce), and it never lifts me, nor my
  # inspector, out of where we stand
  ownsDragsStartingOnMe: -> true
  detachesWhenDragged: -> false
  grabsToParentWhenDragged: -> false

  # my hover shows the cursor a column divider shows (LayoutChromeWdgt.hoverEntered)
  _resizeCursor: -> "col-resize"

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

  # MY PLATE'S CORNERS (SplitPieceAppearance), at layoutChromePlateRadius: joined, the two against the
  # divider square, so its edge runs into mine with no step, and my two free ones -- my right side's
  # -- rounded; alone, all four rounded
  _plateCornerRadii: ->
    radius = WorldWdgt.theme.layoutChromePlateRadius
    if @_myJoinedPiece()? then [0, radius, radius, 0] else radius

  # MY MARK (SplitPieceAppearance paints it, in the divider's own ink): a field of the divider's grip
  # dots, at most splitButtonGripDots each way, down me centred on my height and across centred on the
  # WHOLE piece -- from the leading edge of the divider joined to me, its width left of mine, to my far
  # edge. I stand flush after the divider (I am my header's first piece, my header my inspector's first
  # cell, my inspector the divider's next cell, and the division row gives the divider's far edge and my
  # inspector's near edge one boundary). That width is the one the divider's division box states
  # (getDesiredDim), never the width it was laid out at: the division row rounds each boundary on its
  # own, so a divider can lay out a px wider or narrower by the fraction its leading edge fell on, while
  # the box's width is a FIELD, the same at every pass. So the field stands where the piece's two
  # widths put it, whatever the rounding, at these sizes exactly from my left edge, and I paint all of
  # it. Alone, it is centred on me. Answered as [the field, the most dots across and down]
  # (Appearance._paintGripDots's field and opts).
  _gripDotFieldOnMyPlate: ->
    most = WorldWdgt.theme.splitButtonGripDots
    splitter = @_myJoinedPiece()
    reach = if splitter? then splitter.getDesiredDim().x else 0
    [(new Rectangle (-reach), 0, @width(), @height()), {mostColumns: most, mostRows: most}]

  # A DRAG ON ME: the divider I drag sizes the column on its left, by the seam's solve, the one its own
  # drag asks (InspectorColumnDividerWdgt.nonFloatDragging): my drag's first move, and any move while I
  # hold no anchor, takes the anchor from the divider and moves nothing; every later move hands the
  # column the width the divider's solve answers. The pointer the hand gives me is the raw SCREEN point,
  # mapped into the divider's drag plane on the line that reads it, and where I was grabbed is no input
  # (the solve counts travel), so the divider's drag and mine size the column by the same travel. A
  # drag on me while I drag no divider moves nothing.
  nonFloatDragging: (ignored_grabPointInMe, pos, deltaDragFromPreviousCall) ->
    divider = @_mySplitter()
    plane = divider?.dragPlane()
    return unless plane?
    along = (plane.screenPointToMyPlane pos).x
    unless deltaDragFromPreviousCall? and @_columnDragAnchor?
      @_columnDragAnchor = divider.columnDragAnchorAt along
      return
    sized = divider.columnWidthDraggedTo @_columnDragAnchor, along
    # drag-move STREAM, as the divider's own: the _-private deferred-settle entrypoint check-layering [O]
    # restricts to stream handlers like this one, its layout flush riding the one end-of-cycle settle
    sized?.column._setColumnWidthDeferredSettle sized.width

  # my drag is over: its anchor goes, and my base restores the cursor
  endOfNonFloatDrag: ->
    @_columnDragAnchor = undefined
    super
