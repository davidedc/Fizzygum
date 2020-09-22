class ReconfigurablePaintInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_drawingsMaker_created
      return

    simpleDocument = new @
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new PaintBucketIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "Drawings Maker",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()    

    sdspw.addNormalParagraph "Simple paint app. But you can drop anything inside it (try with the clock) to 'use it as a stamp'."

    sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
    sdspw.addNormalParagraph "To see an example of use, check out the video here:"

    startingContent = new SimpleVideoLinkWdgt "Draw app", "http://fizzygum.org/docs/draw-app/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addNormalParagraph "You can also edit the tools you use, by clicking on the pencil icon next to the tool."
    sdspw.addNormalParagraph "To see how an example of editing the tools, see this video:"

    startingContent = new SimpleVideoLinkWdgt "Hacking Fizzygum", "http://fizzygum.org/docs/hacking-fizzygum/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Drawings Maker info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_drawingsMaker_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()
