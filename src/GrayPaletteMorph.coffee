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
    backBuffer = newCanvas extent.scaleBy pixelRatio
    backBufferContext = backBuffer.getContext "2d"
    backBufferContext.scale pixelRatio, pixelRatio
    @choice = new Color()
    gradient = backBufferContext.createLinearGradient 0, extent.y, extent.x, extent.y
    gradient.addColorStop 0, "black"
    gradient.addColorStop 1, "white"
    backBufferContext.fillStyle = gradient
    backBufferContext.fillRect 0, 0, extent.x, extent.y

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry
