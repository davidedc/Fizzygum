# this is just the same as the "generic panel"

class ElasticWindowCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "elastic panel"

  createAppearance: -> new ElasticWindowIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    genericPanel = new StretchableEditableWdgt
    switcherooWm = new WindowWdgt nil, nil, genericPanel, true, true
    switcherooWm.setTitleWithoutPrependedContentName "elastic panel"
    switcherooWm._applyExtent new Point 200, 200

    return switcherooWm


