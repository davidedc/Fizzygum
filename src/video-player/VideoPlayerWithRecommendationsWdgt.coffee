class VideoPlayerWithRecommendationsWdgt extends Widget

  videoPlayer: nil
  recommendationsPane: nil

  externalPadding: 0
  internalPadding: 5
  padding: nil

  thumb_1: nil

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


    rasterImageWdgt = new RasterImageWdgt "./videos/big-buck-bunny_trailer_thumbnail.png"
    # TODO this is needed because RasterImageWdgt extends CanvasMorph which extends PanelWdgt
    # which actually implements the mouseClickLeft handler and doesn'e escalate it.
    # We hence hack this override to make it so the click is indeed escalated to the
    # parent i.e. the SimpleButtonMorph.
    rasterImageWdgt.mouseClickLeft = (pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) ->
      @escalateEvent "mouseClickLeft", pos, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9

    @thumb_1 = new SimpleButtonMorph true, @, "hi", rasterImageWdgt
    # TODO is there a setPadding method?
    @thumb_1.padding = 2
    @recommendationsPane.add @thumb_1

    # update layout
    @invalidateLayout()

  hi: ->
    @inform "hi!"

  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
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

    # same bounds and layout but for the thumb_1
    thumb_1Bounds = new Rectangle new Point newBoundsForThisLayout.left() + @externalPadding + 10, newBoundsForThisLayout.top() + 2* @externalPadding + @internalPadding + newBoundsForThisLayout.height()/2 + 24 + 10
    thumb_1Bounds = thumb_1Bounds.setBoundsWidthAndHeight 200, 100
    @thumb_1.doLayout thumb_1Bounds

    world.maybeEnableTrackChanges()
    @fullChanged()
