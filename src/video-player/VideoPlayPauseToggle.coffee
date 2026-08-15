class VideoPlayPauseToggle extends ToggleButtonWdgt

  playPausePlayButton: undefined
  playPausePauseButton: undefined

  videoPlayerCanvas: undefined

  # there is a delay between a user scrub / play-pause click and the video
  # element's state catching up, so updating the UI from video state
  # immediately after a user action would visibly bounce it back to the
  # previous state -- the update is deferred briefly instead (the 250ms
  # guard in _updatePlayPauseToggle).
  timeWhenPlayPauseButtonWasLastClicked: undefined

  colloquialName: ->
    "Play/pause button"

  constructor: (@videoPlayerCanvas) ->
    @playPausePauseButton = new SimpleButtonWdgt @, "pause", face: "❙ ❙"
    @playPausePauseButton.faceWidget.alignMiddle()
    @playPausePlayButton = new SimpleButtonWdgt @, "play", face: "▶"
    @playPausePlayButton.faceWidget.alignMiddle()
    super @playPausePauseButton, @playPausePlayButton, 0

    # the toggle's play/pause state is updated via the stepping mechanism, but
    # you could do that via the connectors mechanism instead; ideally the canvas
    # widget would only fire when the play/pause state actually changes, rather
    # than every step.
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
          @_setToggleState 1
        else
          # show the pause button
          @_setToggleState 0

  # pause/play are the SimpleButtonWdgt action targets, dispatched BY NAME from
  # ButtonWdgt.trigger (as target[action]) -- external entry points, so no
  # underscore (the public/private call-separation convention).
  pause: ->
    @videoPlayerCanvas.video.pause()
    @timeWhenPlayPauseButtonWasLastClicked = Date.now()

  play: ->
    @videoPlayerCanvas.video.play()
    @timeWhenPlayPauseButtonWasLastClicked = Date.now()

