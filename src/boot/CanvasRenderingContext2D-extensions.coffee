CanvasRenderingContext2D::useLogicalPixelsUntilRestore = ->
  @scale ceilPixelRatio, ceilPixelRatio

CanvasRenderingContext2D::rebuildDerivedValue = (objectIBelongTo, myPropertyName) ->
  # here we need to re-generate a context from the COPY canvas
  # I can't think of an easy way to do this, just assume that the canvas
  # in in a property with name same as the context one, but without "Context"
  # e.g. "backBufferContext" -> belongs to canvas named: "backBuffer"
  objectIBelongTo[myPropertyName] = objectIBelongTo[myPropertyName.replace "Context", ""].getContext "2d"
