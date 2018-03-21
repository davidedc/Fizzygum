class UsefulTextSnippetsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  constructor: ->
    super
    @appearance = new TemplatesIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "Useful text snippets"

  createWidgetToBeHandled: ->
    return menusHelper.createNewTemplatesWindow()
