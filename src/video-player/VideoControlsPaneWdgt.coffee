class VideoControlsPaneWdgt extends RectangleMorph

  playPausePlayButton: nil
  playPausePauseButton: nil
  playPauseToggle: nil

  # labels
  playHeadTimeLabel: nil
  durationTimeLabel: nil

  videoScrubber: nil

  externalPadding: 0
  internalPadding: 5
  padding: nil

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
  timeWhenScrubWasLastMoved: nil

  colloquialName: ->
    "Video controls"

  constructor: (@videoPlayerCanvas) ->
    super new Point(20, 20), Color.TRANSPARENT
    @buildAndConnectChildren()

    # the label of the current time is updated via the stepping
    # mechanism, but you could do that via the connectors mechanism
    # instead, ideally you should have the canvas widget to only fire when
    # the time changes at the seconds level, and only
    # within a step.
    @fps = 5
    world.steppingWdgts.add @

  step: ->
    @_updatePlayHeadTimeLabel()
    @_updateDurationTimeLabel()
    @_updatePlayPauseToggle()

  _updatePlayPauseToggle: ->
    if @videoPlayerCanvas?
      # only update the toggle if it's not been clicked by the user
      # in the last 250ms
      if (!@timeWhenPlayPauseButtonWasLastClicked?) or (Date.now() - @timeWhenPlayPauseButtonWasLastClicked) > 250
        if @videoPlayerCanvas.video.paused
          # show the play button
          @playPauseToggle.setToggleState 1
        else
          # show the pause button
          @playPauseToggle.setToggleState 0

  _formatTime: (time) ->
    hours = Math.floor(time / 3600)
    minutes = Math.floor((time - (hours * 3600)) / 60)
    seconds = Math.floor(time - (hours * 3600) - (minutes * 60))
    # TODO omit the hours or minutes if they are 0
    "#{hours.toString().padStart(2, '0')}:#{minutes.toString().padStart(2, '0')}:#{seconds.toString().padStart(2, '0')}"

  _updatePlayHeadTimeLabel: ->
    if @videoPlayerCanvas?
      @playHeadTimeLabel.setText @_formatTime @videoPlayerCanvas.video.currentTime
  
  _updateDurationTimeLabel: ->
    if @videoPlayerCanvas?
      @durationTimeLabel.setText @_formatTime @videoPlayerCanvas.video.duration

  buildAndConnectChildren: ->
    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    @fullDestroyChildren()

    @playPausePauseButton = new SimpleButtonMorph true, @, "pause", "❙ ❙"
    @playPausePlayButton = new SimpleButtonMorph true, @, "play", "▶"
    @playPauseToggle = new ToggleButtonMorph @playPausePauseButton, @playPausePlayButton, 0
    @add @playPauseToggle

    @videoScrubber = new VideoScrubberWdgt @videoPlayerCanvas
    @add @videoScrubber


    @playHeadTimeLabel = new StringMorph2 "n/a", WorldMorph.preferencesAndSettings.textInButtonsFontSize
    @playHeadTimeLabel.alignLeft()
    @add @playHeadTimeLabel

    @durationTimeLabel = new StringMorph2 "n/a", WorldMorph.preferencesAndSettings.textInButtonsFontSize
    @durationTimeLabel.alignRight()
    @add @durationTimeLabel

    # update layout
    @invalidateLayout()

  # TODO this is a private method, should have an underscore
  pause: ->
    # pause the vide element in @videoPlayerCanvas.video
    @videoPlayerCanvas.video.pause()
    @timeWhenPlayPauseButtonWasLastClicked = Date.now()

  # TODO this is a private method, should have an underscore
  play: ->
    # pause the vide element in @videoPlayerCanvas.video
    @videoPlayerCanvas.video.play()
    @timeWhenPlayPauseButtonWasLastClicked = Date.now()

  # TODO you should use the newBoundsForThisLayout param
  # and if it's nil then you should use the current bounds
  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    if @_handleCollapsedStateShouldWeReturn() then return

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    playPauseToggleBounds = new Rectangle new Point @left() + @externalPadding, @top() + @externalPadding + @internalPadding
    playPauseToggleBounds = playPauseToggleBounds.setBoundsWidthAndHeight new Point @width()/5 - 2 * @externalPadding, 24
    @playPauseToggle.doLayout playPauseToggleBounds

    @videoScrubber.fullRawMoveTo new Point @left() + @externalPadding + 15, @top() + @externalPadding
    @videoScrubber.rawSetExtent new Point 200, 24

    playHeadTimeLabelBounds = new Rectangle new Point @left() + @externalPadding + 15, @top() + @externalPadding
    playHeadTimeLabelBounds = playHeadTimeLabelBounds.setBoundsWidthAndHeight 80 , 15
    @playHeadTimeLabel.doLayout playHeadTimeLabelBounds

    durationTimeLabelBounds = new Rectangle new Point @left() + @externalPadding + 15, @top() + @externalPadding + 15
    durationTimeLabelBounds = durationTimeLabelBounds.setBoundsWidthAndHeight 80 , 15
    @durationTimeLabel.doLayout durationTimeLabelBounds


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()
