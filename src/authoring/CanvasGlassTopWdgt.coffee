class CanvasGlassTopWdgt extends CanvasWdgt

  underlyingCanvasWdgt: undefined
  defaultRejectDrags: true

  # I clear myself to FULLY TRANSPARENT, so BackBufferMixin's per-pixel answer (which I would
  # otherwise inherit from CanvasWdgt) is "the pointer is never on me" — and hover would stop
  # registering the moment the paint surface is clean. My whole box takes the pointer instead:
  # that is what makes me the glass over the canvas. ⚠ It belongs HERE and not in whichever
  # client builds me (ImageWdgt today) — set from outside, a second client, or one dropped line,
  # silently gets a dead paint surface.
  catchesPointerAt: (aPoint) ->
    @boundsContainPoint aPoint

  # paintingOverlay() capability chain (§5.D): I AM the injection target --
  # the focused widget after a click on the paint surface is me -- and the
  # tools' handlers live on me, painting through @underlyingCanvasWdgt.
  isPaintingOverlay: ->
    true

  paintingOverlay: ->
    @

  constructor: ->
    super
    @color = undefined
    # the overlay canvas is usually attached to a Canvas
    # which unfortunately is a Frame (it shouldn't, it should
    # just clip at its bounds via a mixin TODO ). So, usually
    # things inside a Panel can be dragged-out of it, so we have
    # to avoid that here
    @isLockingToPanels = true
