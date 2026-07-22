# SampleDashboardApp -- the "sample dashboard" example app (an interactive dashboard
# of plots, maps, sliders and speech bubbles). One of the per-app
# IconicDesktopSystemWindowedApp subclasses (Phase 6 step 6c.3): it declares its
# launcher title/icon and the singleton world slot and builds its window inline in
# buildWindow; the base owns the launcher/opener + bring-up-or-create launch logic.
# The window body was lifted verbatim from MenusHelper's
# createSampleDashboardWindowOrBringItUpIfAlreadyCreated (minus the final world-slot
# assignment, now done by the base's launch).

class SampleDashboardApp extends IconicDesktopSystemWindowedApp

  title: "Sample dashboard"
  slot:  "sampleDashboardWindow"

  buildIcon: -> new GenericShortcutIconWdgt new DashboardsIconWdgt

  buildWindow: ->
    slideWdgt = new DashboardWdgt

    container = slideWdgt.contents.contents
    container._applyExtent new Point 725,556

    scatterPlot = new FrameWdgt new PlotWithAxesWdgt(new ExampleScatterPlotWdgt)
    scatterPlot._applyBounds (container.position().add new Point 19, 86), new Point 200, 200
    container.add scatterPlot
    scatterPlot._rememberFractionalSituationInHoldingPanel()

    functionPlot = new FrameWdgt new PlotWithAxesWdgt(new ExampleFunctionPlotWdgt)
    functionPlot._applyBounds (container.position().add new Point 251, 86), new Point 200, 200
    container.add functionPlot
    functionPlot._rememberFractionalSituationInHoldingPanel()

    barPlot = new FrameWdgt new PlotWithAxesWdgt(new ExampleBarPlotWdgt)
    barPlot._applyBounds (container.position().add new Point 19, 327), new Point 200, 200
    container.add barPlot
    barPlot._rememberFractionalSituationInHoldingPanel()

    plot3D = new FrameWdgt new Example3DPlotWdgt
    plot3D._applyBounds (container.position().add new Point 491, 327), new Point 200, 150
    container.add plot3D
    plot3D._rememberFractionalSituationInHoldingPanel()

    usaMap = new SimpleUSAMapIconWdgt Color.create 183, 183, 183
    usaMap._applyBounds (container.position().add new Point 242, 355), new Point 230, 145
    container.add usaMap
    usaMap._rememberFractionalSituationInHoldingPanel()

    mapPin1 = new MapPinIconWdgt
    mapPin1._applyMoveTo container.position().add new Point 226, 376
    container.add mapPin1
    mapPin1._rememberFractionalSituationInHoldingPanel()

    mapPin2 = new MapPinIconWdgt
    mapPin2._applyMoveTo container.position().add new Point 289, 363
    container.add mapPin2
    mapPin2._rememberFractionalSituationInHoldingPanel()

    mapPin3 = new MapPinIconWdgt
    mapPin3._applyMoveTo container.position().add new Point 323, 397
    container.add mapPin3
    mapPin3._rememberFractionalSituationInHoldingPanel()

    mapPin4 = new MapPinIconWdgt
    mapPin4._applyMoveTo container.position().add new Point 360, 421
    container.add mapPin4
    mapPin4._rememberFractionalSituationInHoldingPanel()

    mapPin5 = new MapPinIconWdgt
    mapPin5._applyMoveTo container.position().add new Point 417, 374
    container.add mapPin5
    mapPin5._rememberFractionalSituationInHoldingPanel()

    worldMap = new SimpleWorldMapIconWdgt Color.create 183, 183, 183
    worldMap._applyBounds (container.position().add new Point 464, 128), new Point 240, 125
    container.add worldMap
    worldMap._rememberFractionalSituationInHoldingPanel()

    speechBubble1 = new SpeechBubbleWdgt "online"
    speechBubble1._applyBounds (container.position().add new Point 506, 123), new Point 66, 42
    container.add speechBubble1
    speechBubble1._rememberFractionalSituationInHoldingPanel()

    speechBubble2 = new SpeechBubbleWdgt "offline"
    speechBubble2._applyBounds (container.position().add new Point 590, 105), new Point 66, 42
    container.add speechBubble2
    speechBubble2._rememberFractionalSituationInHoldingPanel()

    dashboardTitle = new TextWdgt "Example dashboard with interactive 3D plot"
    dashboardTitle.alignCenter()
    dashboardTitle.alignMiddle()
    dashboardTitle._applyBounds (container.position().add new Point 161, 6), new Point 403, 50
    container.add dashboardTitle
    dashboardTitle._rememberFractionalSituationInHoldingPanel()


    slider1 = new SliderWdgt nil, nil, nil, nil, nil, true
    slider1._applyBounds (container.position().add new Point 491, 484), new Point 201, 24
    container.add slider1
    slider1._rememberFractionalSituationInHoldingPanel()

    slider1.setTargetAndActionWithOnesPickedFromMenu nil, nil, plot3D.contents, "setParameter"

    slideWdgt._applyBounds (new Point 114, 10), new Point 596, 592
    world.add slideWdgt
    slideWdgt.setTitleWithoutPrependedContentName "Sample dashboard"


    slideWdgt.disableDragsDropsAndEditing()

    # closing just closes (no save prompt) -- a sample window isn't worth
    # saving. The tracked close policy (§5.E E2), replacing the untracked
    # instance-method injection this once was.
    slideWdgt.closeFromFrameBarPolicy = 'close'

    return slideWdgt
