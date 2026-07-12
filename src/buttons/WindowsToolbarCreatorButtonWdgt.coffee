class WindowsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "many types of\npre-made windows"

  createAppearance: -> new WindowsToolbarIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->

    toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

    toolsPanel.addMany [
      new EmptyWindowCreatorButtonWdgt
      new WindowWithPanelCreatorButtonWdgt
      new WindowWithScrollPanelCreatorButtonWdgt
      new ElasticWindowCreatorButtonWdgt
    ]

    toolsPanel.disableDragsDropsAndEditing()

    switcherooWm = new WindowWdgt nil, nil, toolsPanel
    switcherooWm._applyMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm._moveWithin world
    world.add switcherooWm
    switcherooWm._applyExtent new Point 61, 192
    readmeWindow = WindowsToolbarInfoWdgt.createNextTo switcherooWm
    readmeWindow?._applyMoveTo new Point 300, 200
    readmeWindow?._rememberFractionalSituationInHoldingPanel()

    return switcherooWm
