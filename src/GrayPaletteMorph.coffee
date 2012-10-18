# GrayPaletteMorph ///////////////////////////////////////////////////

class GrayPaletteMorph
  constructor: (target, sizePoint) ->
    @init target or null, sizePoint or new Point(80, 10)

# GrayPaletteMorph inherits from ColorPaletteMorph:
GrayPaletteMorph:: = new ColorPaletteMorph()
GrayPaletteMorph::constructor = GrayPaletteMorph
GrayPaletteMorph.uber = ColorPaletteMorph::

# GrayPaletteMorph instance creation:
GrayPaletteMorph::drawNew = ->
  context = undefined
  ext = undefined
  gradient = undefined
  ext = @extent()
  @image = newCanvas(@extent())
  context = @image.getContext("2d")
  @choice = new Color()
  gradient = context.createLinearGradient(0, 0, ext.x, ext.y)
  gradient.addColorStop 0, "black"
  gradient.addColorStop 1, "white"
  context.fillStyle = gradient
  context.fillRect 0, 0, ext.x, ext.y
