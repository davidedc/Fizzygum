class GrayPaletteMorph extends ColorPaletteMorph

  constructor: (@target = nil, sizePoint) ->
    super @target, sizePoint or new Point 80, 10

  initialiseDefaultWindowContentLayoutSpec: ->
    @layoutSpecDetails = new WindowContentLayoutSpec PreferredSize.DONT_MIND , PreferredSize.DONT_MIND, 1

  colloquialName: ->
    "shades of gray"
  
  # no changes of position or extent should be
  # performed in here
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
    gradient = backBufferContext.createLinearGradient 0, extent.y, extent.x, extent.y
    gradient.addColorStop 0, Color.BLACK.toString()
    gradient.addColorStop 1, Color.WHITE.toString()
    backBufferContext.fillStyle = gradient
    backBufferContext.fillRect 0, 0, extent.x, extent.y

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry
