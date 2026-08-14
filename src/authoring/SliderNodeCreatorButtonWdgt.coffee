class SliderNodeCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "slider node"

  createAppearance: -> new SliderNodeIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWdgt = new SliderWdgt 1, 100, 50, 10, smallestValueIsAtBottomEnd: true
    return switcherooWdgt


