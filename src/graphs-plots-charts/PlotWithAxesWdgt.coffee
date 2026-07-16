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

  # Self-protecting resize (INV-2): I am a composite (plot + 2 axes placed by my _reLayout),
  # but window-content / fractional-rescale paths size me with the raw _applyExtent core
  # (KeepsRatioWhenInVerticalStackMixin._setWidthSizeHeightAccordingly), which alone would
  # leave my children at construction geometry -- the 2026-07 plot-collapse regression.
  # Declaring the capability makes the base Widget._applyExtent re-lay my children on an
  # immediate resize (the unified mechanism, 2026-07-16 -- replaces this class's hand-copied
  # _applyExtent override; the inline axes? guard became _compositeChildrenBuilt below).
  _placesChildrenInLayout: ->
    true

  # both axes exist -- skips the base's re-layout during a construction-time _applyExtent
  # (before the axes are built); the trailing settle lays the children out then.
  _compositeChildrenBuilt: ->
    @vertAxis? and @horizAxis?

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
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

    @plot._applyExtent (new Point width - 2 *  @horizAxis.distanceOfAxisOriginFromEdge().x , height - 2 *  @vertAxis.distanceOfAxisOriginFromEdge().y).round()
    @plot._applyMoveTo (@position().add new Point @horizAxis.distanceOfAxisOriginFromEdge().x - adjustmentX + 1, @vertAxis.distanceOfAxisOriginFromEdge().y - 1).round().subtract((new Point -width/ftft,height/ftft).round())

    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()

