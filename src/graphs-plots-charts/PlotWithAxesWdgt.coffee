class PlotWithAxesWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  # the plotted content, taken by the constructor, and the two AxisWdgts built around it
  plot: undefined
  vertAxis: undefined
  horizAxis: undefined

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

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    height = @height()
    width = @width()

    ftft = 35

    # vertAxis / horizAxis are composites (ticks + digit labels placed by THEIR _reLayout).
    # Drive them via _reLayout (not the raw _applyExtent/_applyMoveTo cores) so their children
    # re-lay at the new size instead of staying at construction geometry -- the 2026-07
    # plot-collapse regression (INV-2). Each bounds reproduces the old raw pair's exact
    # origin + extent, so positions/sizes are unchanged -- only the mechanism.
    vertAxisOrigin = (@position().add new Point 0, -2).subtract((new Point -width/ftft,height/ftft).round())
    vertAxisBounds = (new Rectangle vertAxisOrigin).setBoundsWidthAndHeight (new Point width/10 - 4, height).round()
    @vertAxis._reLayout vertAxisBounds

    # horizAxis: apply its extent raw FIRST so adjustmentX below can read the axis's
    # extent-derived distanceOfAxisOriginFromEdge (the original code order relied on this),
    # then drive its final bounds through _reLayout so its children re-lay too.
    @horizAxis._applyExtent (new Point width, height/10).round()
    adjustmentX = (@vertAxis.left() + @horizAxis.distanceOfAxisOriginFromEdge().x) - ( @vertAxis.right() + @vertAxis.distanceOfAxisOriginFromEdge().x )
    horizAxisOrigin = (@bottomLeft().subtract new Point adjustmentX, height/10).round().subtract((new Point -width/ftft,height/ftft).round())
    horizAxisBounds = (new Rectangle horizAxisOrigin).setBoundsWidthAndHeight (new Point width, height/10).round()
    @horizAxis._reLayout horizAxisBounds

    @plot._applyBounds ((@position().add new Point @horizAxis.distanceOfAxisOriginFromEdge().x - adjustmentX + 1, @vertAxis.distanceOfAxisOriginFromEdge().y - 1).round().subtract((new Point -width/ftft,height/ftft).round())), (new Point width - 2 *  @horizAxis.distanceOfAxisOriginFromEdge().x , height - 2 *  @vertAxis.distanceOfAxisOriginFromEdge().y).round()

