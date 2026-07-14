class SimpleSlideInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_slidesMaker_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    iconWidget = new SimpleSlideIconWdgt

    @_buildInfoDocNextTo nextToThisWidget, "infoDoc_slidesMaker_created", simpleDocument, iconWidget, "Slides Maker", "Slides Maker info", (sdspw) ->

      sdspw.addNormalParagraph "Anything you drop inside the slide 'keeps proportion' when resized, which makes it handy to put pins on maps, add callouts, arrange text in custom layouts etc."

      sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
      sdspw.addNormalParagraph "To see an example of use, check out the video here:"

      startingContent = new SimpleVideoLinkWdgt "Slides Maker", "http://fizzygum.org/docs/slides-maker/"
      startingContent._applyExtent new Point 405, 50
      sdspw.add startingContent
      startingContent.layoutSpecDetails.setAlignmentToRight()
