# CanvasMorph //////////////////////////////////////////////////////////
# REQUIRES BackingStoreMixin
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
  @augmentWith BackingStoreMixin


  # Morph pen trails:
  penTrails: ->
    # answer my pen trails canvas. default is to answer my image
    # The implication is that by default every Morph in the system
    # (including the World) is able to act as turtle canvas and can
    # display pen trails.
    # BUT also this means that pen trails will be lost whenever
    # the trail's morph (the pen's parent) performs a "drawNew()"
    # operation. If you want to create your own pen trails canvas,
    # you may wish to modify its **penTrails()** property, so that
    # it keeps a separate offscreen canvas for pen trails
    # (and doesn't lose these on redraw).
    @backBuffer
  
  
  imBeingAddedTo: (newParentMorph) ->

  repaintBackBufferIfNeeded: ->
    if !@backBufferIsPotentiallyDirty then return
    @backBufferIsPotentiallyDirty = false

    if @backBufferValidityChecker?
      if @backBufferValidityChecker.extent == @extent().toString() and
      @backBufferValidityChecker.color == @color.toString()
        console.log "saved a bunch of drawing"
        return

    extent = @extent()
    @backBuffer = newCanvas(extent.scaleBy pixelRatio)
    @backBufferContext = @backBuffer.getContext("2d")
    @backBufferContext.scale pixelRatio, pixelRatio

    @backBufferContext.fillStyle = @color.toString()
    @backBufferContext.fillRect 0, 0, extent.x, extent.y

    @backBufferValidityChecker = new BackBufferValidityChecker()
    @backBufferValidityChecker.extent = @extent().toString()
    @backBufferValidityChecker.color = @color.toString()
