class EmptyWindowCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "empty window"

  createAppearance: -> new EmptyWindowIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    switcherooWm = new WindowWdgt()
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


