class DashboardsWdgt extends StretchableEditableWdgt

  colloquialName: ->
    "Dashboards Maker"

  representativeIcon: ->
    new DashboardsIconWdgt


  _createToolsPanelNoSettle: ->
    # tools -------------------------------
    @toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

    @toolsPanel._addManyNoSettle [
      new TextBoxCreatorButtonWdgt
      new ExternalLinkCreatorButtonWdgt

      new ScatterPlotWithAxesCreatorButtonWdgt
      new FunctionPlotWithAxesCreatorButtonWdgt
      new BarPlotWithAxesCreatorButtonWdgt
      new Plot3DCreatorButtonWdgt

      new WorldMapCreatorButtonWdgt
      new USAMapCreatorButtonWdgt
      new MapPinIconWdgt

      new SpeechBubbleWdgt

      new ArrowNIconWdgt
      new ArrowSIconWdgt
      new ArrowWIconWdgt
      new ArrowEIconWdgt
      new ArrowNWIconWdgt
      new ArrowNEIconWdgt
      new ArrowSWIconWdgt
      new ArrowSEIconWdgt
    ]



    @toolsPanel._disableDragsDropsAndEditingNoSettle()
    @_addNoSettle @toolsPanel
    @dragsDropsAndEditingEnabled = true
    @_invalidateLayout()

  createNewStretchablePanel: ->
    @stretchableWidgetContainer = new StretchableWidgetContainerWdgt
    @add @stretchableWidgetContainer


  # TODO this method is the same as in the simple slide widget
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
    @fullChanged()
    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()

    @markLayoutAsFixed()

