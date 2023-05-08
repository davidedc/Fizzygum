class VideoPlayerWithRecommendationsWdgt extends Widget

  videoPlayer: nil
  recommendationsPane: nil

  externalPadding: 0
  internalPadding: 5
  padding: nil


  thumbs: nil
  thumbnailsRows: 3
  thumbnailsColumns: 5

  prevButton: nil
  nextButton: nil

  videosIndex: nil
  shuffledVideosIndex: nil

  recommendationsPage: 0

  colloquialName: ->
    "Video player with recommendations"

  constructor: ->
    super new Point 300, 300
    @buildAndConnectChildren()


    script = document.createElement "script"
    script.src = "./videos/Fizzygum-videos-private/privateVideosManifest.js"
    script.async = true # should be the default

    # triggers after the script was loaded and executed
    # see https://javascript.info/onload-onerror#script-onload
    script.onload = =>
      console.log "loaded manifest"
      @parseVideosIndex()
      # TODO id: NO_STEPPING_ONLY_ONCE_TO_HANDLE_CALLBACK date: 6-May-2023
      world.steppingWdgts.add @
      

    document.head.appendChild script

    script.onerror = ->
        reject(script)

  setUpVideoThumbsPage: ->
    for i in [0...@thumbs.length]
      shuffledWithPath = "./videos/Fizzygum-videos-private/" + @shuffledVideosIndex[(i + @recommendationsPage * (@thumbnailsRows * @thumbnailsColumns)) % @shuffledVideosIndex.length]
      @thumbs[i].setThumbnailAndVideoPath shuffledWithPath + ".webp", shuffledWithPath + ".webm"

  # stepping is only enabled once when the video index is first loaded
  # and parsed
  # TODO id: NO_STEPPING_ONLY_ONCE_TO_HANDLE_CALLBACK date: 6-May-2023
  step: ->
    @setUpVideoThumbsPage()
    world.steppingWdgts.delete @

  parseVideosIndex: ->
    # filter the names in privateVideos.files ending in .webm

    filteredNames = privateVideos.files.filter (name) ->
      name.endsWith ".webm"

    # map the names in filteredNames so to remove the .webm extension
    filteredNames = filteredNames.map (name) ->
      name.replace ".webm", ""
    
    @videosIndex = filteredNames
    console.log "videosIndex: " + @videosIndex

    @shuffledVideosIndex = @videosIndex.shallowCopy()
    # TODO according to StackOverflow, this is a biased and slow way to shuffle an array :-(
    @shuffledVideosIndex.sort (a, b) ->
      Math.random() - 0.5


  buildAndConnectChildren: ->
    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    @fullDestroyChildren()

    @videoPlayer = new VideoPlayerWdgt
    @add @videoPlayer

    # TODO this should be something better than a RectangleMorph
    @recommendationsPane = new RectangleMorph
    @add @recommendationsPane
    @recommendationsPane.setColor Color.TRANSPARENT

    # TODO this setup (and all the following handlings) of the thumbnails
    # should really be done by the @recommendationsPane.
    # Create nxm thumbnails, stored in thumbs
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

  prev: ->
    #console.log "prev"
    if @recommendationsPage > 0
      @recommendationsPage--
      @setUpVideoThumbsPage()
  
  next: ->
    #console.log "next"
    @recommendationsPage++
    @setUpVideoThumbsPage()

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
    videoPlayerBounds = videoPlayerBounds.setBoundsWidthAndHeight newBoundsForThisLayout.width() - 2 * @externalPadding, Math.floor newBoundsForThisLayout.height()/2 + 24 + newBoundsForThisLayout.height()*0.1125
    #console.log "videoPlayerBounds: " + videoPlayerBounds
    @videoPlayer.doLayout videoPlayerBounds

    recommendationPaneBounds = new Rectangle new Point newBoundsForThisLayout.left() + @externalPadding, newBoundsForThisLayout.top() + 2* @externalPadding + @internalPadding + newBoundsForThisLayout.height()/2 + 24 + newBoundsForThisLayout.height()*0.1125
    recommendationPaneBounds = recommendationPaneBounds.setBoundsWidthAndHeight newBoundsForThisLayout.width() - 2 * @externalPadding, Math.ceil newBoundsForThisLayout.height()/2 - 24 - newBoundsForThisLayout.height()*0.1125
    @recommendationsPane.doLayout recommendationPaneBounds


    # a for loop that positions the @thumbnailsRows x @thumbnailsColumns
    # stored in thumbs. The thumbnails are equally sized, and evenly positioned in the recommendationsPane
    # of size @width() x @height()
    #
    # TODO id: FACTOR_OUT_BOUNDS_WITHIN_BOUNDS_WITH_SPECIFIED_RATIO date: 6-May-2023 description:
    # the thumbnails are now painted with a ratio that changes with the size of the recommendationPane
    # rather, what should happen is that the thumbnails should be painted with a fixed ratio. This coould be
    # done by using a new Rectangle function that takes a bound and creates a new bound completely inside it
    # that has a specified ratio. Note that we do that in the VideoPlayerCanvasWdgt, so we can reuse that code.
    internalPadding = 2
    spaceForPrevNextButtons = 20
    widthOfPrevNextButtons = 60
    spaceBetweenButtons = 20
    widthOfEachThumbnail = Math.round((recommendationPaneBounds.width() - (internalPadding * (@thumbnailsColumns - 1))) / @thumbnailsColumns)
    heightOfEachThumbnail = Math.round((recommendationPaneBounds.height() - spaceForPrevNextButtons - (internalPadding * (@thumbnailsRows + 1))) / @thumbnailsRows)

    for i in [0...@thumbnailsRows]
      for j in [0...@thumbnailsColumns]
        thumb = @thumbs[i*@thumbnailsColumns + j]
        thumbBounds = new Rectangle new Point recommendationPaneBounds.left() + j * (widthOfEachThumbnail + internalPadding), recommendationPaneBounds.top() + spaceForPrevNextButtons + internalPadding + i * (heightOfEachThumbnail + internalPadding)
        thumbBounds = thumbBounds.setBoundsWidthAndHeight widthOfEachThumbnail, heightOfEachThumbnail
        thumb.doLayout thumbBounds

    # place the prev and next buttons on the bottom of the recommendationsPane
    prevButtonBounds = new Rectangle new Point recommendationPaneBounds.left() + recommendationPaneBounds.width()/2 - spaceBetweenButtons/2 - widthOfPrevNextButtons, recommendationPaneBounds.top()
    prevButtonBounds = prevButtonBounds.setBoundsWidthAndHeight widthOfPrevNextButtons, spaceForPrevNextButtons
    @prevButton.doLayout prevButtonBounds

    nextButtonBounds = new Rectangle new Point recommendationPaneBounds.left() + recommendationPaneBounds.width()/2 + spaceBetweenButtons/2, recommendationPaneBounds.top()
    nextButtonBounds = nextButtonBounds.setBoundsWidthAndHeight widthOfPrevNextButtons, spaceForPrevNextButtons
    @nextButton.doLayout nextButtonBounds


    world.maybeEnableTrackChanges()
    @fullChanged()
