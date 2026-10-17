class DoubleChevronRightIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE double right chevron (»), a chrome control face — drawn, never
  # typed (a symbol that stands on its own is an icon). The redesign draft's
  # `more` glyph (docs/plans/redesign/desktop-canvas.html GLYPH: 16-unit
  # viewBox, M3 3 l5 5 -5 5 + M9 3 l5 5 -5 5, 2 units wide, round caps and
  # joins), re-centred in its square, as integer device-pixel geometry. Ink
  # only, no halo: chrome glyphs sit on a bar or a row, never on art.
  #
  # Two copies of ChevronRightIconAppearance's chevron, the second a whole
  # number of pixels to the right of the first, so both sit on the same
  # lattice and the pair mirrors about the box's horizontal axis. The line
  # unit is the RUN n, as there: the pixels each row of a 45° arm holds (the
  # draft's 2-unit weight measured along a row, 2·√2/16 of S, rounded), drawn
  # as lineWidth n/√2 (never under 1) on the lattice n needs — an odd run
  # straddles a pixel centre, an even one a pixel edge — with an odd run's
  # free ends n/4 px inside a pixel corner, where their cap tips land. The
  # offset never closes below one clear pixel between the two chevrons' arms.
  # The pair is one path, so a translucent widget blends it once.

  ARM: 5 / 16                    # each arm's run along x (and along y)
  OFFSET: 6 / 16                 # the second chevron's distance to the right
  ROW_RUN: 2 * Math.SQRT2 / 16   # the draft weight's row cross-section, per px of S

  # the geometry for an S x S device-px square, relative to its top-left
  # corner: the run n, the stroke width, and the two chevrons as point lists
  _glyphMetrics: (S) ->
    n = Math.max 1, Math.round S * @ROW_RUN
    h = Math.round S * @ARM
    d = Math.max n + 1, Math.round S * @OFFSET
    cy = S / 2
    lattice = if n % 2 is 1 then 0 else 0.5
    # the pair's x span [vx - h, vx + d] centred on the box's vertical axis
    vx = cy + lattice + Math.round (h - d) / 2 - lattice
    # an end at (px, py) whose arm runs on along (dx, dy), its cap tip snapped to a corner
    end = (px, py, dx, dy) ->
      return [px, py] if n % 2 is 0
      [Math.round(px - dx * n / 4) + dx * n / 4, Math.round(py - dy * n / 4) + dy * n / 4]
    strokes = for tipX in [vx, vx + d]
      [end(tipX - h, cy - h, 1, 1), [tipX, cy], end(tipX - h, cy + h, 1, -1)]
    { n, lineWidth: (Math.max 1, n / Math.SQRT2), offset: d, strokes }

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 8
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
