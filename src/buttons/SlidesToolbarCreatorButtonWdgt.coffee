class SlidesToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "items for slides"

  createAppearance: -> new SlidesToolbarIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->

    toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

    toolsPanel.addMany [
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

    toolsPanel.disableDragsDropsAndEditing()

    return @_buildToolWindow toolsPanel, new Point 105, 300

