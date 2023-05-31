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
  #
  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023 definition:
  # we currently have most of the doLayout methods
  # invoking super at the end of the method, and a few
  # at the beginning.
  # This is because when creating the Video widget I found out that
  # calling super at the end is actually wrong, bcause fixing the
  # layout of the children before fixing the layout of the
  # parent is problematic.
  #
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023 definition:
  # BUT IN FACT, studying the TODO id SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT 
  # matter a bit more, I found out that
  # super is a bit of a smell, because that's the exact problem:
  # the implementors of doLayout now have to understand some
  # deep aspects that they shouldn't have to - see
  # https://martinfowler.com/bliki/CallSuper.html
  # What should really happen is that there should be
  # a hook for just layouting the children
  # (say "fixLayoutOfFreefloatingChildren") that are
  # attached with free floating layout, and everything
  # else should be done automatically by the
  # doLayout implementation in Widget.
  # So now implementing layouts should be a lot clearer
  # by using that hook rather than understanding the
  # super call (what it doesn, why is it called where it is).

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

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
    # submorphs of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent morph breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    #console.log "newBounds For VideoControlsPaneWdgt: " + newBoundsForThisLayout

    playPauseToggleBounds = new Rectangle new Point newBoundsForThisLayout.left() + @externalPadding, newBoundsForThisLayout.top() + @externalPadding
    playPauseToggleBounds = playPauseToggleBounds.setBoundsWidthAndHeight new Point 44, 23 + 7 + 14
    #console.log "playPauseToggleBounds: " + playPauseToggleBounds
    @playPauseToggle.doLayout playPauseToggleBounds

    videoScrubberBounds = new Rectangle new Point newBoundsForThisLayout.left() +  2 * (44 + @internalPadding), newBoundsForThisLayout.top() + @externalPadding
    videoScrubberBounds = videoScrubberBounds.setBoundsWidthAndHeight newBoundsForThisLayout.width() - 3 * (44 + @internalPadding), 44
    @videoScrubber.doLayout videoScrubberBounds

    playHeadTimeLabelBounds = new Rectangle new Point newBoundsForThisLayout.left() + @externalPadding + 44 + 2 * @internalPadding, newBoundsForThisLayout.top() + @externalPadding + 2 + 5 + 7
    playHeadTimeLabelBounds = playHeadTimeLabelBounds.setBoundsWidthAndHeight 44 , 18
    @playHeadTimeLabel.doLayout playHeadTimeLabelBounds

    durationTimeLabelBounds = new Rectangle new Point newBoundsForThisLayout.right() - 44 + 2 * @internalPadding, newBoundsForThisLayout.top() + @externalPadding + 2 + 5 + 7
    durationTimeLabelBounds = durationTimeLabelBounds.setBoundsWidthAndHeight 44 , 18
    @durationTimeLabel.doLayout durationTimeLabelBounds

    world.maybeEnableTrackChanges()
    @fullChanged()
