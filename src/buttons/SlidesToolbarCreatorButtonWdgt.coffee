class SlidesToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  constructor: ->
    super
    @appearance = new SlidesToolbarIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "items for slides"

  createWidgetToBeHandled: ->

    toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt()

    toolsPanel.addMany [
      new TextBoxCreatorButtonWdgt()
      new ExternalLinkCreatorButtonWdgt()
      new VideoPlayCreatorButtonWdgt()

      new WorldMapCreatorButtonWdgt()
      new USAMapCreatorButtonWdgt()

      new RectangleMorph()

      new MapPinIconWdgt()

      new SpeechBubbleWdgt()

      new DestroyIconMorph()
      new ScratchAreaIconMorph()
      new FloraIconMorph()
      new ScooterIconMorph()
      new HeartIconMorph()

      new FizzygumLogoIconWdgt()
      new FizzygumLogoWithTextIconWdgt()
      new VaporwaveBackgroundIconWdgt()
      new VaporwaveSunIconWdgt()

      new ArrowNIconWdgt()
      new ArrowSIconWdgt()
      new ArrowWIconWdgt()
      new ArrowEIconWdgt()
      new ArrowNWIconWdgt()
      new ArrowNEIconWdgt()
      new ArrowSWIconWdgt()
      new ArrowSEIconWdgt()
    ]

    toolsPanel.disableDragsDropsAndEditing()

    switcherooWm = new WindowWdgt nil, nil, toolsPanel
    switcherooWm.fullRawMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm.fullRawMoveWithin world
    world.add switcherooWm
    switcherooWm.rawSetExtent new Point 105, 300

    return switcherooWm

