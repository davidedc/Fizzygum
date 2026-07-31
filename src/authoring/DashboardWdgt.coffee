# The framed DASHBOARD citizen (Frame-model plan §5.B, owner decision D2):
# kind name + icon + toolbar variant on the GenericPanelWdgt family base.

class DashboardWdgt extends GenericPanelWdgt

  colloquialName: ->
    "Dashboards Maker"

  representativeIcon: ->
    new DashboardsIconWdgt

  # the frame docks this variant in its toolbar-slot (§5.C)
  buildToolbar: ->
    new DashboardsToolbarWdgt
