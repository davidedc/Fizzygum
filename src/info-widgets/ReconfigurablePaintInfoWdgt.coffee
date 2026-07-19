class ReconfigurablePaintInfoWdgt extends DocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_drawingsMaker_created
      return

    doc = new @
    iconWidget = new PaintBucketIconWdgt

    @_buildInfoDocNextTo nextToThisWidget, "infoDoc_drawingsMaker_created", doc, iconWidget, "Drawings Maker", "Drawings Maker info", (sdspw) ->

      sdspw.addNormalParagraph "Simple paint app. But you can drop anything inside it (try with the clock) to 'use it as a stamp'."

      sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
      sdspw.addNormalParagraph "To see an example of use, check out the video here:"

      startingContent = new SimpleVideoLinkWdgt "Draw app", "http://fizzygum.org/docs/draw-app/"
      startingContent._applyExtent new Point 405, 50
      sdspw.add startingContent
      startingContent.layoutSpecDetails.setAlignmentToRight()

      sdspw.addNormalParagraph "You can also edit the tools you use, by clicking on the pencil icon next to the tool."
      sdspw.addNormalParagraph "To see how an example of editing the tools, see this video:"

      startingContent = new SimpleVideoLinkWdgt "Hacking Fizzygum", "http://fizzygum.org/docs/hacking-fizzygum/"
      startingContent._applyExtent new Point 405, 50
      sdspw.add startingContent
      startingContent.layoutSpecDetails.setAlignmentToRight()
