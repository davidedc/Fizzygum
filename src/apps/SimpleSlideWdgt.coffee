class SimpleSlideWdgt extends StretchableEditableWdgt

  colloquialName: ->
    "Slides Maker"

  representativeIcon: ->
    new SimpleSlideIconWdgt


  _createToolsPanelNoSettle: ->
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
    @toolsPanel._addManyNoSettle [
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



    @toolsPanel._disableDragsDropsAndEditingNoSettle()
    @_addNoSettle @toolsPanel
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


  # (_reLayoutSelf is inherited from StretchableEditableWdgt — the byte-identical
  # Dashboards/PatchProgramming/SimpleSlide copies were hoisted there 2026-07-12.)

