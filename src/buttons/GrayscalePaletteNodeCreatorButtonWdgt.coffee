class GrayscalePaletteNodeCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "grayscale palette"

  createAppearance: -> new GrayscalePalettePatchProgrammingIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt new GrayPaletteWdgt
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


