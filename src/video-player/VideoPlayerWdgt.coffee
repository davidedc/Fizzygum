class VideoPlayerWdgt extends Widget

  videoPlayerCanvas: nil
  videoControlsPane: nil

  externalPadding: 0
  internalPadding: 5
  padding: nil

  colloquialName: ->
    "Video player"

  constructor: ->
    super new Point 300, 300
    @buildAndConnectChildren()
  

  buildAndConnectChildren: ->
    # remove all submorhs i.e. panes and buttons
    # THE ONES THAT ARE STILL
    # submorphs of the inspector. If they
    # have been peeled away, they still live
    @fullDestroyChildren()

    @videoPlayerCanvas = new VideoPlayerCanvasWdgt
    @add @videoPlayerCanvas

    # videoControlsPane is just a black rectangle for now
    @videoControlsPane = new VideoControlsPaneWdgt @videoPlayerCanvas
    @add @videoControlsPane

    # update layout
    @invalidateLayout()

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

    @videoPlayerCanvas.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding + 15 + @internalPadding
    @videoPlayerCanvas.rawSetExtent new Point @width() - 2 * @externalPadding, @height()/2 - 2 * @externalPadding - 15 - @internalPadding

    # put the videoControlsPane in the bottom part
    @videoControlsPane.fullRawMoveTo new Point @left() + @externalPadding, @top() + @externalPadding + 15 + @internalPadding + @height()/2
    @videoControlsPane.rawSetExtent new Point @width() - 2 * @externalPadding, @height()/2 - 2 * @externalPadding - 15 - @internalPadding
    @videoControlsPane.doLayout @videoControlsPane.boundingBox()


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()
