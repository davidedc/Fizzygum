class WindowsToolbarInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_windowsToolbar_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new WindowsToolbarIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "Types of windows",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()

    sdspw.addNormalParagraph "There are four main types of windows"
    sdspw.addBulletPoint "empty windows, with a target area where you can drop other items in"
    sdspw.addBulletPoint "windows that crop their content"
    sdspw.addBulletPoint "windows with a scroll view on their content"
    sdspw.addBulletPoint "windows with an elastic panel, such that when resized the content will resize as well"

    #sdspw.addNormalParagraph "Check out some examples of use in this video:"

    #startingContent = new SimpleVideoLinkWdgt "Using windows"
    #startingContent.rawSetExtent new Point 405, 50
    #sdspw.add startingContent
    #startingContent.layoutSpecDetails.setAlignmentToRight()


    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Windows info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_windowsToolbar_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()

    return wm
