# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class SlidesToolbarCreatorButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new SlidesToolbarIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @toolTipMessage = "link"

  grabbedWidgetSwitcheroo: ->

    toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt()

    toolsPanel.add new TextBoxCreatorButtonWdgt()
    toolsPanel.add new ExternalLinkCreatorButtonWdgt()
    toolsPanel.add new VideoPlayCreatorButtonWdgt()

    toolsPanel.add new WorldMapCreatorButtonWdgt()
    toolsPanel.add new USAMapCreatorButtonWdgt()

    toolsPanel.add new RectangleMorph()

    toolsPanel.add new MapPinIconWdgt()

    toolsPanel.add new SpeechBubbleWdgt()

    toolsPanel.add new DestroyIconMorph()
    toolsPanel.add new ScratchAreaIconMorph()
    toolsPanel.add new FloraIconMorph()
    toolsPanel.add new ScooterIconMorph()
    toolsPanel.add new HeartIconMorph()

    toolsPanel.add new FizzygumLogoIconWdgt()
    toolsPanel.add new FizzygumLogoWithTextIconWdgt()
    toolsPanel.add new VaporwaveBackgroundIconWdgt()
    toolsPanel.add new VaporwaveSunIconWdgt()

    toolsPanel.add new ArrowNIconWdgt()
    toolsPanel.add new ArrowSIconWdgt()
    toolsPanel.add new ArrowWIconWdgt()
    toolsPanel.add new ArrowEIconWdgt()
    toolsPanel.add new ArrowNWIconWdgt()
    toolsPanel.add new ArrowNEIconWdgt()
    toolsPanel.add new ArrowSWIconWdgt()
    toolsPanel.add new ArrowSEIconWdgt()

    toolsPanel.disableDragsDropsAndEditing()

    switcherooWm = new WindowWdgt nil, nil, toolsPanel
    switcherooWm.fullRawMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm.fullRawMoveWithin world
    world.add switcherooWm
    switcherooWm.rawSetExtent new Point 105, 300

    return switcherooWm

  # otherwise the glassbox bottom will answer on drags
  # and will just pick up the button and move it,
  # while we want the drag to create a textbox
  grabsToParentWhenDragged: ->
    false

