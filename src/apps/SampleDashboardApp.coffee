# SampleDashboardApp -- the "sample dashboard" example app (an interactive dashboard
# of plots, maps, sliders and speech bubbles). One of the per-app
# IconicDesktopSystemWindowedApp subclasses (Phase 6 step 6c.3): it declares its
# launcher title/icon and the singleton world slot and builds its window inline in
# buildWindow; the base owns the launcher/opener + bring-up-or-create launch logic.
# The window body was lifted verbatim from MenusHelper's
# createSampleDashboardWindowOrBringItUpIfAlreadyCreated (minus the final world-slot
# assignment, now done by the base's launch).

class SampleDashboardApp extends IconicDesktopSystemWindowedApp

  title: "sample dashb"
  slot:  "sampleDashboardWindow"

  buildIcon: -> new GenericShortcutIconWdgt new DashboardsIconWdgt

  buildWindow: ->
    slideWdgt = new DashboardsWdgt

    container = slideWdgt.stretchableWidgetContainer.contents
    container.rawSetExtent new Point 725,556

    scatterPlot = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleScatterPlotWdgt), true, true
    scatterPlot.fullRawMoveTo container.position().add new Point 19, 86
    scatterPlot.rawSetExtent new Point 200, 200
    container.add scatterPlot
    scatterPlot.rememberFractionalSituationInHoldingPanel()

    functionPlot = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleFunctionPlotWdgt), true, true
    functionPlot.fullRawMoveTo container.position().add new Point 251, 86
    functionPlot.rawSetExtent new Point 200, 200
    container.add functionPlot
    functionPlot.rememberFractionalSituationInHoldingPanel()

    barPlot = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleBarPlotWdgt), true, true
    barPlot.fullRawMoveTo container.position().add new Point 19, 327
    barPlot.rawSetExtent new Point 200, 200
    container.add barPlot
    barPlot.rememberFractionalSituationInHoldingPanel()

    plot3D = new WindowWdgt nil, nil, new Example3DPlotWdgt, true, true
    plot3D.fullRawMoveTo container.position().add new Point 491, 327
    plot3D.rawSetExtent new Point 200, 150
    container.add plot3D
    plot3D.rememberFractionalSituationInHoldingPanel()

    usaMap = new SimpleUSAMapIconWdgt Color.create 183, 183, 183
    usaMap.fullRawMoveTo container.position().add new Point 242, 355
    usaMap.rawSetExtent new Point 230, 145
    container.add usaMap
    usaMap.rememberFractionalSituationInHoldingPanel()

    mapPin1 = new MapPinIconWdgt
    mapPin1.fullRawMoveTo container.position().add new Point 226, 376
    container.add mapPin1
    mapPin1.rememberFractionalSituationInHoldingPanel()

    mapPin2 = new MapPinIconWdgt
    mapPin2.fullRawMoveTo container.position().add new Point 289, 363
    container.add mapPin2
    mapPin2.rememberFractionalSituationInHoldingPanel()

    mapPin3 = new MapPinIconWdgt
    mapPin3.fullRawMoveTo container.position().add new Point 323, 397
    container.add mapPin3
    mapPin3.rememberFractionalSituationInHoldingPanel()

    mapPin4 = new MapPinIconWdgt
    mapPin4.fullRawMoveTo container.position().add new Point 360, 421
    container.add mapPin4
    mapPin4.rememberFractionalSituationInHoldingPanel()

    mapPin5 = new MapPinIconWdgt
    mapPin5.fullRawMoveTo container.position().add new Point 417, 374
    container.add mapPin5
    mapPin5.rememberFractionalSituationInHoldingPanel()

    worldMap = new SimpleWorldMapIconWdgt Color.create 183, 183, 183
    worldMap.fullRawMoveTo container.position().add new Point 464, 128
    worldMap.rawSetExtent new Point 240, 125
    container.add worldMap
    worldMap.rememberFractionalSituationInHoldingPanel()

    speechBubble1 = new SpeechBubbleWdgt "online"
    speechBubble1.fullRawMoveTo container.position().add new Point 506, 123
    speechBubble1.rawSetExtent new Point 66, 42
    container.add speechBubble1
    speechBubble1.rememberFractionalSituationInHoldingPanel()

    speechBubble2 = new SpeechBubbleWdgt "offline"
    speechBubble2.fullRawMoveTo container.position().add new Point 590, 105
    speechBubble2.rawSetExtent new Point 66, 42
    container.add speechBubble2
    speechBubble2.rememberFractionalSituationInHoldingPanel()

    dashboardTitle = new TextWdgt "Example dashboard with interactive 3D plot"
    dashboardTitle.alignCenter()
    dashboardTitle.alignMiddle()
    dashboardTitle.fullRawMoveTo container.position().add new Point 161, 6
    dashboardTitle.rawSetExtent new Point 403, 50
    container.add dashboardTitle
    dashboardTitle.rememberFractionalSituationInHoldingPanel()


    slider1 = new SliderWdgt nil, nil, nil, nil, nil, true
    slider1.fullRawMoveTo container.position().add new Point 491, 484
    slider1.rawSetExtent new Point 201, 24
    container.add slider1
    slider1.rememberFractionalSituationInHoldingPanel()

    slider1.setTargetAndActionWithOnesPickedFromMenu nil, nil, plot3D.contents, "setParameter"

    wm = new WindowWdgt nil, nil, slideWdgt
    wm.fullRawMoveTo new Point 114, 10
    wm.rawSetExtent new Point 596, 592
    world.add wm
    wm.setTitleWithoutPrependedContentName "Sample dashboard"


    slideWdgt.disableDragsDropsAndEditing()
    
    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    slideWdgt.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()

    return wm
