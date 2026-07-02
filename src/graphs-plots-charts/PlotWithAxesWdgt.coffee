class PlotWithAxesWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  constructor: (@plot) ->
    super
    @plot.drawOnlyPartOfBoundingRect = true
    @appearance = new RectangularAppearance @
    @_buildAndConnectChildren()
    @setColor Color.create 242,242,242

  # build via the NoSettle core, settle ONCE at the end (orphan-settledness: `new X()` returns settled).
  _buildAndConnectChildren: ->
    @_settleLayoutsAfter => @_buildAndConnectChildrenNoSettle()

  _buildAndConnectChildrenNoSettle: ->
    @_addNoSettle @plot

    @vertAxis = new AxisWdgt -5, 5
    @_addNoSettle @vertAxis
    @horizAxis = new AxisWdgt -5, 5
    @_addNoSettle @horizAxis

    @_invalidateLayout()

  colloquialName: ->
    @plot.colloquialName()

  # TODO id: SUPER_SHOULD BE AT TOP_OF_DO_LAYOUT date: 1-May-2023
  # TODO id: SUPER_IN_DO_LAYOUT_IS_A_SMELL date: 1-May-2023
  _reLayout: (newBoundsForThisLayout) ->
    #if !window.recalculatingLayouts then debugger

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # TODO shouldn't be calling this _applyBounds from here,
    # rather use super
    @_applyBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of the inspector are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
    # then everything is OK.
    # Also note that if you attach something else to its
    # boundary in a way that sticks out, that's still
    # going to be painted and moved OK.
    world.disableTrackChanges()

    height = @height()
    width = @width()

    ftft = 35

    @vertAxis._applyExtent (new Point width/10 - 4, height).round()
    @vertAxis._applyMoveTo (@position().add new Point 0, -2).subtract((new Point -width/ftft,height/ftft).round())

    @horizAxis._applyExtent (new Point width, height/10).round()
    adjustmentX = (@vertAxis.left() + @horizAxis.distanceOfAxisOriginFromEdge().x) - ( @vertAxis.right() + @vertAxis.distanceOfAxisOriginFromEdge().x )
    @horizAxis._applyMoveTo (@bottomLeft().subtract new Point adjustmentX, height/10).round().subtract((new Point -width/ftft,height/ftft).round())

    @plot._applyExtent (new Point width - 2 *  @horizAxis.distanceOfAxisOriginFromEdge().x , height - 2 *  @vertAxis.distanceOfAxisOriginFromEdge().y).round()
    @plot._applyMoveTo (@position().add new Point @horizAxis.distanceOfAxisOriginFromEdge().x - adjustmentX + 1, @vertAxis.distanceOfAxisOriginFromEdge().y - 1).round().subtract((new Point -width/ftft,height/ftft).round())

    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @markLayoutAsFixed()

    if Automator? and Automator.state != Automator.IDLE and Automator.alignmentOfWidgetIDsMechanism
      world.alignIDsOfNextWidgetsInSystemTests()