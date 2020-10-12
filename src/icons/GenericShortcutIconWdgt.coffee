class GenericShortcutIconWdgt extends Widget

  @augmentWith ChildrenStainerMixin, @name

  referenceArrowIcon: nil

  constructor: (@icon) ->
    super()


    if !@icon?
      @icon = new SimpleDropletWdgt "icon"
    @rawSetExtent new Point 95, 95
    @add @icon

    @referenceArrowIcon = new ShortcutArrowIconWdgt
    @add @referenceArrowIcon

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

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # TODO should'be calling this rawSetBounds from here,
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
    p0 = p0.add new Point width/2, height/2
    
    # now the origin is in the top left corner of the
    # square centered in the morph
    p0 = p0.subtract new Point squareDim/2, squareDim/2

    @icon.setExtent (new Point squareDim, squareDim).round()
    @icon.fullRawMoveTo p0.round()


    @referenceArrowIcon.setExtent (new Point squareDim*3/10, squareDim*3/10).round()
    @referenceArrowIcon.fullRawMoveTo (p0.add new Point 0, squareDim*7/10).round()


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()