class SlidesToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  iconToolTipMessage: "items for slides"

  createAppearance: -> new SlidesToolbarIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    @_buildToolWindow new SlidesToolbarWdgt, new Point 105, 300

