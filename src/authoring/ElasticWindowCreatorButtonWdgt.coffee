# this is just the same as the "generic panel"

class ElasticWindowCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "elastic panel"

  createAppearance: -> new ElasticWindowIconAppearance @, WorldWdgt.theme.toolbarGlyph

  _createWidgetToBeHandled: ->
    # nosettle-sanctioned: titles the fresh orphan window built here, at event time (a click or a drag on
    # this button), outside any pass
    genericPanel = new GenericPanelWdgt
    genericPanel.setTitleWithoutPrependedContentName "elastic panel"
    genericPanel._applyExtent new Point 200, 200

    return genericPanel


