# I clip my subwidgets at my bounds. Which potentially saves a lot of redrawing
# and event handling.
# Also I always use a canvas to retain my graphical representation and respond
# to the HTML5 commands.
#
# "container"/"contained" scenario going on.
#
# MY PAPER -- what my raster is laid on as it is made, enlarged or cleared -- is my own colour when
# one is set on me (setColor), else the canvas role, read as the raster is painted (_surfaceFill).
# The paper is part of the raster: a role that moves later shows on the next raster I make, not on
# the one I hold.
#
# MY RASTER BECOMES CONTENT the moment something draws on it through me (drawLine, clear -- the pen's
# two ways in): from then on it is the only copy of the drawing, and no paint can re-derive it. See
# drawnRaster.

class CanvasWdgt extends PanelWdgt
  @augmentWith BackBufferMixin

  # MY DRAWN RASTER: the very canvas object BackBufferMixin holds as my backBuffer, held a second time
  # under a name that rides a save. On every other widget backBuffer is a RENDER CACHE, re-derived on
  # demand after a restore, so Widget declares it a serialization transient (and a subclass can only
  # add to that list, never drop from it); a drawn raster is CONTENT, so it is also held here, where
  # the Serializer writes it as a $Canvas record -- one record, the object table being identity-keyed.
  # Undefined while my raster is only paper, which every raster I make lays again: a canvas nothing
  # has drawn on costs a saved file nothing, and neither does a subclass whose raster is a cache it
  # repaints (a video frame, a loaded image, a 3D render, the paint glass), since none of them draws
  # through drawLine or clear.
  # saved-content: once a pen has drawn on me this raster is the drawing's only copy
  drawnRaster: undefined

  # The paper I lay my raster on while I hold no colour of my own -- like every panel I hold none until
  # one is set on me (the soft hook a surface that wears a role answers: RectangularAppearance
  # ._fillColor, SimpleTextWdgt.blendInWithPanelColor). My border is the panel's (PanelWdgt
  # ._surfaceStroke).
  _surfaceFill: ->
    WorldWdgt.theme.canvasFill

  # Capability query (with ActivePointerWdgt): "can a pen draw onto me?" -- replaces the
  # `whereTo instanceof CanvasWdgt` arm in PenWdgt._reactToBeingAdded. Inherited by all CanvasWdgt
  # subclasses, mirroring the instanceof. (type-test-elimination campaign)
  acceptsPenDrawing: ->
    true

  # paintingOverlay() capability chain (§5.D): the glass a paint tool's
  # press-time injection targets. A canvas answers its glass-top child if it
  # carries one (an ImageWdgt's main canvas does), else undefined.
  paintingOverlay: ->
    @firstChildSuchThat (eachChild) -> eachChild.isPaintingOverlay?()
  
  _reactToBeingAdded: (whereTo, beingDropped) ->

  # No changes of position or extent should be
  # performed in here.
  # There is really little hope to cache this buffer
  # cross-widget, unless you key the buffer with the
  # order of all the primitives and their
  # parameters. So if user wants a cache it will have to specify
  # a dedicated one in here. See textWidget for an example.
  _createRefreshOrGetBackBuffer: ->

    extent = @extent()

    # a canvas restored from a file or a snapshot comes back holding its drawn raster and no back
    # buffer (that one is a transient): the drawing IS the back buffer, at my pixel scaling
    if !@backBuffer? and @drawnRaster?
      @backBuffer = @drawnRaster
      @backBufferContext = @backBuffer.getContext "2d"
      @backBufferContext.setTransform 1, 0, 0, 1, 0, 0
      @backBufferContext.useLogicalPixelsUntilRestore()

    if @backBuffer?
      # @backBuffer.width and @backBuffer.height are already in
      # physical coordinates so no need to adjust for pixelratio
      backBufferExtent = new Point @backBuffer.width, @backBuffer.height
      if backBufferExtent.equals extent.scaleBy ceilPixelRatio
        return [@backBuffer, @backBufferContext]
      else

        original_backBuffer = @backBuffer

        # make a new canvas of the new size
        @backBuffer = HTMLCanvasElement.createOfPhysicalDimensions extent.scaleBy ceilPixelRatio
        @backBufferContext = @backBuffer.getContext "2d"

        # paint the background over it all so there are
        # no holes in the new area (if the canvas is being
        # enlarged).
        paper = @color ? @_surfaceFill()
        if paper?
          @backBufferContext.fillStyle = paper.toString()
          @backBufferContext.fillRect 0, 0, extent.x * ceilPixelRatio, extent.y * ceilPixelRatio

        # copy back the original canvas in the new one.
        @backBufferContext.drawImage original_backBuffer, 0, 0
        
        # we leave the context with the correct pixel scaling.
        # ALWAYS leave the context with the correct pixel scaling.
        @backBufferContext.useLogicalPixelsUntilRestore()
        # the drawing moved to the new raster with the copy above
        @drawnRaster = @backBuffer if @drawnRaster?
        return [@backBuffer, @backBufferContext]

    @backBuffer = HTMLCanvasElement.createOfPhysicalDimensions extent.scaleBy ceilPixelRatio
    @backBufferContext = @backBuffer.getContext "2d"

    paper = @color ? @_surfaceFill()
    if paper?
      @backBufferContext.fillStyle = paper.toString()
      @backBufferContext.fillRect 0, 0, extent.x * ceilPixelRatio, extent.y * ceilPixelRatio

    # we leave the context with the correct scaling.
    # ALWAYS leave the context with the correct pixel scaling.
    @backBufferContext.useLogicalPixelsUntilRestore()
    return [@backBuffer, @backBufferContext]


  clear: (color = @color ? @_surfaceFill()) ->
    if !@backBuffer? then @_createRefreshOrGetBackBuffer()
    # @backBuffer.width and @backBuffer.height are already in
    # physical coordinates so no need to adjust for pixelratio
    backBufferExtent = new Point @backBuffer.width, @backBuffer.height
    
    # just in case we get a dirty transformation matrix:
    # set it to the identity.
    @backBufferContext.setTransform(1, 0, 0, 1, 0, 0)
    # no need to scale here because we get the physical pixels
    # in backBufferExtent
    #@backBufferContext.useLogicalPixelsUntilRestore()
    
    @backBufferContext.fillStyle = color.toString()
    @backBufferContext.fillRect 0, 0, backBufferExtent.x, backBufferExtent.y

    # we leave the context with the correct scaling.
    # ALWAYS leave the context with the correct pixel scaling.
    @backBufferContext.useLogicalPixelsUntilRestore()
    @drawnRaster = @backBuffer
    # the raster mutated in place, so the shadow-silhouette twin is stale (the mixin's
    # identity check cannot see an in-place change)
    @_backBufferShadowSilhouette = undefined
    @_changed()

  # The pen ASKS the canvas (PenWdgt.forward is the sole caller): a line primitive
  # lives on the raster's OWNER because every mutation must be followed by the
  # owner's PRIVATE bookkeeping below (silhouette invalidation + _changed) -- a
  # turtle-side implementation would have to reach into the buffer and repaint a
  # foreign widget, which invalidation-privacy bans. (The once-feared growth of
  # turtle-specific primitives here never happened: this is the only one.)
  drawLine: (start, dest, lineWidth, color) ->
    if !@backBuffer? then @_createRefreshOrGetBackBuffer()

    context = @backBufferContext
    # the line is in my logical pixels, so the context must scale by the pixel ratio -- and a copy's
    # does not: the Duplicator rebuilds a derived context straight off the copied canvas (a fresh,
    # unscaled one), so at a ratio above 1 a copy would take every line at a fraction of its size
    context.setTransform 1, 0, 0, 1, 0, 0
    context.useLogicalPixelsUntilRestore()

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
    @drawnRaster = @backBuffer
    # the raster mutated in place, so the shadow-silhouette twin is stale (the mixin's
    # identity check cannot see an in-place change)
    @_backBufferShadowSilhouette = undefined
    @_changed()
  
