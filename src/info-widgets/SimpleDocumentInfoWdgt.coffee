class SimpleDocumentInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_docsMaker_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    # ---------------------

    startingContent = new TypewriterIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    # ---------------------

    startingContent = new SimplePlainTextWdgt(
      "Docs Maker",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    # ---------------------

    sdspw.addDivider()

    sdspw.addNormalParagraph "A basic text editor. But you can drop anything inside it.\n\nNote that the Docs Maker works 'by paragraph': you can drag/drop paragraphs, and when you change the style the whole paragraph is affected.\n\nQuickest way to compose a document is to drag/drop snippets, which you can find by clicking the button that looks like this:"

    # ---------------------

    startingContent = new GlassBoxBottomWdgt
    startingContent.add new TemplatesButtonWdgt
    startingContent.rawSetExtent new Point 50, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    # ---------------------

    sdspw.addSpacer()

    sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
    sdspw.addNormalParagraph "To see an example of use, check out the video here:"

    # ---------------------

    startingContent = new SimpleVideoLinkWdgt "Docs Maker", "http://fizzygum.org/docs/documents-maker/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    # ---------------------

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Docs Maker info"

    simpleDocument.disableDragsDropsAndEditing()
    world.infoDoc_docsMaker_created = true

    # if we don't do this, the window would ask to save content
    # when closed. Just destroy it instead, since we only show
    # it once.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.destroy()

    wm.fullRawMoveToSideOf nextToThisWidget
    wm.rememberFractionalSituationInHoldingPanel()
