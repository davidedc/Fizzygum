# I show the image at my image path, scaled to fill my box, on black paper.
#
# MY IMAGE PATH IS MY TRUTH, and the only part of my picture that rides a save or a copy. Everything
# else I hold about the picture is derived from it in the page I live in:
#   - @img is the Image this page loaded from the path, and @imageLoaded says whether that load has
#     arrived. Both are serialization transients, and the Duplicator copies no image: a restore
#     (_afterDeserialization) and a copy (_reactToBeingCopied) each load the path again, because a
#     carried "loaded" would claim an image this page has not decoded for me -- drawing that one
#     throws under SWCanvas and draws nothing natively, and a load I did not start never repaints me.
#   - my raster is a RENDER CACHE of the image at my size, repainted on every new raster. I keep no
#     memo of what I painted on it: the back buffer is a Widget serialization transient, so a memo of
#     it would ride a save that the raster it describes does not, and the restored me would skip the
#     paint it needs. I ask the raster instead -- see _createRefreshOrGetBackBuffer.
#
# The image and the raster are kept apart (rather than blitting the image straight to the screen) so
# that something can draw over my picture, or filter it, without losing the source image.

class SimpleImageWdgt extends CanvasWdgt

  imagePath: undefined
  imageLoaded: false
  img: undefined

  @serializationTransients: ["img", "imageLoaded"]

  constructor: (@imagePath) ->
    super
    @color = Color.BLACK

    @loadImage @imagePath

  loadImage: (imagePath) ->
    @_loadImage imagePath

  # The path I load becomes my image path (the @-parameter writes it whatever is passed): a load is a
  # change of truth, and a restore or a copy reloads the truth it already holds.
  #   Answers a promise that settles when this load arrives or fails -- what a restore's whenReady
  # waits on. A load that a later one replaces still runs to its end and settles its promise, so no
  # waiter is left hanging, but it claims nothing: only the newest load's image is mine.
  _loadImage: (@imagePath) ->
    @imageLoaded = false
    img = @img = new Image()
    new Promise (resolve) =>
      img.onload = =>
        if img is @img
          @imageLoaded = true
          # TODO id: NO_STEPPING_ONLY_ONCE_TO_HANDLE_CALLBACK date: 6-May-2023
          world.steppingWdgts.add @
        resolve()
      img.onerror = -> resolve()
      img.src = @imagePath

  # A restored me holds my image path and no image: this page loads its own, and the restore is ready
  # when it has arrived (the Deserializer waits on the promise I answer).
  _afterDeserialization: ->
    return @_loadImage @imagePath

  # A copy of me holds my image path and no image (the Duplicator copies none): it loads its own, and
  # until that load arrives it claims none -- a raster it paints meanwhile gets the black paper, never
  # a draw of an image it has not got.
  _reactToBeingCopied: ->
    @_loadImage @imagePath
    return

  # CanvasWdgt hands me a NEW raster exactly when there was none (I was just built, or restored) or my
  # size changed, and a new raster is an unpainted one -- so the raster's identity is all I need to know
  # whether the image is on it.
  _createRefreshOrGetBackBuffer: ->
    rasterBefore = @backBuffer
    [@backBuffer, @backBufferContext] = super
    @_paintImageOnBackBuffer() unless @backBuffer is rasterBefore
    return [@backBuffer, @backBufferContext]


  # Paints my picture on my raster: on every new raster, and once more when the image arrives (step).
  # The black paper goes down first EVERY time, so a repaint lays exactly the pixels the first paint did:
  # a scaled draw's edge pixels need not be opaque (SWCanvas leaves them part-transparent), and an image
  # drawn over its own earlier copy would composite those edges twice.
  _paintImageOnBackBuffer: ->
    if !@backBuffer? then @_createRefreshOrGetBackBuffer()

    context = @backBufferContext

    context.fillStyle = Color.BLACK.toString()
    context.fillRect 0, 0, @extent().x, @extent().y
    if @imageLoaded
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
    @_paintImageOnBackBuffer()
    @_changed()
    world.steppingWdgts.delete @

  # My raster fills my box — @_paintImageOnBackBuffer draws the image across the whole
  # @width()×@height() — so the pointer question has a constant answer and there is no reason to
  # pay for BackBufferMixin's per-pixel probe (getPixelColor allocates an ImageData per hover
  # sample). VideoPlayerCanvasWdgt says the same thing about its frames.
  catchesPointerAt: (aPoint) ->
    @boundsContainPoint aPoint
