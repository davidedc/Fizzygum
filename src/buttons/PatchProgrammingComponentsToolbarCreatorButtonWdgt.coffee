class PatchProgrammingComponentsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "components that can be connected"

  createAppearance: -> new PatchProgrammingComponentsIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->

    toolsPanel = new ScrollPanelWdgt new ToolPanelWdgt

    toolsPanel.addMany [
      new SliderNodeCreatorButtonWdgt
      new ColorPaletteNodeCreatorButtonWdgt
      new GrayscalePaletteNodeCreatorButtonWdgt
      new CalculatingNodeCreatorButtonWdgt
    ]

    toolsPanel.disableDragsDropsAndEditing()

    switcherooWm = new WindowWdgt nil, nil, toolsPanel
    switcherooWm._applyMoveTo new Point 90, Math.floor((world.height()-192)/2)
    switcherooWm._moveWithin world
    world.add switcherooWm
    switcherooWm._applyExtent new Point 61, 192

    return switcherooWm

