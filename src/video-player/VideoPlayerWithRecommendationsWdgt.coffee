class VideoPlayerWithRecommendationsWdgt extends Widget

  videoPlayer: nil
  recommendationsPane: nil

  externalPadding: 0
  internalPadding: 5
  padding: nil


  thumbs: nil
  thumbnailsRows: 4
  thumbnailsColumns: 4

  prevButton: nil
  nextButton: nil

  videosIndex: nil

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

    # a for loop that creates nxm thumbnails, stored in thumbs

    @thumbs = []
    for i in [0...@thumbnailsRows]
      for j in [0...@thumbnailsColumns]
        thumb = new VideoThumbnailWdgt "./videos/big-buck-bunny_trailer_thumbnail.png", "./videos/big-buck-bunny_trailer.webm", @, "_onRecommendationClicked"
        @recommendationsPane.add thumb
        @thumbs.push thumb

    @prevButton = new SimpleButtonMorph true, @, "prev", "prev ❮"
    @recommendationsPane.add @prevButton

    @nextButton = new SimpleButtonMorph true, @, "next", "next ❯"
    @recommendationsPane.add @nextButton
    
    # update layout
    @invalidateLayout()

  _onRecommendationClicked: (unused1, unused2, videoPath) ->
    @loadVideo videoPath

  loadVideo: (videoPath) ->
    @videoPlayer.loadVideo videoPath
    # TODO reshuffle the video recommandation thumbnails

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


    # a for loop that positions the @thumbnailsRows x @thumbnailsColumns
    # stored in thumbs. The thumbnails are equally sized, and evenly positioned in the recommendationsPane
    # of size @width() x @height()

    internalPadding = 10
    spaceForPrevNextButtons = 24
    widthOfPrevNextButtons = 60
    spaceBetweenButtons = 40
    widthOfEachThumbnail = (recommendationPaneBounds.width() - (internalPadding * (@thumbnailsColumns - 1))) / @thumbnailsColumns
    heightOfEachThumbnail = (recommendationPaneBounds.height() - spaceForPrevNextButtons - (internalPadding * (@thumbnailsRows - 1))) / @thumbnailsRows

    for i in [0...@thumbnailsRows]
      for j in [0...@thumbnailsColumns]
        thumb = @thumbs[i*@thumbnailsColumns + j]
        thumbBounds = new Rectangle new Point recommendationPaneBounds.left() + j * (widthOfEachThumbnail + internalPadding), recommendationPaneBounds.top() + i * (heightOfEachThumbnail + internalPadding)
        thumbBounds = thumbBounds.setBoundsWidthAndHeight widthOfEachThumbnail, heightOfEachThumbnail
        thumb.doLayout thumbBounds

    # place the prev and next buttons on the bottom of the recommendationsPane
    prevButtonBounds = new Rectangle new Point recommendationPaneBounds.left() + recommendationPaneBounds.width()/2 - spaceBetweenButtons/2 - widthOfPrevNextButtons, recommendationPaneBounds.bottom() - spaceForPrevNextButtons
    prevButtonBounds = prevButtonBounds.setBoundsWidthAndHeight widthOfPrevNextButtons, spaceForPrevNextButtons
    @prevButton.doLayout prevButtonBounds

    nextButtonBounds = new Rectangle new Point recommendationPaneBounds.left() + recommendationPaneBounds.width()/2 + spaceBetweenButtons/2, recommendationPaneBounds.bottom() - spaceForPrevNextButtons
    nextButtonBounds = nextButtonBounds.setBoundsWidthAndHeight widthOfPrevNextButtons, spaceForPrevNextButtons
    @nextButton.doLayout nextButtonBounds


    world.maybeEnableTrackChanges()
    @fullChanged()
