# RectangleMorph /////////////////////////////////////////////////////////

class RectangleMorph extends Morph
  constructor: (extent, color) ->
    super()
    @silentSetExtent(extent) if extent?
    @color = color if color?
    @updateRendering()

