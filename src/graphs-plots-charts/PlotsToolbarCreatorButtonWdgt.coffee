class PlotsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "plots/graphs"

  createAppearance: -> new AllPlotsIconAppearance @, WorldWdgt.theme.iconInk

  createWidgetToBeHandled: ->
    @_buildToolWindow new PlotsToolbarWdgt

