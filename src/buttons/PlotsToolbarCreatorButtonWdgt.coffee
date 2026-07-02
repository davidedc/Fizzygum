class PlotsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "plots/graphs"

  createAppearance: -> new AllPlotsIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->

    toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

    toolsPanel.addMany [
      new ScatterPlotWithAxesCreatorButtonWdgt
      new FunctionPlotWithAxesCreatorButtonWdgt
      new BarPlotWithAxesCreatorButtonWdgt
      new Plot3DCreatorButtonWdgt
    ]

    toolsPanel.disableDragsDropsAndEditing()

    switcherooWm = new WindowWdgt nil, nil, toolsPanel
    switcherooWm.setExtent new Point 60, 192
    switcherooWm._applyMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm._moveWithin world
    world.add switcherooWm

    return switcherooWm

