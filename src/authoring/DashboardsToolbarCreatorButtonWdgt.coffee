# The Super toolbar's entry for the dashboard-authoring toolbar (DashboardsToolbarWdgt): a click (or a
# drag out) opens it floating. Its face is the Dashboards desktop icon in the toolbar's ink, the Maker the
# toolbar belongs to.

class DashboardsToolbarCreatorButtonWdgt extends ToolbarCreatorButtonWdgt

  toolTipMessage: "Dashboard tools"

  createAppearance: -> new DashboardsIconAppearance @, WorldWdgt.theme.toolbarGlyph

  createWidgetToBeHandled: ->
    @_buildToolWindow new DashboardsToolbarWdgt
