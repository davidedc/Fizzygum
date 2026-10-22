class DoubleArrowIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE double arrow (↔), a chrome control face -- drawn, never typed (a
  # symbol that stands on its own is an icon): a halo's horizontal resizer
  # wears it (HandleAppearance), and the vertical one its transpose
  # (VerticalDoubleArrowIconAppearance). One shaft along the axis, an OPEN head
  # at each end, as integer device-pixel geometry drawn as fills on the control
  # glyph line (SizeAwareIconAppearance._controlGlyphLine: 2 px at its real 24,
  # in the PARITY-FIT square, where it mirrors exactly about both axes). Ink
  # only, no halo: the glyph stands on its handle's plate, whose fill follows
  # the handle's state, so a paper interior would show as a white patch on a
  # hovered or pressed plate.
  #   - the SHAFT: a rect t thick on the square's axis, tip to tip, pulled in
  #     on its outer rows so it never pokes out of a head's 45-degree outline;
  #   - a HEAD: ONE filled polygon, two 45-degree arms whose ROW RUN n is the
  #     odd integer nearest t * sqrt(2) (so an arm reads as heavy as the shaft),
  #     on ChevronRightIconAppearance's lattice (the vertex's x less S/2 whole:
  #     an odd run straddles a pixel centre), meeting in a point at the tip and
  #     cut flat (parallel to the shaft) where its centre line has run ARM of S
  #     along each axis, on a pixel edge. Every slanted edge is a line half a
  #     pixel off the lattice, so no pixel centre ties an edge and the heads
  #     mirror exactly (a STROKED head leaves pixel centres on its join's
  #     boundary at every tip, where SWCanvas breaks the tie differently for a
  #     head and its mirror);
  #   - the tip's pixel column stands TIP_INSET of S in from the square's edge,
  #     mirrored about the centre.

  LINE_SHARE: 2 / 24    # the control glyph line: 2 px at the real side, 24
  TIP_INSET: 1 / 24     # the tips' pixel columns in from the square's edges, per px of S
  ARM: 6 / 24           # a head's run along each axis, per px of S
  MIN_ARM: 2            # px

  # the axis my shaft runs along: "x" across, "y" down (the vertical twin's)
  axis: "x"

  # the odd row run nearest t * sqrt(2): an arm whose rows each hold it reads as heavy as a shaft t
  # thick
  _rowRun: (t) ->
    Math.max 1, 2 * Math.round((t * Math.SQRT2 - 1) / 2) + 1

  # the last pixel column a right-pointing open head inks: its point is at vx + n/2 (on the axis),
  # and a pixel inks whose centre lies left of the point's outline on the rows next to the axis
  _openTip: (vx, n, S) ->
    Math.ceil(vx + n / 2 - (if S % 2 then 0 else 0.5) - 0.5) - 1

  # the geometry of the arrows in a square of S0 device px, the heads' run `arm` per px of S: the
  # line t, the parity-fit side S, the run n and its stroke-equivalent width lw, the axis cy, the
  # last column T the ink may reach, the head's run h, the vertex vx of the right-pointing head (on
  # the run's lattice: the rightmost whose join stays inside T) and the shaft, as its box
  # {x0, x1, y0, y1} along the x axis (whose outermost rows, half a px less than t/2 off the axis,
  # end where an arm's centre line surely inks)
  _arrowMetrics: (S0, arm) ->
    t = @_controlGlyphLine S0, @LINE_SHARE
    S = @_parityFitSide S0, t
    n = @_rowRun t
    lw = Math.max 1, n / Math.SQRT2
    mI = Math.max 1, Math.round(S * @TIP_INSET)
    cy = S / 2
    T = S - 1 - mI
    h = Math.max @MIN_ARM, Math.round(S * arm)
    vx = cy + Math.ceil(S / 2)
    vx -= 1 while @_openTip(vx, n, S) > T
    e = t / 2 - 0.5
    x1 = Math.floor(vx - e - 0.5) + 1
    shaft = { x0: S - x1, x1: x1, y0: cy - t / 2, y1: cy + t / 2 }
    { S0, S, t, n, lw, mI, cy, T, vx, h, shaft }

  # the open head pointing right, as one polygon: the upper arm's outer and inner edges
  # x - y = (vx - cy) +/- n/2, the lower arm's x + y = (vx + cy) +/- n/2, meeting in a point at the
  # tip (vx + n/2) and a notch (vx - n/2), each arm cut flat on the pixel edge where its centre line
  # has run h
  _openHeadRight: (m) ->
    { vx, cy, h, n, S } = m
    O = vx - cy + n / 2
    I = vx - cy - n / 2
    P = vx + cy + n / 2
    Q = vx + cy - n / 2
    yu = cy - h - (if S % 2 then 0.5 else 0)
    yl = cy + h + (if S % 2 then 0.5 else 0)
    [[vx + n / 2, cy], [O + yu, yu], [I + yu, yu], [vx - n / 2, cy], [Q - yl, yl], [P - yl, yl]]

  # every head of the given axes ("x", "y"), as point lists in the square: the right head and its
  # mirror for "x", both transposed for "y" (exact on a square)
  _heads: (m, axes) ->
    S = m.S
    right = @_openHeadRight m
    flipX = (p) -> [S - p[0], p[1]]
    swap = (p) -> [p[1], p[0]]
    out = []
    for ax in axes
      left = right.map flipX
      if ax is "x"
        out.push right, left
      else
        out.push (right.map swap), (left.map swap)
    out

  # the shafts of the given axes, then every head as ONE path filled once
  _paintArrows: (ctx, x, y, m, axes) ->
    @_useInk ctx
    s = m.shaft
    for ax in axes
      if ax is "x"
        ctx.fillRect x + s.x0, y + s.y0, s.x1 - s.x0, s.y1 - s.y0
      else
        ctx.fillRect x + s.y0, y + s.x0, s.y1 - s.y0, s.x1 - s.x0
    ctx.beginPath()
    for points in @_heads m, axes
      @_addPolygonSubpath ctx, x, y, points
      ctx.closePath()
    ctx.fill()

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 8
    x = x0 + Math.floor((wDev - S) / 2)
    y = y0 + Math.floor((hDev - S) / 2)
    @_paintArrows ctx, x, y, (@_arrowMetrics S, @ARM), [@axis]
