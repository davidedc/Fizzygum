CanvasRenderingContext2D::usePhysicalPixelsUntilRestore = ->
  @scale ceilPixelRatio, ceilPixelRatio
