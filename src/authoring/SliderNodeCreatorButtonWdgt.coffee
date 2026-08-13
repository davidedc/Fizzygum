class SliderNodeCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "slider node"

  createAppearance: -> new SliderNodeIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWdgt = new SliderWdgt undefined, undefined, undefined, undefined, undefined, true
    return switcherooWdgt


