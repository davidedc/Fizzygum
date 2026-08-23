class ToolPanelWdgt extends PanelWdgt

  # the grid's cell gap / outer margin / cell side -- read from the toolInternalPadding /
  # toolExternalPadding / toolThumbnailSize preferences in the constructor rather than declared
  # as literals here, because a caller (e.g. TextToolbarWdgt) writes these fields directly on an
  # instance to retune its own strip -- an instance field a subclass overrides after construction,
  # not a class-level constant.
  internalPadding: undefined
  externalPadding: undefined
  thumbnailSize: undefined

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
    # (type-test-elimination campaign)
    if aWdgt.attachesToViewportDirectly?()
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

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    scanningChildrenX = 0
    scanningChildrenY = 0
    numberOfEntries = 0

    # A viewport parent resizes while keeping its contents' width fixed, and the
    # toolpanel must never scroll horizontally (only vertically) -- so fit my width to
    # the viewport's content width, read via the widthContentsMustFitWithin?
    # capability, not `instanceof ViewportWdgt` (type-test-elimination ε): only a
    # viewport answers the question; any other parent (or no parent) leaves my own width.
    widthINeedToFitContentIn = @parent?.widthContentsMustFitWithin?() ? @width()

    for w in childrenNotHandlesNorCarets

      xPos = scanningChildrenX * (@thumbnailSize + @internalPadding)
      yPos = scanningChildrenY * (@thumbnailSize + @internalPadding)

      if @externalPadding + xPos + @thumbnailSize + @externalPadding > widthINeedToFitContentIn
        scanningChildrenX = 0
        if numberOfEntries != 0
          scanningChildrenY++

        xPos = scanningChildrenX * (@thumbnailSize + @internalPadding)
        yPos = scanningChildrenY * (@thumbnailSize + @internalPadding)

      horizAdj = (@thumbnailSize - w.width()) / 2
      vertAdj = (@thumbnailSize - w.height()) / 2
      w._applyMoveTo @position().add(new Point @externalPadding, @externalPadding).add(new Point xPos, yPos).add(new Point horizAdj, vertAdj).round()
      scanningChildrenX++
      numberOfEntries++


