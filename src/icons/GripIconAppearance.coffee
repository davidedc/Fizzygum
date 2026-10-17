class GripIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE resize grip: three parallel 45° strokes in the bottom-right
  # half of its square — the redesign draft's `grip` glyph
  # (docs/plans/redesign/desktop-canvas.html GLYPH: 36-unit viewBox,
  # M33 5 L5 33 + M33 15 L15 33 + M33 25 l-8 8, 1.5 units wide, round caps) as
  # integer device-pixel geometry. Every stroke starts on the same column and
  # ends on the same row, so the grip mirrors about the box's main diagonal.
  # Ink only, no halo: it is painted in its widget's colour, over content.
  #
  # The line unit is the RUN n: the pixels each row of a 45° stroke holds,
  # which is the weight the eye reads (n/√2 across the stroke) — the draft's
  # 1.5-unit weight measured along a row (1.5·√2/36 of S), rounded: 2 at the
  # grip's 36 px, as close to the draft's 1.5 as a crisp staircase gets. It is
  # drawn as lineWidth n/√2 (never under 1: a sub-pixel stroke paints faint),
  # whose row cross-section is exactly n with half a pixel of margin either
  # way. An odd run straddles a pixel centre, so each end sits n/4 px inside a
  # pixel corner along both axes, which is where its round cap's tip then
  # lands: cap and stroke meet on a line no pixel centre lies on, so no sample
  # point is left to the rounding of the edge two polygons share. An even run
  # straddles a pixel edge, so instead each end moves half a pixel outward,
  # off the column (or row) it starts on, which already keeps that line
  # clear. Both keep the mirror about the main diagonal. The strokes are one
  # path, so a translucent widget blends them once.

  END: 33 / 36                         # the column every stroke starts on, the row it ends on
  STARTS: [5 / 36, 15 / 36, 25 / 36]   # each stroke's starting row (and ending column)
  ROW_RUN: 1.5 * Math.SQRT2 / 36       # the draft weight's row cross-section, per px of S

  # the geometry for an S x S device-px square, relative to its top-left
  # corner: the run n, the stroke width, and the three strokes as point lists
  _glyphMetrics: (S) ->
    n = Math.max 1, Math.round S * @ROW_RUN
    e = Math.round S * @END
    strokes = for f in @STARTS
      start = Math.round S * f
      if n % 2 is 0
        [[e + 0.5, start], [start, e + 0.5]]
      else
        # the start end's cap tip (n/4 px up and right of it: its stroke runs on
        # down-left) snapped to the nearest pixel corner
        tipX = Math.round e + n / 4
        tipY = Math.round start - n / 4
        [[tipX - n / 4, tipY + n / 4], [tipY + n / 4, tipX - n / 4]]
    { n, lineWidth: (Math.max 1, n / Math.SQRT2), strokes }

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 8
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    m = @_glyphMetrics S

    @_useInk ctx
    ctx.lineWidth = m.lineWidth
    ctx.lineCap = 'round'
    ctx.beginPath()
    for [[fromX, fromY], [toX, toY]] in m.strokes
      ctx.moveTo x + fromX, y + fromY
      ctx.lineTo x + toX, y + toY
    ctx.stroke()
