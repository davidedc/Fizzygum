class VideoControlsPaneWdgt extends RectangleMorph

  playPausePlayButton: nil
  playPausePauseButton: nil
  playPauseToggle: nil

  externalPadding: 0
  internalPadding: 5
  padding: nil

  colloquialName: ->
    "Video controls"

  constructor: ->
    super new Point(20, 20), Color.BLACK
    @buildAndConnectChildren()
  

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

    # update layout
    @invalidateLayout()

  pause: ->
    # pause the vide element in @parent.videoPlayerCanvas.video
    @parent.videoPlayerCanvas.video.pause()

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
    playPauseToggleBounds = playPauseToggleBounds.setBoundsWidthAndHeight new Point @width() - 2 * @externalPadding, @height() - 2 * @externalPadding - @internalPadding - 15
    @playPauseToggle.doLayout playPauseToggleBounds


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()
