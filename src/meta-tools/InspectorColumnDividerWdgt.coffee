# A COLUMN DIVIDER: the strip between two columns of an inspector browser's set (InspectorRowWdgt),
# the mouse's way to size the column on my LEFT. A drag on me states that column's width
# (InspectorWdgt.statedWidth): the width it had as my drag began, plus the pointer's travel since, in
# whole px, never below the column's least width. The columns right of it shift, each at its own width,
# but for the set's last column, which takes whatever room the others leave (the set is the wider of
# its columns and its viewport: InspectorRowWdgt.scrolledContentMeasure, takesMySlack). Nothing trades
# width between the two cells beside me, which is what the adjuster of every other division stack does
# (StackElementsSizeAdjustingWdgt, whose look, thickness, cursor, joined split button and departure
# from its stack I keep, and whose kind I am, so the halo's "Resize/move…" adds no trading adjuster
# beside me: Widget._showResizeAndMoveHandlesAndLayoutAdjustersNoSettle asks the kind).
#   THE SOLVE reads two things fixed as the drag begins -- where the pointer stood along the plane my
# set's scroll leaves still (my set's viewport's, never the set's own, which the scroll translates)
# and the column's width then -- and the pointer, never a laid-out position nor a scroll offset. At the
# far end of the set's scroll a drag that narrows the column lets the viewport's clamp slide the set
# under the pointer: measured in the set's own plane, that slide would read as more travel and run the
# column down to its least width in a few frames; measured in the still plane, the column narrows by
# the pointer's travel alone, and the clamp moves the view, never the width.
#   THE SEAM: three queries on me (dragPlane, columnDragAnchorAt, columnWidthDraggedTo) that my own
# drag and the split button joined to me both ask (SplitGripWdgt, the finger's way, the tab at the
# head of the column on my right). Each of the two handlers maps its own pointer into dragPlane on the
# line that reads it, keeps the anchor its own drag began at, and makes the column's one deferred-settle
# write itself, as the house's two rules on a drag handler require (check-plane-discipline C2,
# check-layering [O]): one solve, two handlers, never one handler relayed to the other.
#   My box is exactly my thickness on both sides, its most no more (spreadability 0), so my set's
# division arrange hands its spare room to its last column alone. A press on me is kept where it lands
# (LayoutChromeWdgt.pressBegan), so the pane my set scrolls in never scrolls under my drag.
class InspectorColumnDividerWdgt extends StackElementsSizeAdjustingWdgt

  # WHERE MY DRAG BEGAN, as one number along my drag plane: the pointer's place there at my drag's first
  # move, less the width of the column I size then (columnDragAnchorAt), or undefined at rest. Set by my
  # drag's first move and cleared at its end (endOfNonFloatDrag): a moment of one stroke, which neither
  # a copy nor a save carries.
  _columnDragAnchor: undefined
  @serializationTransients: ["_columnDragAnchor"]
  @copyTransients: ["_columnDragAnchor"]

  # my box, my base's thickness each way, with no most beyond it (my header says why)
  constructor: ->
    super()
    thickness = WorldWdgt.theme.layoutAdjusterThickness
    @setMinAndMaxBoundsAndSpreadability (new Point thickness, thickness), (new Point thickness, thickness), 0

  # THE COLUMN I SIZE: the cell just before me among my set's cells, when it is a column
  # (InspectorRowWdgt.columnBefore), or undefined -- a divider picked out of its set, or standing
  # anywhere else, sizes nothing
  _columnISize: ->
    @parent?.columnBefore? @

  # THE PLANE A DRAG ON ME, OR ON MY SPLIT BUTTON, IS MEASURED IN: the one my set's scroll leaves still
  # (InspectorRowWdgt.planeItsScrollLeavesStill), or undefined standing in no set. A query of the seam.
  dragPlane: ->
    @parent?.planeItsScrollLeavesStill?()

  # A DRAG'S ANCHOR, a query of the seam: for a drag that begins with the pointer at `along` (in
  # dragPlane), where the left edge of the column I size stands along that plane -- `along` less that
  # column's width as its FIELDS state it (getDesiredDim: its stated width, else its natural one, which
  # is the width it lies at, since only my set's last column takes more and a column I size has me after
  # it). Undefined while I size no column.
  columnDragAnchorAt: (along) ->
    column = @_columnISize()
    along - column.getDesiredDim().x  if column?

  # THE ONE SOLVE, a query of the seam both drags ask: the column I size, and its width for a drag that
  # began at `anchor` (columnDragAnchorAt) and has the pointer at `along` (in dragPlane) -- the width it
  # had then plus the travel since, in whole px, never below its least width (that least taken up to a
  # whole px) -- as {column, width}; undefined while I size no column or the drag has no anchor. It
  # reads the pointer and the column's fields only, and changes nothing.
  columnWidthDraggedTo: (anchor, along) ->
    column = @_columnISize()
    return unless column? and anchor?
    width = Math.max (Math.ceil column.getMinDim().x), Math.round(along - anchor)
    {column: column, width: width}

  # A DRAG ON ME: the seam's solve (my header). My drag's first move, and any move while I hold no
  # anchor, takes the anchor and moves nothing; every later move hands the column the width the solve
  # answers. The pointer the hand gives me is the raw SCREEN point, mapped on the line that reads it;
  # where I was grabbed is no input (the solve counts travel).
  nonFloatDragging: (ignored_grabPointInMe, pos, deltaDragFromPreviousCall) ->
    plane = @dragPlane()
    return unless plane?
    along = (plane.screenPointToMyPlane pos).x
    unless deltaDragFromPreviousCall? and @_columnDragAnchor?
      @_columnDragAnchor = @columnDragAnchorAt along
      return
    sized = @columnWidthDraggedTo @_columnDragAnchor, along
    # drag-move STREAM: the _-private deferred-settle entrypoint check-layering [O] restricts to stream
    # handlers like this one, its layout flush riding the one end-of-cycle settle
    sized?.column._setColumnWidthDeferredSettle sized.width

  # my drag is over: its anchor goes, and my base restores the cursor
  endOfNonFloatDrag: ->
    @_columnDragAnchor = undefined
    super
