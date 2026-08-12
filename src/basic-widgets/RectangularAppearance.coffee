class RectangularAppearance extends Appearance

  isTransparentAt: (aPoint) ->
    if @widget.boundingBoxTight().containsPoint aPoint
      return false
    if @widget.backgroundTransparency? and @widget.backgroundColor?
      if @widget.backgroundTransparency > 0
        if @widget.boundsContainPoint aPoint
          return false
    return true

  # This method only paints this very widget
  # i.e. it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer,
  # which eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return nil

    # Soft hook (a no-op for every plain rectangular widget): DesktopAppearance overrides it to build its
    # wallpaper-tile pattern here, BEFORE the size guard, exactly where its old inlined copy of this method did.
    @_setUpBackgroundPattern? aContext

    # the scope below re-derives the key values; this early bail must also gate the post-scope
    # stroke + pattern-fill epilogues, so it runs here too (pure, cheap)
    return nil unless (@_calculateKeyValuesOrNil aContext, clippingRectangle)?

    @_paintInLocalScope aContext, clippingRectangle, appliedShadow, { clip: false }, (ctx, localArea) =>
      if !@widget.color? then debugger

      # paint the background: the whole damage box (the padding halo beyond the tight box)
      if @widget.backgroundColor?
        color = @widget.backgroundColor
        if appliedShadow?
          color = Color.BLACK
        ctx.fillStyle = color.toString()
        @_fillLocalRectSnappedToDevicePixels ctx, localArea

      # now paint the actual widget, which is a rectangle
      # (potentially inset because of the padding): the damage box ∩ the tight box
      toBePainted = localArea.intersect @widget.boundingBoxTight().translateBy @widget.position().neg()

      color = @widget.color
      if appliedShadow?
        color = Color.BLACK

      if color?
        ctx.fillStyle = color.toString()
        @_fillLocalRectSnappedToDevicePixels ctx, toBePainted

      @drawAdditionalPartsOnBaseShape? appliedShadow, ctx, localArea

    # the stroke re-derives its own key values (it is also a standalone entry — see paintStroke),
    # so it runs after the scope, not inside it
    if !appliedShadow?
      @paintStroke aContext, clippingRectangle

    # Soft hook (a no-op for every plain rectangular widget): DesktopAppearance overrides it to fill its
    # wallpaper pattern over the damage∩tight box — DEVICE-space by declaration (a CanvasPattern anchors
    # to the coordinate space, so the fill cannot ride the logical-pixels scope; see the override) —
    # after the stroke, its old epilogue position.
    if @_paintBackgroundPatternFill?
      area = clippingRectangle.intersect(@widget.bounds).round()
      @_paintBackgroundPatternFill aContext, (area.intersect @widget.boundingBoxTight()).scaleBy(ceilPixelRatio), appliedShadow

  # The rectangular border: ONE DEVICE pixel wide by design, at every dpr — visually a hairline
  # at dpr 2, half the logical thickness of BoxyAppearance's 1-logical-px stroke. Spelled in the
  # local-logical scope as lineWidth 1/ceilPixelRatio with a half-DEVICE-pixel inset
  # 0.5/ceilPixelRatio — dyadic for dpr ∈ {1,2}, so the device geometry AND SWCanvas's hairline
  # classification (which reads the CTM-scaled width) are exactly the old device spelling's.
  # Also a standalone entry (the clipping panels and the world re-stroke their border after the
  # children paint), so it derives its own key values.
  #
  # Some notes / thoughts around the 1-device-pixel choice:
  #  1) for a stroke width of one pixel, the stroke is inset by half a pixel. This is needed because
  #     lines in HTML5 Canvas are centered on the coordinates, so we have to center them in the middle
  #     of the pixel to fill the full width of precisely one pixel.
  #  2) this means that the stroke is drawn inside the widget, so in rectangular widgets that clip at
  #     their bounds, the stroke will NOT be clipped
  #
  #  IF you'll want to make the stroke width arbitrary then...
  #
  #  3) in case the stroke width is even (which might depend on the ceilPixelRatio, see the TODO
  #     below), you don't need to inset by 0.5. TODO.
  #  4) in case the stroke is > 1, the question is where do we draw it? All inside so that it's not
  #     clipped? But then that eats into the widget's area... TODO.
  paintStroke: (aContext, clippingRectangle) ->

    # normal-pass only (the base paint skips it under appliedShadow; the standalone callers gate on
    # !appliedShadow too), so the scope's default alpha reduces to the plain widget alpha
    @_paintInLocalScope aContext, clippingRectangle, nil, { clip: false }, (ctx, localArea) =>
      return unless @widget.strokeColor?

      # clip to the damage ∩ tight box (the stroke must not paint into the padding halo)
      toBePainted = localArea.intersect @widget.boundingBoxTight().translateBy @widget.position().neg()

      ctx.beginPath()
      ctx.rect Math.round(toBePainted.left()),
        Math.round(toBePainted.top()),
        Math.round(toBePainted.width()),
        Math.round(toBePainted.height())
      ctx.clip()

      ctx.strokeStyle = @widget.strokeColor.toString()
      ctx.lineWidth = 1 / ceilPixelRatio # TODO might look better as 1 logical px (the Boxy spelling) — a dpr-2 recapture
      # the widget box snapped to the device grid (Math.round, the legacy spelling — a
      # rotated-container payload's plane position is legitimately fractional), inset by half
      # a DEVICE pixel for the crisp one-device-pixel line. For an integer position this is
      # exactly inset 0.5/ceilPixelRatio at width-1/ceilPixelRatio — the probe-proven form.
      widgetPosition = @widget.position()
      sx = (Math.round(widgetPosition.x * ceilPixelRatio) + 0.5) / ceilPixelRatio - widgetPosition.x
      sy = (Math.round(widgetPosition.y * ceilPixelRatio) + 0.5) / ceilPixelRatio - widgetPosition.y
      sw = (Math.round(@widget.width() * ceilPixelRatio) - 1) / ceilPixelRatio
      sh = (Math.round(@widget.height() * ceilPixelRatio) - 1) / ceilPixelRatio
      ctx.strokeRect sx, sy, sw, sh

