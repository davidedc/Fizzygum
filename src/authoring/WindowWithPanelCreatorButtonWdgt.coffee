class WindowWithPanelCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "cropping panel"

  createAppearance: -> new WindowWithCroppingPanelIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new PanelWdgt
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


