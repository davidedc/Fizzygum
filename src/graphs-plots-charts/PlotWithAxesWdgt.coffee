class PlotWithAxesWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  constructor: (@plot) ->
    super
    @plot.drawOnlyPartOfBoundingRect = true
    @appearance = new RectangularAppearance @

    @add @plot

    @vertAxis = new AxisWdgt -5, 5
    @add @vertAxis
    @horizAxis = new AxisWdgt -5, 5
    @add @horizAxis

    @setColor Color.create 242,242,242

    @invalidateLayout()

  colloquialName: ->
    @plot.colloquialName()

  rawSetExtent: (aPoint) ->
    super
    @invalidateLayout()

  doLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts
    #  debugger

    if !newBoundsForThisLayout?
      if @desiredExtent?
        newBoundsForThisLayout = @desiredExtent
        @desiredExtent = nil
      else
        newBoundsForThisLayout = @extent()

      if @desiredPosition?
        newBoundsForThisLayout = (new Rectangle @desiredPosition).setBoundsWidthAndHeight newBoundsForThisLayout
        @desiredPosition = nil
      else
        newBoundsForThisLayout = (new Rectangle @position()).setBoundsWidthAndHeight newBoundsForThisLayout

    if @isCollapsed()
      @layoutIsValid = true
      @notifyAllChildrenRecursivelyThatParentHasReLayouted()
      return

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
    trackChanges.push false

    height = @height()
    width = @width()

    ftft = 35

    @vertAxis.rawSetExtent (new Point width/10 - 4, height).round()
    @vertAxis.fullRawMoveTo (@position().add new Point 0, -2).subtract((new Point -width/ftft,height/ftft).round())

    @horizAxis.rawSetExtent (new Point width, height/10).round()
    adjustmentX = (@vertAxis.left() + @horizAxis.distanceOfAxisOriginFromEdge().x) - ( @vertAxis.right() + @vertAxis.distanceOfAxisOriginFromEdge().x )
    @horizAxis.fullRawMoveTo (@bottomLeft().subtract new Point adjustmentX, height/10).round().subtract((new Point -width/ftft,height/ftft).round())

    @plot.rawSetExtent (new Point width - 2 *  @horizAxis.distanceOfAxisOriginFromEdge().x , height - 2 *  @vertAxis.distanceOfAxisOriginFromEdge().y).round()
    @plot.fullRawMoveTo (@position().add new Point @horizAxis.distanceOfAxisOriginFromEdge().x - adjustmentX + 1, @vertAxis.distanceOfAxisOriginFromEdge().y - 1).round().subtract((new Point -width/ftft,height/ftft).round())

    trackChanges.pop()
    @fullChanged()

    @layoutIsValid = true
    @notifyAllChildrenRecursivelyThatParentHasReLayouted()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfMorphIDsMechanism
      world.alignIDsOfNextMorphsInSystemTests()