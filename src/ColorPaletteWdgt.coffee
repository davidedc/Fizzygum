# A draggable HSL colour field: drag across it to pick a colour, which is pushed
# to a target widget's colour property. See PaletteWdgt for the shared plumbing;
# this subclass supplies only the HSL pixel fill + its colloquial name (the
# default 80x50 size comes from the base).

class ColorPaletteWdgt extends PaletteWdgt

  colloquialName: ->
    "color palette"

  fillPaletteBuffer: (backBufferContext, extent) ->
    for x in [0..extent.x]
      h = 360 * x / extent.x
      y = 0
      for y in [0..extent.y]
        l = 100 - (y / extent.y * 100)
        # see link below for alternatives on how to set a single
        # pixel color.
        # You should really be using putImageData of the whole buffer
        # here anyways. But this is clearer.
        # http://stackoverflow.com/questions/4899799/whats-the-best-way-to-set-a-single-pixel-in-an-html5-canvas
        backBufferContext.fillStyle = "hsl(" + h + ",100%," + l + "%)"
        backBufferContext.fillRect x, y, 1, 1
