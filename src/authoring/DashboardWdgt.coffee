# The framed DASHBOARD citizen (Frame-model plan §5.B, owner decision D2):
# kind name + icon + toolbar variant on the GenericPanelWdgt family base.

class DashboardWdgt extends GenericPanelWdgt

  #: printing

  colloquialName: ->
    "Dashboards Maker"

  #: shortcuts

  representativeIcon: ->
    new DashboardsIconWdgt

  #: docking

  # the frame docks this variant in its toolbar-slot (§5.C)
  _buildToolbar: ->
    new DashboardsToolbarWdgt
