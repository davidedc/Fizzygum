# A draggable black->white gradient: drag across it to pick a shade of gray,
# pushed to a target widget's colour property. See PaletteWdgt — a gray palette
# is a SIBLING of (not a) ColorPaletteWdgt; it supplies only its own MAP (the
# gradient fill and the inverse that reads a colour back to a point on it), its
# shorter default size, and its colloquial name.

class GrayPaletteWdgt extends PaletteWdgt

  defaultSize: -> new Point 80, 10

  colloquialName: ->
    "shades of gray"

  # The INVERSE of the gradient below (PaletteWdgt states the rule). My map is one-dimensional:
  # black to white along x, every row identical — so a colour is on me exactly when it is
  # achromatic, its lightness names the column, and the row I answer is simply my middle.
  positionForColor: (aColor) ->
    return undefined unless aColor?
    [hue, saturation, lightness] = aColor.hueSaturationLightness()
    return undefined unless saturation == 0
    extent = @extent()
    new Point Math.round(lightness * extent.x), Math.floor(extent.y / 2)

  fillPaletteBuffer: (backBufferContext, extent) ->
    gradient = backBufferContext.createLinearGradient 0, extent.y, extent.x, extent.y
    gradient.addColorStop 0, Color.BLACK.toString()
    gradient.addColorStop 1, Color.WHITE.toString()
    backBufferContext.fillStyle = gradient
    backBufferContext.fillRect 0, 0, extent.x, extent.y
