class BasementInfoWdgt extends SimpleDocumentWdgt

  @createNextTo: (nextToThisWidget) ->
    if world.infoDoc_basement_created
      return nil

    simpleDocument = new SimpleDocumentWdgt
    iconWidget = new BasementIconWdgt

    @_buildInfoDocNextTo nextToThisWidget, "infoDoc_basement_created", simpleDocument, iconWidget, "Basement", "Basement info", (sdspw) ->

      sdspw.addNormalParagraph "Drag things in here to recycle them.\n\nClosed or invisible items also end up in here, and the items that can't be used again are automatically recycled."
