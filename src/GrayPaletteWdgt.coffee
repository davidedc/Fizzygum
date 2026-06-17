# A draggable black->white gradient: drag across it to pick a shade of gray,
# pushed to a target widget's colour property. See PaletteWdgt — a gray palette
# is a SIBLING of (not a) ColorPaletteWdgt; it supplies only its gradient fill,
# its shorter default size, and its colloquial name.

class GrayPaletteWdgt extends PaletteWdgt

  defaultSize: -> new Point 80, 10

  colloquialName: ->
    "shades of gray"

  fillPaletteBuffer: (backBufferContext, extent) ->
    gradient = backBufferContext.createLinearGradient 0, extent.y, extent.x, extent.y
    gradient.addColorStop 0, Color.BLACK.toString()
    gradient.addColorStop 1, Color.WHITE.toString()
    backBufferContext.fillStyle = gradient
    backBufferContext.fillRect 0, 0, extent.x, extent.y
