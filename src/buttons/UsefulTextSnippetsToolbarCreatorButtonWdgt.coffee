class UsefulTextSnippetsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  constructor: ->
    super
    @appearance = new TemplatesIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "Useful text snippets"

  createWidgetToBeHandled: ->
    return menusHelper.createNewTemplatesWindow()
