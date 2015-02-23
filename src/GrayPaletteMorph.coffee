# GrayPaletteMorph ///////////////////////////////////////////////////

class GrayPaletteMorph extends ColorPaletteMorph

  constructor: (@target = null, sizePoint) ->
    super @target, sizePoint or new Point(80, 10)
  
  updateBackingStore: ->
    ext = @extent()
    @image = newCanvas(@extent().scaleBy pixelRatio)
    context = @image.getContext("2d")
    context.scale pixelRatio, pixelRatio
    @choice = new Color()
    gradient = context.createLinearGradient(0, 0, ext.x, ext.y)
    gradient.addColorStop 0, "black"
    gradient.addColorStop 1, "white"
    context.fillStyle = gradient
    context.fillRect 0, 0, ext.x, ext.y
