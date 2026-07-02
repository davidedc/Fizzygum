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

      @toolsPanel.add new RectangleWdgt

      @toolsPanel.add new MapPinIconWdgt

      @toolsPanel.add new SpeechBubbleWdgt

      @toolsPanel.add new DestroyIconWdgt
      @toolsPanel.add new ScratchAreaIconWdgt
      @toolsPanel.add new FloraIconWdgt
      @toolsPanel.add new ScooterIconWdgt
      @toolsPanel.add new HeartIconWdgt

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

      new RectangleWdgt

      new MapPinIconWdgt

      new SpeechBubbleWdgt

      new DestroyIconWdgt
      new ScratchAreaIconWdgt
      new FloraIconWdgt
      new ScooterIconWdgt
      new HeartIconWdgt

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
    @_invalidateLayout()

  createNewStretchablePanel: ->
    @stretchableWidgetContainer = new StretchableWidgetContainerWdgt
    @add @stretchableWidgetContainer

  # I coordinate drags/drops/editing for my stretchable container, which delegates its
  # enable/disable up to me (replacing its `@parent instanceof SimpleSlideWdgt` test
  # with this query). (type-test-elimination campaign)
  coordinatesDragsDropsAndEditingForChildren: ->
    true


  _reLayoutSelf: ->
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

    # label
    labelLeft = @left() + @externalPadding
    labelRight = @right() - @externalPadding
    labelBottom = @top() + @externalPadding

    # tools -------------------------------

    if @toolsPanel?.parent == @
      @toolsPanel._applyMoveTo new Point @left() + @externalPadding, labelBottom
      @toolsPanel._applyExtent new Point 95, @height() - 2 * @externalPadding


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
      @stretchableWidgetContainer._applyMoveTo new Point stretchableWidgetContainerLeft, labelBottom
      @stretchableWidgetContainer._applyExtent new Point stretchableWidgetContainerWidth, stretchableWidgetContainerHeight

    # ----------------------------------------------


    world.maybeEnableTrackChanges()
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    @markLayoutAsFixed()

