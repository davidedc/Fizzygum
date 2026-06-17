# Base for the draggable colour palettes — a rectangle you drag across to pick
# a pixel colour, which is pushed to a target widget's colour property (or a
# chosen property). ColorPaletteWdgt paints an HSL field; GrayPaletteWdgt a
# black->white gradient.
#
# They are SIBLINGS here: a gray palette is-not-a colour palette, so the shared
# drag / target / menu plumbing + the back-buffer cache shell live on this base,
# and each subclass supplies only its fill (fillPaletteBuffer), its default size
# (defaultSize, if not the 80x50 default), and its colloquial name.

class PaletteWdgt extends Widget

  @augmentWith ControllerMixin
  @augmentWith BackBufferMixin

  target: nil
  action: nil
  argumentToAction: nil
  choice: nil

  constructor: (@target = nil, sizePoint) ->
    super()
    @silentRawSetExtent sizePoint or @defaultSize()

  # subclass overrides this only if it wants a size other than the default
  defaultSize: -> new Point 80, 50

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec PreferredSize.DONT_MIND , PreferredSize.DONT_MIND, 1

  detachesWhenDragged: ->
    false

  # no changes of position or extent should be performed in here. The cache
  # shell (key -> lookup -> allocate -> fill -> store) is shared; the subclass
  # paints the pixels via fillPaletteBuffer.
  createRefreshOrGetBackBuffer: ->
    cacheKey =
      @constructor.name + "-" + @extent().toString()

    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit? then return cacheHit

    extent = @extent()
    backBuffer = HTMLCanvasElement.createOfPhysicalDimensions extent.scaleBy ceilPixelRatio
    backBufferContext = backBuffer.getContext "2d"
    backBufferContext.useLogicalPixelsUntilRestore()
    @choice = Color.BLACK
    @fillPaletteBuffer backBufferContext, extent

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry

  nonFloatDragging: (nonFloatDragPositionWithinWdgtAtStart, pos, deltaDragFromPreviousCall) ->
    @choice = @getPixelColor pos.add (deltaDragFromPreviousCall or new Point 0, 0)
    @connectionsCalculationToken = world.makeNewConnectionsCalculationToken()
    @updateTarget()

  mouseDownLeft: (pos) ->
    @choice = @getPixelColor pos
    @connectionsCalculationToken = world.makeNewConnectionsCalculationToken()
    @updateTarget()

  # the three setter flavours each append the same "bang!" entry on top of the
  # ControllerMixin's list, then dedupe — factored here to kill the triplication.
  addBangSetter: (menuEntriesStrings, functionNamesStrings) ->
    menuEntriesStrings.push "bang!"
    functionNamesStrings.push "bang"
    return @deduplicateSettersAndSortByMenuEntryString menuEntriesStrings, functionNamesStrings

  stringSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @addBangSetter menuEntriesStrings, functionNamesStrings

  numericalSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @addBangSetter menuEntriesStrings, functionNamesStrings

  colorSetters: (menuEntriesStrings, functionNamesStrings) ->
    [menuEntriesStrings, functionNamesStrings] = super menuEntriesStrings, functionNamesStrings
    @addBangSetter menuEntriesStrings, functionNamesStrings

  # the bang makes the node fire the current output value
  bang: (newvalue, ignored, connectionsCalculationToken, superCall) ->
    if !@choice? then return
    if !superCall and connectionsCalculationToken == @connectionsCalculationToken then return else if !connectionsCalculationToken? then @connectionsCalculationToken = world.makeNewConnectionsCalculationToken() else @connectionsCalculationToken = connectionsCalculationToken
    @updateTarget()

  updateTarget: ->
    if !@target? then return

    if !@action?
      @action = "setColor"

    @target[@action].call @target, @choice, nil, @connectionsCalculationToken
    return

  reactToTargetConnection: ->

  # palette menu:
  addWidgetSpecificMenuEntries: (widgetOpeningThePopUp, menu) ->
    super
    menu.addLine()
    if world.isIndexPage
      menu.addMenuItem "connect to ➜", true, @, "openTargetSelector", "connect to\nanother widget"
    else
      menu.addMenuItem "set target", true, @, "openTargetSelector", "choose another widget\nwhose color property\n will be" + " controlled by this one"

  # openTargetSelector: -> taken from the ControllerMixin

  openTargetPropertySelector: (ignored, ignored2, theTarget) ->
    [menuEntriesStrings, functionNamesStrings] = theTarget.colorSetters()
    menu = new MenuWdgt @, false, @, true, true, "choose target property:"
    for i in [0...menuEntriesStrings.length]
      menu.addMenuItem menuEntriesStrings[i], true, @, "setTargetAndActionWithOnesPickedFromMenu", nil, nil, nil, nil, nil, theTarget, functionNamesStrings[i]
    if menuEntriesStrings.length == 0
      menu = new MenuWdgt @, false, @, true, true, "no target properties available"
    menu.popUpAtHand()
