# I clip my submorphs at my bounds. Which potentially saves a lot of redrawing
# and event handling.
# Also I always use a canvas to retain my graphical representation and respond
# to the HTML5 commands.
# 
# "container"/"contained" scenario going on.

# Having both the image and the backbuffer around
# might seem redundant, and in most cases it is, since
# the image in most cases eventually gets painted on the main
# canvas "as is", in which case we might as well just do that directly
# without need for an intermediate buffer.
# However consider that you might attach a turtle to this widget to
# draw some lines on it, or might want to apply some kind of filter effect,
# in which case you might want to keep the
# source image and the backbuffer separate.
class RasterImageWdgt extends CanvasMorph

  imagePath: nil
  imageLoaded: false
  img: nil
  lastPaintedImageSize: nil

  constructor: (@imagePath) ->
    super
    @color = Color.BLACK
  
    @img = new Image();
    @img.onload = =>
      @imageLoaded = true
      @lastPaintedImageSize = nil
      world.steppingWdgts.add @
    @img.src = @imagePath

  createRefreshOrGetBackBuffer: ->
    [@backBuffer, @backBufferContext] = super
    # This is so we draw the image on the backbuffer every time the
    # widget (and, consequently, the backbuffer) is resized.
    # To do that, we remember the size of the backbuffer we last painted the image on,
    # and if it's same as current size, and repaint the image if
    # the size has changed.
    if !@lastPaintedImageSize? or !@lastPaintedImageSize.equals @extent()
      @paintImageOnBackBuffer()
      @lastPaintedImageSize = @extent()
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
