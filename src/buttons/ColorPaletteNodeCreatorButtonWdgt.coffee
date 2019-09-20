class ColorPaletteNodeCreatorButtonWdgt extends CreatorButtonWdgt

  constructor: ->
    super
    @appearance = new ColorPalettePatchProgrammingIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "color palette"

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new ColorPaletteMorph, true
    switcherooWm.rawSetExtent new Point 200, 200
    return switcherooWm


