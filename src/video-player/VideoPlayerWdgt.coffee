class VideoPlayerWdgt extends Widget

  videoPlayerCanvas: undefined
  videoControlsPane: undefined

  externalPadding: 0
  internalPadding: 5
  padding: undefined


  constructor: ->
    super new Point 300, 300
    @_buildAndConnectChildren()
    world.keyboardEventsReceivers.add @

  processKeyDown: (key, code, shiftKey, ctrlKey, altKey, metaKey) ->

    # see:
    #   https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key/Key_Values
    #   https://w3c.github.io/uievents/tools/key-event-viewer.html

    if key == " " and @isInForeground()
        @togglePlayPause()

  play: ->
    # play the video element in @videoPlayerCanvas.video
    @videoPlayerCanvas.play()

  pause: ->
    # pause the video element in @videoPlayerCanvas.video
    @videoPlayerCanvas.pause()

  togglePlayPause: ->
    @videoPlayerCanvas.togglePlayPause()

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    # Remove all children that are still ours (fullDestroyChildren walks @children only --
    # widgets already peeled away elsewhere are untouched and still live).
    @fullDestroyChildren()

    @videoPlayerCanvas = new VideoPlayerCanvasWdgt
    @_addNoSettle @videoPlayerCanvas

    # videoControlsPane is just a black rectangle for now
    @videoControlsPane = new VideoControlsPaneWdgt @videoPlayerCanvas
    @_addNoSettle @videoControlsPane

    # update layout
    @_invalidateLayout()

  loadVideo: (videoPath) ->
    @videoPlayerCanvas.loadVideo videoPath

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


    @_repaintAsOneUnit =>

      # like the above but use the bounding box
      # to do the layout
      videoPlayerCanvasBounds = new Rectangle new Point newBoundsForThisLayout.left() + @externalPadding, newBoundsForThisLayout.top() + @externalPadding
      videoPlayerCanvasBounds = videoPlayerCanvasBounds.setBoundsWidthAndHeight newBoundsForThisLayout.width() - 2 * @externalPadding, newBoundsForThisLayout.height() - 24  - @internalPadding - 14
      @videoPlayerCanvas._reLayout videoPlayerCanvasBounds

      # put the videoControlsPane in the bottom part
      videoControlsBounds = new Rectangle new Point newBoundsForThisLayout.left() + @externalPadding, videoPlayerCanvasBounds.bottom() + 2
      videoControlsBounds = videoControlsBounds.setBoundsWidthAndHeight newBoundsForThisLayout.width() - 2 * @externalPadding, 22 + 7 + 14
      @videoControlsPane._reLayout videoControlsBounds
