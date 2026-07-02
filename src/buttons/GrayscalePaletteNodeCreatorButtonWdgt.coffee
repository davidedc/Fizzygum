class GrayscalePaletteNodeCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "grayscale palette"

  createAppearance: -> new GrayscalePalettePatchProgrammingIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new GrayPaletteWdgt, true
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


