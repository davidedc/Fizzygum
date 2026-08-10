class VideoScrubberWdgt extends SliderWdgt

  videoPlayerCanvas: nil

  # there is a delay between a user scrub / play-pause click and the video
  # element's state catching up, so updating the UI from video state
  # immediately after a user action would visibly bounce it back to the
  # previous state -- the update is deferred briefly instead (the 750ms
  # guard in _updateHbar).
  timeWhenScrubWasLastMoved: nil

  colloquialName: ->
    "Video scrubber"

  constructor: (@videoPlayerCanvas) ->
    super nil, nil, nil, nil, nil, true
    @setTargetAndActionWithOnesPickedFromMenu nil, nil, @, "setPlayAt"
    @fps = 5
    world.steppingWdgts.add @

  step: ->
    @_updateHbar()
  
  _updateHbar: ->
    if @videoPlayerCanvas? and !@videoPlayerCanvas.seeking
      # only update the bar if it's not been moved by the user
      # in the last 750ms
      if (!@timeWhenScrubWasLastMoved?) or (Date.now() - @timeWhenScrubWasLastMoved) > 750
        @_updateHandlePosition 100 * @videoPlayerCanvas.video.currentTime / @videoPlayerCanvas.video.duration


  # setPlayAt is my action target, dispatched BY NAME (the string is wired in
  # the constructor; the dataflow engine resolves it on the target) -- an
  # external entry point, so no underscore (same ruling as
  # VideoPlayPauseToggle's pause/play).
  setPlayAt: (sliderPercentage)->
    # set the video to play at the "location"
    # as set by the slider
    if @videoPlayerCanvas?.video? and isFinite(@videoPlayerCanvas.video.duration)
      @videoPlayerCanvas.video.currentTime = @videoPlayerCanvas.video.duration * sliderPercentage/100
      @timeWhenScrubWasLastMoved = Date.now()
