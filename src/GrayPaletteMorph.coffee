# GrayPaletteMorph ///////////////////////////////////////////////////

class GrayPaletteMorph extends ColorPaletteMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  constructor: (@target = null, sizePoint) ->
    super @target, sizePoint or new Point(80, 10)
  
  # no changes of position or extent
  updateBackingStore: ->
    extent = @extent()
    @image = newCanvas(extent.scaleBy pixelRatio)
    @imageContext = @image.getContext("2d")
    @imageContext.scale pixelRatio, pixelRatio
    @choice = new Color()
    gradient = @imageContext.createLinearGradient(0, 0, extent.x, extent.y)
    gradient.addColorStop 0, "black"
    gradient.addColorStop 1, "white"
    @imageContext.fillStyle = gradient
    @imageContext.fillRect 0, 0, extent.x, extent.y
