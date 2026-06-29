class ColorPaletteNodeCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "color palette"

  createAppearance: -> new ColorPalettePatchProgrammingIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new ColorPaletteWdgt, true
    switcherooWm._applyExtentAndNotify new Point 200, 200
    return switcherooWm


