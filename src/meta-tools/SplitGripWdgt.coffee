# A SPLIT GRIP: the FINGER's way to move a split. I am a 44 x 44 piece of layout chrome (the 44
# rule, visual-design-system §4.2: a target that must be big is drawn big) standing at the left end
# of an inspector's header band, right of the splitter that stands before that inspector. The
# splitter itself is the mouse's way; we are both always there, since a device can have both. A drag
# on me moves that splitter's split exactly as a drag on the splitter does: the split's arithmetic is
# the splitter's own (StackElementsSizeAdjustingWdgt.maxDimsPuttingMyLeadingEdgeAt), and I only say
# where its leading edge should be.
#   I hold no splitter: I ask the inspector I stand in which one stands before it, as I am dragged
# (InspectorWdgt.splitterBeforeMe, read off its row's children), so a copy of me, or my inspector
# taken out of its row, drags nothing that is not its own.
#   My look is the layout chrome's (LayoutChromeWdgt, LayoutChromeAppearance): its plate, in the look
# of my pointer state, and on it the double arrow across, as a layout spacer shows it. A drop on me
# is refused, as on every plain widget.
class SplitGripWdgt extends LayoutChromeWdgt

  # My box is a chrome target's side square, fixed: my band holds me at my own size.
  constructor: ->
    super()
    side = WorldWdgt.theme.minimumTargetSize
    extent = new Point side, side
    @__commitExtent extent
    @setMinAndMaxBoundsAndSpreadability extent, extent, 0

  # I am CHROME, as the splitter is: a drag that starts on me moves my split, at once, for a finger as
  # for a mouse (ActivePointerWdgt._touchPressArmsAtOnce), and it never lifts me, nor my inspector,
  # out of where we stand
  ownsDragsStartingOnMe: -> true
  detachesWhenDragged: -> false
  grabsToParentWhenDragged: -> false

  # MY GLYPH (LayoutChromeWdgt._glyphOnMyPlate): the double arrow across, in layoutChromeGlyph at
  # layoutSpacerGlyphSize, centred on my plate, as a layout spacer in a row shows it
  _glyphOnMyPlate: ->
    theme = WorldWdgt.theme
    [(new DoubleArrowIconAppearance @, theme.layoutChromeGlyph), theme.layoutSpacerGlyphSize]

  # my hover shows the cursor a row's splitter shows (LayoutChromeWdgt.hoverEntered)
  _resizeCursor: -> "col-resize"

  # the splitter before the inspector I stand in: the nearest container of mine that can say
  _mySplitter: ->
    holder = @parent
    holder = holder.parent  until !holder? or holder.splitterBeforeMe?
    holder?.splitterBeforeMe()

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
