# HowToSaveMessageApp -- the "How to save?" desktop app (a SimpleDocument explaining
# how to save). One of the per-app IconicDesktopSystemWindowedApp subclasses (Phase 6
# step 6c.3): it declares its launcher title/icon and the singleton world slot and
# builds its window inline in buildWindow; the base owns the launcher/opener + the
# bring-up-or-create launch logic. Its opener is on the DESKTOP (no folder), so the
# WorldWdgt bootstrap calls createOpener() with no argument. The window body was folded
# in verbatim from the former HowToSaveMessageInfoWdg.create (a single-use factory-
# namespace class, now removed -- which also fixes its filename/classname mismatch).

class HowToSaveMessageApp extends IconicDesktopSystemWindowedApp

  title: "How to save?"
  slot:  "howToSaveDocWindow"

  buildIcon: -> new FloppyDiskIconWdgt

  buildWindow: ->
    doc = new DocumentWdgt
    sdspw = doc.contents

    startingContent = new FloppyDiskIconWdgt
    startingContent._applyExtent new Point 85, 85

    sdspw.setContents startingContent, 5
    startingContent.layoutSpecDetails.setGrow 0
    startingContent.layoutSpecDetails.setAlignmentToCenter()

    startingContent = new SimpleTextWdgt(
      "How to save?",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 24
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.add startingContent


    sdspw.addDivider()


    sdspw.addNormalParagraph "There are a couple of ways to save data in Fizzygum.¹\n\nHowever, \"in-house\" stable saving solutions are only available in private versions.²\n\nIn the meantime that these solutions make their way into the public version, the Fizzygum team can consult for you to tailor 'saving' functionality to your needs (save to file, save to cloud, connect to databases etc. ).\n\nPlease enquiry via one of the Fizzygum contacts here:"

    sdspw.addSpacer()

    startingContent = new SimpleLinkWdgt "Contacts", "http://fizzygum.org/contact/"
    startingContent._applyExtent new Point 405, 50
    sdspw.add startingContent
    startingContent.layoutSpecDetails.setAlignmentToRight()

    sdspw.addSpacer()

    startingContent = new SimpleTextWdgt(
      "Footnotes",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
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


    doc._applyBounds (new Point 114, 10), new Point 365, 447
    world.add doc
    doc._rememberFractionalSituationInHoldingPanel()
    doc.setTitleWithoutPrependedContentName "How to save?"

    doc.disableDragsDropsAndEditing()

    # closing just closes (no save prompt) -- a sample window isn't worth
    # saving. The tracked close policy (§5.E E2), replacing the untracked
    # instance-method injection this once was.
    doc.closeFromFrameBarPolicy = 'close'

    return doc
