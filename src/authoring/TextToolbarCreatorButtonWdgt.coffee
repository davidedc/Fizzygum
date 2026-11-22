class TextToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "Text tools"

  createAppearance: -> new TextToolbarIconAppearance @, WorldWdgt.theme.toolbarGlyph

  _createWidgetToBeHandled: ->
    @_buildToolWindow new TextToolbarWdgt
