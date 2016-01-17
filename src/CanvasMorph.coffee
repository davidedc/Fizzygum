# CanvasMorph //////////////////////////////////////////////////////////
# REQUIRES BackBufferMixin
# 
# I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
# and event handling. 
# Also I always use a canvas to retain my graphical representation and respond
# to the HTML5 commands.
# 
# "container"/"contained" scenario going on.

class CanvasMorph extends FrameMorph
  # this is so we can create objects from the object class name 
  # (for the deserialization process)
  namedClasses[@name] = @prototype
  @augmentWith BackBufferMixin

  
  imBeingAddedTo: (newParentMorph) ->

  createRefreshOrGetBackBuffer: ->

    cacheKey =
      @extent().toString() + "-" +
      @toStringWithoutGeometry()

    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit? then return cacheHit

    extent = @extent()
    backBuffer = newCanvas extent.scaleBy pixelRatio
    backBufferContext = backBuffer.getContext "2d"
    backBufferContext.scale pixelRatio, pixelRatio

    backBufferContext.fillStyle = @color.toString()
    backBufferContext.fillRect 0, 0, extent.x, extent.y

    cacheEntry = [backBuffer, backBufferContext]
    world.cacheForImmutableBackBuffers.set cacheKey, cacheEntry
    return cacheEntry
