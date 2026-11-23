# this is just the same as the "generic panel"

class ElasticWindowCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "elastic panel"

  createAppearance: -> new ElasticWindowIconAppearance @, WorldWdgt.theme.toolbarGlyph

  _createWidgetToBeHandled: ->
    genericPanel = new GenericPanelWdgt
    # settling-call-sanctioned: titles the fresh orphan window built just above, at event time (CreatorWdgt's
    # press, or a drag on this button, asks me for it), outside any settle or pass
    genericPanel.setTitleWithoutPrependedContentName "elastic panel"
    genericPanel._applyExtent new Point 200, 200

    return genericPanel


