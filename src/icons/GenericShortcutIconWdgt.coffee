class GenericShortcutIconWdgt extends GenericCompositeIconWdgt

  referenceArrowIcon: undefined

  # (ctor, the settling _buildAndConnectChildren wrapper, the square-sizing surface and the
  # children-staining setColor live in GenericCompositeIconWdgt)

  _buildAndConnectChildrenNoSettle: ->
    if !@icon?
      @icon = new SimpleDropletWdgt "icon"
    # born at the desktop icon's glyph square; the holder that takes me lays me out in that square
    glyphSize = WorldWdgt.theme.desktopIconGlyphSize
    @_applyExtent new Point glyphSize, glyphSize
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

    # the badge's side is its own HOST_SHARE of my square: the one share it is laid out at and
    # reads its host's line unit back from (ShortcutArrowIconAppearance)
    badgeSide = squareDim * @referenceArrowIcon.appearance.HOST_SHARE
    @referenceArrowIcon._applyBounds ((squareTopLeft.add new Point 0, squareDim - badgeSide).round()), (new Point badgeSide, badgeSide).round()
