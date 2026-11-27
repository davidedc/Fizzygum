# The look of a SPLIT'S PIECE of layout chrome: a division stack's divider
# (StackElementsSizeAdjustingWdgt) and, where one joins it, the tab that is an inspector's split button
# (SplitGripWdgt, at the left end of the next inspector's header: right of a column divider, or turned a
# quarter and hanging under the divider above an inspector browser's body), painted as ONE flat grey
# piece:
#   the PLATE  one flat tone over my widget's whole box, with no outline: splitPieceFill at rest,
#              splitPieceHoverFill while the pointer rests on either part of the piece,
#              splitPiecePressFill while either part is pressed or dragged (LayoutChromeWdgt's
#              _pieceShowsPress / _pieceShowsHover: a hover or a press on one part lights both). Its
#              corners are my widget's (_plateCornerRadii): a divider's square, a tab's free ones
#              rounded at layoutChromePlateRadius (Appearance._plateRadius clamps each to my widget's
#              box), so the two parts meet with no line and no step between them.
#   the MARK   my widget's grip dots, the same in every state: the house's (Appearance._paintGripDots)
#              in layoutAdjusterGripMark, in the field my widget names and at most as many as it says
#              (_gripDotFieldOnMyPlate): a divider's along its length, a tab's across the whole piece. A
#              field reaching past my widget's box is cut at it.
# Every value is my widget's state, its box, the part joined to it or a Theme role or metric, read as I
# paint, so a saved or copied piece wears the look of the world it is shown in.
#
# My SHAPE is my widget's whole box (the base answer): a tab's rounded corners are the tab's too, so a
# press at its very corner still lands on it. My SILHOUETTE is the plate, on every shadow pass (my
# widget's own, as a free-floating piece, or an ancestor's): the plate is opaque, so its black version
# is the complete silhouette -- the dots inside it add no coverage and are skipped.

class SplitPieceAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      theme = WorldWdgt.theme
      radii = @widget._plateCornerRadii()

      if appliedShadow?
        @_paintPlate ctx, radii, theme.shadowColor
        return

      @_paintPlate ctx, radii, @_fillForMyPiecesState()
      [field, mostDots] = @widget._gripDotFieldOnMyPlate()
      @_paintGripDots ctx, field, theme.layoutAdjusterGripMark, mostDots

    return undefined

  # the tone of the pointer state my widget's piece shows now: pressed, else hovered, else at rest
  _fillForMyPiecesState: ->
    theme = WorldWdgt.theme
    if @widget._pieceShowsPress()
      theme.splitPiecePressFill
    else if @widget._pieceShowsHover()
      theme.splitPieceHoverFill
    else
      theme.splitPieceFill
