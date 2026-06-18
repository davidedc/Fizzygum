# DegreesConverterApp -- the "C <-> F" degrees-converter example app (a patch-
# programming window wiring two sliders/calc nodes into a live converter). One of the
# per-app IconicDesktopSystemWindowedApp subclasses (Phase 6 step 6c.3): it declares
# its launcher title/icon and the singleton world slot and builds its window inline in
# buildWindow; the base owns the launcher/opener + bring-up-or-create launch logic. The
# window body was lifted verbatim from MenusHelper's
# createDegreesConverterWindowOrBringItUpIfAlreadyCreated (minus the final world-slot
# assignment, now done by the base's launch).

class DegreesConverterApp extends IconicDesktopSystemWindowedApp

  title: "°C ↔ °F"
  slot:  "degreesConverterWindow"

  buildIcon: -> new DegreesConverterIconWdgt

  buildWindow: ->
    xCorrection = 32
    yCorrection = 50
    patchProgrammingWdgt = new PatchProgrammingWdgt

    container = patchProgrammingWdgt.stretchableWidgetContainer.contents
    container.rawSetExtent new Point 584,552

    slider1 = new SliderWdgt nil, nil, nil, nil, nil, true
    slider1.fullRawMoveTo container.position().add new Point 43+xCorrection, 195+yCorrection
    slider1.rawSetExtent new Point 20, 100
    container.add slider1
    slider1.rememberFractionalSituationInHoldingPanel()

    slider2 = new SliderWdgt nil, nil, nil, nil, nil, true
    slider2.fullRawMoveTo container.position().add new Point 472+xCorrection, 203+yCorrection
    slider2.rawSetExtent new Point 20, 100
    container.add slider2
    slider2.rememberFractionalSituationInHoldingPanel()

    cText = new TextWdgt "0"
    cText.fullRawMoveTo container.position().add new Point 104, 253
    cText.rawSetExtent new Point 150, 75
    container.add cText
    cText.rememberFractionalSituationInHoldingPanel()

    fText = new TextWdgt "0"
    fText.fullRawMoveTo container.position().add new Point 344, 255
    fText.alignRight()
    fText.rawSetExtent new Point 150, 75
    container.add fText
    fText.rememberFractionalSituationInHoldingPanel()

    calc1 = new WindowWdgt nil, nil, new CalculatingPatchNodeWdgt("# °C → °F formula\n(in1)->Math.round in1*9/5+32"), true
    calc1.fullRawMoveTo container.position().add new Point 148+xCorrection/2, 19
    calc1.rawSetExtent new Point 241, 167
    container.add calc1
    calc1.rememberFractionalSituationInHoldingPanel()

    calc2 = new WindowWdgt nil, nil, new CalculatingPatchNodeWdgt("# °F → °C formula\n(in1)->Math.round (in1-32)*5/9"), true
    calc2.fullRawMoveTo container.position().add new Point 148+xCorrection/2, 365
    calc2.rawSetExtent new Point 241, 167
    container.add calc2
    calc2.rememberFractionalSituationInHoldingPanel()


    slider1.setTargetAndActionWithOnesPickedFromMenu nil, nil, cText, "setText"
    cText.setTargetAndActionWithOnesPickedFromMenu nil, nil, calc1.contents, "setInput1"
    calc1.contents.setTargetAndActionWithOnesPickedFromMenu nil, nil, fText, "setText"
    fText.setTargetAndActionWithOnesPickedFromMenu nil, nil, slider2, "setValue"
    slider2.setTargetAndActionWithOnesPickedFromMenu nil, nil, calc2.contents, "setInput1"
    calc2.contents.setTargetAndActionWithOnesPickedFromMenu nil, nil, slider1, "setValue"



    cLabel = new TextWdgt "°C"
    cLabel.fullRawMoveTo container.position().add new Point 0+xCorrection, 102+yCorrection
    cLabel.rawSetExtent new Point 90, 90
    container.add cLabel
    cLabel.rememberFractionalSituationInHoldingPanel()

    fLabel = new TextWdgt "°F"
    fLabel.fullRawMoveTo container.position().add new Point 422+xCorrection, 102+yCorrection
    fLabel.rawSetExtent new Point 90, 90
    container.add fLabel
    fLabel.rememberFractionalSituationInHoldingPanel()

    #@inform (@position().subtract @parent.position()) + " " +  @extent()

    wm = new WindowWdgt nil, nil, patchProgrammingWdgt
    wm.fullRawMoveTo new Point 114, 10
    wm.rawSetExtent new Point 596, 592
    world.add wm
    wm.setTitleWithoutPrependedContentName "°C ↔ °F converter"


    patchProgrammingWdgt.disableDragsDropsAndEditing()
    
    cText.isEditable = true
    fText.isEditable = true

    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    patchProgrammingWdgt.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()

    return wm
