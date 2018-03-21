class UsefulTextSnippetsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  constructor: ->
    super
    @appearance = new TemplatesIconAppearance @, WorldMorph.preferencesAndSettings.iconDarkLineColor
    @toolTipMessage = "Useful text snippets"

  grabbedWidgetSwitcheroo: ->
    return menusHelper.createNewTemplatesWindow()
