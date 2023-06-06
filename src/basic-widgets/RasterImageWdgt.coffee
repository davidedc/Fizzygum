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

# Note also that you could get rid of the Image once it's loaded
# and keep the Image content in a separate dedicated canvas.
# This would have the advantage that you don't keep around
# (and potentially need to deepcopy, with consequent extra code) an Image, which is
# a special class for _loading_ images rather than keeping them around.
# So you wouldn't be able to deepCopy this class while the Image is loading then,
# which also would be odd.

class RasterImageWdgt extends CanvasMorph

  imagePath: nil
  imageLoaded: false
  img: nil
  lastPaintedImageSize: nil

  constructor: (@imagePath) ->
    super
    @color = Color.BLACK
  
    @loadImage @imagePath

  loadImage: (@imagePath) ->
    if @img?
      @img.onload = null
      @img.src = ''
      @img = null

    @imageLoaded = false

    @img = new Image()
    @img.onload = =>
      @imageLoaded = true
      @lastPaintedImageSize = nil
      # TODO id: NO_STEPPING_ONLY_ONCE_TO_HANDLE_CALLBACK date: 6-May-2023
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
      #console.log "raster image not loaded yet, painting black"
      context.fillStyle = Color.BLACK.toString()
      context.fillRect 0, 0, @extent().x, @extent().y
    else
      #console.log "raster image loaded, painting it to backbuffer"
      context.drawImage @img, 0, 0, @extent().x, @extent().y
      # you can't dispose the Image here, just in case the widget is resized
      # and the Image needs to be redrawn at a different size.

  # this is only called when the @img.onload callback fires
  # and is only executed once.
  #
  # TODO id: NO_STEPPING_ONLY_ONCE_TO_HANDLE_CALLBACK date: 6-May-2023 description:
  # This looks like a fishy pattern where the stepping is only started to do
  # something after a callback fires (e.g. an image loads, a manifest loads, a piece
  # of data loads etc. etc.) and then there is only once step and then the widget
  # is removed from the stepping list immediately after. This is done so to
  # the callback is executed like all other events i.e. we "do stuff" not
  # at any random possible time, but rather within a frame cycle, in a controlled
  # manner. HOWEVER this specific way of doing it surely is not elegant. Maybe
  # there should be a way of registering events against this widget to be executed
  # at the next frame cycle, e.g. "onNextFrameCycleCall(method, args...)" or
  # something like that.
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
