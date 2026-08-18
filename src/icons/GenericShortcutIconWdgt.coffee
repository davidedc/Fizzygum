class GenericShortcutIconWdgt extends GenericCompositeIconWdgt

  referenceArrowIcon: undefined

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
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    # the largest square centred in my bounds: the icon fills it, the little
    # reference-arrow overlay sits in its bottom-left corner
    square = @boundingBox().largestCenteredSquare()
    squareDim = square.width()
    squareTopLeft = square.topLeft()

    @icon._applyBounds squareTopLeft.round(), (new Point squareDim, squareDim).round()


    @referenceArrowIcon._applyBounds ((squareTopLeft.add new Point 0, squareDim*7/10).round()), (new Point squareDim*3/10, squareDim*3/10).round()
