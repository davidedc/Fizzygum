class CrossIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE cross (×), a chrome control face — drawn, never typed (a
  # symbol that stands on its own is an icon). The redesign draft's `close`
  # glyph (docs/plans/redesign/desktop-canvas.html GLYPH: 14-unit viewBox,
  # M2 2 L12 12 + M12 2 L2 12, 2 units wide, round caps) as integer
  # device-pixel geometry. Ink only, no halo: chrome glyphs sit on a bar or a
  # row, never on art.
  #
  # The line unit is the RUN n: a 45° stroke on the pixel grid is a staircase
  # whose every row holds the same number of pixels, and that run is the
  # weight the eye reads (n/√2 across the stroke). n is the draft's 2-unit
  # weight measured along a row (2·√2/14 of S) rounded to the nearest ODD
  # integer: both diagonals pass through the box centre, so each must straddle
  # a pixel centre symmetrically for the cross to mirror about both axes and
  # both diagonals. The stroke is lineWidth n/√2 (never under 1: a sub-pixel
  # stroke paints faint), whose row cross-section is exactly n with half a
  # pixel of margin either way. Each end sits n/4 px (along both axes) inside
  # a pixel CORNER, which is exactly where its round cap's tip then lands: the
  # cap and the stroke body meet on a line no pixel centre lies on, and every
  # cap vertex is off the pixel-centre grid, so no sample point is left to the
  # rounding of the edge between two polygons. The ends are inset by the
  # draft's 2/14, but never so little that a cap's widest point (n·(√2 − 1)/4
  # px past its tip, along an axis) reaches the box's outer pixel ring.

  ARM_END: 2 / 14                # the stroke ends' inset from the box edge
  ROW_RUN: 2 * Math.SQRT2 / 14   # the draft weight's row cross-section, per px of S

  # the geometry for an S x S device-px square, relative to its top-left
  # corner: the run n, the stroke width, and the two strokes as point lists
  _glyphMetrics: (S) ->
    n = Math.max 1, 2 * Math.round((S * @ROW_RUN - 1) / 2) + 1
    lineWidth = Math.max 1, n / Math.SQRT2
    tip = Math.max Math.round(S * @ARM_END - n / 4), Math.ceil 0.5 + n * (Math.SQRT2 - 1) / 4
    a = tip + n / 4
    b = S - a
    { n, lineWidth, strokes: [[[a, a], [b, b]], [[b, a], [a, b]]] }

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 6
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    m = @_glyphMetrics S

    # one path, so the crossing blends once under a translucent widget
    @_useInk ctx
    ctx.lineWidth = m.lineWidth
    ctx.lineCap = 'round'
    ctx.beginPath()
    for [[fromX, fromY], [toX, toY]] in m.strokes
      ctx.moveTo x + fromX, y + fromY
      ctx.lineTo x + toX, y + toY
    ctx.stroke()
