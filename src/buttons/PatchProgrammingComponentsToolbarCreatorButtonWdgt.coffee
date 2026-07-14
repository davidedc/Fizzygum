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

    return @_buildToolWindow toolsPanel, new Point 61, 192

