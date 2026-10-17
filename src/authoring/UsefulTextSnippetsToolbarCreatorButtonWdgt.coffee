class UsefulTextSnippetsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "Useful text snippets"

  createAppearance: -> new TemplatesIconAppearance @, WorldWdgt.theme.iconInk

  createWidgetToBeHandled: ->
    return TemplatesWindowWdgt.create()
