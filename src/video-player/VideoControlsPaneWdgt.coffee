class VideoControlsPaneWdgt extends RectangleMorph

  playPauseButton: nil

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

    @playPauseButton = new SimpleButtonMorph true, @, "pause", "▶"

    @add @playPauseButton

    # update layout
    @invalidateLayout()

  pause: ->
    # pause the vide element in @parent.videoPlayerCanvas.video
    @parent.videoPlayerCanvas.video.pause()
  
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

    playPauseButtonBounds = new Rectangle new Point @left() + @externalPadding, @top() + @externalPadding + @internalPadding
    playPauseButtonBounds = playPauseButtonBounds.setBoundsWidthAndHeight new Point @width() - 2 * @externalPadding, @height() - 2 * @externalPadding - @internalPadding - 15
    @playPauseButton.doLayout playPauseButtonBounds


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()
