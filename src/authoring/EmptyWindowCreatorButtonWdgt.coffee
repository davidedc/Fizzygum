class EmptyWindowCreatorButtonWdgt extends CreatorButtonWdgt

  toolTipMessage: "empty window"

  createAppearance: -> new EmptyWindowIconAppearance @, WorldWdgt.theme.toolbarGlyph

  _createWidgetToBeHandled: ->
    switcherooWm = new FrameWdgt()
    switcherooWm._applyExtent new Point 200, 200
    return switcherooWm


