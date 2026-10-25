# Paints a LabelButtonWdgt's box and its STATE: its rest fill (@color) and, while it is hovered or
# pressed, its state fill (highlightColor / pressColor). A widget carrying no plateRadius paints
# its state fill over its whole box, square, in place of the rest fill; one carrying a plateRadius
# (every menu, list and member row) keeps its rest fill over its whole box and paints the state
# fill on it as a rounded PLATE of that radius, so outside the plate's corners the rest fill shows
# (a menu row) -- and below the plate too, when the widget's plateHeight stops it short of its
# bottom (a list or a member row). At rest, a widget may still ask for a plate of its own
# (_restPlateFill: a plain list row's hover, its highlighted look being its selection).
#   The state I paint is the one my widget SHOWS: its own @state, unless it answers _shownState
# (a soft hook) -- a list row does, since its highlighted look is its list's selection, a fact of
# the list's model read as I paint and never stored on the row (MenuItemWdgt._shownState).
# Solid BLACK over the whole box on the shadow pass, plate or no plate: the box is the silhouette.
# The @label text is a child StringWdgt and paints itself; this appearance draws the fills and
# the row's grip below.

class LabelButtonAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    # unconditional (unlike preliminaryCheckNothingToDraw's live-tree-conditioned twin gates):
    # a hidden/collapsed label button skips even scratch renders, as it always did
    if !@widget.visibleBasedOnIsVisibleProperty() or @widget.isInCollapsedSubtree()
      return undefined

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, (ctx, localDamageBox) =>
      if appliedShadow?
        ctx.fillStyle = WorldWdgt.theme.shadowColor.toString()
        @_fillLocalRectSnappedToDevicePixels ctx, localDamageBox
        return

      shownState = @widget._shownState?() ? @widget.state
      stateColor = switch shownState
        when @widget.STATE_NORMAL
          @widget.color
        when @widget.STATE_HIGHLIGHTED
          @widget.highlightColor
        when @widget.STATE_PRESSED
          @widget.pressColor

      if @widget.plateRadius?
        @_paintRestFillAndStatePlate ctx, localDamageBox, shownState, stateColor
      else if stateColor?
        ctx.fillStyle = stateColor.toString()
        @_fillLocalRectSnappedToDevicePixels ctx, localDamageBox

      @_paintLiftableGrip ctx

  # The PLATE look: my rest fill over the part of my box being repainted, then a plate across my
  # WHOLE width, from my top down my widget's plateHeight (absent: my whole height), rounded at its
  # plateRadius (a uniform radius goes to fillRoundRect as the scalar, its fast path): out of my rest
  # state, in that state's fill; at rest, in the fill my widget asks for at rest (_restPlateFill: a
  # plain list row's hover plate while the pointer is over it), if any. A pure function of the state
  # my widget shows and its box: no timer, no fade.
  #   ⚠ The plate's geometry comes from MY WIDGET, never from the scope's `localDamageBox` — the law
  # is on Appearance._paintInLocalScope; the scope has already clipped to the damage box
  # (`clipsToDamageBox` is true here), so painting the whole plate is safe.
  _paintRestFillAndStatePlate: (ctx, localDamageBox, shownState, stateColor) ->
    if @widget.color?
      ctx.fillStyle = @widget.color.toString()
      @_fillLocalRectSnappedToDevicePixels ctx, localDamageBox
    plateColor = if shownState is @widget.STATE_NORMAL then @widget._restPlateFill?() else stateColor
    return unless plateColor?
    ctx.fillStyle = plateColor.toString()
    ctx.fillRoundRect 0, 0, @widget.width(), (@widget.plateHeight ? @widget.height()), @widget.plateRadius

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
    ctx.fillStyle = WorldWdgt.theme.menuRowGrip.toString()
    @_fillLocalRectSnappedToDevicePixels ctx, new Rectangle 1, 3, 3, (@widget.height() - 3)
