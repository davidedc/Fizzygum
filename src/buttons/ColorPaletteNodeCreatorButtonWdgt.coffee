class ColorPaletteNodeCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "color palette"

  createAppearance: -> new ColorPalettePatchProgrammingIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt new ColorPaletteWdgt
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


