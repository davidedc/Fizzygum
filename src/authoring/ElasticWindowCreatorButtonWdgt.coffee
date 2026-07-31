# this is just the same as the "generic panel"

class ElasticWindowCreatorButtonWdgt extends CreatorButtonWdgt

  iconToolTipMessage: "elastic panel"

  createAppearance: -> new ElasticWindowIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    genericPanel = new GenericPanelWdgt
    genericPanel.setTitleWithoutPrependedContentName "elastic panel"
    genericPanel._applyExtent new Point 200, 200

    return genericPanel


