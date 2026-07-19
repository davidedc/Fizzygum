# SampleDocApp -- the "sample doc" example app (a SimpleDocument showing what can be
# embedded in a text document: an interactive 3D plot, a connected slider, etc.). One
# of the per-app IconicDesktopSystemWindowedApp subclasses (Phase 6 step 6c.3): it
# declares its launcher title/icon and the singleton world slot and builds its window
# inline in buildWindow; the base owns the launcher/opener + bring-up-or-create launch
# logic. The window body was folded in verbatim from the former
# SimpleDocumentSampleWdgt.create (a single-use factory-namespace class, now removed).

class SampleDocApp extends IconicDesktopSystemWindowedApp

  title: "sample doc"
  slot:  "sampleDocWindow"

  buildIcon: -> new GenericShortcutIconWdgt new TypewriterIconWdgt

  buildWindow: ->
    doc = new DocumentWdgt
    sdspw = doc.contents

    startingContent = new SimpleTextWdgt(
      "Sample Doc",nil,nil,nil,nil,nil,WorldWdgt.preferencesAndSettings.editableItemBackgroundColor, 1)
    startingContent.alignCenter()
    startingContent.setFontSize 22
    startingContent.isEditable = true
    startingContent.enableSelecting()
    sdspw.setContents startingContent, 5

    sdspw.addDivider()

    sdspw.addNormalParagraph "Text documents (or simply: docs) don't just contain text or images: they can embed any widget."
    sdspw.addNormalParagraph "For example, here is an interactive 3D plot:\n"

    plot3D = new FrameWdgt new Example3DPlotWdgt
    plot3D._applyExtent new Point 400, 255
    # "_constrainToRatio" makes it so the plot in the doc gets taller
    # as the page is made wider
    plot3D.contents._constrainToRatio()
    sdspw.add plot3D

    sdspw.addSpacer()

    sdspw.addNormalParagraph "Connected widgets can be added too, for example this slider below controls the data points of the graph above:\n"

    slider1 = new SliderWdgt nil, nil, nil, nil, nil, true
    slider1._applyExtent new Point 400, 24
    sdspw.add slider1
    slider1.setTargetAndActionWithOnesPickedFromMenu nil, nil, plot3D.contents, "setParameter"

    sdspw.addSpacer()

    sdspw.addNormalParagraph "How to add connected widgets? Simple: just connect any number of them (see the °C ↔ °F converter for an example), then drop them in the doc."

    sdspw.addSpacer()

    sdspw.addNormalParagraph "What else could be added? Anything! Scripts, maps, maps inside scrolling views, maps with graphs, slides, other docs, and on and on and on..."

    doc._applyExtent new Point 331, 545
    doc._applyMoveTo new Point 257, 110
    world.add doc
    doc.setTitleWithoutPrependedContentName "Sample text document"

    doc.disableDragsDropsAndEditing()


    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    doc.closeFromFrameBar = ->
      @close()

    # return the WINDOW: the base stores it in world[@slot] for the
    # bring-forward-on-relaunch path. (The old code fell off the end returning
    # the monkey-patch closure, so the slot held a FUNCTION -- latent.)
    return doc

    return wm
