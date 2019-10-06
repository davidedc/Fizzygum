class SimpleSlideWdgt extends StretchableEditableWdgt

  colloquialName: ->   
    "Slides Maker"

  representativeIcon: ->
    new SimpleSlideIconWdgt


  createToolsPanel: ->
    # tools -------------------------------
    @toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

    if false
      console.time 'createToolsPanel'
      @toolsPanel.add new TextBoxCreatorButtonWdgt
      @toolsPanel.add new ExternalLinkCreatorButtonWdgt
      @toolsPanel.add new VideoPlayCreatorButtonWdgt

      @toolsPanel.add new WorldMapCreatorButtonWdgt
      @toolsPanel.add new USAMapCreatorButtonWdgt

      @toolsPanel.add new RectangleMorph

      @toolsPanel.add new MapPinIconWdgt

      @toolsPanel.add new SpeechBubbleWdgt

      @toolsPanel.add new DestroyIconMorph
      @toolsPanel.add new ScratchAreaIconMorph
      @toolsPanel.add new FloraIconMorph
      @toolsPanel.add new ScooterIconMorph
      @toolsPanel.add new HeartIconMorph

      @toolsPanel.add new FizzygumLogoIconWdgt
      @toolsPanel.add new FizzygumLogoWithTextIconWdgt
      @toolsPanel.add new VaporwaveBackgroundIconWdgt
      @toolsPanel.add new VaporwaveSunIconWdgt

      @toolsPanel.add new ArrowNIconWdgt
      @toolsPanel.add new ArrowSIconWdgt
      @toolsPanel.add new ArrowWIconWdgt
      @toolsPanel.add new ArrowEIconWdgt
      @toolsPanel.add new ArrowNWIconWdgt
      @toolsPanel.add new ArrowNEIconWdgt
      @toolsPanel.add new ArrowSWIconWdgt
      @toolsPanel.add new ArrowSEIconWdgt
      console.timeEnd 'createToolsPanel'

    # from some measuring (30 measurements or so)
    # the batched approach seems twice as fast
    # (average of 5.4 ms on my machine instead of 10 ms), and
    # also variance is lower (3.1 vs 9.5).
    #console.time 'createToolsPanel'
    @toolsPanel.addMany [
      new TextBoxCreatorButtonWdgt
      new ExternalLinkCreatorButtonWdgt
      new VideoPlayCreatorButtonWdgt

      new WorldMapCreatorButtonWdgt
      new USAMapCreatorButtonWdgt

      new RectangleMorph

      new MapPinIconWdgt

      new SpeechBubbleWdgt

      new DestroyIconMorph
      new ScratchAreaIconMorph
      new FloraIconMorph
      new ScooterIconMorph
      new HeartIconMorph

      new FizzygumLogoIconWdgt
      new FizzygumLogoWithTextIconWdgt
      new VaporwaveBackgroundIconWdgt
      new VaporwaveSunIconWdgt

      new ArrowNIconWdgt
      new ArrowSIconWdgt
      new ArrowWIconWdgt
      new ArrowEIconWdgt
      new ArrowNWIconWdgt
      new ArrowNEIconWdgt
      new ArrowSWIconWdgt
      new ArrowSEIconWdgt
    ]
    #console.timeEnd 'createToolsPanel'



    @toolsPanel.disableDragsDropsAndEditing()
    @add @toolsPanel
    @dragsDropsAndEditingEnabled = true
    @invalidateLayout()

  createNewStretchablePanel: ->
    @stretchableWidgetContainer = new StretchableWidgetContainerWdgt
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
    labelRight = @right() - @externalPadding
    labelBottom = @top() + @externalPadding

    # tools -------------------------------

    if @toolsPanel?.parent == @
      @toolsPanel.fullRawMoveTo new Point @left() + @externalPadding, labelBottom
      @toolsPanel.rawSetExtent new Point 95, @height() - 2 * @externalPadding


    # stretchableWidgetContainer --------------------------

    stretchableWidgetContainerWidth = @width() - 2*@externalPadding
    
    if @dragsDropsAndEditingEnabled
      stretchableWidgetContainerWidth -= @toolsPanel.width() + @internalPadding

    stretchableWidgetContainerHeight =  @height() - 2 * @externalPadding
    if @dragsDropsAndEditingEnabled
      stretchableWidgetContainerLeft = @toolsPanel.right() + @internalPadding
    else
      stretchableWidgetContainerLeft = @left() + @externalPadding

    if @stretchableWidgetContainer.parent == @
      @stretchableWidgetContainer.fullRawMoveTo new Point stretchableWidgetContainerLeft, labelBottom
      @stretchableWidgetContainer.setExtent new Point stretchableWidgetContainerWidth, stretchableWidgetContainerHeight

    # ----------------------------------------------


    trackChanges.pop()
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()

    @layoutIsValid = true
    @notifyChildrenThatParentHasReLayouted()


