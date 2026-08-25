class PlotsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "plots/graphs"

  createAppearance: -> new AllPlotsIconAppearance @, WorldWdgt.preferencesAndSettings.iconDarkLineColor

  createWidgetToBeHandled: ->
    @_buildToolWindow new PlotsToolbarWdgt

