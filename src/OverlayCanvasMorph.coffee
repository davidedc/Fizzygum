# OverlayCanvasMorph //////////////////////////////////////////////////////////

class OverlayCanvasMorph extends CanvasMorph

  underlyingCanvasMorph: nil

  constructor: ->
    super
    @color = nil

  isFloatDraggable: ->
    false