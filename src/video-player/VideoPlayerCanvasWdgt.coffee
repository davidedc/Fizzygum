# this file is excluded from the fizzygum homepage build

# "container"/"contained" scenario going on.

class VideoPlayerCanvasWdgt extends CanvasMorph

  video: nil
  _extentWhenPreviousBackgroundWasPainted: nil

  createRefreshOrGetBackBuffer: ->
    [@backBuffer, @backBufferContext] = super
    @paintNewFrame()
    return [@backBuffer, @backBufferContext]

  constructor: ->
    super

    @video = document.createElement('video');
    @video.src = 'videos/big-buck-bunny_trailer.webm';
    @video.autoplay = true;

    # @fps = 5 # you can do that
    world.steppingWdgts.add @

  step: ->
    @paintNewFrame()
    @changed()

  # draw the frame on black background such that it's fully contained
  # within the bounding box of the canvas, maintaining the aspect ratio
  # of the video
  paintNewFrame: ->
    # we get the context already with the correct pixel scaling
    # (ALWAYS leave the context with the correct pixel scaling.)

    frameWidthKeepingRatioBasedOnHeight = Math.floor(@height() * @video.videoWidth / @video.videoHeight)
    frameHeightKeepingRatioBasedOnWidth = Math.floor(@width() * @video.videoHeight / @video.videoWidth)

    # let's paint the black background only if we need to i.e.
    # if the current extent is different from the extent when we
    # painted the previous background
    if (!@_extentWhenPreviousBackgroundWasPainted?) or (!@_extentWhenPreviousBackgroundWasPainted.equals @extent())
        if @backBufferContext?
          # paint the black background
          @backBufferContext?.fillStyle = "black"
          @backBufferContext?.fillRect 0, 0, @width(), @height()
          # remember the extent of the canvas 
          @_extentWhenPreviousBackgroundWasPainted = @extent()
          #console.log "painting black background"

    # paint the frame so that it is fully contained in the canvas
    # and also centered
    if frameWidthKeepingRatioBasedOnHeight <= @width()
      @backBufferContext?.drawImage(@video, Math.floor((@width() - frameWidthKeepingRatioBasedOnHeight)/2), 0, frameWidthKeepingRatioBasedOnHeight, @height());
    else
      @backBufferContext?.drawImage(@video, 0, Math.floor((@height() - frameHeightKeepingRatioBasedOnWidth)/2), @width(), frameHeightKeepingRatioBasedOnWidth);



  # TODO You should override isTransparentAt much much more extensively, because
  # having the mouse reading pixels via @getPixelColorAt: (aPoint)
  # is not very efficient. You should console.out whenever that happens and see if it
  # happens too often, and avoid that from happening.
  #
  # TODO copied from RectangularAppearance
  isTransparentAt: (aPoint) ->
    if @boundingBoxTight().containsPoint aPoint
      return false
    if @backgroundTransparency? and @backgroundColor?
      if @backgroundTransparency > 0
        if @boundsContainPoint aPoint
          return false
    return true
