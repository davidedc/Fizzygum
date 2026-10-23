# The look of a DESKTOP ICON (WidgetHolderWithCaptionWdgt and its family, on the desktop and in a
# folder; docs/archive/redesign/UI-guidelines.md §5.1-5.3): two rounded boxes in my widget's cell.
# Both are paint, never a child widget, and every value in them is my widget's state, its caption's
# box or a Theme role or metric: I hold nothing of my own.
#   the TILE   my widget's tile square (WidgetHolderWithCaptionWdgt._tileRect), rounded at
#              desktopIconTileRadius, filled and bordered with my widget's state look
#              (_fillForMyState / _strokeForMyState: paper inside a 1 px line border at rest); while
#              my widget is the SELECTED icon (WorldWdgt.isSelectedIcon) its border is the selected
#              ring instead (desktopIconTileSelectedStroke, desktopIconTileSelectedStrokeWidth), and
#              its fill is still its state's
#   the PLATE  desktopIconPlateFill (desktopIconPlateSelectedFill while selected), rounded at
#              desktopIconPlateRadius, no border (a plate is not pressable): the box under my
#              widget's caption, which is the caption's own box outset by the plate's padding
#              (_plateRect), read again at every paint so it follows the caption's lines as they
#              change
# My widget's glyph (its icon child) stands inside the tile and its caption on the plate; I paint
# under both.
#
# My SHAPE is those two boxes and nothing else (shapeContainsPoint): a press or a drop in a cell's
# empty corners, or in the gap between the tile and the plate, reaches whatever lies behind the
# icon (a target never extends beyond the widget that owns it). My SILHOUETTE is the same two
# boxes: on the shadow pass I fill both in shadowColor and nothing else, and my widget casts no
# shadow of its children (WidgetHolderWithCaptionWdgt's shadow pass), so the drag lift stays two
# clean shapes.

class DesktopIconAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx) =>
      theme = WorldWdgt.theme
      # my widget answers both boxes in its plane; I paint in its local coordinates
      toLocal = @widget.position().neg()
      tile = @widget._tileRect().translateBy toLocal
      plate = @widget._plateRect()?.translateBy toLocal

      if appliedShadow?
        # the silhouette, both boxes in the one shadow colour, at the alpha (and under the offset)
        # the pass is given. The two never overlap -- the tile-to-plate gap lies between them -- so
        # two fills are their union, darkened once.
        ctx.fillStyle = theme.shadowColor.toString()
        ctx.fillRoundRect tile.left(), tile.top(), tile.width(), tile.height(), theme.desktopIconTileRadius
        if plate?
          ctx.fillRoundRect plate.left(), plate.top(), plate.width(), plate.height(), theme.desktopIconPlateRadius
        return

      # the SELECTED icon (WorldWdgt.isSelectedIcon, read as I paint) takes its selected border and
      # plate; its tile's fill is its state's either way
      selected = !!world?.isSelectedIcon @widget
      ctx.fillStyle = @widget._fillForMyState().toString()
      ctx.fillRoundRect tile.left(), tile.top(), tile.width(), tile.height(), theme.desktopIconTileRadius
      if selected
        # the selected tile's border: a ring desktopIconTileSelectedStrokeWidth wide in
        # desktopIconTileSelectedStroke, wholly inside the tile, its corners the tile's and its inner
        # edge concentric with them -- the one ring painter (HighlightOutlineAppearance.paintRing),
        # because a rounded border wider than a pixel that must hug a rounded fill is a FILL on
        # SWCanvas, never a stroke, which leaves the tile's fill showing outside it at every rounded
        # corner. Its stroke half is on, as for any bordered body: with the crisp 1 px stroke of the
        # tile's outline over it the ring covers every pixel the resting 1 px border covers (a ring
        # one pixel wide leaves a few of them to the fill at each rounded corner), so selecting an
        # icon recolours and thickens its border inward and never moves its outline.
        radius = theme.desktopIconTileRadius
        ctx.save()
        ctx.translate tile.left(), tile.top()
        HighlightOutlineAppearance.paintRing ctx, tile.width(), tile.height(), theme.desktopIconTileSelectedStrokeWidth,
          [radius, radius, radius, radius], theme.desktopIconTileSelectedStroke, true
        ctx.restore()
      else
        # the tile's 1 px border in its state's look, the house crisp spelling: the ring just inside the
        # fill, at its radius
        ctx.lineWidth = 1
        ctx.strokeStyle = @widget._strokeForMyState().toString()
        ctx.strokeRoundRect tile.left() + 0.5, tile.top() + 0.5, tile.width() - 1, tile.height() - 1, theme.desktopIconTileRadius

      if plate?
        ctx.fillStyle = (if selected then theme.desktopIconPlateSelectedFill else theme.desktopIconPlateFill).toString()
        ctx.fillRoundRect plate.left(), plate.top(), plate.width(), plate.height(), theme.desktopIconPlateRadius

  # The tile and the plate, rounded, by pixel centre (BoxyAppearance's one rounded-box test).
  # TOTAL (see Appearance): nothing outside my widget's bounds is mine, so a piece a box too small
  # for the look leaves outside it (where I paint nothing) takes no press either.
  shapeContainsPoint: (aPoint) ->
    return false unless @widget.boundsContainPoint aPoint
    (@_roundedBoxContainsPoint aPoint, @widget._tileRect(), WorldWdgt.theme.desktopIconTileRadius) or
      @plateContainsPoint aPoint

  # Is aPoint (my widget's plane) on the PLATE? My widget asks it of a press that reached it, to
  # tell a press on the plate (a rename) from one on the tile (WidgetHolderWithCaptionWdgt.
  # _pressIsOnMyPlate). No plate, no point on it.
  plateContainsPoint: (aPoint) ->
    plate = @widget._plateRect()
    return false unless plate? and @widget.boundsContainPoint aPoint
    @_roundedBoxContainsPoint aPoint, plate, WorldWdgt.theme.desktopIconPlateRadius

  # aPoint against `box`, both in my widget's plane, the box rounded at `radius` in all four corners.
  _roundedBoxContainsPoint: (aPoint, box, radius) ->
    BoxyAppearance.roundedBoxContainsPixelCentreOf (aPoint.subtract box.topLeft()), box.width(), box.height(), [radius, radius, radius, radius]

  # CONSERVATIVE: only the inside of the tile -- the tile inset by its radius + 1 on every side, as a
  # rounded box answers -- which the tile's opaque fill covers in every state, and only where it lies
  # inside my widget's box (outside it I paint nothing). Never the cell: its corners and the gap
  # paint nothing at all, and the plate is too small to be worth claiming.
  opaqueCoveredRect: ->
    covered = (@widget._tileRect().insetBy WorldWdgt.theme.desktopIconTileRadius + 1).intersect @widget.boundingBox()
    if covered.isEmpty() then undefined else covered
