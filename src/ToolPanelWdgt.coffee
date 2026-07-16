class ToolPanelWdgt extends PanelWdgt

  # TODO pretty sure that we don't need numberOfIconsOnPanel
  numberOfIconsOnPanel: 0
  internalPadding: 5
  externalPadding: 10
  thumbnailSize: 30

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
  # SimpleVerticalStackPanelWdgt add/_addNoSettle pattern). Was: a public add ending in a
  # bare _invalidateLayout() that rode the end-of-cycle flush, plus a hand-rolled
  # `dontLayout` batching flag -- the pre-convert shape everywhere else already left.
  add: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen) ->
    @_settleLayoutsAfter => @_addNoSettle aWdgt, position: position, layoutSpec: layoutSpec, beingDropped: beingDropped, positionOnScreen: positionOnScreen

  _addNoSettle: (aWdgt, opts = {}) ->
    position = opts.position
    layoutSpec = opts.layoutSpec ? LayoutSpec.ATTACHEDAS_FREEFLOATING
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
        super aWdgt, position: @numberOfIconsOnPanel, layoutSpec: layoutSpec, beingDropped: beingDropped

      @numberOfIconsOnPanel++

      @_invalidateLayout()

  # immediate-resize-relay-exempt: LATENT-FINDING(2026-07-16): SimpleDocumentWdgt/StretchableEditableWdgt._reLayout raw-resize me WITHOUT a re-lay and my arrangement WRAPS by width, so stale children are possible -- pre-existing, suite-invisible; declaring true = behaviour change, deferred as a follow-on (INV-2 unification plan)
  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my own bounds FIRST, so the children laid out below read the FINAL frame and
    # not the previous pass's (else they lag one cadence on resize -- see InspectorWdgt._reLayout /
    # FanoutWdgt._reLayout). The trailing super re-applies the same bounds, idempotently.
    @_applyBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

    scanningChildrenX = 0
    scanningChildrenY = 0
    numberOfEntries = 0

    # The ToolPanel if often inside a scroll panel,
    # in which case the panel width stays the same as the scroll panel
    # is resized (because that's what scrollpanels do, they change
    # dimensions but the contents remain the same).
    # BUT we want the toolpanel to never scroll horizontally
    # (only vertically), i.e. we want it to fit the contents
    # of the scroll panel parent
    widthINeedToFitContentIn = @width()
    if @parent?
      if @parent instanceof ScrollPanelWdgt
        widthINeedToFitContentIn = @parent.width()
      else
        widthINeedToFitContentIn = @width()

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

    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()


