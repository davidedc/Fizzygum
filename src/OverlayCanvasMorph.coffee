# OverlayCanvasMorph //////////////////////////////////////////////////////////

class OverlayCanvasMorph extends CanvasMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  underlyingCanvasMorph: nil

  constructor: ->
    super
    @color = nil

  isFloatDraggable: ->
    false