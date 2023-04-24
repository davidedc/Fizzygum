class VideoControlsPaneWdgt extends RectangleMorph

  playPausePlayButton: nil
  playPausePauseButton: nil
  playPauseToggle: nil
  playHeadTimeLabel: nil

  hbar: nil

  externalPadding: 0
  internalPadding: 5
  padding: nil

  colloquialName: ->
    "Video controls"

  constructor: ->
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

  _formatTime: (time) ->
    hours = Math.floor(time / 3600)
    minutes = Math.floor((time - (hours * 3600)) / 60)
    seconds = Math.floor(time - (hours * 3600) - (minutes * 60))
    # TODO omit the hours or minutes if they are 0
    "#{hours.toString().padStart(2, '0')}:#{minutes.toString().padStart(2, '0')}:#{seconds.toString().padStart(2, '0')}"

  _updatePlayHeadTimeLabel: ->
    if @parent?.videoPlayerCanvas?
      @playHeadTimeLabel.setText @_formatTime @parent.videoPlayerCanvas.video.currentTime

  buildAndConnectChildren: ->
    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    @fullDestroyChildren()

    @playPausePlayButton = new SimpleButtonMorph true, @, "play", "▶"
    @playPausePauseButton = new SimpleButtonMorph true, @, "pause", "❙ ❙"
    @playPauseToggle = new ToggleButtonMorph @playPausePlayButton, @playPausePauseButton, 1
    @add @playPauseToggle

    @hbar = new SliderMorph nil, nil, nil, nil, nil, true
    @add @hbar
    @hbar.setTargetAndActionWithOnesPickedFromMenu nil, nil, @, "setPlayAt"


    @playHeadTimeLabel = new StringMorph2 "n/a", WorldMorph.preferencesAndSettings.textInButtonsFontSize
    @playHeadTimeLabel.toggleHeaderLine()
    @playHeadTimeLabel.alignLeft()
    @add @playHeadTimeLabel


    # update layout
    @invalidateLayout()

  pause: ->
    # pause the vide element in @parent.videoPlayerCanvas.video
    @parent.videoPlayerCanvas.video.pause()

  setPlayAt: (sliderPercentage)->
    # set the video to play at the "location"
    # as set by the slider
    if @parent?.videoPlayerCanvas?
      @parent.videoPlayerCanvas.video.currentTime = @parent.videoPlayerCanvas.video.duration * sliderPercentage/100


  play: ->
    # pause the vide element in @parent.videoPlayerCanvas.video
    @parent.videoPlayerCanvas.video.play()

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

    @hbar.fullRawMoveTo new Point @left() + @externalPadding + 15, @top() + @externalPadding
    @hbar.rawSetExtent new Point 200, 24

    playHeadTimeLabelBounds = new Rectangle new Point @left() + @externalPadding + 15, @top() + @externalPadding
    playHeadTimeLabelBounds = playHeadTimeLabelBounds.setBoundsWidthAndHeight @width() - 2 * @externalPadding , 15
    @playHeadTimeLabel.doLayout playHeadTimeLabelBounds


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()
