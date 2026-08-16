class WindowWithScrollPanelCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "scroll panel"

  createAppearance: -> new WindowWithScrollingPanelIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt new ScrollPanelWdgt
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


