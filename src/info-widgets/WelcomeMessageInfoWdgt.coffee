class WelcomeMessageInfoWdgt extends SimpleDocumentWdgt

  @create: ->
    simpleDocument = new SimpleDocumentWdgt
    sdspw = simpleDocument.simpleDocumentScrollPanel

    sdspw.fullRawMoveTo new Point 114, 10
    sdspw.rawSetExtent new Point 365, 405

    startingContent = new FizzygumLogoIconWdgt
    startingContent.rawSetExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setElasticity 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()


    startingContent = new SimplePlainTextWdgt(
      "Welcome to Fizzygum",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 24
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    startingContent = new SimplePlainTextWdgt(
      "version 1.1.12",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 9
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()


    sdspw.addNormalParagraph "Tired of stringing libraries together?"
    sdspw.addNormalParagraph "Welcome to a powerful new framework designed from the ground up to do complex things, easily."

    sdspw.addSpacer()

    startingContent = new SimplePlainTextWdgt(
      "What it can do for you",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()

    sdspw.addNormalParagraph "Fizzygum enables you to do all of this and more:"

    sdspw.addBulletPoint "make dashboards and visualise data (plots, maps, ...)"
    sdspw.addBulletPoint "author, organise and navigate documents (drawings / text docs / slides)"
    sdspw.addBulletPoint "embed live graphs, dynamic calculations or even entire running programs inside any document, via simple drag & drop"
    sdspw.addBulletPoint "go beyond traditional embedding: you can now infinitely nest and compose programs and documents. Need a program inside a presentation inside a text? You have it"
    sdspw.addBulletPoint "make custom utilities (e.g. temperature converter) by simply connecting existing components - no coding required"
    sdspw.addBulletPoint "use the internal development tools to create entirely new apps, or change existing ones while they are running. Add custom features without even needing to refresh the page."
    sdspw.addBulletPoint "do all of the above, concurrently"

    sdspw.addSpacer()

    startingContent = new SimplePlainTextWdgt(
      "New here?",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()

    sdspw.addNormalParagraph "Feel free to click around this sandbox. Double-click the items on the desktop to open them. Just reload to start again from scratch."

    sdspw.addSpacer()
    sdspw.addNormalParagraph "Also check out some screenshots here:"

    startingContent = new SimpleLinkWdgt "Screenshots", "http://fizzygum.org/screenshots/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addNormalParagraph "...or watch some quick demos on the Youtube channel:"

    startingContent = new SimpleVideoLinkWdgt "YouTube channel", "https://www.youtube.com/channel/UCmYco9RU3h9dofRVN3bqxIw"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addNormalParagraph "...or docs here:"

    startingContent = new SimpleLinkWdgt "Docs", "http://fizzygum.org/docs/intro/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addSpacer(2)

    startingContent = new SimplePlainTextWdgt(
      "Get in touch",nil,nil,nil,nil,nil,WorldMorph.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent

    sdspw.addDivider()

    sdspw.addNormalParagraph "Mail? Mailing list? Facebook page? Twitter? Chat? We have it all."

    startingContent = new SimpleLinkWdgt "Contacts", "http://fizzygum.org/contact/"
    startingContent.rawSetExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    wm = new WindowWdgt nil, nil, simpleDocument
    wm.rawSetExtent new Point 365, 405
    wm.fullRawMoveFullCenterTo world.center()
    world.add wm
    wm.setTitleWithoutPrependedContentName "Welcome"

    simpleDocument.disableDragsDropsAndEditing()

    return wm
