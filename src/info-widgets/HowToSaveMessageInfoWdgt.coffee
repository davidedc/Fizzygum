class HowToSaveMessageInfoWdg extends SimpleDocumentWdgt

  @create: ->
    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new FloppyDiskIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimplePlainTextWdgt(
      "How to save?",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 24
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent


    sdspw.addDivider()


    sdspw.addNormalParagraph "There are a couple of ways to save data in Fizzygum.¹\n\nHowever, \"in-house\" stable saving solutions are only available in private versions.²\n\nIn the meantime that these solutions make their way into the public version, the Fizzygum team can consult for you to tailor 'saving' functionality to your needs (save to file, save to cloud, connect to databases etc. ).\n\nPlease enquiry via one of the Fizzygum contacts here:"

    sdspw.addSpacer()

    startingContent = new SimpleLinkWdgt "Contacts", "http://fizzygum.org/contact/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addSpacer()

    startingContent = new SimplePlainTextWdgt(
      "Footnotes",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.toggleWeight()
    startingContent.isEditable = true
    startingContent.enableSelecting()
    startingContent.toggleHeaderLine()
    sdspw.add startingContent

    sdspw.addSpacer()

    sdspw.addNormalParagraph "¹ Saving solutions:\n"+
     "1) saving data with existing formats (e.g. markdown etc.). Advantages: compatibility. Disadvantages: works only with \"plain\" documents (no live documents, no documents within documents etc.)\n"+
     "2) serialising objects graph. Advantages: fidelity. Disadvantages: needs some management of versioning of Fizzygum platform and documents\n"+
     "3) deducing source code to generate content. Advantages: compactness, inspectability of source code, high-level semantics of source code preserved. Disadvantages: only possible with relatively simple objects.\n"+
     "\n"+
     "² Why private beta:\n"+
     "Proliferation of saving solutions done without our help could be detrimental to the Fizzygum platform (due to degraded experience on third party sites, incompatibilities between sites, migration issues, security issues, etc.), hence the Fizzygum team decided to withhold this functionality from public until we can package an open turn-key solution that minimises misuse and sub-par experiences."


    wm = new WindowWdgt nil, nil, simpleDocument
    wm.fullRawMoveTo new Point 114, 10
    wm.rawSetExtent new Point 365, 447
    world.add wm
    wm.rememberFractionalSituationInHoldingPanel()
    wm.setTitleWithoutPrependedContentName "How to save?"

    simpleDocument.disableDragsDropsAndEditing()

    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    simpleDocument.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()

    return wm
