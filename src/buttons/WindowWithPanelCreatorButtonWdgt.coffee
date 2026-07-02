class WindowWithPanelCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "cropping panel"

  createAppearance: -> new WindowWithCroppingPanelIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new PanelWdgt, true, true
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


