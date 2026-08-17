# A draggable HSL colour field: drag across it to pick a colour, which is pushed
# to a target widget's colour property. See PaletteWdgt for the shared plumbing;
# this subclass supplies only its MAP — the pixel fill that draws it and the
# inverse that reads a colour back to a point on it (the default 80x50 size comes
# from the base, and the colloquial name derives from the class name).

class ColorPaletteWdgt extends PaletteWdgt

  # The INVERSE of the fill below (PaletteWdgt states the rule): read the hue back to a column and
  # the lightness back to a row.
  #   My surface is the saturation-100% slice of HSL and nothing else, so a colour with any other
  # saturation is genuinely NOT on me — which is most colours, and is why the off-map rendering
  # exists rather than a nearest-point snap. The two achromatic ENDS are on me though: at
  # lightness 0 every column is black and at lightness 1 every column is white, so those pass, and
  # answer column 0 because that is the hue an achromatic colour reports.
  #   Exact, no tolerance: an hsl(h,100%,l) colour still reports saturation 1 after the browser has
  # rounded it to integer channels (Color.hueSaturationLightness), and one column spans far more
  # hue than that rounding can move it — so a colour picked off me inverts back to the very pixel
  # it was picked from.
  positionForColor: (aColor) ->
    return undefined unless aColor?
    [hue, saturation, lightness] = aColor.hueSaturationLightness()
    return undefined unless saturation == 1 or lightness == 0 or lightness == 1
    extent = @extent()
    new Point Math.round(hue / 360 * extent.x), Math.round((1 - lightness) * extent.y)

  fillPaletteBuffer: (backBufferContext, extent) ->
    for x in [0..extent.x]
      h = 360 * x / extent.x
      y = 0
      for y in [0..extent.y]
        l = 100 - (y / extent.y * 100)
        # deliberately per-pixel fillRect for clarity -- putImageData of the
        # whole buffer would be faster; alternatives:
        # http://stackoverflow.com/questions/4899799/whats-the-best-way-to-set-a-single-pixel-in-an-html5-canvas
        backBufferContext.fillStyle = "hsl(" + h + ",100%," + l + "%)"
        backBufferContext.fillRect x, y, 1, 1
