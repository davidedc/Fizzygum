class SlidesToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "items for slides"

  createAppearance: -> new SlidesToolbarIconAppearance @, WorldWdgt.theme.iconInk

  createWidgetToBeHandled: ->
    @_buildToolWindow new SlidesToolbarWdgt

