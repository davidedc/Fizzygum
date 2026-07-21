class SizeAwareIconAppearance extends IconAppearance

  # Base for SIZE-AWARE icons (extracted 2026-07-21 from TypewriterIconAppearance,
  # the reference implementation, on the second conversion — see
  # docs/plans/pixel-icons-plan.md §5b).
  #
  # A size-aware icon never draws in a fixed design space: it reads its ACTUAL
  # size in device pixels and computes integer-pixel geometry from that budget.
  # THE POINT: the non-AA backend (SWCanvas) renders it cleanly at every size —
  # no ragged or uneven strokes, no dropouts — because the icon is smart about
  # how it uses its space and aligns integer-width strokes to the grid per
  # size. The same discipline makes the HTML5-canvas render neater too (AA
  # itself was never a defect). Useful side effect, kept as a verification gate
  # rather than being a goal: both backends render these icons byte-identically
  # at every size and dpr.
  #
  # Subclasses implement _paintSizeAware (all drawing) and typically follow the
  # reference implementation's shape: a metrics method computing every shared
  # measurement (line units, inner square, named-fraction layout) and one named
  # painter per visual region.

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    keyValues = @_calculateKeyValuesOrNil aContext, clippingRectangle
    return nil unless keyValues?
    [area,sl,st,al,at,w,h] = keyValues

    aContext.save()

    # clip out the dirty rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @widget.alpha

    # deliberately NO useLogicalPixelsUntilRestore(): subclasses draw in
    # integer DEVICE pixels, anchored to the widget's own origin — never to the
    # dirty rect's corner (al/at), which shifts under partial repaints. The
    # widget's bounds are integer logical px (integer-placement policy), so
    # these products are exact integers.
    @_paintSizeAware aContext,
      @widget.left() * ceilPixelRatio,
      @widget.top() * ceilPixelRatio,
      @widget.width() * ceilPixelRatio,
      @widget.height() * ceilPixelRatio

    aContext.restore()
    return nil

  # subclass responsibility: all-integer device-pixel drawing into the
  # (x0, y0, wDev, hDev) box
  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->

  # ---- pixel-drawing vocabulary --------------------------------------------

  # four t-thick filled edges — the crisp replacement for a stroked rect
  _pxBorder: (ctx, x, y, w, h, t) ->
    ctx.fillRect x, y, w, t
    ctx.fillRect x, y + h - t, w, t
    ctx.fillRect x, y + t, t, h - 2 * t
    ctx.fillRect x + w - t, y + t, t, h - 2 * t

  # integer row spans [x0, width] of a pixel disc of diameter k (Math.sqrt is
  # IEEE-exact, so these are engine-independent)
  _pxDiscRows: (k) ->
    c = k / 2
    for j in [0...k]
      ry = j + 0.5 - c
      s = Math.sqrt Math.max 0, c * c - ry * ry
      x0 = Math.round c - s
      [x0, Math.round(c + s) - x0]

  _pxDisc: (ctx, x, y, k, color) ->
    ctx.fillStyle = color
    for [r0, rw], j in @_pxDiscRows k
      ctx.fillRect x + r0, y + j, rw, 1 if rw > 0

  # a stadium/capsule: straight middle, disc-row caps
  _pxStadium: (ctx, x, y, w, k, color) ->
    ctx.fillStyle = color
    for [r0, rw], j in @_pxDiscRows k
      rowW = w - k + rw
      ctx.fillRect x + r0, y + j, rowW, 1 if rowW > 0

  # a filled round-rect with quarter-circle corners of radius r, as integer row
  # runs: the top/bottom r rows get per-row insets from the circle equation,
  # the middle is one solid rect
  _pxRoundRect: (ctx, x, y, w, h, r, color) ->
    ctx.fillStyle = color
    r = Math.max 0, Math.min r, Math.floor(Math.min(w, h) / 2)
    if r is 0
      ctx.fillRect x, y, w, h
      return
    for j in [0...r]
      ry = r - j - 0.5
      inset = r - Math.round Math.sqrt Math.max 0, r * r - ry * ry
      rowW = w - 2 * inset
      continue if rowW < 1
      ctx.fillRect x + inset, y + j, rowW, 1
      ctx.fillRect x + inset, y + h - 1 - j, rowW, 1
    ctx.fillRect x, y + r, w, h - 2 * r
