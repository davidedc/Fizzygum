class SimpleDocumentInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_docsMaker_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    iconWidget = new TypewriterIconWdgt

    @_buildInfoDocNextTo nextToThisWidget, "infoDoc_docsMaker_created", simpleDocument, iconWidget, "Docs Maker", "Docs Maker info", (sdspw) ->

      sdspw.addNormalParagraph "A basic text editor. But you can drop anything inside it.\n\nNote that the Docs Maker works 'by paragraph': you can drag/drop paragraphs, and when you change the style the whole paragraph is affected.\n\nQuickest way to compose a document is to drag/drop snippets, which you can find by clicking the button that looks like this:"

      startingContent = new GlassBoxBottomWdgt
      startingContent.add new TemplatesButtonWdgt
      startingContent._applyExtent new Point 50, 50
      sdspw.add startingContent
      startingContent.layoutSpecDetails.setAlignmentToCenter()

      sdspw.addSpacer()

      sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
      sdspw.addNormalParagraph "To see an example of use, check out the video here:"

      startingContent = new SimpleVideoLinkWdgt "Docs Maker", "http://fizzygum.org/docs/documents-maker/"
      startingContent._applyExtent new Point 405, 50
      sdspw.add startingContent
      startingContent.layoutSpecDetails.setAlignmentToRight()
