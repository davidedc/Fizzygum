class SimpleDocumentSampleWdgt extends SimpleDocumentWdgt

  @create: ->
    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new SimplePlainTextWdgt(
      "Sample Doc",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.setContents startingContent, 5

    sdspw.addDivider()

    sdspw.addNormalParagraph "Text documents (or simply: docs) don't just contain text or images: they can embed any widget."
    sdspw.addNormalParagraph "For example, here is an interactive 3D plot:\n"

    plot3D = new WindowWdgt nil, nil, new Example3DPlotWdgt, true, true
    plot3D.rawSetExtent new Point 400, 255
    # "constrainToRatio" makes it so the plot in the doc gets taller
    # as the page is made wider
    plot3D.contents.constrainToRatio()
    sdspw.add plot3D

    sdspw.addSpacer()

    sdspw.addNormalParagraph "Connected widgets can be added too, for example this slider below controls the data points of the graph above:\n"

    slider1 = new SliderMorph nil, nil, nil, nil, nil, true
    slider1.rawSetExtent new Point 400, 24
    sdspw.add slider1
    slider1.setTargetAndActionWithOnesPickedFromMenu nil, nil, plot3D.contents, "setParameter"

    sdspw.addSpacer()

    sdspw.addNormalParagraph "How to add connected widgets? Simple: just connect any number of them (see the °C ↔ °F converter for an example), then drop them in the doc."

    sdspw.addSpacer()

    sdspw.addNormalParagraph "What else could be added? Anything! Scripts, maps, maps inside scrolling views, maps with graphs, slides, other docs, and on and on and on..."

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 331, 545
    wm.fullRawMoveTo new Point 257, 110
    world.add wm
    wm.setTitleWithoutPrependedContentName "Sample text document"

    simpleDocument.disableDragsDropsAndEditing()

    
    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()

    return wm
