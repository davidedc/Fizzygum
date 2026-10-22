class TickIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE tick (✓), a chrome state indicator — drawn, never typed (a
  # symbol that stands on its own is an icon). One short 45° arm down into one
  # long 45° arm up, in the 14-unit family and weight of the redesign draft's
  # `close`/`minimise` glyphs (docs/archive/redesign/desktop-canvas.html GLYPH:
  # 2 units wide, round caps and join), as integer device-pixel geometry. Ink
  # only, no halo: chrome glyphs sit on a bar or a row, never on art.
  #
  # The line unit is the RUN n: the pixels each row of a 45° arm holds, which
  # is the weight the eye reads (n/√2 across the arm) — the family's 2-unit
  # weight measured along a row (2·√2/14 of S), rounded. It is drawn as
  # lineWidth n/√2 (never under 1: a sub-pixel stroke paints faint), whose row
  # cross-section is exactly n with half a pixel of margin either way. An odd
  # run straddles a pixel centre and an even one a pixel edge, so the vertex's
  # x sits on whichever lattice n needs (its y stays on a pixel edge); the
  # arms' span is centred on the box to within half a pixel. An odd run's free
  # ENDS sit n/4 px inside a pixel corner along both axes, which is where their
  # round caps' tips then land: cap and arm meet on a line no pixel centre lies
  # on (an even run's ends already do), so no sample point is left to the
  # rounding of the edge two polygons share.

  SHORT_ARM: 3 / 14              # the short arm's run along x (and along y)
  LONG_ARM: 7 / 14               # the long arm's run along x (and along y)
  ROW_RUN: 2 * Math.SQRT2 / 14   # the family weight's row cross-section, per px of S

  # the geometry for an S x S device-px square, relative to its top-left
  # corner: the run n, the stroke width, and the tick as a point list
  _glyphMetrics: (S) ->
    n = Math.max 1, Math.round S * @ROW_RUN
    s = Math.max 1, Math.round S * @SHORT_ARM
    l = Math.round S * @LONG_ARM
    lattice = if n % 2 is 1 then 0 else 0.5
    # the vertex: the arms' x span [vx - s, vx + l] and y span [vy - l, vy]
    # centred on the box
    vx = lattice + Math.round S / 2 + (s - l) / 2 - lattice
    vy = Math.round (S + l) / 2
    # an end at (px, py) whose arm runs on along (dx, dy), its cap tip snapped to a corner
    end = (px, py, dx, dy) ->
      return [px, py] if n % 2 is 0
      [Math.round(px - dx * n / 4) + dx * n / 4, Math.round(py - dy * n / 4) + dy * n / 4]
    { n, lineWidth: (Math.max 1, n / Math.SQRT2), strokes: [[end(vx - s, vy - s, 1, 1), [vx, vy], end(vx + l, vy - l, -1, 1)]] }

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 7
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    m = @_glyphMetrics S

    @_useInk ctx
    ctx.lineWidth = m.lineWidth
    ctx.lineCap = 'round'
    ctx.lineJoin = 'round'
    ctx.beginPath()
    for points in m.strokes
      for [px, py], i in points
        if i is 0 then ctx.moveTo x + px, y + py else ctx.lineTo x + px, y + py
    ctx.stroke()
