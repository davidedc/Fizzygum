# SampleSlideApp -- the "sample slide" example app: the New York City slide (a
# scrolling USA map with a pin, a small bar plot, a caption and a wiki link),
# opened from the examples folder. One of the per-app IconicDesktopSystemWindowedApp
# subclasses (Phase 6 step 6c.2): it declares its required parts and the singleton
# world slot, and builds its window in buildWindow; its launcher title and icon
# live in AppCatalog, not here (see IconicDesktopSystemWindowedApp's header). The
# base class owns the launcher/opener construction and the bring-up-or-create
# launch logic. The window body was lifted verbatim from MenusHelper (the
# createSampleSlideWindow... builder, minus its final world-slot assignment, now
# done by the base's launch).

class SampleSlideApp extends IconicDesktopSystemWindowedApp

  requiredParts: ["maps", "plots", "authoring"]

  slot:  "sampleSlideWindow"

  buildWindow: ->
    slideWdgt = new SlideWdgt

    container = slideWdgt.contents.contents
    container._applyExtent new Point 575,454

    windowWithScrollingPanel = new FrameWdgt new ScrollPanelWdgt
    windowWithScrollingPanel.setTitleWithoutPrependedContentName "New York City"
    windowWithScrollingPanel._applyBounds (container.position().add new Point 28, 43), new Point 322, 268
    container.add windowWithScrollingPanel


    usaMap = new SimpleUSAMapIconWdgt Color.create 183, 183, 183
    usaMap._applyExtent new Point 1808, 1115
    windowWithScrollingPanel.contents.add usaMap

    mapPin = new MapPinIconWdgt
    windowWithScrollingPanel.contents.add mapPin
    mapPin._applyMoveTo windowWithScrollingPanel.contents.contents.position().add new Point 1606, 343

    sampleBarPlot = new FrameWdgt new PlotWithAxesWdgt(new ExampleBarPlotWdgt)
    sampleBarPlot._applyExtent new Point 240, 104
    windowWithScrollingPanel.contents.add sampleBarPlot
    sampleBarPlot._applyMoveTo windowWithScrollingPanel.contents.contents.position().add new Point 1566, 420
    sampleBarPlot.setTitleWithoutPrependedContentName "NYC: traffic"


    windowWithScrollingPanel.contents.disableDragsDropsAndEditing()

    mapCaption = new TextWdgt "The City of New York, often called New York City or simply New York, is the most populous city in the United States. With an estimated 2017 population of 8,622,698 distributed over a land area of about 302.6 square miles (784 km2), New York City is also the most densely populated major city in the United States."
    mapCaption.fittingSpecWhenBoundsTooLarge = FittingSpecTextInLargerBounds.SCALEUP
    mapCaption.fittingSpecWhenBoundsTooSmall = FittingSpecTextInSmallerBounds.SCALEDOWN

    mapCaption._applyBounds (container.position().add new Point 366, 40), new Point 176, 387
    container.add mapCaption

    wikiLink = new SimpleLinkWdgt "New York City Wikipedia page", "https://en.wikipedia.org/wiki/New_York_City"
    wikiLink._applyBounds (container.position().add new Point 110, 348), new Point 250, 50
    container.add wikiLink


    slideWdgt._applyBounds (new Point 114, 10), new Point 596, 592
    world.add slideWdgt
    slideWdgt.setTitleWithoutPrependedContentName "Sample slide"

    slideWdgt.disableDragsDropsAndEditing()

    # Re-anchor the NYC viewport AFTER the mode flip: the container shifts left when editing
    # turns off, and post-orphan-settledness (ce21dcf7) the scroll no longer re-derives, so
    # scrolling LAST anchors it in the geometry the user actually sees (2026-07 mis-scrolled
    # -slide regression). Expressed in the pin's OWN content coordinates -- put the pin toward
    # the frame's top-left, (89,23) -- so it is robust to the frame's final position/size
    # (ScrollPanelWdgt.scrollTo is frame-relative). No magic viewport constant. Horizontally
    # that request lies just past the map's end, so the clamped scrollTo stops at the edge:
    # the map sits flush with the viewport and the pin lands at (116,23). (The 89 is the
    # July-2026 calibration, measured from a state that was itself over-scrolled by the 27px
    # container shift -- kept as the intent, with the clamp supplying the reachable truth.)
    pinOffsetInScrolledContent = mapPin.position().subtract windowWithScrollingPanel.contents.contents.position()
    windowWithScrollingPanel.contents.scrollTo pinOffsetInScrolledContent.subtract new Point 89, 23
    
    # closing just closes (no save prompt) -- a sample window isn't worth
    # saving. The tracked close policy (§5.E E2), replacing the untracked
    # instance-method injection this once was.
    slideWdgt.closeFromFrameBarPolicy = 'close'

    return slideWdgt
