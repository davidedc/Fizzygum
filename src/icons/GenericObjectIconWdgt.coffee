# The icon of a DOCUMENT, or of any filed widget: the family's page (ObjectIconWdgt) with the
# thing's own picture inside it -- for a document, the glyph of the kind that made it (its
# representativeIcon, which is the glyph its Maker wears on the desktop). A filed or aliased widget
# wears it (ShortcutWdgt._defaultInnerIcon), and so does an Examples door, whose catalog entry
# names the Maker its document is made with (AppCatalog's `madeWith`).
class GenericObjectIconWdgt extends GenericCompositeIconWdgt

  objectIcon: undefined

  # (ctor, the settling _buildAndConnectChildren wrapper, the square-sizing surface and the
  # children-staining setColor live in GenericCompositeIconWdgt)

  _buildAndConnectChildrenNoSettle: ->
    @objectIcon = new ObjectIconWdgt
    @_addNoSettle @objectIcon


    if !@icon?
      @icon = new SimpleDropletWdgt "icon"
    # born at the desktop icon's glyph square; what holds me (a desktop icon's holder, or the arrow
    # composite around me) lays me out in its own box
    glyphSize = WorldWdgt.theme.desktopIconGlyphSize
    @_applyExtent new Point glyphSize, glyphSize
    @_addNoSettle @icon

    # update layout
    @_invalidateLayout()

  _reLayout: (newBoundsForThisLayout) ->
    @_reLayoutWithOwnContents newBoundsForThisLayout

  # position my contents against my CURRENT frame (already committed by
  # _reLayoutWithOwnContents, so the @-geometry read below is the frame this layout grants me): the
  # page fills the largest square centred in me, and the picture is the page's own PICTURE square,
  # its PAGE_PICTURE share of that square, centred too -- the one square the page's fold keeps
  # clear of (SizeAwareIconAppearance._pageMetrics)
  _layOutOwnContents: ->

    height = @height()
    width = @width()

    squareDim = Math.min width, height

    centerPoint = @topLeft().add new Point width/2, height/2
    # the top-left corner of the squareDim-sized square centered in the widget
    inscribedSquareTopLeft = centerPoint.subtract new Point squareDim/2, squareDim/2

    page = @objectIcon.appearance
    pictureSide = squareDim * page.PAGE_PICTURE / page.GLYPH_GRID
    @icon._applyBounds ((centerPoint.subtract new Point pictureSide/2, pictureSide/2).round()), (new Point pictureSide, pictureSide).round()

    # rounded: a square centred in a box whose width and height differ by an odd amount starts on a
    # half pixel, and a widget is placed in integer pixels
    @objectIcon._applyBounds inscribedSquareTopLeft.round(), (new Point squareDim, squareDim).round()
