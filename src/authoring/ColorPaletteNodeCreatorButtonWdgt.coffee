class ColorPaletteNodeCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "color palette"

  createAppearance: -> new ColorPalettePatchProgrammingIconAppearance @, WorldWdgt.theme.iconInk

  createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new ColorPaletteWdgt
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


