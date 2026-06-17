class GrayscalePaletteNodeCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new GrayscalePalettePatchProgrammingIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "grayscale palette"

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new GrayPaletteWdgt, true
    switcherooWm.rawSetExtent new Point 200, 200
    return switcherooWm


