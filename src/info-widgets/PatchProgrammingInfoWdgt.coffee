class PatchProgrammingInfoWdgt extends DocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_patchProgramming_created
      return nil

    doc = new DocumentWdgt
    iconWidget = new PatchProgrammingIconWdgt

    @_buildInfoDocNextTo nextToThisWidget, "infoDoc_patchProgramming_created", doc, iconWidget, "Patch Programming", "Patch Programming info", (sdspw) ->

      sdspw.addNormalParagraph "'Patch programming' is a type of visual programming where you simply connect together existing widgets. It's useful to make simple applications/utilities quickly."
      sdspw.addNormalParagraph "You can imagine the widgets being 'patched together' by imaginary wires."
      sdspw.addNormalParagraph "You can see in the `example docs` folder a °C ↔ °F converter example made with this."
      sdspw.addNormalParagraph "Once you are done editing, click the pencil icon on the window bar."
      sdspw.addNormalParagraph "To see an example of use, check out the videos here:"

      startingContent = new SimpleVideoLinkWdgt "Patch programming - basics", "http://fizzygum.org/docs/basic-connections/"
      startingContent._applyExtent new Point 405, 50
      sdspw.add startingContent
      startingContent.layoutSpecDetails.setAlignmentToRight()

      startingContent = new SimpleVideoLinkWdgt "Patch programming - advanced", "http://fizzygum.org/docs/advanced-connections/"
      startingContent._applyExtent new Point 405, 50
      sdspw.add startingContent
      startingContent.layoutSpecDetails.setAlignmentToRight()
