class WindowWithPanelCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "cropping panel"

  createAppearance: -> new WindowWithCroppingPanelIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt new PanelWdgt
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


