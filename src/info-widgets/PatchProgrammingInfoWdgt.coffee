class PatchProgrammingInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_patchProgramming_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    # ---------------------

    startingContent = new PatchProgrammingIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    # ---------------------

    startingContent = new SimplePlainTextWdgt(
      "Patch Programming",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    # ---------------------

    sdspw.addDivider()

    sdspw.addNormalParagraph "'Patch programming' is a type of visual programming where you simply connect together existing widgets. It's useful to make simple applications/utilities quickly."
    sdspw.addNormalParagraph "You can imagine the widgets being 'patched together' by imaginary wires."
    sdspw.addNormalParagraph "You can see in the `example docs` folder a °C ↔ °F converter example made with this."
    sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
    sdspw.addNormalParagraph "To see an example of use, check out the videos here:"

    # ---------------------

    startingContent = new SimpleVideoLinkWdgt "Patch programming - basics", "http://fizzygum.org/docs/basic-connections/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    # ---------------------

    startingContent = new SimpleVideoLinkWdgt "Patch programming - advanced", "http://fizzygum.org/docs/advanced-connections/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    # ---------------------

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Patch Programming info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_patchProgramming_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()
