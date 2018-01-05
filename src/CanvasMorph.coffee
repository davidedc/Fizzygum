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
  @augmentWith BackBufferMixin

  
  imBeingAddedTo: (newParentMorph) ->

  # No changes of position or extent should be
  # performed in here.
  # There is really little hope to cache this buffer
  # cross-morph, unless you key the buffer with the
  # order of all the primitives and their
  # parameters. So if user wants a cache it will have to specify
  # a dedicated one in here. See textMorph for an example.
  createRefreshOrGetBackBuffer: ->

    extent = @extent()

    if @backBuffer?
      # @backBuffer.width and @backBuffer.height are already in
      # physical coordinates so no need to adjust for pixelratio
      backBufferExtent = new Point @backBuffer.width, @backBuffer.height
      if backBufferExtent.eq extent.scaleBy pixelRatio
        return [@backBuffer, @backBufferContext]
      else

        original_backBuffer = @backBuffer

        # make a new canvas of the new size
        @backBuffer = newCanvas extent.scaleBy pixelRatio
        @backBufferContext = @backBuffer.getContext "2d"

        # paint the background over it all so there are
        # no holes in the new area (if the canvas is being
        # enlarged).
        if @color?
          @backBufferContext.fillStyle = @color.toString()
          @backBufferContext.fillRect 0, 0, extent.x * pixelRatio, extent.y * pixelRatio

        # copy back the original canvas in the new one.
        @backBufferContext.drawImage original_backBuffer, 0, 0
        
        # we leave the context with the correct pixel scaling.
        # ALWAYS leave the context with the correct pixel scaling.
        @backBufferContext.scale pixelRatio, pixelRatio
        return [@backBuffer, @backBufferContext]

    @backBuffer = newCanvas extent.scaleBy pixelRatio
    @backBufferContext = @backBuffer.getContext "2d"

    if @color?
      @backBufferContext.fillStyle = @color.toString()
      @backBufferContext.fillRect 0, 0, extent.x * pixelRatio, extent.y * pixelRatio

    # we leave the context with the correct scaling.
    # ALWAYS leave the context with the correct pixel scaling.
    @backBufferContext.scale pixelRatio, pixelRatio
    return [@backBuffer, @backBufferContext]


  clear: (color = @color.toString()) ->
    if !@backBuffer? then @createRefreshOrGetBackBuffer()
    # @backBuffer.width and @backBuffer.height are already in
    # physical coordinates so no need to adjust for pixelratio
    backBufferExtent = new Point @backBuffer.width, @backBuffer.height
    
    # just in case we get a dirty transformation matrix:
    # set it to the identity.
    @backBufferContext.setTransform(1, 0, 0, 1, 0, 0)
    # no need to scale here because we get the physical pixels
    # in backBufferExtent 
    #@backBufferContext.scale pixelRatio, pixelRatio
    
    @backBufferContext.fillStyle = color
    @backBufferContext.fillRect 0, 0, backBufferExtent.x, backBufferExtent.y

    # we leave the context with the correct scaling.
    # ALWAYS leave the context with the correct pixel scaling.
    @backBufferContext.scale pixelRatio, pixelRatio
    @changed()

  drawLine: (start, dest, lineWidth, color) ->
    if !@backBuffer? then @createRefreshOrGetBackBuffer()

    context = @backBufferContext

    from = start
    to = dest
    context.lineWidth = lineWidth
    context.strokeStyle = color.toString()
    context.lineCap = "round"
    context.lineJoin = "round"
    context.beginPath()
    context.moveTo from.x, from.y
    context.lineTo to.x, to.y
    context.stroke()
    @changed()
  
