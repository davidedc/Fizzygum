class WindowsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  constructor: ->
    super
    @appearance = new WindowsToolbarIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "many types of\npre-made windows"

  grabbedWidgetSwitcheroo: ->

    toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt()

    toolsPanel.addMany [
      new EmptyWindowCreatorButtonWdgt()
      new WindowWithPanelCreatorButtonWdgt()
      new WindowWithScrollPanelCreatorButtonWdgt()
      new ElasticWindowCreatorButtonWdgt()
    ]

    toolsPanel.disableDragsDropsAndEditing()

    switcherooWm = new WindowWdgt nil, nil, toolsPanel
    switcherooWm.fullRawMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm.fullRawMoveWithin world
    world.add switcherooWm
    switcherooWm.rawSetExtent new Point 61, 192

    return switcherooWm
