# A DIVIDER of an inspector browser (InspectorBrowserWdgt): the mouse's way to size the cell standing
# just BEFORE me along my axis (splitAxis, my division spec's), a STATED size, never a trade. Two
# holders stand me, each saying which cell I size (cellSizedBy):
#   between two columns of the browser's set (InspectorRowWdgt, across), I size the column on my LEFT:
# a drag on me states that column's width (InspectorWdgt.statedWidth). The columns right of it shift,
# each at its own width, but for the set's last column, which takes whatever room the others leave (the
# set is the wider of its columns and its viewport: InspectorRowWdgt.scrolledContentMeasure,
# takesMySlack);
#   between the browser's set and its body below (the browser's own division stack, down), I size the
# STRIP OF LISTS above me, the set's viewport: a drag on me states its height (its division box's desired
# and most: InspectorRowViewportWdgt._setStatedSizeNoSettle), and the body below me takes every pixel
# the strip leaves, so the person's split stands when the window is resized. The browser caps that
# height so its whole stack still fits it at every cell's desired size (mostSizeOf: the regime where the
# strip lies at exactly its desired height), so I stay under the pointer down to the body's least.
#   Either way the size is the size the cell had as my drag began plus the pointer's travel since, in
# whole px, never below the cell's least size, never above the most its holder allows; and where that
# most is no more than the cell's least (a browser no taller than its cells' least sizes, whose stack
# squeezes every cell) a drag states nothing, so the size the person stated stands for when the window
# grows back. Nothing trades
# size between the two cells beside me, which is what the adjuster of every other division stack does
# (StackElementsSizeAdjustingWdgt, whose look, thickness, cursor by axis, joined split button and
# departure from its stack I keep, and whose kind I am, so the halo's "Resize/move…" adds no trading
# adjuster beside me: Widget._showResizeAndMoveHandlesAndLayoutAdjustersNoSettle asks the kind).
#   THE SOLVE reads two things fixed as the drag begins -- where the pointer stood along the plane my
# holder's scroll leaves still (for a column, my set's viewport's, never the set's own, which the scroll
# translates; for the strip, my browser's own, which nothing scrolls) and the cell's size then -- and
# the pointer, never a laid-out position nor a scroll offset. At the far end of the set's scroll a drag
# that narrows a column lets the viewport's clamp slide the set under the pointer: measured in the set's
# own plane, that slide would read as more travel and run the column down to its least width in a few
# frames; measured in the still plane, the column narrows by the pointer's travel alone, and the clamp
# moves the view, never the width.
#   THE SEAM: three queries on me (dragPlane, dragAnchorAt, sizeDraggedTo), each taking the pointer as a
# point and reading it along my axis, that my own drag and the split button joined to me both ask
# (SplitGripWdgt, the finger's way: the tab at the head of the column on my right, or at the left end of
# the body's header below me). Each of the two handlers maps its own pointer into dragPlane on the line
# that reads it, keeps the anchor its own drag began at, and makes the cell's one deferred-settle write
# itself (_setStatedSizeDeferredSettle, which a column and the strip both answer), as the house's two
# rules on a drag handler require (check-plane-discipline C2, check-layering [O]): one solve, two
# handlers, never one handler relayed to the other.
#   My box is exactly my thickness on both sides, its most no more (spreadability 0), so a division
# arrange I stand in hands its spare room to its other cells alone. A press on me is kept where it lands
# (LayoutChromeWdgt.pressBegan), so the pane my set scrolls in never scrolls under my drag.
class InspectorDividerWdgt extends StackElementsSizeAdjustingWdgt

  # WHERE MY DRAG BEGAN, as one number along my axis in my drag plane: the pointer's place there at my
  # drag's first move, less the size of the cell I size then (dragAnchorAt), or undefined at rest. Set
  # by my drag's first move and cleared at its end (endOfNonFloatDrag): a moment of one stroke, which
  # neither a copy nor a save carries.
  _dragAnchor: undefined
  @serializationTransients: ["_dragAnchor"]
  @copyTransients: ["_dragAnchor"]

  #: initialization

  # my box, my base's thickness each way, with no most beyond it (my header says why)
  constructor: ->
    super()
    thickness = WorldWdgt.theme.layoutAdjusterThickness
    @setMinAndMaxBoundsAndSpreadability (new Point thickness, thickness), (new Point thickness, thickness), 0

  #: splitting

  # THE CELL I SIZE: my holder's answer (cellSizedBy: my set's column just before me, or my browser's
  # set's viewport just above me), or undefined -- a divider picked out of its holder, or standing
  # anywhere else, sizes nothing
  _cellISize: ->
    @parent?.cellSizedBy? @

  # `point`'s coordinate along my axis (splitAxis): across, x; down, y
  _along: (point) ->
    if @splitAxis() is 'y' then point.y else point.x

  # THE MOST `cell` MAY TAKE along my axis, as my holder states it (mostSizeOf: my browser, so its stack
  # still fits it at every cell's desired size), or undefined for no cap (my set: a column overflows it)
  _mostSizeOf: (cell) ->
    @parent?.mostSizeOf? cell

  # THE PLANE A DRAG ON ME, OR ON MY SPLIT BUTTON, IS MEASURED IN: the one my holder's scroll leaves
  # still (planeItsScrollLeavesStill: my set's viewport's, or my browser's own), or undefined standing in
  # neither. A query of the seam.
  dragPlane: ->
    @parent?.planeItsScrollLeavesStill?()

  # A DRAG'S ANCHOR, a query of the seam: for a drag that begins with the pointer at `point` (in
  # dragPlane), where the leading edge of the cell I size stands along my axis in that plane -- the
  # pointer's place along it less the size that cell lies at as its FIELDS state it: its desired size
  # (getDesiredDim: a column's stated width, else its natural one, which is the width it lies at, since
  # only my set's last column takes more and a column I size has me after it; the strip's stated height,
  # never below the least a column of its set needs: InspectorRowViewportWdgt.getDesiredDim),
  # down to the most my holder allows (_mostSizeOf). My browser's division stack has three regimes
  # (StackLayoutEngine), and the strip lies at that answer in the two a drag can size it in: with room
  # for every cell's desired (the third), at its desired, which is never above that most; with room for
  # every cell's least but not for every desired (the second), at that most exactly, since each of its
  # other cells needs what it desires (their least and desired are one), so the whole shortfall is the
  # strip's. With room for no more than every cell's least (the first) every cell lies at its least or
  # below it, whatever height the strip states, and the most is then no more than the strip's least: my
  # solve states nothing there (sizeDraggedTo), so no drag reads this anchor. Undefined while I size no
  # cell.
  dragAnchorAt: (point) ->
    cell = @_cellISize()
    return unless cell?
    size = @_along cell.getDesiredDim()
    most = @_mostSizeOf cell
    size = Math.min size, most  if most?
    @_along(point) - size

  # THE ONE SOLVE, a query of the seam both drags ask: the cell I size, and its size along my axis for a
  # drag that began at `anchor` (dragAnchorAt) and has the pointer at `point` (in dragPlane) -- the size
  # it had then plus the travel since, in whole px, never above the most my holder allows
  # (_mostSizeOf), never below its least size (that least taken up to a whole px) -- as {cell, size};
  # undefined while I size no cell or the drag has no anchor, and undefined while that most is no more
  # than that least: my holder is then no taller than its cells' least sizes summed (my browser's
  # division stack in its first regime, every cell at or below its least: dragAnchorAt says why the
  # two meet there), no size I could state would change what shows, and stating the least would lose
  # the size the person stated for when it grows back, so I state nothing and it stands. It reads the
  # pointer and the cells' fields only, and changes nothing.
  sizeDraggedTo: (anchor, point) ->
    cell = @_cellISize()
    return unless cell? and anchor?
    least = Math.ceil @_along cell.getMinDim()
    most = @_mostSizeOf cell
    return  if most? and most <= least
    size = Math.round(@_along(point) - anchor)
    size = Math.min most, size  if most?
    {cell: cell, size: Math.max least, size}

  #: event handling

  # A DRAG ON ME: the seam's solve (my header). My drag's first move, and any move while I hold no
  # anchor, takes the anchor and moves nothing; every later move hands the cell the size the solve
  # answers. The pointer the hand gives me is the raw SCREEN point, mapped on the line that reads it;
  # where I was grabbed is no input (the solve counts travel).
  nonFloatDragging: (ignored_grabPointInMe, pos, deltaDragFromPreviousCall) ->
    plane = @dragPlane()
    return unless plane?
    point = plane.screenPointToMyPlane pos
    unless deltaDragFromPreviousCall? and @_dragAnchor?
      @_dragAnchor = @dragAnchorAt point
      return
    sized = @sizeDraggedTo @_dragAnchor, point
    # drag-move STREAM: the _-private deferred-settle entrypoint check-layering [O] restricts to stream
    # handlers like this one, its layout flush riding the one end-of-cycle settle
    sized?.cell._setStatedSizeDeferredSettle sized.size

  # my drag is over: its anchor goes, and my base restores the cursor
  endOfNonFloatDrag: ->
    @_dragAnchor = undefined
    super
