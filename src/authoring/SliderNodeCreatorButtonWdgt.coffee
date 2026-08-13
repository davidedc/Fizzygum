class SliderNodeCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "slider node"

  createAppearance: -> new SliderNodeIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWdgt = new SliderWdgt smallestValueIsAtBottomEnd: true
    return switcherooWdgt


