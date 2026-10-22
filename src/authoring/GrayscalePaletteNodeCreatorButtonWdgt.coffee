class GrayscalePaletteNodeCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "grayscale palette"

  createAppearance: -> new GrayscalePalettePatchProgrammingIconAppearance @, WorldWdgt.theme.toolbarGlyph

  createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new GrayPaletteWdgt
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


