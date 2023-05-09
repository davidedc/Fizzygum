# this file is excluded from the fizzygum homepage build

# "container"/"contained" scenario going on.

class VideoPlayerCanvasWdgt extends CanvasMorph

  video: nil
  _extentWhenPreviousBackgroundWasPainted: nil

  createRefreshOrGetBackBuffer: ->
    [@backBuffer, @backBufferContext] = super
    # TODO we don't actually need to put the current video frame on the backbuffer
    # every time this widget needs to draw itself (e.g. because something is being moved
    # briefly over it). We should just draw the backbuffer as is.
    @paintNewFrame()
    return [@backBuffer, @backBufferContext]

  constructor: (videoPath = "videos/big-buck-bunny_trailer.webm") ->
    super

    @_createVideoTagAndLoadVideo videoPath
    # @fps = 5 # you can do that
    world.steppingWdgts.add @

  loadVideo: (videoPath) ->    
    @_createVideoTagAndLoadVideo videoPath

  _createVideoTagAndLoadVideo: (videoPath) ->    
    # how to safely dispose of a video
    # https://stackoverflow.com/a/28060352
    if @video?
      @video.pause()
      @video.removeAttribute 'src'
      @video.load()

    # note that while Image and Audio have their own classes
    # with clean constructors, there is no Video class
    # and the only way to create a video is via the DOM
    @video = document.createElement 'video'
    @video.src = videoPath
    @video.autoplay = true
    @_extentWhenPreviousBackgroundWasPainted = nil


  # might come useful, but never used nor tested
  # see https://stackoverflow.com/questions/6877403/how-to-tell-if-a-video-element-is-currently-playing
  isPlaying: ->
    !!(@video.currentTime > 0 && !@video.paused && !@video.ended && @video.readyState > 2)

  pause: ->
    # pause the vide element in @videoPlayerCanvas.video
    @video.pause()

  play: ->
    # pause the vide element in @videoPlayerCanvas.video
    @video.play()

  togglePlayPause: ->
    if @video.paused
      @video.play()
    else
      @video.pause()

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
    # TODO id: FACTOR_OUT_BOUNDS_WITHIN_BOUNDS_WITH_SPECIFIED_RATIO date: 6-May-2023
    if frameWidthKeepingRatioBasedOnHeight <= @width()
      @backBufferContext?.drawImage(@video, Math.floor((@width() - frameWidthKeepingRatioBasedOnHeight)/2), 0, frameWidthKeepingRatioBasedOnHeight, @height());
    else
      @backBufferContext?.drawImage(@video, 0, Math.floor((@height() - frameHeightKeepingRatioBasedOnWidth)/2), @width(), frameHeightKeepingRatioBasedOnWidth);



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
