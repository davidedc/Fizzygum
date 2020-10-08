class ToolPanelWdgt extends PanelWdgt

  # TODO pretty sure that we don't need numberOfIconsOnPanel
  numberOfIconsOnPanel: 0
  internalPadding: 5
  externalPadding: 10
  thumbnailSize: 30

  addMany: (widgetsToBeAdded) ->
    for eachWidget in widgetsToBeAdded
      @add eachWidget, nil, nil, nil, nil, nil, true
    @invalidateLayout()

  add: (aWdgt, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen, dontLayout) ->

    if (aWdgt instanceof ModifiedTextTriangleAnnotationWdgt) or
     (aWdgt instanceof HandleMorph)
      super
    else
      # if aWdgt specifies a non-default switcharoo then it
      # means it's like the TextBoxCreatorButtonWdgt, which creates a textbox
      # when dragged. So in that case we DON'T set it as a template
      # otherwise we do.
      if aWdgt.grabbedWidgetSwitcheroo == Widget::grabbedWidgetSwitcheroo
        aWdgt.isTemplate = true

      if !aWdgt.extentToGetWhenDraggedFromGlassBox?
        aWdgt.extentToGetWhenDraggedFromGlassBox = aWdgt.extent()

      if !(aWdgt instanceof GlassBoxBottomWdgt)
        glassBoxBottom = new GlassBoxBottomWdgt
        glassBoxBottom.add aWdgt

        if !aWdgt.actionableAsThumbnail
          glassBoxTop = new GlassBoxTopWdgt
          glassBoxTop.toolTipMessage = aWdgt.toolTipMessage
          glassBoxBottom.add glassBoxTop

        glassBoxBottom.fullRawMoveTo @topLeft().add new Point @externalPadding, @externalPadding
        # TODO anti-pattern - this rawSetExtent should be called within doLayout, not here
        glassBoxBottom.rawSetExtent new Point @thumbnailSize, @thumbnailSize
        glassBoxBottom.invalidateLayout()

        aWdgt = glassBoxBottom


      childrenNotHandlesNorCarets = @childrenNotHandlesNorCarets()

      foundDrop = false

      if positionOnScreen? and childrenNotHandlesNorCarets.length > 0
        positionNumberAmongSiblings = 0

        for w in childrenNotHandlesNorCarets
          if w.bounds.growBy(@internalPadding).containsPoint positionOnScreen
            foundDrop = true
            if w.bounds.growBy(@internalPadding).rightHalf().containsPoint positionOnScreen
              positionNumberAmongSiblings++
            break
          positionNumberAmongSiblings++
      
      if foundDrop
        super aWdgt, positionNumberAmongSiblings, layoutSpec, beingDropped
      else
        super aWdgt, @numberOfIconsOnPanel, layoutSpec, beingDropped

      @numberOfIconsOnPanel++

      unless dontLayout
        @invalidateLayout()

  # TODO this is an anti-pattern where a lower-level function calls an higher-level
  # one. doLayout should be calling this rawSetExtent.
  # If we don't do this, the toolbar won't relayout its content when resized, but this
  # is not the right way to go about it
  rawSetExtent: (aPoint) ->
    super
    @invalidateLayout()

  doLayout: ->
    #if !window.recalculatingLayouts
    #  debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    if @isCollapsed()
      @layoutIsValid = true
      return

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.trackChanges.push false

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
      w.fullRawMoveTo @position().add(new Point @externalPadding, @externalPadding).add(new Point xPos, yPos).add(new Point horizAdj, vertAdj).round()
      scanningChildrenX++
      numberOfEntries++

    world.trackChanges.pop()
    @fullChanged()

    super
    @layoutIsValid = true

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

