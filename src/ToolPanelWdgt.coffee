class ToolPanelWdgt extends PanelWdgt

  # TODO pretty sure that we don't need numberOfIconsOnPanel
  numberOfIconsOnPanel: 0
  internalPadding: 5
  externalPadding: 10
  thumbnailSize: 30

  addMany: (widgetsToBeAdded) ->

    for eachWidget in widgetsToBeAdded
      @add eachWidget, nil, nil, nil, nil, nil, true
    @reLayout()

  add: (aMorph, position = nil, layoutSpec = LayoutSpec.ATTACHEDAS_FREEFLOATING, beingDropped, unused, positionOnScreen, dontLayout) ->

    if (aMorph instanceof ModifiedTextTriangleAnnotationWdgt) or
     (aMorph instanceof HandleMorph)
      super
    else
      # if aMorph specifies a non-default switcharoo then it
      # means it's like the TextBoxCreatorButtonWdgt, which creates a textbox
      # when dragged. So in that case we DON'T set it as a template
      # otherwise we do.
      if aMorph.grabbedWidgetSwitcheroo == Widget::grabbedWidgetSwitcheroo
        aMorph.isTemplate = true

      if !aMorph.extentToGetWhenDraggedFromGlassBox?
        aMorph.extentToGetWhenDraggedFromGlassBox = aMorph.extent()

      if !(aMorph instanceof GlassBoxBottomWdgt)
        glassBoxBottom = new GlassBoxBottomWdgt()
        glassBoxBottom.add aMorph

        if !aMorph.actionableAsThumbnail
          glassBoxTop = new GlassBoxTopWdgt()
          glassBoxTop.toolTipMessage = aMorph.toolTipMessage
          glassBoxBottom.add glassBoxTop

        glassBoxBottom.fullRawMoveTo @topLeft().add new Point @externalPadding, @externalPadding
        glassBoxBottom.rawSetExtent new Point @thumbnailSize, @thumbnailSize
        glassBoxBottom.reLayout()

        aMorph = glassBoxBottom


      childrenNotHandlesNorCarets = @children.filter (m) ->
        !((m instanceof HandleMorph) or (m instanceof CaretMorph))

      foundDrop = false

      if positionOnScreen? and childrenNotHandlesNorCarets.length > 0
        positionNumberAmongSiblings = 0

        for eachChild in childrenNotHandlesNorCarets
          if eachChild.bounds.growBy(@internalPadding).containsPoint positionOnScreen
            foundDrop = true
            if eachChild.bounds.growBy(@internalPadding).rightHalf().containsPoint positionOnScreen
              positionNumberAmongSiblings++
            break
          positionNumberAmongSiblings++
      
      if foundDrop
        super aMorph, positionNumberAmongSiblings, layoutSpec, beingDropped
      else
        super aMorph, @numberOfIconsOnPanel, layoutSpec, beingDropped

      @numberOfIconsOnPanel++

      unless dontLayout
        @reLayout()


  rawSetExtent: (aPoint) ->
    super
    @reLayout()

  reLayout: ->

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    trackChanges.push false

    childrenNotHandlesNorCarets = @children.filter (m) ->
      !((m instanceof HandleMorph) or (m instanceof CaretMorph))

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

    for eachChild in childrenNotHandlesNorCarets

      xPos = scanningChildrenX * (@thumbnailSize + @internalPadding)
      yPos = scanningChildrenY * (@thumbnailSize + @internalPadding)

      if @externalPadding + xPos + @thumbnailSize + @externalPadding > widthINeedToFitContentIn
        scanningChildrenX = 0
        if numberOfEntries != 0
          scanningChildrenY++

        xPos = scanningChildrenX * (@thumbnailSize + @internalPadding)
        yPos = scanningChildrenY * (@thumbnailSize + @internalPadding)

      horizAdj = (@thumbnailSize - eachChild.width()) / 2
      vertAdj = (@thumbnailSize - eachChild.height()) / 2
      eachChild.fullRawMoveTo @position().add(new Point @externalPadding, @externalPadding).add(new Point xPos, yPos).add(new Point horizAdj, vertAdj).round()
      scanningChildrenX++
      numberOfEntries++

    trackChanges.pop()
    @layoutIsValid = true
    @fullChanged()

