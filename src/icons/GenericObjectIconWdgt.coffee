class GenericObjectIconWdgt extends GenericCompositeIconWdgt

  objectIcon: undefined

  # (ctor, the settling _buildAndConnectChildren wrapper, the square-sizing surface and the
  # children-staining setColor live in GenericCompositeIconWdgt)

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
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me)
  _layOutOwnContents: ->

    height = @height()
    width = @width()

    squareDim = Math.min width, height

    centerPoint = @topLeft().add new Point width/2, height/2
    # the top-left corner of the squareDim-sized square centered in the widget
    inscribedSquareTopLeft = centerPoint.subtract new Point squareDim/2, squareDim/2

    @icon._applyBounds ((centerPoint.subtract new Point squareDim*25/100, squareDim*25/100).round()), (new Point squareDim*50/100, squareDim*50/100).round()


    @objectIcon._applyBounds inscribedSquareTopLeft, (new Point squareDim, squareDim).round()
