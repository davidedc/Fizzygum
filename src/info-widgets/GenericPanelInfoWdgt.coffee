class GenericPanelInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_genericPanel_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    iconWidget = new GenericPanelIconWdgt

    @_buildInfoDocNextTo nextToThisWidget, "infoDoc_genericPanel_created", simpleDocument, iconWidget, "Generic Panel", "Generic Panels info", (sdspw) ->

      sdspw.addNormalParagraph "You can use this panel to temporarily hold widgets, or to put together any mix of widgets. It's just a more generic version of slides and dashboards."
      sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
      sdspw.addNormalParagraph "To see an example of use, check out the video here:"

      startingContent = new SimpleVideoLinkWdgt "Mixing widgets (using generic panels)", "http://fizzygum.org/docs/mixing-widgets/"
      startingContent._applyExtent new Point 405, 50
      sdspw.add startingContent
      startingContent.layoutSpecDetails.setAlignmentToRight()
