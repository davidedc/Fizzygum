class CalculatingNodeCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "calculating node"

  createAppearance: -> new CalculatingNodeIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new CalculatingPatchNodeWdgt, true
    switcherooWm._applyExtentAndNotify new Point 260, 265
    return switcherooWm
