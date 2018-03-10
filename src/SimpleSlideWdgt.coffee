class SimpleSlideWdgt extends StretchableEditableWdgt

  colloquialName: ->   
    "Simple slide"

  representativeIcon: ->
    new SimpleSlideIconWdgt()


  createToolsPanel: ->
    # tools -------------------------------
    @toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt()

    @toolsPanel.add new TextBoxCreatorButtonWdgt()
    @toolsPanel.add new ExternalLinkCreatorButtonWdgt()
    @toolsPanel.add new VideoPlayCreatorButtonWdgt()

    @toolsPanel.add new WorldMapCreatorButtonWdgt()
    @toolsPanel.add new USAMapCreatorButtonWdgt()

    @toolsPanel.add new RectangleMorph()

    @toolsPanel.add new MapPinIconWdgt()

    @toolsPanel.add new DestroyIconMorph()
    @toolsPanel.add new ScratchAreaIconMorph()
    @toolsPanel.add new FloraIconMorph()
    @toolsPanel.add new ScooterIconMorph()
    @toolsPanel.add new HeartIconMorph()

    @toolsPanel.add new FizzygumLogoIconWdgt()
    @toolsPanel.add new FizzygumLogoWithTextIconWdgt()
    @toolsPanel.add new VaporwaveBackgroundIconWdgt()
    @toolsPanel.add new VaporwaveSunIconWdgt()

    @toolsPanel.add new ArrowNIconWdgt()
    @toolsPanel.add new ArrowSIconWdgt()
    @toolsPanel.add new ArrowWIconWdgt()
    @toolsPanel.add new ArrowEIconWdgt()
    @toolsPanel.add new ArrowNWIconWdgt()
    @toolsPanel.add new ArrowNEIconWdgt()
    @toolsPanel.add new ArrowSWIconWdgt()
    @toolsPanel.add new ArrowSEIconWdgt()

    @toolsPanel.disableDragsDropsAndEditing()
    @add @toolsPanel
    @dragsDropsAndEditingEnabled = true
    @invalidateLayout()

  createNewStretchablePanel: ->
    @stretchableWidgetContainer = new StretchableWidgetContainerWdgt()
    @add @stretchableWidgetContainer


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

    # label
    labelLeft = @left() + @externalPadding
    labelTop = @top() + @externalPadding
    labelRight = @right() - @externalPadding
    labelWidth = labelRight - labelLeft
    labelBottom = @top() + @externalPadding

    # tools -------------------------------

    b = @bottom() - (2 * @externalPadding)

    if @toolsPanel?.parent == @
      @toolsPanel.fullRawMoveTo new Point @left() + @externalPadding, labelBottom
      @toolsPanel.rawSetExtent new Point 95, @height() - 2 * @externalPadding


    # stretchableWidgetContainer --------------------------

    stretchableWidgetContainerWidth = @width() - 2*@externalPadding
    
    if @dragsDropsAndEditingEnabled
      stretchableWidgetContainerWidth -= @toolsPanel.width() + @internalPadding

    b = @bottom() - (2 * @externalPadding)
    stretchableWidgetContainerHeight =  @height() - 2 * @externalPadding
    stretchableWidgetContainerBottom = labelBottom + stretchableWidgetContainerHeight
    if @dragsDropsAndEditingEnabled
      stretchableWidgetContainerLeft = @toolsPanel.right() + @internalPadding
    else
      stretchableWidgetContainerLeft = @left() + @externalPadding

    if @stretchableWidgetContainer.parent == @
      @stretchableWidgetContainer.fullRawMoveTo new Point stretchableWidgetContainerLeft, labelBottom
      @stretchableWidgetContainer.setExtent new Point stretchableWidgetContainerWidth, stretchableWidgetContainerHeight

    # ----------------------------------------------


    trackChanges.pop()
    if AutomatorRecorderAndPlayer? and AutomatorRecorderAndPlayer.state != AutomatorRecorderAndPlayer.IDLE and AutomatorRecorderAndPlayer.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()


