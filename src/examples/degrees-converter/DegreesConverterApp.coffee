# DegreesConverterApp -- the "C <-> F" degrees-converter example app (a patch-
# programming window wiring two sliders/calc nodes into a live converter). One of the
# per-app WindowedApp subclasses (Phase 6 step 6c.3): it declares
# the singleton world slot and builds its window inline in buildWindow; its launcher
# caption lives in AppCatalog, keyed by class name, and it has NO icon there (its art
# is in the lazy examples-icons part, passed in by ExamplesFolderWindowWdgt -- the one
# override in the system). The base owns the launcher/opener + bring-up-or-create
# launch logic. The window body was lifted verbatim from MenusHelper's
# createDegreesConverterWindowOrBringItUpIfAlreadyCreated (minus the final world-slot
# assignment, now done by the base's launch).

class DegreesConverterApp extends WindowedApp

  requiredParts: ["authoring"]

  slot:  "degreesConverterWindow"

  buildWindow: ->
    xCorrection = 32
    yCorrection = 50
    patchProgrammingWdgt = new PatchProgrammingWdgt

    container = patchProgrammingWdgt.contents.contents
    container._applyExtent new Point 584,552

    # Build this orphan window tree settle-free: `container` is part of the not-yet-attached
    # patchProgrammingWdgt, so add the body widgets via the non-settling _addNoSettle core (orphan
    # construction). Under orphan-settledness a public container.add() would settle MID-construction
    # on the half-built tree and crash; the single `world.add wm` below settles the whole tree once.

    slider1 = new SliderWdgt 1, 100, 50, 10, smallestValueIsAtBottomEnd: true
    slider1._applyBounds (container.position().add new Point 43+xCorrection, 195+yCorrection), new Point 20, 100
    container._addNoSettle slider1

    slider2 = new SliderWdgt 1, 100, 50, 10, smallestValueIsAtBottomEnd: true
    slider2._applyBounds (container.position().add new Point 472+xCorrection, 203+yCorrection), new Point 20, 100
    container._addNoSettle slider2

    cText = new TextWdgt "0"
    cText._applyBounds (container.position().add new Point 104, 253), new Point 150, 75
    container._addNoSettle cText

    fText = new TextWdgt "0"
    fText._applyMoveTo container.position().add new Point 344, 255
    fText.alignRight()
    fText._applyExtent new Point 150, 75
    container._addNoSettle fText

    # Each calc frame is tall enough for what its node lays out inside a window's chrome: the node
    # splits its height 2:1 between the formula box (two lines) and the output box (one line), and a
    # text box needs its lines at 15px (fonts.code) plus 5px of padding top and bottom -- 25px for
    # the output. At 186 (scaled by the stretch panel to ~181) the output box gets 27; shorter, it
    # overflows by a few pixels and scrolls. calc2 at 186 still ends inside the 552px container.
    calcFrameExtent = new Point 241, 186
    calc1 = new FrameWdgt new CalculatingPatchNodeWdgt("# °C → °F formula\n(in1)->Math.round in1*9/5+32")
    calc1._applyBounds (container.position().add new Point 148+xCorrection/2, 19), calcFrameExtent
    container._addNoSettle calc1

    calc2 = new FrameWdgt new CalculatingPatchNodeWdgt("# °F → °C formula\n(in1)->Math.round (in1-32)*5/9")
    calc2._applyBounds (container.position().add new Point 148+xCorrection/2, 365), calcFrameExtent
    container._addNoSettle calc2


    slider1.wireTo cText, "setText"
    cText.wireTo calc1.contents, "setInput1"
    calc1.contents.wireTo fText, "setText"
    fText.wireTo slider2, "setValue"
    slider2.wireTo calc2.contents, "setInput1"
    calc2.contents.wireTo slider1, "setValue"



    cLabel = new TextWdgt "°C"
    cLabel._applyBounds (container.position().add new Point 0+xCorrection, 102+yCorrection), new Point 90, 90
    container._addNoSettle cLabel

    fLabel = new TextWdgt "°F"
    fLabel._applyBounds (container.position().add new Point 422+xCorrection, 102+yCorrection), new Point 90, 90
    container._addNoSettle fLabel


    patchProgrammingWdgt._applyBounds (new Point 114, 10), new Point 596, 592
    # disableDragsDropsAndEditing now self-settles (wrapper + _disableDragsDropsAndEditingNoSettle core), so
    # calling it BEFORE or AFTER world.add is equally legal; order kept as-is. See
    # docs/archive/disable-editing-family-convert-plan.md.
    patchProgrammingWdgt.disableDragsDropsAndEditing()
    world.add patchProgrammingWdgt
    patchProgrammingWdgt.setTitleWithoutPrependedContentName "°C ↔ °F converter"

    cText.isEditable = true
    fText.isEditable = true

    # closing just closes (no save prompt) -- a sample window isn't worth
    # saving. The tracked close policy (§5.E E2).
    patchProgrammingWdgt.closeFromFrameBarPolicy = 'close'

    return patchProgrammingWdgt
