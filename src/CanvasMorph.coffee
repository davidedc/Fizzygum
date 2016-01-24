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

  # No changes of position or extent should be
  # performed in here.
  # There is really little hope to cache this buffer
  # cross-morph, unless you key the buffer with the
  # order of all the primitives and their
  # parameters. So just keep a dedicated one
  # for each canvas, simple.
  createRefreshOrGetBackBuffer: ->

    extent = @extent()

    if @backBuffer?
      backBufferExtent = new Point @backBuffer.width, @backBuffer.height
      if backBufferExtent.eq extent.scaleBy pixelRatio
        return [@backBuffer, @backBufferContext]

    @backBuffer = newCanvas extent.scaleBy pixelRatio
    @backBufferContext = @backBuffer.getContext "2d"
    @backBufferContext.scale pixelRatio, pixelRatio

    @backBufferContext.fillStyle = @color.toString()
    @backBufferContext.fillRect 0, 0, extent.x, extent.y

    return [@backBuffer, @backBufferContext]
