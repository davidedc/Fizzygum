class SlidesToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "items for slides"

  createAppearance: -> new SlidesToolbarIconAppearance @, WorldWdgt.theme.toolbarGlyph

  _createWidgetToBeHandled: ->
    @_buildToolWindow new SlidesToolbarWdgt

