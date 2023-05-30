class VideoPlayPauseToggle extends ToggleButtonMorph

  playPausePlayButton: nil
  playPausePauseButton: nil

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
  timeWhenPlayPauseButtonWasLastClicked: nil

  colloquialName: ->
    "Play/pause button"

  constructor: (@videoPlayerCanvas) ->
    @playPausePauseButton = new SimpleButtonMorph true, @, "pause", "❙ ❙"
    @playPausePauseButton.faceMorph.alignMiddle()
    @playPausePlayButton = new SimpleButtonMorph true, @, "play", "▶"
    @playPausePlayButton.faceMorph.alignMiddle()
    super @playPausePauseButton, @playPausePlayButton, 0

    # the label of the current time is updated via the stepping
    # mechanism, but you could do that via the connectors mechanism
    # instead, ideally you should have the canvas widget to only fire when
    # the time changes at the seconds level, and only
    # within a step.
    @fps = 5
    world.steppingWdgts.add @

  step: ->
    @_updatePlayPauseToggle()

  _updatePlayPauseToggle: ->
    if @videoPlayerCanvas?
      # only update the toggle if it's not been clicked by the user
      # in the last 250ms
      if (!@timeWhenPlayPauseButtonWasLastClicked?) or (Date.now() - @timeWhenPlayPauseButtonWasLastClicked) > 250
        if @videoPlayerCanvas.video.paused
          # show the play button
          @setToggleState 1
        else
          # show the pause button
          @setToggleState 0

  # TODO this is a private method, should have an underscore
  pause: ->
    # pause the video element in @videoPlayerCanvas.video
    @videoPlayerCanvas.video.pause()
    @timeWhenPlayPauseButtonWasLastClicked = Date.now()

  # TODO this is a private method, should have an underscore
  play: ->
    # pause the video element in @videoPlayerCanvas.video
    @videoPlayerCanvas.video.play()
    @timeWhenPlayPauseButtonWasLastClicked = Date.now()

