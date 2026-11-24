# The framed IMAGE citizen (Frame-model plan §5.D, owner decision D2): a
# paintable image IS its window, with paint as its EDIT MODE (the provenance
# note's "Paint program + Image widget should use the same editing pattern as
# Text editor + Text widget"). Kind name + icon + toolbar variant + the
# paintable payload on the GenericPanelWdgt family base -- close policy, reset
# guard, title and the changed-check (ratio crystallizes on the first paint,
# via getContextForPainting -> setRatio) all inherit.
#
# The payload is the paint APPARATUS -- a StretchableWidgetContainerWdgt over a
# StretchableCanvasWdgt with a CanvasGlassTopWdgt overlay. There is no bitmap
# loader: a load-image-file flow, when one is built, decides where a loader
# lives (docs/BACKLOG.md).

class ImageWdgt extends GenericPanelWdgt

  colloquialName: ->
    "Drawings Maker"

  representativeIcon: ->
    new SprayCanIconWdgt

  # the frame docks this variant in its toolbar-slot (§5.C)
  buildToolbar: ->
    new PaintToolbarWdgt

  _makeStartingPayload: ->
    # mainCanvas
    container = new StretchableWidgetContainerWdgt new StretchableCanvasWdgt
    container.disableDrops()
    mainCanvas = container.contents

    # overlayCanvas: the glass, the paint surface. It takes its tool up itself whenever it is used
    # (CanvasGlassTopWdgt), so nothing is given to it here. Feedback draws on the glass; the actual
    # painting reaches the canvas through @underlyingCanvasWdgt.getContextForPainting().
    overlayCanvas = new CanvasGlassTopWdgt
    overlayCanvas.underlyingCanvasWdgt = mainCanvas
    overlayCanvas.disableDrops()
    mainCanvas.add overlayCanvas

    container

  # BORN PAINTING. The palette my frame docks makes me adopt WHAT THE HAND HOLDS as it arrives
  # (ToolbarWdgt.noteDockedOn): open a drawing while holding the brush and it hands you the brush. An
  # EMPTY hand falls back to the pencil, because a new drawing must always be immediately paintable
  # -- and that fallback is THIS drawing's birth choice, armed on me alone: it puts nothing in the
  # person's hand, so a hand deliberately emptied stays empty everywhere else. Asked wherever my
  # toolbar is docked: at my birth, at a payload reset that finds my own palette gone (floated away,
  # or emptied of its toolbar; a reset that finds it docked keeps it, and my tool with it), and from
  # the "Toolbar" row of my menu.
  _buildDockedToolbarNoSettle: (side) ->
    super
    # public-call-sanctioned: armDrawingTool is the holder's one write (FrameWdgt), settle-free and
    # touching no geometry; this birth choice is exactly that write
    @armDrawingTool 'pencil' if !@armedDrawingTool? and ToolbarWdgt.wearsDrawingTools @
    return
