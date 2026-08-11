class GenericShortcutIconWdgt extends GenericCompositeIconWdgt

  referenceArrowIcon: nil

  # (ctor, the settling _buildAndConnectChildren wrapper, the square-sizing surface and the
  # children-staining setColor live in GenericCompositeIconWdgt)

  _buildAndConnectChildrenNoSettle: ->
    if !@icon?
      @icon = new SimpleDropletWdgt "icon"
    @_applyExtent new Point 95, 95
    @_addNoSettle @icon

    @referenceArrowIcon = new ShortcutArrowIconWdgt
    @_addNoSettle @referenceArrowIcon

    # update layout
    @_invalidateLayout()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyGrantedBounds newBoundsForThisLayout

    @_repaintAsOneUnit =>

      # the largest square centred in my bounds: the icon fills it, the little
      # reference-arrow overlay sits in its bottom-left corner
      square = @boundingBox().largestCenteredSquare()
      squareDim = square.width()
      p0 = square.topLeft()

      @icon._applyBounds p0.round(), (new Point squareDim, squareDim).round()


      @referenceArrowIcon._applyBounds ((p0.add new Point 0, squareDim*7/10).round()), (new Point squareDim*3/10, squareDim*3/10).round()

    super
    @_markLayoutAsFixed()
