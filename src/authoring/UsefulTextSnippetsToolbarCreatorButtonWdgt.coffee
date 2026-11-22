class UsefulTextSnippetsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "Useful text snippets"

  createAppearance: -> new TemplatesIconAppearance @, WorldWdgt.theme.toolbarGlyph

  _createWidgetToBeHandled: ->
    return TemplatesWindowWdgt.create()
