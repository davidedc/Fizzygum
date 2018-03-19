# REQUIRES HighlightableMixin
# REQUIRES ParentStainerMixin

class PlotsToolbarCreatorButtonWdgt extends Widget

  @augmentWith HighlightableMixin, @name
  @augmentWith ParentStainerMixin, @name

  color_hover: new Color 90, 90, 90
  color_pressed: new Color 128, 128, 128
  color_normal: new Color 230, 230, 230

  constructor: ->
    super
    @appearance = new AllPlotsIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @actionableAsThumbnail = true
    @editorContentPropertyChangerButton = true
    @toolTipMessage = "text box"

  grabbedWidgetSwitcheroo: ->

    toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt()

    toolsPanel.add new ScatterPlotWithAxesCreatorButtonWdgt()
    toolsPanel.add new FunctionPlotWithAxesCreatorButtonWdgt()
    toolsPanel.add new BarPlotWithAxesCreatorButtonWdgt()
    toolsPanel.add new Plot3DCreatorButtonWdgt()

    toolsPanel.disableDragsDropsAndEditing()

    switcherooWm = new WindowWdgt nil, nil, toolsPanel
    switcherooWm.setExtent new Point 60, 192
    switcherooWm.fullRawMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm.fullRawMoveWithin world
    world.add switcherooWm
    switcherooWm.changed()

    return switcherooWm

  # otherwise the glassbox bottom will answer on drags
  # and will just pick up the button and move it,
  # while we want the drag to create a textbox
  grabsToParentWhenDragged: ->
    false

