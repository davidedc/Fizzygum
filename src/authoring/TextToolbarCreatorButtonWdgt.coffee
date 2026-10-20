class TextToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "Text tools"

  createAppearance: -> new TextToolbarIconAppearance @, WorldWdgt.theme.toolbarGlyph

  createWidgetToBeHandled: ->
    @_buildToolWindow new TextToolbarWdgt
