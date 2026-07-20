class CanvasGlassTopWdgt extends CanvasWdgt

  underlyingCanvasWdgt: nil
  defaultRejectDrags: true

  # paintingOverlay() capability chain (§5.D): I AM the injection target --
  # the focused widget after a click on the paint surface is me (I notice
  # transparent clicks over the whole canvas), and the tools' handlers live
  # on me, painting through @underlyingCanvasWdgt.
  isPaintingOverlay: ->
    true

  paintingOverlay: ->
    @

  constructor: ->
    super
    @color = nil
    # the overlay canvas is usually attached to a Canvas
    # which unfortunately is a Frame (it shouldn't, it should
    # just clip at its bounds via a mixin TODO ). So, usually
    # things inside a Panel can be dragged-out of it, so we have
    # to avoid that here
    @isLockingToPanels = true
