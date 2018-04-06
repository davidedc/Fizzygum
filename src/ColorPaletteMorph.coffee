# REQUIRES ControllerMixin
# REQUIRES BackBufferMixin

class ColorPaletteMorph extends Widget

  @augmentWith ControllerMixin
  @augmentWith BackBufferMixin

  target: nil
  action: nil
  argumentToAction: nil
  choice: nil

  constructor: (@target = nil, sizePoint) ->
    super()
    @silentRawSetExtent sizePoint or new Point 80, 50

  colloquialName: ->
    "color palette"

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec PreferredSize.DONT_MIND , PreferredSize.DONT_MIND, 1
  
  detachesWhenDragged: ->
    false

  # no changes of position or extent should be
  # performed in here
  createRefreshOrGetBackBuffer: ->
    cacheKey =
      @constructor.name + "-" + @extent().toString()

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
  
  nonFloatDragging: (nonFloatDragPositionWithinMorphAtStart, pos, deltaDragFromPreviousCall) ->
    @choice = @getPixelColor pos.add (deltaDragFromPreviousCall or new Point 0, 0)
    @connectionsCalculationToken = getRandomInt -20000, 20000
    @updateTarget()
  
  mouseDownLeft: (pos) ->
    @choice = @getPixelColor pos
    @connectionsCalculationToken = getRandomInt -20000, 20000
    @updateTarget()

  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!"
    functionNamesStrings.push "bang"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!"
    functionNamesStrings.push "bang"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  colorSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    menuEntriesStrings.push "bang!"
    functionNamesStrings.push "bang"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings


  # the bang makes the node fire the current output value
  bang: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    debugger
    if !@choice? then return
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = getRandomInt -20000, 20000 else @connectionsCalculationToken = connectionsCalculationToken
    @updateTarget()
  
  updateTarget: ->
    debugger

    if !@target? then return

    if !@action?
      @action = "setColor"

    @target[@action].call @target, @choice, nil, @connectionsCalculationToken
    return  

  reactToTargetConnection: ->

  # ColorPaletteMorph menu:
  addMorphSpecificMenuEntries: (morphOpeningThePopUp, menu) ->
    super
    menu.addLine()
    if world.isIndexPage
      menu.addMenuItem "connect to ➜", true, @, "openTargetSelector", "connect to\nanother widget"
    else
      menu.addMenuItem "set target", true, @, "openTargetSelector", "choose another morph\nwhose color property\n will be" + " controlled by this one"
  
  # openTargetSelector: -> taken form the ControllerMixin

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    [menuEntriesStrings, functionNamesStrings] = theTarget.colorSetters()
    menu = new MenuMorph @, false, @, true, true, "choose target property:"
    for i in [0...menuEntriesStrings.length]
      menu.addMenuItem menuEntriesStrings[i], true, @, "setTargetAndActionWithOnesPickedFromMenu", nil, nil, nil, nil, nil, theTarget, functionNamesStrings[i]
    if menuEntriesStrings.length == 0
      menu = new MenuMorph @, false, @, true, true, "no target properties available"
    menu.popUpAtHand()
