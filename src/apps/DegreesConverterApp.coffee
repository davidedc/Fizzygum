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
    container._applyExtent new Point 584,552

    # Build this orphan window tree settle-free: `container` is part of the not-yet-attached
    # patchProgrammingWdgt, so add the body widgets via the non-settling _addNoSettle core (orphan
    # construction). Under orphan-settledness a public container.add() would settle MID-construction
    # on the half-built tree and crash; the single `world.add wm` below settles the whole tree once.

    slider1 = new SliderWdgt nil, nil, nil, nil, nil, true
    slider1._applyMoveTo container.position().add new Point 43+xCorrection, 195+yCorrection
    slider1._applyExtent new Point 20, 100
    container._addNoSettle slider1
    slider1._rememberFractionalSituationInHoldingPanel()

    slider2 = new SliderWdgt nil, nil, nil, nil, nil, true
    slider2._applyMoveTo container.position().add new Point 472+xCorrection, 203+yCorrection
    slider2._applyExtent new Point 20, 100
    container._addNoSettle slider2
    slider2._rememberFractionalSituationInHoldingPanel()

    cText = new TextWdgt "0"
    cText._applyMoveTo container.position().add new Point 104, 253
    cText._applyExtent new Point 150, 75
    container._addNoSettle cText
    cText._rememberFractionalSituationInHoldingPanel()

    fText = new TextWdgt "0"
    fText._applyMoveTo container.position().add new Point 344, 255
    fText.alignRight()
    fText._applyExtent new Point 150, 75
    container._addNoSettle fText
    fText._rememberFractionalSituationInHoldingPanel()

    calc1 = new FrameWdgt new CalculatingPatchNodeWdgt("# °C → °F formula\n(in1)->Math.round in1*9/5+32")
    calc1._applyMoveTo container.position().add new Point 148+xCorrection/2, 19
    calc1._applyExtent new Point 241, 167
    container._addNoSettle calc1
    calc1._rememberFractionalSituationInHoldingPanel()

    calc2 = new FrameWdgt new CalculatingPatchNodeWdgt("# °F → °C formula\n(in1)->Math.round (in1-32)*5/9")
    calc2._applyMoveTo container.position().add new Point 148+xCorrection/2, 365
    calc2._applyExtent new Point 241, 167
    container._addNoSettle calc2
    calc2._rememberFractionalSituationInHoldingPanel()


    slider1.setTargetAndActionWithOnesPickedFromMenu nil, nil, cText, "setText"
    cText.setTargetAndActionWithOnesPickedFromMenu nil, nil, calc1.contents, "setInput1"
    calc1.contents.setTargetAndActionWithOnesPickedFromMenu nil, nil, fText, "setText"
    fText.setTargetAndActionWithOnesPickedFromMenu nil, nil, slider2, "setValue"
    slider2.setTargetAndActionWithOnesPickedFromMenu nil, nil, calc2.contents, "setInput1"
    calc2.contents.setTargetAndActionWithOnesPickedFromMenu nil, nil, slider1, "setValue"



    cLabel = new TextWdgt "°C"
    cLabel._applyMoveTo container.position().add new Point 0+xCorrection, 102+yCorrection
    cLabel._applyExtent new Point 90, 90
    container._addNoSettle cLabel
    cLabel._rememberFractionalSituationInHoldingPanel()

    fLabel = new TextWdgt "°F"
    fLabel._applyMoveTo container.position().add new Point 422+xCorrection, 102+yCorrection
    fLabel._applyExtent new Point 90, 90
    container._addNoSettle fLabel
    fLabel._rememberFractionalSituationInHoldingPanel()

    #@inform (@position().subtract @parent.position()) + " " +  @extent()

    wm = new FrameWdgt patchProgrammingWdgt
    wm._applyMoveTo new Point 114, 10
    wm._applyExtent new Point 596, 592
    # disableDragsDropsAndEditing now self-settles (wrapper + _disableDragsDropsAndEditingNoSettle core -- the
    # disable/enable-editing family convert), so calling it BEFORE or AFTER world.add is equally legal: the delicate
    # "must precede world.add" ordering that once made this the lone witness of that method's careless tail has
    # DISSOLVED (the tail rides the wrapper's own flush now, on orphan or attached alike). Order kept as-is, unchanged.
    patchProgrammingWdgt.disableDragsDropsAndEditing()
    world.add wm
    wm.setTitleWithoutPrependedContentName "°C ↔ °F converter"
    
    cText.isEditable = true
    fText.isEditable = true

    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    patchProgrammingWdgt.closeFromContainerFrame = (containerWindow) ->
      containerWindow.close()

    return wm
