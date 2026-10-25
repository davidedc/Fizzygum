# "container"/"contained" scenario going on.

# IMPORTANT - if you are using fizzygum / video player via webserver (instead of via filesystem)
# then you need to use a webserver that supports range requests, otherwise the scrubbing
# will not work. This is because the browser will use range requests when scrubbing, however there
# doesn't seem to be a graceful handling when the server doesn't support range requests.
# Ideally 1) the browser should attempt a range request 2) the server should say "not supported"
# and 3) the browser should fall back to a non-range request. However, something (or many things)
# are not working as expected, and the server serves the beginning of the file again, and the
# browser shows the beginning of the video again.
# Note that python3 -m http.server does not support range requests, but RangeHTTPServer does.
# see https://github.com/danvk/RangeHTTPServer

class VideoPlayerCanvasWdgt extends CanvasWdgt

  # MY VIDEO PATH IS MY TRUTH, and the only part of my video that rides a save or a copy. @video is the
  # element this page made from it -- a PAGE FACT, so a serialization transient, and the Duplicator
  # copies none -- and a restore (_afterDeserialization) or a copy (_reactToBeingCopied) makes its own
  # from the path. A video made again plays from its beginning.
  videoPath: undefined
  video: undefined

  @serializationTransients: ["video"]

  _createRefreshOrGetBackBuffer: ->
    [@backBuffer, @backBufferContext] = super
    # TODO we don't actually need to put the current video frame on the backbuffer
    # every time this widget needs to draw itself (e.g. because something is being moved
    # briefly over it). We should just draw the backbuffer as is.
    @_paintNewFrame()
    return [@backBuffer, @backBufferContext]

  constructor: (videoPath = "videos/big-buck-bunny_trailer.webm") ->
    super

    @_createVideoTagAndLoadVideo videoPath
    # @fps = 5 # you can do that
    world.steppingWdgts.add @

  loadVideo: (videoPath) ->
    @_createVideoTagAndLoadVideo videoPath

  # The path I load becomes my video path (the @-parameter writes it whatever is passed): a load is a
  # change of truth, and a restore or a copy makes its video from the truth it already holds.
  _createVideoTagAndLoadVideo: (@videoPath) ->
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
    @video.src = @videoPath
    @video.autoplay = true

  # A restored me holds my video path and no video: this page makes its own. The restore does not wait
  # for it -- a video streams, and my step paints whatever frame it has reached.
  _afterDeserialization: ->
    @_createVideoTagAndLoadVideo @videoPath
    return

  # A copy of me holds my video path and no video (the Duplicator copies none): it makes its own, which
  # plays from its beginning while mine plays on.
  _reactToBeingCopied: ->
    @_createVideoTagAndLoadVideo @videoPath
    return


  play: ->
    # pause the video element in @videoPlayerCanvas.video
    @video.play()

  pause: ->
    # pause the video element in @videoPlayerCanvas.video
    @video.pause()

  togglePlayPause: ->
    if @video.paused
      @video.play()
    else
      @video.pause()

  step: ->
    @_paintNewFrame()
    @_changed()

  # draw the frame on black background such that it's fully contained
  # within the bounding box of the canvas, maintaining the aspect ratio
  # of the video
  _paintNewFrame: ->
    # we get the context already with the correct pixel scaling
    # (ALWAYS leave the context with the correct pixel scaling.)

    frameWidthKeepingRatioBasedOnHeight = Math.floor(@height() * @video.videoWidth / @video.videoHeight)
    frameHeightKeepingRatioBasedOnWidth = Math.floor(@width() * @video.videoHeight / @video.videoWidth)

    # the letterbox is black, laid under EVERY frame rather than once per size: my raster is a render
    # cache (the back buffer is a Widget serialization transient), so a "background already laid" memo
    # would ride a save that the raster does not, and a restored player would show its paper in the
    # letterbox. One fillRect costs less than the frame drawn over it.
    @backBufferContext?.fillStyle = "black"
    @backBufferContext?.fillRect 0, 0, @width(), @height()

    # paint the frame so that it is fully contained in the canvas
    # and also centered
    # TODO id: FACTOR_OUT_BOUNDS_WITHIN_BOUNDS_WITH_SPECIFIED_RATIO date: 6-May-2023
    if frameWidthKeepingRatioBasedOnHeight <= @width()
      @backBufferContext?.drawImage(@video, Math.floor((@width() - frameWidthKeepingRatioBasedOnHeight)/2), 0, frameWidthKeepingRatioBasedOnHeight, @height());
    else
      @backBufferContext?.drawImage(@video, 0, Math.floor((@height() - frameHeightKeepingRatioBasedOnWidth)/2), @width(), frameHeightKeepingRatioBasedOnWidth);



  # A video frame fills my box (the drawImage above spans @width()/@height(), letterboxing
  # inside it), so the pointer question has a constant answer and there is no reason to pay for
  # BackBufferMixin's per-pixel probe. SimpleImageWdgt says the same thing about its image.
  catchesPointerAt: (aPoint) ->
    @boundsContainPoint aPoint
