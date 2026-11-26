# THE SET of an inspector browser (InspectorBrowserWdgt): the ROW OF COLUMNS its inspectors stand in,
# in the order of its sequence, and the column dividers between them. The browser owns the sequence and
# the rule of choice, and places each inspector it adds at my end (_addColumnNoSettle); I own the set's
# STRUCTURE. Built empty (`new InspectorRowWdgt()`): a subject is an inspector's, never mine.
#   I am the PLANE of my browser's set viewport (InspectorRowViewportWdgt), which clips me and scrolls
# me sideways. My columns, inspectors (InspectorWdgt), are the elements of a horizontal DIVISION row
# (StackLayoutEngine), a column divider between two of them (InspectorColumnDividerWdgt), and that
# arrange is all the layout I have. My viewport commits my MEASURE as my frame
# (scrolledContentMeasure), read from fields only: every column at the width it answers
# (InspectorWdgt.getDesiredDim: what its cells desire, or the width a person stated), every divider
# at its own, the whole never narrower than my viewport and exactly as tall; only my LAST column
# takes more than its own width (takesMySlack): the room my viewport has to spare and, while my
# columns overflow my viewport, as much more as stands the end of my scroll on a column's left edge
# (columnLefts). So no column narrows to fit my viewport: I overflow it, and it scrolls me. A
# divider's drag SIZES the one column on its left (states its width) and the columns right of it
# shift: nothing trades width between two columns, and in me a column's width is its own answer. A
# drag on a divider is measured in the plane my scroll leaves still (planeItsScrollLeavesStill). I
# paint nothing: my browser paints the BODY every inspector of mine stands on, and I say so to my parts
# (laysTheInspectorBodyUnderItsParts); a part of the tool standing anywhere else paints a body of its
# own (InspectorBodyAppearance).
#   My COLUMNS are my inspectors that are cells of my division row (columns): the ones its arrange
# lays out, and the only ones my measure, my rest points and my slack count. An inspector a person
# attaches to me free-floating (its developer menu's "Attach") stands where it was put, over my
# columns: no column of mine, in no sequence of my browser's, its choices opening a window of their own
# (InspectorBrowserWdgt.showChoice).
#   My DIVIDERS, my splitters, are derived from my columns, never placed by hand: exactly one
# between two columns that stand side by side, none anywhere else (_reconcileSplittersNoSettle),
# re-derived at every choice and whenever a child of mine leaves me, however it leaves -- a choice's
# removal, a person's "Pick up" or "Destroy" of an inspector or of a divider -- and each column then
# re-derives its split button from them, a button a person took out of its header (or put back after
# its title) included. A child a person attaches to me is no moment of its own: it waits for the next
# of those, an inspector attached to me as a cell of my row ("Attach with horizontal layout") standing
# as my last column with no divider until then. My CELLS, the only children that reconcile reads or
# touches, are my columns and my dividers (my division cells that answer a column divider's solve,
# columnWidthDraggedTo); any other child of mine (a halo's handle or its trading adjuster, an "Edit
# layout" slot, an inspector attached to me free-floating, a widget attached to me that is neither) is
# left where it is. Every reconcile ends by
# telling my browser, whose name is its first inspector's, that its first inspector may be another one
# (InspectorBrowserWdgt._noteFirstInspectorMayHaveChangedNoSettle): a person's "Pick up" of my first
# column reaches only me.
class InspectorRowWdgt extends Widget

  # am I being destroyed as a whole (_fullDestroyNoSettle)? Then a child of mine leaving me is my
  # teardown, and nothing of mine is reconciled or rebuilt on the way out (as FrameWdgt's flag)
  _beingFullDestroyed: undefined
  # is my reconcile running? Its own splitter removals tell me a child left, and must not reconcile
  # again inside it. True only inside one synchronous call, so no copy or save carries it true.
  _reconcilingSplitters: false

  # I lay the inspector's body under my parts: my browser paints it, under me and so under all of
  # them, so an inspector of mine paints none of its own (InspectorBodyAppearance asks, as it paints).
  laysTheInspectorBodyUnderItsParts: -> true

  # my COLUMNS, left to right: my children that are columns of mine (_isMyColumn: my other children
  # are splitters, or not mine to arrange). The one statement of my columns as my row lays them: my
  # browser's sequence is read from them (InspectorBrowserWdgt.inspectors), and so are where they stand
  # (columnLefts, in their order), which takes my slack (takesMySlack) and where a new one goes
  # (_addColumnNoSettle).
  columns: ->
    (child for child in @children when @_isMyColumn child)

  # Is `child` a COLUMN of mine: an inspector (it answers showsSubject) that is a cell of my division
  # row, which its arrange lays out (its spec a division element's)? An inspector standing free-floating
  # in me is none.
  _isMyColumn: (child) ->
    child.showsSubject? and (child.layoutSpec?.isDivisionElement?() is true)

  # MY MEASURE, which my viewport commits as my frame (it is content-sizing: InspectorRowViewportWdgt),
  # read from FIELDS and my viewport's own size only, never from where a cell of mine lies laid out (a
  # rule reading a size its own effect changes flip-flops). My CONTENT is my cells' desired widths
  # summed, the sum my division row's arrange lays out (Widget.getRecursiveDesiredDim), and
  # `viewWidth` is my viewport's width. I am the wider of the two; while my content is the wider, I am
  # widened to the first of my columns' left edges at or past the scroll that shows my content's end,
  # plus `viewWidth`, so the end of my scroll is that column's left edge and my last column takes the
  # extra room (takesMySlack). A last column wider than my viewport leaves no such edge, and I am then
  # my content wide. As tall as my viewport, at my own origin, which the commit never moves.
  scrolledContentMeasure: (viewWidth) ->
    content = Math.ceil @getRecursiveDesiredDim().x
    width = Math.max content, viewWidth
    if content > viewWidth
      end = (left for left in @columnLefts() when left >= content - viewWidth)[0]
      width = end + viewWidth  if end?
    new Rectangle @left(), @top(), @left() + width, @top() + @parent.height()

  # My measure is my WHOLE frame, committed verbatim (the scrolled-content contract, read by
  # ViewportWdgt._positionAndResizeChildren): it stands at my origin, at least my viewport's width and
  # exactly its height, so the commit's width floor and grow-to-fill have nothing to add.
  scrolledContentMeasureIsMyFrame: -> true

  # IS MY PLACE MY HOLDER'S, though no layout spec of mine says so? While I am my viewport's plane
  # (isMyContentsPanel, its role query): it commits my measure as my whole frame at its every arrange,
  # at my own origin, so a handle that moved me would leave me shifted inside it. The halo's climb asks
  # it (Widget._showResizeAndMoveHandlesAndLayoutAdjustersNoSettle): a column's "Resize/move…" goes on
  # past me and my viewport, to my browser's window, or to my browser standing with none. Standing
  # anywhere else I am free-floating as any widget, and the halo is mine.
  _placedByMyHolder: ->
    @parent?.isMyContentsPanel?(@) is true

  # My cells are placed in MY OWN layout pass, my division row's arrange, so a frame committed onto me
  # owes my re-lay: my viewport commits my measure silently and schedules my re-lay only for a plane
  # that says so (ViewportWdgt._positionAndResizeChildren), and my columns would otherwise stay placed
  # for my old width whenever my viewport is itself sized inside my browser's arrange. My own pass
  # lands on the box I hold, the one my viewport committed, so the two writers of my frame agree. Its
  # two other readers: a stack sizing me re-lays me at once (Widget._setWidthSizeHeightAccordingly),
  # and a holder merging its children's bounds takes my box, which my cells stand inside
  # (Widget.subWidgetsMergedFullBounds).
  implementsDeferredLayout: -> true

  # WHERE MY COLUMNS STAND, left to right: each one's left edge, from my own left, as my division row's
  # arrange lays it -- the desired widths of my cells before it, summed and rounded as the arrange
  # rounds a boundary (StackLayoutEngine). At my measure that arrange hands every cell but my last
  # column its desired width (a divider's box, as a column's, has no most beyond it: my last column
  # takes the whole spare), so the two agree. Read from fields only: my measure reads it for the end
  # of my scroll, and my viewport for the rest points its scroll comes to rest at
  # (InspectorRowViewportWdgt._restOffsets). One left per column of mine (_isMyColumn), in the order
  # of my columns, so the n-th left is the n-th column's.
  columnLefts: ->
    lefts = []
    sum = 0
    for cell in @children when cell.layoutSpec?.isDivisionElement?()
      lefts.push Math.round sum  if @_isMyColumn cell
      sum += cell.getDesiredDim().x
    lefts

  # Does `column` take my spare width? Exactly when it is my last column (columns: a cell of my
  # division row, never an inspector standing free-floating in me), whose most width then outgrows its
  # desired (InspectorWdgt.getMaxDim asks), so my division row's arrange hands it all the room my
  # measure gives beyond my cells' own widths. Read off my structure each time, never stored.
  takesMySlack: (column) ->
    column is @columns().pop()

  # `inspector` added after my last column, as an element of my row, then my splitters reconciled: a
  # divider between it and the column before it, and its split button. My browser places every
  # inspector it adds here (InspectorBrowserWdgt._placeNoSettle).
  _addColumnNoSettle: (inspector) ->
    last = @columns().pop()
    atIndex = if last? then @children.indexOf(last) + 1 else undefined
    @_addNoSettle inspector, atIndex: atIndex, layoutSpec: inspector.divisionBox()
    @_reconcileSplittersNoSettle()

  # MY CELLS: my children that are a column of mine or one of my splitters, in order -- the only
  # children my reconcile reads or touches
  _myCells: ->
    (child for child in @children when @_isMyColumn(child) or @_isMySplitter(child))

  # Is `child` a SPLITTER of mine, a column divider? Asked of the capability its users need, never of a
  # type: a cell of my division row that answers a column divider's solve (columnWidthDraggedTo), the
  # seam a split button asks of the divider before its inspector (SplitGripWdgt). Another cell that
  # takes a drag in place (a palette or a slider's button dropped on an "Edit layout" slot of mine)
  # answers no such solve, and neither does a trading adjuster the halo's "Resize/move…" adds beside an
  # inspector of mine (StackElementsSizeAdjustingWdgt), so neither is ever destroyed as a stray divider
  # nor dragged as one; an "Edit layout" slot is a cell that answers none either; a halo's handle and a
  # widget attached to me stand free.
  _isMySplitter: (child) ->
    (child.layoutSpec?.isDivisionElement?() is true) and child.columnWidthDraggedTo?

  # THE CELL JUST BEFORE `cell` among my cells, or undefined (first, or no cell of mine): an "Edit
  # layout" slot between the two is no cell of mine, so it does not stand between them
  _cellBefore: (cell) ->
    cells = @_myCells()
    cells[cells.indexOf(cell) - 1]

  # The divider standing before `inspector` among my cells, or undefined: what its split button drags
  # (InspectorWdgt._splitterBeforeMe asks).
  splitterBefore: (inspector) ->
    before = @_cellBefore inspector
    before  if before? and @_isMySplitter before

  # THE COLUMN `divider` SIZES, splitterBefore's twin: the cell just before it among my cells, when
  # that cell is a column of mine, or undefined. Asked by the divider as a drag on it, or on its split
  # button, begins and goes on (InspectorColumnDividerWdgt.columnDragAnchorAt, columnWidthDraggedTo).
  columnBefore: (divider) ->
    before = @_cellBefore divider
    before  if before?.showsSubject?

  # THE PLANE MY SCROLL LEAVES STILL: my viewport's while I am its plane (isMyContentsPanel, its role
  # query) -- its own plane excludes the scroll that translates me, so a point mapped into it stays put
  # as my scroll moves me -- or my own while I stand in no viewport (turned in a transform island, which
  # maps into me). A drag on a divider of mine is measured in it (InspectorColumnDividerWdgt.dragPlane):
  # at my scroll's far end a drag that narrows a column lets my viewport's clamp slide me under the
  # pointer, which a drag measured in my own plane would read as more travel.
  planeItsScrollLeavesStill: ->
    if @parent?.isMyContentsPanel?(@) then @parent else @

  # THE ONE RULE of my splitters: exactly one between two of my columns that stand side by side,
  # none anywhere else -- then each column re-derives its split button from it, and my browser is
  # told that its first inspector may be another one (what changed my children may have changed which
  # column is first: a person's "Pick up" of it), which is the browser's to judge, settling nothing.
  # Run under a flag, in a try/finally: the splitters it destroys tell me they left, and that must not
  # reconcile again inside this run. Builds nothing when nothing is out of place, so a child leaving me
  # in the middle of a layout pass (an "Edit layout" slot the pass takes away) finds nothing to do; a
  # split button a person took out is out of place, and its inspector rebuilds it only outside a pass
  # (InspectorWdgt._reconcileSplitGripNoSettle).
  _reconcileSplittersNoSettle: ->
    @_reconcilingSplitters = true
    try
      @_dropStraySplittersNoSettle()
      @_addMissingSplittersNoSettle()
      inspector._reconcileSplitGripNoSettle() for inspector in @columns()
      InspectorBrowserWdgt.holding(@)?._noteFirstInspectorMayHaveChangedNoSettle()
    finally
      @_reconcilingSplitters = false
    return

  # every splitter of mine that does not stand between two columns destroyed: one first among my
  # cells, one following another splitter, and one after my last column
  _dropStraySplittersNoSettle: ->
    kept = []
    for cell in @_myCells()
      if @_isMySplitter(cell) and !(kept[kept.length - 1]?.showsSubject?)
        cell._fullDestroyNoSettle()
      else
        kept.push cell
    last = kept[kept.length - 1]
    last._fullDestroyNoSettle()  if last? and @_isMySplitter last
    return

  # a column divider added between two of my columns that stand side by side among my cells
  _addMissingSplittersNoSettle: ->
    previous = undefined
    for cell in @_myCells()
      if cell.showsSubject? and previous?.showsSubject?
        splitter = new InspectorColumnDividerWdgt()
        @_addNoSettle splitter, atIndex: @children.indexOf(cell), layoutSpec: splitter.divisionBox()
      previous = cell
    return

  # A CHILD OF MINE LEFT ME (destroyed, or re-homed: a "Pick up", an "Attach", a drop into another
  # widget -- or re-added to me elsewhere, which also tells me). A splitter that left me, however it
  # left (my own reconcile's removals and my teardown included), is told so first, and parts from the
  # split button joined to it (StackElementsSizeAdjustingWdgt.noteLeftMyStack): it divides nothing of
  # mine. The rest not while I am destroyed or being destroyed as a whole, and not while my own
  # reconcile is removing it: an inspector that is no column of mine -- it LEFT me, not destroyed, or
  # came back into me free-floating -- re-derives its split button where it stands; then my splitters
  # are reconciled, which joins each column's button to the splitter before it.
  _reactToChildRemoved: (child) ->
    child.noteLeftMyStack?()
    return if @destroyed or @_beingFullDestroyed or @_reconcilingSplitters
    child._reconcileSplitGripNoSettle?()  unless child.destroyed or child in @columns()
    @_reconcileSplittersNoSettle()

  # Destroyed as a whole: flagged at entry, so every child my teardown destroys finds me being torn
  # down (_reactToChildRemoved) and nothing is built into a dying row.
  _fullDestroyNoSettle: ->
    @_beingFullDestroyed = true
    super
