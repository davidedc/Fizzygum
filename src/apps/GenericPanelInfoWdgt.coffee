class GenericPanelInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_genericPanel_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    # ---------------------

    startingContent = new GenericPanelIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    # ---------------------

    startingContent = new SimplePlainTextWdgt(
      "Generic Panel",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    # ---------------------

    sdspw.addDivider()    

    sdspw.addNormalParagraph "You can use this panel to temporarily hold widgets, or to put together any mix of widgets. It's just a more generic version of slides and dashboards."
    sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
    sdspw.addNormalParagraph "To see an example of use, check out the video here:"

    # ---------------------

    startingContent = new SimpleVideoLinkWdgt "Mixing widgets (using generic panels)", "http://fizzygum.org/docs/mixing-widgets/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    # ---------------------

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Generic Panels info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_genericPanel_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()
