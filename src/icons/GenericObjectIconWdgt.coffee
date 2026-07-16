class GenericObjectIconWdgt extends GenericCompositeIconWdgt

  @augmentWith ChildrenStainerMixin, @name

  objectIcon: nil

  # (ctor, the settling _buildAndConnectChildren wrapper, the square-sizing surface and the
  # INV-2 self-protecting _applyExtent live in GenericCompositeIconWdgt)

  _buildAndConnectChildrenNoSettle: ->
    @objectIcon = new ObjectIconWdgt
    @_addNoSettle @objectIcon


    if !@icon?
      @icon = new SimpleDropletWdgt "icon"
    @_applyExtent new Point 95, 95
    @_addNoSettle @icon

    # update layout
    @_invalidateLayout()

  _reLayout: (newBoundsForThisLayout) ->

    newBoundsForThisLayout = @__calculateNewBoundsWhenDoingLayout newBoundsForThisLayout

    if @_handleCollapsedStateShouldWeReturn() then return

    # Apply my OWN bounds FIRST (do NOT defer this to the trailing super): children below are
    # positioned from my frame, so applying via super-at-the-bottom would lag them one cadence
    # (the InspectorWdgt 2026-06-16 bug; enforced by buildSystem/check-relayout-bounds-first.js).
    @_applyBounds newBoundsForThisLayout

    # here we are disabling all the broken
    # rectangles. The reason is that all the
    # subwidgets of this composite are within the
    # bounds of the parent Widget. This means that
    # if only the parent widget breaks its rectangle
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
    # square centered in the widget
    p0 = p0.subtract new Point squareDim/2, squareDim/2

    @icon._applyExtent (new Point squareDim*50/100, squareDim*50/100).round()
    @icon._applyMoveTo (centerPoint.subtract new Point squareDim*25/100, squareDim*25/100).round()


    @objectIcon._applyExtent (new Point squareDim, squareDim).round()
    @objectIcon._applyMoveTo p0


    world.maybeEnableTrackChanges()
    @fullChanged()

    super
    @_markLayoutAsFixed()
