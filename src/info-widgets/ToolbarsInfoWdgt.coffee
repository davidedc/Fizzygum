class ToolbarsInfoWdgt extends DocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_superToolbar_created
      return nil

    doc = new DocumentWdgt
    iconWidget = new ToolbarsIconWdgt

    @_buildInfoDocNextTo nextToThisWidget, "infoDoc_superToolbar_created", doc, iconWidget, "Super Toolbar", "Super Toolbar info", (sdspw) ->

      sdspw.addNormalParagraph "The Super Toolbar can create all other toolbars for you, and from those toolbars you can create any widget.\n\nThis is handy because any widget can go in any document... so here is a way to access them all.\n\nFor an example on how this is useful, see the video on `mixing widgets`:"

      startingContent = new SimpleVideoLinkWdgt "Mixing widgets", "http://fizzygum.org/docs/mixing-widgets/"
      startingContent._applyExtent new Point 405, 50
      sdspw.add startingContent
      startingContent.layoutSpecDetails.setAlignmentToRight()
