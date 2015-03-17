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
    context = @image.getContext("2d")
    context.scale pixelRatio, pixelRatio
    @choice = new Color()
    gradient = context.createLinearGradient(0, 0, extent.x, extent.y)
    gradient.addColorStop 0, "black"
    gradient.addColorStop 1, "white"
    context.fillStyle = gradient
    context.fillRect 0, 0, extent.x, extent.y
