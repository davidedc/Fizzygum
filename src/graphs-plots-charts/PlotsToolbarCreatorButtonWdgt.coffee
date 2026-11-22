class PlotsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "plots/graphs"

  createAppearance: -> new AllPlotsIconAppearance @, WorldWdgt.theme.toolbarGlyph

  _createWidgetToBeHandled: ->
    @_buildToolWindow new PlotsToolbarWdgt

