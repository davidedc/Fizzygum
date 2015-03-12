# ColorPaletteMorph ///////////////////////////////////////////////////
# REQUIRES ControllerMixin
# REQUIRES BackingStoreMixin

class ColorPaletteMorph extends Morph
  @augmentWith ControllerMixin
  @augmentWith BackingStoreMixin

  target: null
  targetSetter: "color"
  choice: null

  constructor: (@target = null, sizePoint) ->
    super()
    @silentSetExtent sizePoint or new Point(80, 50)
  
  # no changes of position or extent
  updateBackingStore: ->
    extent = @extent()
    @image = newCanvas(extent.scaleBy pixelRatio)
    context = @image.getContext("2d")
    context.scale pixelRatio, pixelRatio
    @choice = new Color()
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
        context.fillStyle = "hsl(" + h + ",100%," + l + "%)"
        context.fillRect x, y, 1, 1
  
  mouseMove: (pos) ->
    @choice = @getPixelColor(pos)
    @updateTarget()
  
  mouseDownLeft: (pos) ->
    @choice = @getPixelColor(pos)
    @updateTarget()
  
  updateTarget: ->
    if @target instanceof Morph and @choice?
      if @target[@targetSetter] instanceof Function
        @target[@targetSetter] @choice
      else
        @target[@targetSetter] = @choice
        @target.setLayoutBeforeUpdatingBackingStore()
        @target.updateBackingStore()
        @target.changed()
  
    
  # ColorPaletteMorph menu:
  developersMenu: ->
    menu = super()
    menu.addLine()
    menu.addItem "set target", @, "setTarget", "choose another morph\nwhose color property\n will be" + " controlled by this one"
    menu
  
  # setTarget: -> taken form the ControllerMixin
  
  setTargetSetter: (theTarget) ->
    choices = theTarget.colorSetters()
    menu = new MenuMorph(@, "choose target property:")
    choices.forEach (each) =>
      menu.addItem each, @, =>
        @target = theTarget
        @targetSetter = each
    if choices.length == 0
      menu = new MenuMorph(@, "no target properties available")
    menu.popUpAtHand()
