# I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
# and event handling.
# Also I always use a canvas to retain my graphical representation and respond
# to the HTML5 commands.
# 
# "container"/"contained" scenario going on.

class RasterImageWdgt extends CanvasMorph

  imagePath: nil
  imageLoaded: false
  img: nil
  imagePaintedOnBackbuffer: false

  constructor: (@imagePath) ->
    super
    @color = Color.BLACK
  
    @img = new Image();
    @img.onload = =>
      @imageLoaded = true
      @imagePaintedOnBackbuffer = false
      world.steppingWdgts.add @
    @img.src = @imagePath

  createRefreshOrGetBackBuffer: ->
    [@backBuffer, @backBufferContext] = super
    # TODO this doesn't repaint the image when the thumbnail is resized
    # because the image is painted on the backbuffer only once...
    # we should remember the size we last painted the image at and
    # check that against the current size, and repaint the image if
    # the size has changed.
    if !@imagePaintedOnBackbuffer
      @paintImageOnBackBuffer()
    return [@backBuffer, @backBufferContext]


  # Assuming that the widget is not resized, this method should get called
  # two times: one when the widget is created and there is no image loaded yet
  # (i.e. painted black), and one when the image is loaded
  # and it is painted on the backbuffer.
  # This should _also_ get called when the widget is resized.
  paintImageOnBackBuffer: ->
    if !@backBuffer? then @createRefreshOrGetBackBuffer()

    context = @backBufferContext

    #console.log " painting image on backbuffer @extent().x, @extent().y: " +  @extent().x + " " + @extent().y

    if !@imageLoaded
      # if the image is not loaded then just draw a black rectangle
      console.log "raster image not loaded yet, painting black"
      context.fillStyle = Color.BLACK.toString()
      context.fillRect 0, 0, @extent().x * ceilPixelRatio, @extent().y * ceilPixelRatio
    else
      console.log "raster image loaded, painting it to backbuffer"
      context.drawImage @img, 0, 0, @extent().x * ceilPixelRatio, @extent().y * ceilPixelRatio
      # you can't dispose the Image here, just in case the widget is resized
      # and the Image needs to be redrawn at a different size.

    @imagePaintedOnBackbuffer = true
    

  step: ->
    @paintImageOnBackBuffer()
    @changed()
    world.steppingWdgts.delete @

  # TODO You should override isTransparentAt much much more extensively, because
  # having the mouse reading pixels via @getPixelColorAt: (aPoint)
  # is not very efficient. You should console.out whenever that happens and see if it
  # happens too often, and avoid that from happening.
  #
  # TODO copied from RectangularAppearance, and there are other copies of this
  isTransparentAt: (aPoint) ->
    if @boundingBoxTight().containsPoint aPoint
      return false
    if @backgroundTransparency? and @backgroundColor?
      if @backgroundTransparency > 0
        if @boundsContainPoint aPoint
          return false
    return true
