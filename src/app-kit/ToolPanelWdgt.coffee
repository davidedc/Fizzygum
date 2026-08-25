class ToolPanelWdgt extends PanelWdgt

  # the grid's cell gap / outer margin / cell side -- read from the toolInternalPadding /
  # toolExternalPadding / toolThumbnailSize preferences in the constructor rather than declared
  # as literals here, because a caller (e.g. TextToolbarWdgt) writes these fields directly on an
  # instance to retune its own strip -- an instance field a subclass overrides after construction,
  # not a class-level constant.
  internalPadding: undefined
  externalPadding: undefined
  thumbnailSize: undefined

  # the trailing chevron my arrange shows when my cells outrun my strip (ruling T2, absorbed
  # into the single geometry): a strip shows the prefix that fits and this pops the remainder as
  # a menu. Declared so duplication carries the handle.
  overflowChevron: undefined

  constructor: ->
    super()
    @internalPadding = WorldWdgt.preferencesAndSettings.toolInternalPadding
    @externalPadding = WorldWdgt.preferencesAndSettings.toolExternalPadding
    @thumbnailSize = WorldWdgt.preferencesAndSettings.toolThumbnailSize

  # my enclosing viewport borrows my colloquial name (type-test-elimination ε; see
  # ViewportWdgt.colloquialName)
  viewportColloquialName: ->
    "toolbar"

  # ONE settle over the whole bundle; each core's _invalidateLayout is deduped by
  # layoutIsValid, so N adds still cost one flush.
  addMany: (widgetsToBeAdded) ->
    @_settleLayoutsAfter => @_addManyNoSettle widgetsToBeAdded

  # NON-settling core (mirror of _addNoSettle): the COMPLETE addMany minus the settle. A core building a tools
  # panel (createToolsPanel) loop-adds through this so the whole bundle rides ONE enclosing flush; each
  # _addNoSettle's _invalidateLayout is deduped by layoutIsValid, so N adds still cost one flush.
  _addManyNoSettle: (widgetsToBeAdded) ->
    for eachWidget in widgetsToBeAdded
      @_addNoSettle eachWidget
    return

  # Public add self-settles over the non-settling core (the Widget /
  # VerticalStackPanelWdgt add/_addNoSettle pattern); the pre-convert shape is in
  # docs/archive/layout-optimizations-and-oo-cleanup-plan.md.
  add: (aWdgt, opts = {}) ->
    @_settleLayoutsAfter => @_addNoSettle aWdgt, opts

  _addNoSettle: (aWdgt, opts = {}) ->
    positionInPlane = opts.positionInPlane

    # annotation + handle both attach to the viewport directly (was their two instanceof)
    # (type-test-elimination campaign). The overflow chevron is CHROME I build and place
    # myself, so it joins as itself rather than as a wrapped tool thumbnail.
    if aWdgt.attachesToViewportDirectly?() or aWdgt is @overflowChevron
      super aWdgt, opts
    else
      # if aWdgt specifies a non-default switcharoo then it
      # means it's like the TextBoxCreatorButtonWdgt, which creates a textbox
      # when dragged. So in that case we DON'T set it as a template
      # otherwise we do.
      if aWdgt.grabbedWidgetSwitcheroo == Widget::grabbedWidgetSwitcheroo
        aWdgt.isTemplate = true

      if !aWdgt.extentToGetWhenDraggedFromGlassBox?
        aWdgt.extentToGetWhenDraggedFromGlassBox = aWdgt.extent()

      if !(aWdgt.isGlassBoxWrapper?())
        glassBoxBottom = new GlassBoxBottomWdgt
        glassBoxBottom.add aWdgt

        if !aWdgt.actionableAsThumbnail
          glassBoxTop = new GlassBoxTopWdgt
          glassBoxTop.toolTipMessage = aWdgt.toolTipMessage
          glassBoxBottom.add glassBoxTop

        glassBoxBottom._applyMoveTo @topLeft().add new Point @externalPadding, @externalPadding
        # TODO anti-pattern - this _applyExtent should be called within _reLayout, not here
        glassBoxBottom._applyExtent new Point @thumbnailSize, @thumbnailSize
        glassBoxBottom._invalidateLayout()

        aWdgt = glassBoxBottom


      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      dropSlot = @_findDropSlot positionInPlane, childrenNotHandlesNorCarets

      if dropSlot?
        super aWdgt, Object.assign {}, opts, atIndex: dropSlot
      else
        # no drop position (a programmatic add): append after the existing icons
        super aWdgt, opts

      @_invalidateLayout()

  # The inherited seam re-fits my holder whenever a child leaves me, because a child leaving is
  # normally a GESTURE and my content really did change. The overflow chevron is neither: it is
  # chrome MY OWN arrange builds and retires, inside the very flush that is settling my holder,
  # so re-fitting for it would re-dirty a node the pass has already settled -- a settle re-visit
  # for a piece whose whole existence is a layout OUTPUT.
  _reactToChildRemoved: (child) ->
    # the field still names the piece while it dies: _layOutOverflowChevron clears it only after
    # the destroy returns.
    return if child is @overflowChevron
    super child

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # my tool cells, in strip order: every content child except the overflow chevron, which is
  # chrome I place myself rather than a tool the strip offers.
  _toolCells: ->
    (w for w in @childrenNotHandlesNorCarets() when w isnt @overflowChevron)

  # What sits BEHIND the chevron right now: each CELL the arrange hid. The chevron asks me at pop
  # time and builds its remainder menu from the answer, so the menu is DERIVED at open rather than
  # kept in step with me.
  #   Cells rather than the tools inside them, because a row stands in for a TAP on the cell and
  # only the cell knows what a tap on it reaches (thumbnailClickReceiver) -- for a drag-out
  # thumbnail that is the lid over the tool, and the tool itself carries no click at all.
  cellsBehindTheOverflowChevron: ->
    (cell for cell in @_toolCells() when !cell.visibleBasedOnIsVisibleProperty())

  # the step from one cell's edge to the next: the cell itself plus the gap after it
  _cellPitch: ->
    @thumbnailSize + @internalPadding

  # how many whole cells a run of `run` pixels holds, margins and inter-cell gaps included
  _cellsFittingIn: (run, pitch) ->
    Math.max 1, Math.floor (run - 2 * @externalPadding + @internalPadding) / pitch

  # THE INVERSE of _cellsFittingIn: the run that holds exactly `count` cells -- their pitches
  # minus the gap the last one does not need, plus a margin at each end. The two must stay
  # inverses, which is why they are written as one pair here and read from both the arrange
  # (which wraps) and the hug (which sizes).
  _naturalRunFor: (count, pitch) ->
    count * pitch - @internalPadding + 2 * @externalPadding

  # MY DEPTH AS A STRIP: the cross-axis run one strip-depth of cells needs -- toolRows of them
  # with my own margin on either side, so cells sit centred across a band with nothing left
  # over. The same _naturalRunFor the hug and the arrange use, so a docked band's depth and a
  # floating window's box are ONE arithmetic. PURE -- cell dials only, no laid-out extent --
  # which is exactly what a dock spec's thickness must be (§6.1 rule 1).
  naturalGridCrossExtent: ->
    @_naturalRunFor (Math.max 1, WorldWdgt.preferencesAndSettings.toolRows), @_cellPitch()

  # THE BOX THAT HUGS MY CELLS, within the `room` a free-floating home can offer (owner ruling:
  # a floating toolbar hugs its payload; C10's never-bigger-than-the-world is what `room` carries).
  # Across: toolRows columns -- a cell column with the grid's own margins beside it, so the cells
  # sit centred and nothing overflows sideways. Along: EVERY cell's run, capped by the room and,
  # when capped, QUANTIZED DOWN to whole cells -- a sliver of a cell shows nothing anyone can use,
  # and the overflow chevron carries what is left out either way.
  naturalGridExtentWithin: (room) ->
    pitch = @_cellPitch()
    columns = Math.min (Math.max 1, WorldWdgt.preferencesAndSettings.toolRows), (@_cellsFittingIn room.x, pitch)
    rows = Math.min (Math.max 1, Math.ceil @_toolCells().length / columns), (@_cellsFittingIn room.y, pitch)
    new Point (@_naturalRunFor columns, pitch), (@_naturalRunFor rows, pitch)

  # place one cell in slot `slot` of a `columns`-wide grid, centred in its cell box
  _placeInSlot: (w, slot, columns, pitch) ->
    xPos = (slot % columns) * pitch
    yPos = Math.floor(slot / columns) * pitch
    horizAdj = (@thumbnailSize - w.width()) / 2
    vertAdj = (@thumbnailSize - w.height()) / 2
    w._applyMoveTo @position().add(new Point @externalPadding, @externalPadding).add(new Point xPos, yPos).add(new Point horizAdj, vertAdj).round()

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    cells = @_toolCells()
    pitch = @_cellPitch()

    # The box my cells must fit in is my enclosing viewport's, read via the
    # widthContentsMustFitWithin? / heightContentsMustFitWithin? capabilities, not `instanceof
    # ViewportWdgt` (type-test-elimination ε): only a viewport answers; any other parent (or no
    # parent) leaves my own extent.
    runW = @parent?.widthContentsMustFitWithin?() ? @width()
    runH = @parent?.heightContentsMustFitWithin?() ? @height()

    # A STRIP runs along its longer axis, and toolRows is how many cells its CROSS axis takes.
    # So a wide strip is toolRows deep and as many columns as fit, a tall one is toolRows wide
    # and as many rows as fit -- one arrange, two directions.
    if runH > runW
      columns = Math.max 1, WorldWdgt.preferencesAndSettings.toolRows
      rows = @_cellsFittingIn runH, pitch
    else
      columns = @_cellsFittingIn runW, pitch
      rows = Math.max 1, WorldWdgt.preferencesAndSettings.toolRows

    # The trailing slot becomes the chevron's the moment one cell would be left out, so the
    # count that SHOWS is one short of the fit whenever anything overflows. When everything
    # fits there is no chevron at all -- a control nothing needs charges no rent.
    overflows = cells.length > columns * rows
    shownCount = if overflows then columns * rows - 1 else cells.length

    for cell, i in cells
      if i < shownCount
        cell.show()
        @_placeInSlot cell, i, columns, pitch
      else
        # hidden BY the layout (visibility as layout OUTPUT, never as layout input) and parked
        # in the chevron's own slot, so an out-of-sight cell also stops stretching my frame.
        cell.hide()
        @_placeInSlot cell, shownCount, columns, pitch

    @_layOutOverflowChevron overflows, shownCount, columns, pitch

  # The chevron EXISTS exactly while some cell is hidden: built into the trailing slot the moment
  # one overflows, RETIRED the moment they all fit again. A control nothing needs charges no rent,
  # and a parked-and-hidden one still charges the rent of a widget nobody can see -- so this is a
  # build-and-retire derivation, the same shape the frame bar's roster uses for its own pieces.
  #   Both halves go through the NON-settling cores: this runs inside a layout pass, where the
  # self-settling public add/destroy would re-enter the flush guard.
  _layOutOverflowChevron: (overflows, shownCount, columns, pitch) ->
    unless overflows
      if @overflowChevron?
        # the SUBTREE, through the non-settling core: an icon button owns a face widget, and
        # destroying the button alone would leave that face alive and off-tree -- an escaped
        # widget the instances registry pins forever.
        @overflowChevron._fullDestroyNoSettle()
        @overflowChevron = undefined
      return
    unless @overflowChevron?
      @overflowChevron = new OverflowChevronButtonWdgt
      # my own core routes the chevron past the tool-wrapping branch (it is chrome I place, not
      # a tool the strip offers)
      @_addNoSettle @overflowChevron
    cellExtent = new Point @thumbnailSize, @thumbnailSize
    @overflowChevron._applyExtent cellExtent  unless @overflowChevron.extent().equals cellExtent
    @_placeInSlot @overflowChevron, shownCount, columns, pitch


