class SliderNodeCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "slider node"

  createAppearance: -> new SliderNodeIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWdgt = new SliderWdgt nil, nil, nil, nil, nil, true
    return switcherooWdgt


