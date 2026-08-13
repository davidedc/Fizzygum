# SampleDashboardApp -- the "sample dashboard" example app (an interactive dashboard
# of plots, maps, sliders and speech bubbles). One of the per-app
# IconicDesktopSystemWindowedApp subclasses (Phase 6 step 6c.3): it declares the parts
# its window needs and the singleton world slot, and builds its window inline in
# buildWindow; the base owns the launcher/opener + bring-up-or-create launch logic, and
# AppCatalog (keyed by class name) holds its launcher title/icon.
# The window body was lifted verbatim from MenusHelper's
# createSampleDashboardWindowOrBringItUpIfAlreadyCreated (minus the final world-slot
# assignment, now done by the base's launch).

class SampleDashboardApp extends IconicDesktopSystemWindowedApp

  requiredParts: ["maps", "plots", "authoring"]

  slot:  "sampleDashboardWindow"

  buildWindow: ->
    slideWdgt = new DashboardWdgt

    container = slideWdgt.contents.contents
    container._applyExtent new Point 725,556

    scatterPlot = new FrameWdgt new PlotWithAxesWdgt(new ExampleScatterPlotWdgt)
    scatterPlot._applyBounds (container.position().add new Point 19, 86), new Point 200, 200
    container.add scatterPlot

    functionPlot = new FrameWdgt new PlotWithAxesWdgt(new ExampleFunctionPlotWdgt)
    functionPlot._applyBounds (container.position().add new Point 251, 86), new Point 200, 200
    container.add functionPlot

    barPlot = new FrameWdgt new PlotWithAxesWdgt(new ExampleBarPlotWdgt)
    barPlot._applyBounds (container.position().add new Point 19, 327), new Point 200, 200
    container.add barPlot

    plot3D = new FrameWdgt new Example3DPlotWdgt
    plot3D._applyBounds (container.position().add new Point 491, 327), new Point 200, 150
    container.add plot3D

    usaMap = new SimpleUSAMapIconWdgt Color.create 183, 183, 183
    usaMap._applyBounds (container.position().add new Point 242, 355), new Point 230, 145
    container.add usaMap

    mapPin1 = new MapPinIconWdgt
    mapPin1._applyMoveTo container.position().add new Point 226, 376
    container.add mapPin1

    mapPin2 = new MapPinIconWdgt
    mapPin2._applyMoveTo container.position().add new Point 289, 363
    container.add mapPin2

    mapPin3 = new MapPinIconWdgt
    mapPin3._applyMoveTo container.position().add new Point 323, 397
    container.add mapPin3

    mapPin4 = new MapPinIconWdgt
    mapPin4._applyMoveTo container.position().add new Point 360, 421
    container.add mapPin4

    mapPin5 = new MapPinIconWdgt
    mapPin5._applyMoveTo container.position().add new Point 417, 374
    container.add mapPin5

    worldMap = new SimpleWorldMapIconWdgt Color.create 183, 183, 183
    worldMap._applyBounds (container.position().add new Point 464, 128), new Point 240, 125
    container.add worldMap

    speechBubble1 = new SpeechBubbleWdgt "online"
    speechBubble1._applyBounds (container.position().add new Point 506, 123), new Point 66, 42
    container.add speechBubble1

    speechBubble2 = new SpeechBubbleWdgt "offline"
    speechBubble2._applyBounds (container.position().add new Point 590, 105), new Point 66, 42
    container.add speechBubble2

    dashboardTitle = new TextWdgt "Example dashboard with interactive 3D plot"
    dashboardTitle.alignCenter()
    dashboardTitle.alignMiddle()
    dashboardTitle._applyBounds (container.position().add new Point 161, 6), new Point 403, 50
    container.add dashboardTitle


    slider1 = new SliderWdgt undefined, undefined, undefined, undefined, undefined, true
    slider1._applyBounds (container.position().add new Point 491, 484), new Point 201, 24
    container.add slider1

    slider1.setTargetAndActionWithOnesPickedFromMenu undefined, undefined, plot3D.contents, "setParameter"

    slideWdgt._applyBounds (new Point 114, 10), new Point 596, 592
    world.add slideWdgt
    slideWdgt.setTitleWithoutPrependedContentName "Sample dashboard"


    slideWdgt.disableDragsDropsAndEditing()

    # closing just closes (no save prompt) -- a sample window isn't worth
    # saving. The tracked close policy (§5.E E2).
    slideWdgt.closeFromFrameBarPolicy = 'close'

    return slideWdgt
