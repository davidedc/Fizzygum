class WindowsToolbarInfoWdgt extends SimpleDocumentWdgt

  # NB returns the WindowWdgt: WindowsToolbarCreatorButtonWdgt captures it (readmeWindow) to reposition it.
  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_windowsToolbar_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    iconWidget = new WindowsToolbarIconWdgt

    @_buildInfoDocNextTo nextToThisWidget, "infoDoc_windowsToolbar_created", simpleDocument, iconWidget, "Types of windows", "Windows info", (sdspw) ->

      sdspw.addNormalParagraph "There are four main types of windows"
      sdspw.addBulletPoint "empty windows, with a target area where you can drop other items in"
      sdspw.addBulletPoint "windows that crop their content"
      sdspw.addBulletPoint "windows with a scroll view on their content"
      sdspw.addBulletPoint "windows with an elastic panel, such that when resized the content will resize as well"

      #sdspw.addNormalParagraph "Check out some examples of use in this video:"

      #startingContent = new SimpleVideoLinkWdgt "Using windows"
      #startingContent._applyExtent new Point 405, 50
      #sdspw.add startingContent
      #startingContent.layoutSpecDetails.setAlignmentToRight()
