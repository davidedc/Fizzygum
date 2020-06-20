CanvasRenderingContext2D::useLogicalPixelsUntilRestore = ->
  @scale ceilPixelRatio, ceilPixelRatio
