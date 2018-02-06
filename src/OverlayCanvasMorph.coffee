# OverlayCanvasMorph //////////////////////////////////////////////////////////

class OverlayCanvasMorph extends CanvasMorph

  underlyingCanvasMorph: nil
  defaultRejectDrags: true

  constructor: ->
    super
    @color = nil
    # the overlay canvas is usually attached to a Canvas
    # which unfortunately is a Frame (it shouldn't, it should
    # just clip at its bounds via a mixin TODO ). So, usually
    # things inside a Panel can be dragged-out of it, so we have
    # to avoid that here
    @isLockingToPanels = true
