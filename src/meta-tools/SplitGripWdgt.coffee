# A SPLIT GRIP: the FINGER's way to move a split. I am a TAB on the splitter that stands before an
# inspector: a piece of layout chrome splitButtonWidth wide and a chrome target's side tall, standing
# at the left end of that inspector's header band, flush right of the splitter, so the splitter and I
# make one piece a chrome target's side across at the header (the 44 rule, visual-design-system §4.2:
# a target that must be big is drawn big), and a finger landing anywhere on it, on the splitter beside
# me as on me, moves the split. The splitter alone is the mouse's way; we are both always there, since
# a device can have both. A drag on me moves that splitter's split exactly as a drag on the splitter
# does: the split's arithmetic is the splitter's own
# (StackElementsSizeAdjustingWdgt.maxDimsPuttingMyLeadingEdgeAt), and I only say where its leading
# edge should be.
#   I hold no splitter: I ask the inspector I stand in which splitter I move, as I am dragged and as I
# am painted (InspectorWdgt.splitterMovedBy, read off its row's children), and it answers only while I
# am its own split button and lead its header: a copy of me, my inspector taken out of its row, a
# button a person put after a title or into another inspector's header, or one on the desktop drags
# nothing.
#   My look is a split's piece (SplitPieceAppearance): one flat plate, and on it a field of the
# splitter's own grip dots. Joined to that splitter (we hold each other: LayoutChromeWdgt.joinedPiece,
# whose rule says when we join and part) we are painted as one piece: my corners against it square, my
# two free ones rounded, the field centred on the whole piece, and a hover or a press on either of us
# lights both. Alone, my four corners are rounded and the field is centred on me. A drop on me is
# refused, as on every plain widget.
class SplitGripWdgt extends LayoutChromeWdgt

  # My box is splitButtonWidth by a chrome target's side, fixed: my band holds me at my own size.
  constructor: ->
    super()
    theme = WorldWdgt.theme
    extent = new Point theme.splitButtonWidth, theme.minimumTargetSize
    @__commitExtent extent
    @setMinAndMaxBoundsAndSpreadability extent, extent, 0

  # my look: a split's piece, one flat plate (LayoutChromeWdgt.createAppearance)
  createAppearance: -> new SplitPieceAppearance @

  # I am CHROME, as the splitter is: a drag that starts on me moves my split, at once, for a finger as
  # for a mouse (ActivePointerWdgt._touchPressArmsAtOnce), and it never lifts me, nor my inspector,
  # out of where we stand
  ownsDragsStartingOnMe: -> true
  detachesWhenDragged: -> false
  grabsToParentWhenDragged: -> false

  # my hover shows the cursor a row's splitter shows (LayoutChromeWdgt.hoverEntered)
  _resizeCursor: -> "col-resize"

  # the splitter I move: the nearest container of mine that can say (an inspector) says, or none
  _mySplitter: ->
    holder = @parent
    holder = holder.parent  until !holder? or holder.splitterMovedBy?
    holder?.splitterMovedBy @

  # the part joined to me (LayoutChromeWdgt._myJoinedPiece): the divider I hold, while it is the
  # splitter I move -- taken out of my header, or put after my title, I stand alone, though my
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
  # splitter square, so its edge runs into mine with no step, and my two free ones -- my right side's
  # -- rounded; alone, all four rounded
  _plateCornerRadii: ->
    radius = WorldWdgt.theme.layoutChromePlateRadius
    if @_myJoinedPiece()? then [0, radius, radius, 0] else radius

  # MY MARK (SplitPieceAppearance paints it, in the splitter's own ink): a field of the splitter's
  # grip dots, at most splitButtonGripDots each way, down me centred on my height and across centred
  # on the WHOLE piece -- from the leading edge of the splitter joined to me, its width left of mine,
  # to my far edge. That width is the one the splitter's division box states (getDesiredDim), the
  # width the split's solve sums, never the width it was laid out at, which a division row's rounding
  # can make a px wider or narrower (nonFloatDragging, below, says why): so the field stands where the
  # piece's two widths put it, whatever the rounding, at these sizes exactly from my left edge, and I
  # paint all of it. Alone, it is centred on me. Answered as [the field, the most dots across and
  # down] (Appearance._paintGripDots's field and opts).
  _gripDotFieldOnMyPlate: ->
    most = WorldWdgt.theme.splitButtonGripDots
    splitter = @_myJoinedPiece()
    reach = if splitter? then splitter.getDesiredDim().x else 0
    [(new Rectangle (-reach), 0, @width(), @height()), {mostColumns: most, mostRows: most}]

  # A drag on me: the split moves so that the splitter's LEADING EDGE lands where the pointer, less
  # where I was grabbed, less the splitter's own width says. I stand flush after the splitter (I am
  # my header's first piece, my header my inspector's first cell, my inspector the splitter's next
  # cell, and the division row gives the splitter's far edge and my inspector's near edge one
  # boundary), so my left edge is the splitter's leading edge plus its width, to within the rounding
  # of that one boundary.
  #   That width is the one the splitter's division BOX states (getDesiredDim), never the width it was
  # laid out at: the division row rounds each boundary on its own, so a splitter lays out a px wider
  # or narrower by the fraction its leading edge fell on at the LAST layout pass, and a drag drains
  # many moves against one end-of-cycle pass, so which pass was last when a move is handled depends
  # on how many moves a frame drained -- a laid-out width would move the wanted edge by a px with the
  # event cadence. The box's width is a FIELD, the same on every move of a frame, and it is the
  # splitter's width as the solve itself sums it (its desired width), so the edge I hand it is in the
  # solve's own terms, as the splitter's handler reads only box fields. For the same reason I read no
  # laid-out position at all. The splitter and I stand in one plane -- the row's: an inspector a
  # transform turns stands in an island, in no row, and shows no grip -- so the edge I map my pointer
  # to is the edge the splitter solves for.
  #   A row divides its width, so only x moves. The rest is the splitter's handler's: the same "no
  # move yet" guard, the same query, and the two deferred settles of a drag-move stream.
  nonFloatDragging: (grabPointInMe, pos, deltaDragFromPreviousCall) ->
    return unless deltaDragFromPreviousCall?
    splitter = @_mySplitter()
    return unless splitter?
    wantedLeadingEdge = (@screenPointToMyPlane pos).x - grabPointInMe.x - splitter.getDesiredDim().x
    split = splitter.maxDimsPuttingMyLeadingEdgeAt wantedLeadingEdge
    return unless split?
    # drag-move STREAM, as the splitter's own (StackElementsSizeAdjustingWdgt.nonFloatDragging): the
    # _-private deferred-settle entrypoint, restricted to stream handlers like this one by
    # check-layering [O], declaring intentional per-move deferred settling onto the one end-of-cycle flush
    split.before._setMaxDimDeferredSettle split.beforeMax
    split.after._setMaxDimDeferredSettle split.afterMax
