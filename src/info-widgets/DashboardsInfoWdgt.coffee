class DashboardsInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_dashboardsMaker_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    iconWidget = new DashboardsIconWdgt

    @_buildInfoDocNextTo nextToThisWidget, "infoDoc_dashboardsMaker_created", simpleDocument, iconWidget, "Dashboards Maker", "Dashboards Maker info", (sdspw) ->

      sdspw.addNormalParagraph "Lets you arrange a choice of graphs/charts/plots/maps in any way you please. The visualisations can also be interactive (as in the 3D plot example, which you can drag to rotate) and/or calculated on the fly.\n\nOn the bar on the left you can find four example graphs and two example maps."

      sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
      sdspw.addNormalParagraph "To see an example of use, check out the video here:"

      startingContent = new SimpleVideoLinkWdgt "Dashboards Maker", "http://fizzygum.org/docs/dashboards/"
      startingContent._applyExtent new Point 405, 50
      sdspw.add startingContent
      startingContent.layoutSpecDetails.setAlignmentToRight()
