class GenericObjectIconWdgt extends Widget

  @augmentWith ChildrenStainerMixin, @name

  objectIcon: nil

  constructor: (@icon) ->
    super()

    @objectIcon = new ObjectIconWdgt
    @add @objectIcon


    if !@icon?
      @icon = new SimpleDropletWdgt "icon"
    @rawSetExtent new Point 95, 95
    @add @icon

    # update layout
    @invalidateLayout()

  widthWithoutSpacing: ->
    Math.min @width(), @height()

  rawResizeToWithoutSpacing: ->
    @rawSetExtent new Point @widthWithoutSpacing(), @widthWithoutSpacing()
    @invalidateLayout()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    @rawResizeToWithoutSpacing()
    @rawSetExtent new Point newWidth, newWidth
    @invalidateLayout()

  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # TODO shouldn't be calling this rawSetBounds from here,
    # rather use super
    @rawSetBounds newBoundsForThisLayout

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

    height = @height()
    width = @width()

    squareDim = Math.min width, height

     # p0 is the origin, the origin being in the bottom-left corner
    p0 = @topLeft()

    # now the origin is in the middle of the widget
    centerPoint = p0.add new Point width/2, height/2
    p0 = centerPoint
    
    # now the origin is in the top left corner of the
    # square centered in the morph
    p0 = p0.subtract new Point squareDim/2, squareDim/2

    @icon.setExtent (new Point squareDim*50/100, squareDim*50/100).round()
    @icon.fullRawMoveTo (centerPoint.subtract new Point squareDim*25/100, squareDim*25/100).round()


    @objectIcon.setExtent (new Point squareDim, squareDim).round()
    @objectIcon.fullRawMoveTo p0


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()