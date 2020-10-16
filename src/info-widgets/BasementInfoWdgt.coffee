class BasementInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_basement_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new BasementIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "Basement",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()

    sdspw.addNormalParagraph "Drag things in here to recycle them.\n\nClosed or invisible items also end up in here, and the items that can't be used again are automatically recycled."

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Basement info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_basement_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()
