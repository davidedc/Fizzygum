class ToolPanelWdgt extends PanelWdgt

  # (My grid's dials -- the cell's side, the least gap between two cells, my padding along the
  # strip and across it, and how many cells deep a strip is -- are the theme's toolbar metrics,
  # read through the small readers under "my grid's dials" at every arrange and measure, and never
  # copied into me: a toolbar saved and loaded, or duplicated, lays itself out in the theme of the
  # world that lays it out.)

  # the trailing chevron my arrange shows when my cells outrun my strip (ruling T2, absorbed
  # into the single geometry): a strip shows the prefix that fits and this pops the remainder as
  # a menu. Declared so duplication carries the handle.
  overflowChevron: undefined

  constructor: ->
    super()
    @appearance = @createAppearance()

  # I paint nothing of my own, neither a fill nor a border, so what lies under me shows: in a
  # toolbar, the frame it lives in (a docked band's card, a floating toolbar's window), whose
  # outline is then the one line around my cells (visual-design-system §4.1); in a plain
  # ViewportWdgt, that viewport's own fill and border. A press between two cells still lands on
  # me: the base appearance's shape is my whole box.
  createAppearance: -> new SeamRulesAppearance @

  # ===== my grid's dials, from the theme =====
  _cellSide: ->
    WorldWdgt.theme.toolThumbnailSize

  # the least gap between two cells: the gap a strip that hugs its cells shows, and the one the
  # fit count reserves, so it decides how many cells a strip shows
  _minimumGap: ->
    WorldWdgt.theme.toolInternalPadding

  # my padding ALONG the strip, before its first slot and, unless a resizer needs more room there
  # (_farAlongPadding), after its last ...
  _alongPadding: ->
    WorldWdgt.theme.toolAlongPadding

  # ... my padding at the strip's FAR end -- its right end for a row, its bottom for a column, so
  # always the end at my viewport's bottom-right corner, which is where a frame's resize grip sits:
  # my along padding, or how far a resizer over that corner reaches in, whichever is more, so my
  # last slot (the chevron's, when anything overflows) stays clear of the grip. My viewport answers
  # the reach (ViewportWdgt.cornerResizerFootprint: STRUCTURAL, a reserve by occupancy, the one its
  # scroll bars keep), so a floating toolbar's window keeps it and a band docked at its host's right
  # or bottom keeps the host's; a parent with no answer has no corner to keep.
  _farAlongPadding: ->
    Math.max @_alongPadding(), (@parent?.cornerResizerFootprint?() ? 0)

  # ... and ACROSS it, on either side of my rows of cells
  _crossPadding: ->
    WorldWdgt.theme.toolCrossPadding

  # how many cells deep a strip is, across its run
  _stripDepthInCells: ->
    Math.max 1, WorldWdgt.theme.toolRows

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

        # a provisional seat inside my padding: the arrange this add schedules places the cell
        glassBoxBottom._applyMoveTo @topLeft().add new Point @_crossPadding(), @_crossPadding()
        # TODO anti-pattern - this _applyExtent should be called within _reLayout, not here
        glassBoxBottom._applyExtent new Point @_cellSide(), @_cellSide()
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

  # Where among `children` (a childrenNotHandlesNorCarets list) does a payload dropped at `posInPlane`
  # -- the release point expressed in MY plane (the drop dispatcher maps it, ActivePointerWdgt.drop)
  # -- land? The sibling insertion index (one past a cell whose right half holds the point; a cell
  # reaches the least gap past its right and bottom edges), or undefined when the point is over no
  # cell, and the add then appends at the end. Pure computation.
  _findDropSlot: (posInPlane, children) ->
    return undefined unless posInPlane? and children.length > 0
    reach = @_minimumGap()
    positionNumberAmongSiblings = 0
    for w in children
      if w.bounds.growBy(reach).containsPoint posInPlane
        if w.bounds.growBy(reach).rightHalf().containsPoint posInPlane
          positionNumberAmongSiblings++
        return positionNumberAmongSiblings
      positionNumberAmongSiblings++
    return undefined

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

  # the step from one cell's edge to the next at the least gap: the cell itself plus that gap
  _cellPitch: ->
    @_cellSide() + @_minimumGap()

  # how many whole cells a run of `run` pixels holds at the least gap between them, with
  # `nearPadding` before the first and `farPadding` after the last (along a strip, my along padding
  # and my far-end padding; across it, my cross padding at both ends) -- and always at least one,
  # so a strip too short for a cell still has a slot for the chevron
  _cellsFittingIn: (run, nearPadding, farPadding) ->
    Math.max 1, Math.floor (run - nearPadding - farPadding + @_minimumGap()) / @_cellPitch()

  # THE INVERSE of _cellsFittingIn: the run that holds exactly `count` cells at the least gap --
  # their pitches minus the gap the last one does not need, plus the padding at each end. The two
  # must stay inverses, which is why they are written as one pair here and read from both the
  # arrange (which fits) and the hug (which sizes): a strip at the run this answers has no
  # leftover, so its cells sit exactly the least gap apart.
  _naturalRunFor: (count, nearPadding, farPadding) ->
    count * @_cellPitch() - @_minimumGap() + nearPadding + farPadding

  # MY DEPTH AS A STRIP: the cross-axis run one strip-depth of cells needs -- toolRows of them
  # with my cross padding on either side, so a band has nothing left over across its cells. The
  # same _naturalRunFor the hug and the arrange use, so a docked band's depth and a floating
  # window's box are ONE arithmetic. PURE -- theme dials only, no laid-out extent -- which is
  # exactly what a dock thickness must be (§6.1 rule 1), and read at every measure
  # (ToolbarWdgt.dockThickness), so a band follows the theme it is laid out in.
  naturalGridCrossExtent: ->
    @_naturalRunFor @_stripDepthInCells(), @_crossPadding(), @_crossPadding()

  # THE BOX THAT HUGS MY CELLS, within the `room` a free-floating home can offer (owner ruling:
  # a floating toolbar hugs its payload; C10's never-bigger-than-the-world is what `room` carries).
  # Across: toolRows columns -- a cell column with my cross padding beside it, so nothing
  # overflows sideways. Along: EVERY cell's run at the least gap, my along padding before it and my
  # far-end padding after it (the reach of the window's own grip over that end), capped by the room
  # and, when capped, QUANTIZED DOWN to whole cells -- a sliver of a cell shows nothing anyone can
  # use, and the overflow chevron carries what is left out either way. Either way the run has no
  # leftover, so nothing spreads until someone makes the strip longer.
  naturalGridExtentWithin: (room) ->
    farPadding = @_farAlongPadding()
    columns = Math.min @_stripDepthInCells(), (@_cellsFittingIn room.x, @_crossPadding(), @_crossPadding())
    rows = Math.min (Math.max 1, Math.ceil @_toolCells().length / columns), (@_cellsFittingIn room.y, @_alongPadding(), farPadding)
    new Point (@_naturalRunFor columns, @_crossPadding(), @_crossPadding()), (@_naturalRunFor rows, @_alongPadding(), farPadding)

  # WHERE EACH SLOT STARTS ALONG A STRIP `run` long, for `count` slots in use: the first
  # `nearPadding` in, the last ending `farPadding` short of the far end, and the leftover between
  # them shared evenly -- SPACE-BETWEEN. One slot sits `nearPadding` in. Each slot is rounded on its
  # own, so a fractional share (a 61.25 step) never commits a fractional bound and the last slot
  # still ends exactly at the far padding.
  _slotOffsetsAlong: (count, run, nearPadding, farPadding) ->
    return [nearPadding] if count is 1
    spread = run - nearPadding - farPadding - @_cellSide()
    (nearPadding + Math.round(i * spread / (count - 1)) for i in [0...count])

  # place one cell in slot `slot` of my grid, centred in its cell box. Slots fill a `columns`-wide
  # grid row by row; along the strip a slot stands where _slotOffsetsAlong put it, across the strip
  # at my cross padding plus whole cell pitches.
  _placeInSlot: (w, slot, grid) ->
    column = slot % grid.columns
    row = Math.floor slot / grid.columns
    alongIndex = if grid.vertical then row else column
    crossIndex = if grid.vertical then column else row
    along = grid.alongOffsets[alongIndex]
    across = @_crossPadding() + crossIndex * @_cellPitch()
    offset = if grid.vertical then new Point across, along else new Point along, across
    centring = new Point (@_cellSide() - w.width()) / 2, (@_cellSide() - w.height()) / 2
    w._applyMoveTo @position().add(offset).add(centring).round()

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    cells = @_toolCells()

    # The box my cells must fit in is my enclosing viewport's, read via the
    # widthContentsMustFitWithin? / heightContentsMustFitWithin? capabilities, not `instanceof
    # ViewportWdgt` (type-test-elimination ε): only a viewport answers; any other parent (or no
    # parent) leaves my own extent.
    runW = @parent?.widthContentsMustFitWithin?() ? @width()
    runH = @parent?.heightContentsMustFitWithin?() ? @height()

    # A STRIP runs along its longer axis, and toolRows is how many cells its CROSS axis takes.
    # So a wide strip is toolRows deep and as many columns as fit, a tall one is toolRows wide
    # and as many rows as fit -- one arrange, two directions. The fit counts cells at the least
    # gap between my along padding and my far-end padding (which keeps the last slot clear of a
    # resizer over my viewport's bottom-right corner).
    nearPadding = @_alongPadding()
    farPadding = @_farAlongPadding()
    vertical = runH > runW
    if vertical
      columns = @_stripDepthInCells()
      rows = @_cellsFittingIn runH, nearPadding, farPadding
    else
      columns = @_cellsFittingIn runW, nearPadding, farPadding
      rows = @_stripDepthInCells()

    # The trailing slot becomes the chevron's the moment one cell would be left out, so the
    # count that SHOWS is one short of the fit whenever anything overflows. When everything
    # fits there is no chevron at all -- a control nothing needs charges no rent.
    overflows = cells.length > columns * rows
    shownCount = if overflows then columns * rows - 1 else cells.length

    # The slots in use -- the shown cells, and the chevron's whenever anything overflows -- spread
    # along the whole strip (_slotOffsetsAlong), down a tall strip as across a wide one: a strip
    # longer than its cells need shares the leftover between them.
    slotsInUse = if overflows then shownCount + 1 else shownCount
    slotsAlong = if vertical then Math.ceil(slotsInUse / columns) else Math.min(slotsInUse, columns)
    grid =
      columns: columns
      vertical: vertical
      alongOffsets: @_slotOffsetsAlong slotsAlong, (if vertical then runH else runW), nearPadding, farPadding

    for cell, i in cells
      if i < shownCount
        cell.show()
        @_placeInSlot cell, i, grid
      else
        # hidden BY the layout (visibility as layout OUTPUT, never as layout input) and parked
        # in the chevron's own slot, so an out-of-sight cell also stops stretching my frame.
        cell.hide()
        @_placeInSlot cell, shownCount, grid

    @_layOutOverflowChevron overflows, shownCount, grid

  # The chevron EXISTS exactly while some cell is hidden: built into the trailing slot the moment
  # one overflows, RETIRED the moment they all fit again. A control nothing needs charges no rent,
  # and a parked-and-hidden one still charges the rent of a widget nobody can see -- so this is a
  # build-and-retire derivation, the same shape the frame bar's roster uses for its own pieces.
  #   Both halves go through the NON-settling cores: this runs inside a layout pass, where the
  # self-settling public add/destroy would re-enter the flush guard.
  _layOutOverflowChevron: (overflows, shownCount, grid) ->
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
    cellExtent = new Point @_cellSide(), @_cellSide()
    @overflowChevron._applyExtent cellExtent  unless @overflowChevron.extent().equals cellExtent
    # its mark is drawn smaller than its cell-sized target (IconButtonWdgt.glyphSize: the placer
    # names it), at the theme's side, read at every arrange
    @overflowChevron.glyphSize = WorldWdgt.theme.toolOverflowGlyphSize
    @_placeInSlot @overflowChevron, shownCount, grid


