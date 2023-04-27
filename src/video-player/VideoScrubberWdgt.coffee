class VideoScrubberWdgt extends SliderMorph

  videoPlayerCanvas: nil

  # these are used because there is some delay between
  # when the user scrubs / clicks play/pause and the
  # video element state catching up / reacting. So if we update
  # the UI based on video state immediately after a user
  # action, the UI will seem to "bounce back" to the
  # previous play/pause state, or scrub time.
  # So the solution is to wait a bit before updating
  # the UI, so the video element state has time
  # to catch up on the user action, and the UI
  # then doesn't bounce.
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
    if @videoPlayerCanvas?
      # only update the bar if it's not been moved by the user
      # in the last 250ms
      if (!@timeWhenScrubWasLastMoved?) or (Date.now() - @timeWhenScrubWasLastMoved) > 750
        @updateHandlePosition 100 * @videoPlayerCanvas.video.currentTime / @videoPlayerCanvas.video.duration


  # TODO this is a private method, should have an underscore
  setPlayAt: (sliderPercentage)->
    # set the video to play at the "location"
    # as set by the slider
    if @videoPlayerCanvas?.video? and isFinite(@videoPlayerCanvas.video.duration)
      @videoPlayerCanvas.video.currentTime = @videoPlayerCanvas.video.duration * sliderPercentage/100
      @timeWhenScrubWasLastMoved = Date.now()
