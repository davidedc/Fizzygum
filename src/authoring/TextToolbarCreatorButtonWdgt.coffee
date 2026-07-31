class TextToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "Text tools"

  createAppearance: -> new TextToolbarIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    @_buildToolWindow new TextToolbarWdgt, new Point 130, 156
