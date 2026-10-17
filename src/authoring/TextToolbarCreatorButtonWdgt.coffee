class TextToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "Text tools"

  createAppearance: -> new TextToolbarIconAppearance @, WorldWdgt.theme.iconInk

  createWidgetToBeHandled: ->
    @_buildToolWindow new TextToolbarWdgt
