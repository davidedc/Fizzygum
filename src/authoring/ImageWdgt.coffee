# The framed IMAGE citizen (Frame-model plan §5.D, owner decision D2): a
# paintable image IS its window, with paint as its EDIT MODE (the provenance
# note's "Paint program + Image widget should use the same editing pattern as
# Text editor + Text widget"). Kind name + icon + toolbar variant + the
# paintable payload on the GenericPanelWdgt family base -- close policy, reset
# guard, title and the changed-check (ratio crystallizes on the first paint,
# via getContextForPainting -> setRatio) all inherit.
#
# The payload is the paint APPARATUS -- a StretchableWidgetContainerWdgt over a
# StretchableCanvasWdgt with a CanvasGlassTopWdgt overlay -- NOT the bitmap
# loader SimpleImageWdgt (owner decision D13: that class has one consumer, a
# button face, and no content flow today; merging it in waits for a
# load-image-file consumer -- docs/BACKLOG.md).

class ImageWdgt extends GenericPanelWdgt

  colloquialName: ->
    "Drawings Maker"

  representativeIcon: ->
    new PaintBucketIconWdgt

  # the frame docks this variant in its toolbar-slot (§5.C)
  buildToolbar: ->
    new PaintToolbarWdgt

  _makeStartingPayload: ->
    # mainCanvas
    container = new StretchableWidgetContainerWdgt new StretchableCanvasWdgt
    container.disableDrops()
    mainCanvas = container.contents

    # overlayCanvas: the glass the tools inject their handlers into (the
    # paintingOverlay() capability chain resolves to it). Feedback draws on
    # the glass; the actual painting reaches the canvas through
    # @underlyingCanvasWdgt.getContextForPainting().
    overlayCanvas = new CanvasGlassTopWdgt
    overlayCanvas.underlyingCanvasWdgt = mainCanvas
    overlayCanvas.disableDrops()
    mainCanvas.add overlayCanvas

    # if you clear the overlay to perfectly
    # transparent, then we need to set this flag
    # otherwise the pointer won't be reported
    # as moving inside the canvas.
    # If you give the overlay canvas even the smallest
    # tint then you don't need this flag.
    overlayCanvas.noticesTransparentClick = true

    overlayCanvas.injectProperty "mouseLeave", """
        # don't leave any trace behind then the pointer
        # moves out.
        (pos) ->
            context = @backBufferContext
            context.setTransform 1, 0, 0, 1, 0, 0
            context.clearRect 0, 0, @width() * ceilPixelRatio, @height() * ceilPixelRatio
            @_changed()
    """

    # born ARMED with the pencil (parity with the retired editor, whose build
    # auto-selected pencil): the toolbar variant is built showing pencil
    # selected to match (its _armed default).
    overlayCanvas.injectProperties PaintToolbarWdgt.PENCIL_TOOL_SOURCE

    container
