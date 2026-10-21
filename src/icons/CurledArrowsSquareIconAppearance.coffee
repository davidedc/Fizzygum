class CurledArrowsSquareIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE curled-arrows square, a chrome control face -- drawn, never
  # typed: the owner's "four-swirlies square" (four curled arrows round a small
  # square, the classic rotate glyph), which a halo's rotate handle wears
  # (HandleAppearance). Integer device-pixel geometry drawn as fills on the
  # control glyph line (SizeAwareIconAppearance._controlGlyphLine: 2 px at its
  # real 28, in the PARITY-FIT square). Ink only, no halo.
  #   - the SWIRLS: arcs of ONE circle about the centre (radius R to the band's
  #     centre line, t thick), each curling clockwise round one corner of the
  #     square and ending exactly at a MID-SIDE (12, 3, 6, 9 o'clock), where the
  #     clockwise tangent is axis-aligned. Each arc is the exact ring
  #     (strokeCircle, the house ring spelling) clipped to its swirl's wedge;
  #   - a HEAD at each swirl's end: a filled triangle, its base on the arc's
  #     end, its apex hb past it along the tangent (right, down, left, up), its
  #     flanks 45 degrees; hb is a half-integer, so no flank ties a pixel centre;
  #   - the SQUARE: an outline of four t-thick rects, centred.
  #   Fit, in this order: the heads stay inside the margin (R <= c - margin -
  #   hb); a swirl leaves its head's depth, the plate and a px of arc before
  #   the next head (it spans 360/swirls degrees less that), and one shorter
  #   than MIN_SPAN drops (four become two, two one -- a single swirl spans at
  #   most 360 - OPEN degrees); the square keeps the plate off the heads' inner
  #   corners and off the arcs' inner edge.
  #   Detail by rule: a square whose hole would be under MIN_HOLE px is not
  #   drawn, and the line steps up from t - 1 to t only where the heavier line
  #   keeps every swirl and the square the lighter one draws at that size, so
  #   no feature turns back as S grows.
  #   An ODD square's vertical axis is a column of pixel CENTRES, so there a
  #   head's base (and its arc's end) moves half a px right of it (endDelta): a
  #   base edge on the axis would tie every row.

  LINE_SHARE: 2 / 28    # the control glyph line: 2 px at the real side, 28
  SQUARE: 10 / 28       # the square's side, per px of S, before the fit
  SWIRLS: 4             # the swirls drawn where they fit
  OPEN: 80              # degrees of circle a single swirl leaves open at its head
  MIN_SPAN: 30          # degrees: a swirl shorter than this drops
  MIN_HOLE: 2           # px: the least hole the square keeps, or it is not drawn

  # the geometry in a square of S0 device px: at the line t, unless the line one px lighter draws
  # more swirls or keeps the square the heavier one loses
  _curledArrowsMetrics: (S0) ->
    t = @_controlGlyphLine S0, @LINE_SHARE
    m = @_curledArrowsMetricsAt S0, t
    if t > 1
      lighter = @_curledArrowsMetricsAt S0, t - 1
      return lighter if lighter.swirls > m.swirls or (lighter.hasSquare and !m.hasSquare)
    m

  # the geometry at the line t: the parity-fit side S and its centre c, the margin mI and the plate
  # kept between parts (half the line, at least a px), a head's half-base hb (= its depth), the
  # circle's radius R (on the lattice that puts the band's outer rows on a head's axis rows), the
  # heads' base column vx and the arcs' end offset endDelta, the swirls drawn and each one's span in
  # degrees, the square's side q and whether it is drawn
  _curledArrowsMetricsAt: (S0, t) ->
    S = @_parityFitSide S0, t
    c = S / 2
    mI = Math.max 1, Math.round(t / 2)
    clear = mI
    hb = 1.5 * t + 0.5
    reach = hb
    R = Math.floor(c - mI - reach)
    R -= 0.5 if (c - R - t / 2) % 1 isnt 0
    vx = c + (if S % 2 then 0.5 else 0)
    endDelta = Math.asin((vx - c) / R)
    gap = (reach + clear + 1) / R
    spanOf = (k) -> 360 / k - gap * 180 / Math.PI
    swirls = @SWIRLS
    swirls /= 2 while swirls > 1 and spanOf(swirls) < @MIN_SPAN
    span = if swirls is 1 then Math.min(360 - @OPEN, spanOf(1)) else spanOf(swirls)
    q = Math.round(S * @SQUARE)
    q += 1 if (S - q) % 2
    q -= 2 while q > 0 and (q / 2 > R - reach - clear or q / Math.SQRT2 > R - t / 2 - clear)
    hasSquare = q - 2 * t >= @MIN_HOLE
    { S0, S, t, c, R, hb, reach, clear, q, hasSquare, mI, vx, endDelta, swirls, span }

  # the wedge from angle a0 to a1 about the centre, as the current path (a polygon reaching past
  # the band's outer edge), for a swirl's clip
  _wedge: (ctx, x, y, m, a0, a1) ->
    L = (m.R + m.t + 2) / Math.cos(Math.PI / 16)
    steps = Math.max 2, Math.ceil(Math.abs(a1 - a0) / (Math.PI / 8))
    ctx.beginPath()
    ctx.moveTo x + m.c, y + m.c
    for i in [0..steps]
      a = a0 + (a1 - a0) * i / steps
      ctx.lineTo x + m.c + L * Math.cos(a), y + m.c + L * Math.sin(a)
    ctx.closePath()

  # the swirl ending at the mid-side k (0 at 12 o'clock, clockwise): the ring clipped to its wedge
  _swirlArc: (ctx, x, y, m, k) ->
    end = (-90 + 90 * k) * Math.PI / 180 + m.endDelta
    a0 = end - m.span * Math.PI / 180 - m.endDelta
    ctx.lineWidth = m.t
    ctx.save()
    @_wedge ctx, x, y, m, a0, end
    ctx.clip()
    ctx.strokeCircle x + m.c, y + m.c, m.R
    ctx.restore()

  # the head at the mid-side k, pointing clockwise: the 12 o'clock one turned by k quarter turns
  # (exact on the square)
  _swirlHead: (m, k) ->
    { R, hb, vx, c } = m
    vy = c - R
    points = [[vx, vy - hb], [vx + hb, vy], [vx, vy + hb]]
    for i in [0...k]
      points = points.map ([px, py]) -> [m.S - py, px]
    points

  _squareOutline: (ctx, x, y, m) ->
    q = m.q
    t = m.t
    l = x + (m.S - q) / 2
    tp = y + (m.S - q) / 2
    ctx.fillRect l, tp, q, t
    ctx.fillRect l, tp + q - t, q, t
    ctx.fillRect l, tp + t, t, q - 2 * t
    ctx.fillRect l + q - t, tp + t, t, q - 2 * t

  # the swirls' mid-sides: four at 12, 3, 6 and 9, two at 12 and 6, one at 12
  _swirlMidSides: (m) ->
    switch m.swirls
      when 4 then [0, 1, 2, 3]
      when 2 then [0, 2]
      else [0]

  # the square, the arcs, then every head as ONE path filled once
  _paintCurledArrows: (ctx, x, y, m) ->
    @_useInk ctx
    @_squareOutline ctx, x, y, m if m.hasSquare
    midSides = @_swirlMidSides m
    @_swirlArc ctx, x, y, m, k for k in midSides
    ctx.beginPath()
    for k in midSides
      @_addPolygonSubpath ctx, x, y, @_swirlHead(m, k)
      ctx.closePath()
    ctx.fill()

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 12
    x = x0 + Math.floor((wDev - S) / 2)
    y = y0 + Math.floor((hDev - S) / 2)
    @_paintCurledArrows ctx, x, y, @_curledArrowsMetrics(S)
