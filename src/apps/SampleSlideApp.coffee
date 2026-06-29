# SampleSlideApp -- the "sample slide" example app: the New York City slide (a
# scrolling USA map with a pin, a small bar plot, a caption and a wiki link),
# opened from the examples folder. One of the per-app IconicDesktopSystemWindowedApp
# subclasses (Phase 6 step 6c.2): it declares its launcher title/icon and the
# singleton world slot, and builds its window in buildWindow; the base class owns
# the launcher/opener construction and the bring-up-or-create launch logic. The
# window body was lifted verbatim from MenusHelper (the createSampleSlideWindow...
# builder, minus its final world-slot assignment, now done by the base's launch).

class SampleSlideApp extends IconicDesktopSystemWindowedApp

  title: "sample slide"
  slot:  "sampleSlideWindow"

  buildIcon: -> new GenericShortcutIconWdgt new SimpleSlideIconWdgt

  buildWindow: ->
    slideWdgt = new SimpleSlideWdgt

    container = slideWdgt.stretchableWidgetContainer.contents
    container._applyExtentAndNotify new Point 575,454

    windowWithScrollingPanel = new WindowWdgt nil, nil, new ScrollPanelWdgt, true, true
    windowWithScrollingPanel.setTitleWithoutPrependedContentName "New York City"
    windowWithScrollingPanel._applyMoveToAndNotify container.position().add new Point 28, 43
    windowWithScrollingPanel._applyExtentAndNotify new Point 322, 268
    container.add windowWithScrollingPanel
    windowWithScrollingPanel.rememberFractionalSituationInHoldingPanel()


    usaMap = new SimpleUSAMapIconWdgt Color.create 183, 183, 183
    usaMap._applyExtentAndNotify new Point 1808, 1115
    windowWithScrollingPanel.contents.add usaMap
    windowWithScrollingPanel.contents.scrollTo new Point 1484, 246
    usaMap.rememberFractionalSituationInHoldingPanel()

    mapPin = new MapPinIconWdgt
    windowWithScrollingPanel.contents.add mapPin
    mapPin._applyMoveToAndNotify windowWithScrollingPanel.contents.contents.position().add new Point 1606, 343
    mapPin.rememberFractionalSituationInHoldingPanel()

    sampleBarPlot = new WindowWdgt nil, nil, new PlotWithAxesWdgt(new ExampleBarPlotWdgt), true, true
    sampleBarPlot._applyExtentAndNotify new Point 240, 104
    windowWithScrollingPanel.contents.add sampleBarPlot
    sampleBarPlot._applyMoveToAndNotify windowWithScrollingPanel.contents.contents.position().add new Point 1566, 420
    sampleBarPlot.setTitleWithoutPrependedContentName "NYC: traffic"


    windowWithScrollingPanel.contents.disableDragsDropsAndEditing()

    mapCaption = new TextWdgt "The City of New York, often called New York City or simply New York, is the most populous city in the United States. With an estimated 2017 population of 8,622,698 distributed over a land area of about 302.6 square miles (784 km2), New York City is also the most densely populated major city in the United States."
    mapCaption.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    mapCaption.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN

    mapCaption._applyMoveToAndNotify container.position().add new Point 366, 40
    mapCaption._applyExtentAndNotify new Point 176, 387
    container.add mapCaption
    mapCaption.rememberFractionalSituationInHoldingPanel()

    wikiLink = new SimpleLinkWdgt "New York City Wikipedia page", "https://en.wikipedia.org/wiki/New_York_City"
    wikiLink._applyMoveToAndNotify container.position().add new Point 110, 348
    wikiLink._applyExtentAndNotify new Point 250, 50
    container.add wikiLink
    wikiLink.rememberFractionalSituationInHoldingPanel()


    wm = new WindowWdgt nil, nil, slideWdgt
    wm._applyMoveToAndNotify new Point 114, 10
    wm._applyExtentAndNotify new Point 596, 592
    world.add wm
    wm.setTitleWithoutPrependedContentName "Sample slide"

    slideWdgt.disableDragsDropsAndEditing()
    
    # if we don't do this, the window would ask to save content
    # when closed. Just close it instead.
    # TODO: should be done using a flag, we don't like
    # to inject code like this: the source is not tracked
    slideWdgt.closeFromContainerWindow = (containerWindow) ->
      containerWindow.close()

    return wm
