class VideoControlsPaneWdgt extends RectangleMorph

  playPauseToggle: nil

  # labels
  playHeadTimeLabel: nil
  durationTimeLabel: nil

  videoScrubber: nil

  externalPadding: 0
  internalPadding: 5
  padding: nil

  videoPlayerCanvas: nil

  colloquialName: ->
    "Video controls"

  constructor: (@videoPlayerCanvas) ->
    super new Point(20, 20), Color.TRANSPARENT
    @buildAndConnectChildren()

  buildAndConnectChildren: ->
    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    @fullDestroyChildren()

    @playPauseToggle = new VideoPlayPauseToggle @videoPlayerCanvas
    @add @playPauseToggle

    @videoScrubber = new VideoScrubberWdgt @videoPlayerCanvas
    @add @videoScrubber


    @playHeadTimeLabel = new VideoTimeLabelWdgt @videoPlayerCanvas
    @add @playHeadTimeLabel

    @durationTimeLabel = new VideoDurationLabelWdgt @videoPlayerCanvas
    @add @durationTimeLabel

    # update layout
    @invalidateLayout()


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

    playPauseToggleBounds = new Rectangle new Point @left() + @externalPadding, @top() + @externalPadding
    playPauseToggleBounds = playPauseToggleBounds.setBoundsWidthAndHeight new Point @width()/15, 20
    @playPauseToggle.doLayout playPauseToggleBounds

    @videoScrubber.fullRawMoveTo new Point @left() + @externalPadding + 2 * @width()/15, @top() + @externalPadding
    @videoScrubber.rawSetExtent new Point @width() - (3 * @width()/15 + @internalPadding), 20

    playHeadTimeLabelBounds = new Rectangle new Point @left() + @externalPadding + @width()/15 + 2 * @internalPadding, @top() + @externalPadding + 2
    playHeadTimeLabelBounds = playHeadTimeLabelBounds.setBoundsWidthAndHeight @width()/15 , 15
    @playHeadTimeLabel.doLayout playHeadTimeLabelBounds

    durationTimeLabelBounds = new Rectangle new Point @right() - @width()/15 + 2 * @internalPadding, @top() + @externalPadding + 2
    durationTimeLabelBounds = durationTimeLabelBounds.setBoundsWidthAndHeight @width()/15 , 15
    @durationTimeLabel.doLayout durationTimeLabelBounds


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()
