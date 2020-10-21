class DashboardsInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_dashboardsMaker_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    # ---------------------

    startingContent = new DashboardsIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    # ---------------------

    startingContent = new SimplePlainTextWdgt(
      "Dashboards Maker",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    # ---------------------

    sdspw.addDivider()

    sdspw.addNormalParagraph "Lets you arrange a choice of graphs/charts/plots/maps in any way you please. The visualisations can also be interactive (as in the 3D plot example, which you can drag to rotate) and/or calculated on the fly.\n\nOn the bar on the left you can find four example graphs and two example maps."

    sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
    sdspw.addNormalParagraph "To see an example of use, check out the video here:"

    # ---------------------

    startingContent = new SimpleVideoLinkWdgt "Dashboards Maker", "http://fizzygum.org/docs/dashboards/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    # ---------------------

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Dashboards Maker info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_dashboardsMaker_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()
