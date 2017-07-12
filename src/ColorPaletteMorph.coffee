# ColorPaletteMorph ///////////////////////////////////////////////////
# REQUIRES ControllerMixin
# REQUIRES BackBufferMixin

class ColorPaletteMorph extends Morph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype

  @augmentWith ControllerMixin
  @augmentWith BackBufferMixin

  target: null
  targetSetter: "color"
  choice: null

  constructor: (@target = null, sizePoint) ->
    super()
    @silentRawSetExtent sizePoint or new Point 80, 50
  
  # no changes of position or extent should be
  # performed in here
  createRefreshOrGetBackBuffer: ->
    cacheKey =
      @extent().toString()

    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit? then return cacheHit

    extent = @extent()
    backBuffer = newCanvas extent.scaleBy pixelRatio
    backBufferContext = backBuffer.getContext "2d"
    backBufferContext.scale pixelRatio, pixelRatio
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
        backBufferContext.fillStyle = "hsl(" + h + ",100%," + l + "%)"
        backBufferContext.fillRect x, y, 1, 1

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry

  # you can't grab the colorPaletteMorph because
  # the drag operation currently picks a color.
  # You could change that, you could pick color
  # only by normal click for example.
  # Or you could have either behaviour based on
  # preference.
  # Or you could perhaps allow it to be grabbed
  # if it's disabled, say. (but we don't have this
  # "disabled" concept implemented now).
  rootForGrab: ->
    return null
  
  mouseMove: (pos, mouseButton) ->
    # effectively takes care of drag as well

    if mouseButton == "left"
      @choice = @getPixelColor pos
      @updateTarget()
  
  mouseDownLeft: (pos) ->
    @choice = @getPixelColor pos
    @updateTarget()
    super
  
  updateTarget: ->
    if @target instanceof Morph and @choice?
      setterMethodString = "set" + @targetSetter.camelize()
      if @target[setterMethodString] instanceof Function
        @target[setterMethodString] @choice
      else
        alert "this shouldn't happen"
  
    
  # ColorPaletteMorph menu:
  developersMenu: (morphOpeningTheMenu) ->
    menu = super
    menu.addLine()
    menu.addMenuItem "set target", true, @, "setTarget", "choose another morph\nwhose color property\n will be" + " controlled by this one"
    menu
  
  # setTarget: -> taken form the ControllerMixin

  swapTargetsTHISNAMEISRANDOM: (ignored, ignored2, theTarget, each) ->
    @target = theTarget
    @targetSetter = each

  setTargetSetter: (ignored, ignored2, theTarget) ->
    choices = theTarget.colorSetters()
    menu = new MenuMorph @, false, @, true, true, "choose target property:"
    choices.forEach (each) =>
      menu.addMenuItem each, true, @, "swapTargetsTHISNAMEISRANDOM", null, null, null, null, null, theTarget, each

    if choices.length == 0
      menu = new MenuMorph @, false, @, true, true, "no target properties available"
    menu.popUpAtHand()
