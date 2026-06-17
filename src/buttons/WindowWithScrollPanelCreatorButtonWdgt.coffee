class WindowWithScrollPanelCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "scroll panel"

  createAppearance: -> new WindowWithScrollingPanelIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt nil, nil, new ScrollPanelWdgt, true, true
    switcherooWm.rawSetExtent new Point 200, 200
    return switcherooWm


