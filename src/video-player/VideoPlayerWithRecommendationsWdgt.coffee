class VideoPlayerWithRecommendationsWdgt extends Widget

  videoPlayer: nil
  recommendationsPane: nil

  externalPadding: 0
  internalPadding: 5
  padding: nil

  colloquialName: ->
    "Video player with recommendations"

  constructor: ->
    super new Point 300, 300
    @buildAndConnectChildren()
  

  buildAndConnectChildren: ->
    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    @fullDestroyChildren()

    @videoPlayer = new VideoPlayerWdgt
    @add @videoPlayer

    @recommendationsPane = new RectangleMorph
    @add @recommendationsPane

    # update layout
    @invalidateLayout()

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

    videoPlayerBounds = new Rectangle new Point newBoundsForThisLayout.left() + @externalPadding, newBoundsForThisLayout.top() + @externalPadding
    videoPlayerBounds = videoPlayerBounds.setBoundsWidthAndHeight newBoundsForThisLayout.width() - 2 * @externalPadding, newBoundsForThisLayout.height()/2 + 24
    #console.log "videoPlayerBounds: " + videoPlayerBounds
    @videoPlayer.doLayout videoPlayerBounds

    recommendationPaneBounds = new Rectangle new Point newBoundsForThisLayout.left() + @externalPadding, newBoundsForThisLayout.top() + 2* @externalPadding + @internalPadding + newBoundsForThisLayout.height()/2 + 24
    recommendationPaneBounds = recommendationPaneBounds.setBoundsWidthAndHeight newBoundsForThisLayout.width() - 2 * @externalPadding, newBoundsForThisLayout.height()/2 - 24
    @recommendationsPane.doLayout recommendationPaneBounds

    world.maybeEnableTrackChanges()
    @fullChanged()
