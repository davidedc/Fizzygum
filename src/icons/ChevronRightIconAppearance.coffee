class ChevronRightIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE right chevron (›), a chrome indicator or separator — drawn,
  # never typed (a symbol that stands on its own is an icon). One half of the
  # redesign draft's `more` glyph (docs/plans/redesign/desktop-canvas.html
  # GLYPH: 16-unit viewBox, M3 3 l5 5 -5 5, 2 units wide, round caps and
  # join), re-centred in its own square, as integer device-pixel geometry. Ink
  # only, no halo: chrome glyphs sit on a bar or a row, never on art.
  #
  # Two exact 45° arms meet at a vertex on the box's horizontal axis, so the
  # chevron mirrors about that axis. The line unit is the RUN n: the pixels
  # each row of a 45° arm holds, which is the weight the eye reads (n/√2
  # across the arm) — the draft's 2-unit weight measured along a row (2·√2/16
  # of S), rounded. The stroke is lineWidth n/√2 (never under 1: a sub-pixel
  # stroke paints faint), whose row cross-section is exactly n with half a
  # pixel of margin either way. An odd run straddles a pixel centre and an
  # even one a pixel edge, so the vertex sits a whole number of pixels from
  # the axis in x for odd n and a whole number and a half for even n; its x is
  # the one coordinate free to move, which centres the arms' span on the box
  # to within half a pixel. An odd run's free END sits n/4 px inside a pixel
  # corner along both axes, which is where its round cap's tip then lands: cap
  # and arm meet on a line no pixel centre lies on (an even run's ends already
  # do), so no sample point is left to the rounding of the edge two polygons
  # share.

  ARM: 5 / 16                    # each arm's run along x (and along y)
  ROW_RUN: 2 * Math.SQRT2 / 16   # the draft weight's row cross-section, per px of S

  # the geometry for an S x S device-px square, relative to its top-left
  # corner: the run n, the stroke width, and the chevron as a point list
  _glyphMetrics: (S) ->
    n = Math.max 1, Math.round S * @ROW_RUN
    h = Math.round S * @ARM
    cy = S / 2
    lattice = if n % 2 is 1 then 0 else 0.5
    # the arms' x span [vx - h, vx] centred on the box's vertical axis
    vx = cy + lattice + Math.round h / 2 - lattice
    # an end at (px, py) whose arm runs on along (dx, dy), its cap tip snapped to a corner
    end = (px, py, dx, dy) ->
      return [px, py] if n % 2 is 0
      [Math.round(px - dx * n / 4) + dx * n / 4, Math.round(py - dy * n / 4) + dy * n / 4]
    { n, lineWidth: (Math.max 1, n / Math.SQRT2), strokes: [[end(vx - h, cy - h, 1, 1), [vx, cy], end(vx - h, cy + h, 1, -1)]] }

  # THE INK'S HORIZONTAL SPAN in an S x S square: [left, right) in px from the square's left
  # edge, each end rounded to the pixel lattice -- the stroke's outermost points, widened by the
  # half stroke its round caps and join reach past them (at S = 16: [5, 12), which is the ink
  # SWCanvas lays down). Asked of the CLASS, because a layout aligning my INK rather than my
  # square needs the number before any widget wears me: MenuItemWdgt's submenu chevron, whose ink
  # ends a side inset short of its row's right edge.
  @inkSpanX: (S) ->
    m = @::_glyphMetrics S
    left = Infinity
    right = -Infinity
    for points in m.strokes
      for point in points
        left = Math.min left, point[0]
        right = Math.max right, point[0]
    reach = m.lineWidth / 2
    [(Math.round left - reach), (Math.round right + reach)]

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 6
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
