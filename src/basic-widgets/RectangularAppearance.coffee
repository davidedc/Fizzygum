class RectangularAppearance extends Appearance

  isTransparentAt: (aPoint) ->
    if @widget.boundingBoxTight().containsPoint aPoint
      return false
    # backgroundTransparency is an INVARIANT (Widget defaults it to 1 and no constructor
    # leaves it undefined) — so only the "is it actually opaque enough to catch a click" test
    # remains; the old `backgroundTransparency?` existence check was vacuous.
    if @widget.backgroundColor? and @widget.backgroundTransparency > 0
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
      return undefined

    # Soft hook (a no-op for every plain rectangular widget): DesktopAppearance overrides it to build its
    # wallpaper-tile pattern here, BEFORE the size guard, exactly where its old inlined copy of this method did.
    @_setUpBackgroundPattern? aContext

    # the scope below re-derives the key values; this early bail must also gate the post-scope
    # stroke + pattern-fill epilogues, so it runs here too (pure, cheap)
    return undefined unless (@_calculateKeyValuesOrNil aContext, clippingRectangle)?

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

  # The rectangular border: ONE LOGICAL pixel wide at every dpr (2 device px at dpr 2) — the
  # same thickness and the same raw local-logical spelling as BoxyAppearance's strokeOutline,
  # so every rectangular-family border shares one look through the scope's matrix.
  # Also a standalone entry (the clipping panels and the world re-stroke their border after the
  # children paint), so it derives its own key values.
  #
  # Some notes / thoughts around the stroke:
  #  1) for a stroke width of one pixel, the stroke is inset by half a pixel. This is needed because
  #     lines in HTML5 Canvas are centered on the coordinates, so we have to center them in the middle
  #     of the pixel to fill the full width of precisely one pixel.
  #  2) this means that the stroke is drawn inside the widget, so in rectangular widgets that clip at
  #     their bounds, the stroke will NOT be clipped
  #
  #  IF you'll want to make the stroke width arbitrary then...
  #
  #  3) in case the stroke width is even, you don't need to inset by 0.5. TODO.
  #  4) in case the stroke is > 1, the question is where do we draw it? All inside so that it's not
  #     clipped? But then that eats into the widget's area... TODO.
  paintStroke: (aContext, clippingRectangle) ->

    # normal-pass only (the base paint skips it under appliedShadow; the standalone callers gate on
    # !appliedShadow too), so the scope's default alpha reduces to the plain widget alpha
    @_paintInLocalScope aContext, clippingRectangle, undefined, { clip: false }, (ctx, localArea) =>
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
      ctx.lineWidth = 1
      # raw local coords, the Boxy spelling — deliberately NOT snapped to the device grid: a
      # widget's own plane position is integer by the placement law, so snapping is provably
      # the identity here, and the one genuinely fractional offset (a compensating wrapper's
      # figure origin, plus its rotation pair) lives in the CTM, which a body never reads.
      # Under rotated composites the stroke renders continuously — SWCanvas samples the
      # island warp bilinear (docs/architecture/transforms.md §8, sampling contract).
      ctx.strokeRect 0.5, 0.5, @widget.width() - 1, @widget.height() - 1

