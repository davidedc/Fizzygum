class FourWayArrowIconAppearance extends DoubleArrowIconAppearance

  # SIZE-AWARE four-way arrow (✥), a chrome control face -- drawn, never typed:
  # a halo's move handle wears it (HandleAppearance). The two double arrows of
  # DoubleArrowIconAppearance crossing, on its line, lattice and open heads
  # (both its axes, so its own `axis` is never read). Ink only, no halo.
  #   Two neighbouring heads' arms lie on ONE 45-degree line (the diamond
  #   |x - c| + |y - c| = vx - c), so a head is drawn shorter than a double
  #   arrow's -- MOVE_ARM of S -- and shortened further, a px at a time, until
  #   the facing arm ends keep MIN_HEAD_GAP px of plate between their inks.
  #   Detail by rule: where not even MIN_ARM-px heads keep the gap, the heads
  #   JOIN into the DIAMOND -- the four tips joined, one filled ring over the
  #   two shafts -- rather than touch.

  MOVE_ARM: 4 / 24      # a head's run along each axis, per px of S, before the gap shortens it
  MIN_HEAD_GAP: 1       # px of plate between two neighbouring heads, along their common line

  # the plate left between two neighbouring heads' facing arm ends, in px along their common
  # 45-degree line
  _headGap: (m) ->
    Math.SQRT2 * (m.vx - m.cy - 2 * m.h) - m.lw

  # the double arrow's metrics at MOVE_ARM, the heads shortened until they keep the gap; `diamond`
  # where even MIN_ARM-px heads do not
  _fourWayMetrics: (S) ->
    m = @_arrowMetrics S, @MOVE_ARM
    m.h -= 1 while m.h > @MIN_ARM and @_headGap(m) < @MIN_HEAD_GAP
    m.diamond = @_headGap(m) < @MIN_HEAD_GAP
    m

  # the DIAMOND: the two shafts, then the four tips joined as ONE filled ring -- the outer diamond
  # clockwise and the inner one counter-clockwise, so the nonzero rule leaves the hole -- its edges
  # |x - c| + |y - c| = (vx - c) +/- n/2, half a px off the lattice
  _paintDiamond: (ctx, x, y, m) ->
    s = m.shaft
    c = m.S / 2
    V = m.vx - c
    @_useInk ctx
    ctx.fillRect x + s.x0, y + s.y0, s.x1 - s.x0, s.y1 - s.y0
    ctx.fillRect x + s.y0, y + s.x0, s.y1 - s.y0, s.x1 - s.x0
    ring = (r) -> [[c + r, c], [c, c + r], [c - r, c], [c, c - r]]
    ctx.beginPath()
    @_addPolygonSubpath ctx, x, y, ring(V + m.n / 2)
    ctx.closePath()
    @_addPolygonSubpath ctx, x, y, ring(V - m.n / 2).reverse()
    ctx.closePath()
    ctx.fill()

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 10
    x = x0 + Math.floor((wDev - S) / 2)
    y = y0 + Math.floor((hDev - S) / 2)
    m = @_fourWayMetrics S
    if m.diamond
      @_paintDiamond ctx, x, y, m
    else
      @_paintArrows ctx, x, y, m, ["x", "y"]
