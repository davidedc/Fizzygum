class ToolPanelWdgt extends PanelWdgt

  internalPadding: 5
  externalPadding: 10
  thumbnailSize: 30

  # my enclosing scroll frame borrows my colloquial name (type-test-elimination ε; see
  # ScrollPanelWdgt.colloquialName)
  scrollPanelColloquialName: ->
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
  # SimpleVerticalStackPanelWdgt add/_addNoSettle pattern); the pre-convert shape is in
  # docs/archive/layout-optimizations-and-oo-cleanup-plan.md.
  # slot 5 is `notContent` family-wide — accepted and ignored here (see SimpleVerticalStackPanelWdgt.add)
  add: (aWdgt, position, layoutSpec, beingDropped, notContent, positionOnScreen) ->
    @_settleLayoutsAfter => @_addNoSettle aWdgt, position: position, layoutSpec: layoutSpec, beingDropped: beingDropped, positionOnScreen: positionOnScreen

  _addNoSettle: (aWdgt, opts = {}) ->
    position = opts.position
    layoutSpec = opts.layoutSpec
    beingDropped = opts.beingDropped
    positionOnScreen = opts.positionOnScreen

    # annotation + handle both attach to the scroll frame directly (was their two instanceof)
    # (type-test-elimination campaign)
    if aWdgt.attachesToScrollFrameDirectly?()
      super aWdgt, position: position, layoutSpec: layoutSpec, beingDropped: beingDropped
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

      dropSlot = @_findDropSlot positionOnScreen, childrenNotHandlesNorCarets

      if dropSlot?
        super aWdgt, position: dropSlot, layoutSpec: layoutSpec, beingDropped: beingDropped
      else
        # no drop position (a programmatic add): append after the existing icons
        super aWdgt, layoutSpec: layoutSpec, beingDropped: beingDropped

      @_invalidateLayout()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
    @_applyGrantedBounds newBoundsForThisLayout

    @_repaintAsOneUnit =>

      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      scanningChildrenX = 0
      scanningChildrenY = 0
      numberOfEntries = 0

      # A scroll-panel parent resizes while keeping its contents' width fixed, and the
      # toolpanel must never scroll horizontally (only vertically) -- so fit my width to
      # the scroll frame's content width, read via the widthContentsMustFitWithin?
      # capability, not `instanceof ScrollPanelWdgt` (type-test-elimination ε): only a scroll
      # frame answers the question; any other parent (or no parent) leaves my own width.
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

    super
    @_markLayoutAsFixed()


