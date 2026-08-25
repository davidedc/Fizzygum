# Paints the LabelButtonWdgt's flat state-fill: a filled rectangle in the widget's
# normal colour (the menu background), its highlightColor (SILVER) on hover or its
# pressColor (GRAY) while pressed — solid BLACK on the shadow pass. The @label text
# is a child StringWdgt and paints itself; this appearance draws only the fill.

class LabelButtonAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    # unconditional (unlike preliminaryCheckNothingToDraw's live-tree-conditioned twin gates):
    # a hidden/collapsed label button skips even scratch renders, as it always did
    if !@widget.visibleBasedOnIsVisibleProperty() or @widget.isInCollapsedSubtree()
      return undefined

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx, localDamageBox) =>
      if appliedShadow?
        color = Color.BLACK
      else
        color = switch @widget.state
          when @widget.STATE_NORMAL
            @widget.color
          when @widget.STATE_HIGHLIGHTED
            @widget.highlightColor
          when @widget.STATE_PRESSED
            @widget.pressColor

      if color?
        ctx.fillStyle = color.toString()
        @_fillLocalRectSnappedToDevicePixels ctx, localDamageBox

      unless appliedShadow?
        @_paintSeparatorAbove ctx
        @_paintLiftableGrip ctx

  # The hairline along my TOP edge, drawn only while my container has told me the row above me is
  # another row (MenuItemWdgt.showSeparatorAbove — a rows panel DERIVES adjacency at arrange, so no
  # row has to know where it sits). PAINT, never layout: the line takes no height, so two rows stay
  # flush and no dead zone opens between two touch targets.
  #   Inset a pixel at each end, so it reads as a rhythm mark inside the menu's box rather than as
  # a second border crossing it.
  #   Nothing on the SHADOW pass: that pass has already filled my rectangle solid black.
  #   ⚠ The geometry comes from MY WIDGET, never from the scope's `localDamageBox` — see the grip
  # below for the law and the bug that proved it.
  _paintSeparatorAbove: (ctx) ->
    return unless @widget.showsSeparatorAbove?()
    ctx.fillStyle = WorldWdgt.preferencesAndSettings.menuRowSeparatorColor.toString()
    @_fillLocalRectSnappedToDevicePixels ctx, new Rectangle 1, 0, (@widget.width() - 1), 1

  # A short bar down my left edge, drawn only when my container has declared me a payload it
  # hands out (ButtonWdgt.isDetachablePayloadOfMyParent — the SAME declaration the grab reads,
  # so the mark and the behaviour cannot disagree). Today that means a command row in a PINNED
  # menu: pin a menu and its rows visibly become things you can pull off it.
  #   DRAWN, not a character in the label. A glyph would have to exist in the bitmap-font atlas
  # (many do not, and an absent one renders as a black box), and — the heavier reason — the
  # label STRING is an identity: menus are driven, swept and tested by matching it, so decorating
  # it would rename every row it marks.
  #   Nothing on the SHADOW pass: the grip sits inside a rectangle that pass has already filled
  # solid black, so it would be painting black on black.
  #   ⚠ The geometry comes from MY WIDGET, never from the scope's `localDamageBox` — the law is on
  # Appearance._paintInLocalScope. Painting my whole rect is safe because the scope has already
  # clipped to the damage box (`clipsToDamageBox` is true here). Found the hard way: a row that
  # moved up when its neighbour was dragged out came back three pixels short, which the
  # paint-truthfulness gate caught and no screenshot did.
  _paintLiftableGrip: (ctx) ->
    return unless @widget.isDetachablePayloadOfMyParent?()
    # 2px wide, inset 1px, and stopping 3px short top and bottom so consecutive rows read as
    # separate grips rather than one continuous rule down the menu's edge
    return if @widget.height() <= 6
    ctx.fillStyle = Color.DARKGRAY.toString()
    @_fillLocalRectSnappedToDevicePixels ctx, new Rectangle 1, 3, 3, (@widget.height() - 3)
