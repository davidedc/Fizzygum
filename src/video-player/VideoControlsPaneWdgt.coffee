class VideoControlsPaneWdgt extends RectangleWdgt

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
    @_buildAndConnectChildren()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # subwidgets of the inspector. If they
    # have been peeled away, they still live
    @fullDestroyChildren()

    @playPauseToggle = new VideoPlayPauseToggle @videoPlayerCanvas
    @_addNoSettle @playPauseToggle

    @videoScrubber = new VideoScrubberWdgt @videoPlayerCanvas
    @_addNoSettle @videoScrubber


    @playHeadTimeLabel = new VideoTimeLabelWdgt @videoPlayerCanvas
    @_addNoSettle @playHeadTimeLabel

    @durationTimeLabel = new VideoDurationLabelWdgt @videoPlayerCanvas
    @_addNoSettle @durationTimeLabel

    # update layout
    @_invalidateLayout()


  # TODO you should use the newBoundsForThisLayout param
  # and if it's nil then you should use the current bounds
  #

  _reLayout: (newBoundsForThisLayout) ->

    if @_handleCollapsedStateShouldWeReturn() then return

    if !newBoundsForThisLayout?
      newBoundsForThisLayout = @boundingBox()

    # this sets my bounds and the ones of the children
    # that are attached with a special layout, and sets
    # the layout as "fixed".
    # For the ones that are attached with a free floating
    # layout... that's what the code after this
    # call is for
    super newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    #console.log "newBounds For VideoControlsPaneWdgt: " + newBoundsForThisLayout

    playPauseToggleBounds = new Rectangle new Point newBoundsForThisLayout.left() + @externalPadding, newBoundsForThisLayout.top() + @externalPadding
    playPauseToggleBounds = playPauseToggleBounds.setBoundsWidthAndHeight new Point 44, 23 + 7 + 14
    #console.log "playPauseToggleBounds: " + playPauseToggleBounds
    @playPauseToggle._reLayout playPauseToggleBounds

    videoScrubberBounds = new Rectangle new Point newBoundsForThisLayout.left() +  2 * (44 + @internalPadding), newBoundsForThisLayout.top() + @externalPadding
    videoScrubberBounds = videoScrubberBounds.setBoundsWidthAndHeight newBoundsForThisLayout.width() - 3 * (44 + @internalPadding), 44
    @videoScrubber._reLayout videoScrubberBounds

    playHeadTimeLabelBounds = new Rectangle new Point newBoundsForThisLayout.left() + @externalPadding + 44 + 2 * @internalPadding, newBoundsForThisLayout.top() + @externalPadding + 2 + 5 + 7
    playHeadTimeLabelBounds = playHeadTimeLabelBounds.setBoundsWidthAndHeight 44 , 18
    @playHeadTimeLabel._reLayout playHeadTimeLabelBounds

    durationTimeLabelBounds = new Rectangle new Point newBoundsForThisLayout.right() - 44 + 2 * @internalPadding, newBoundsForThisLayout.top() + @externalPadding + 2 + 5 + 7
    durationTimeLabelBounds = durationTimeLabelBounds.setBoundsWidthAndHeight 44 , 18
    @durationTimeLabel._reLayout durationTimeLabelBounds

    world.maybeEnableTrackChanges()
    @fullChanged()
