class SlidesToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "items for slides"

  createAppearance: -> new SlidesToolbarIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    @_buildToolWindow new SlidesToolbarWdgt

