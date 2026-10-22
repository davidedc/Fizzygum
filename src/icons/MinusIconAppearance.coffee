class MinusIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE minus (−), a chrome control face — drawn, never typed (a
  # symbol that stands on its own is an icon). The redesign draft's
  # `minimise` glyph (docs/archive/redesign/desktop-canvas.html GLYPH: 14-unit
  # viewBox, M2 7 h10, 2 units wide, round caps) as integer device-pixel
  # geometry. Ink only, no halo: chrome glyphs sit on a bar or a row, never
  # on art.
  #
  # The line unit is the bar's thickness t in device rows: the draft's 2/14 of
  # S rounded to the nearest integer of S's own PARITY, so (S − t)/2 is whole
  # and the bar sits exactly on the box's horizontal axis. The bar is a
  # capsule — the draft's round caps — whose box is the stroke plus its caps,
  # ending 1/14 of S in from each side. A capsule t rows thick fills exactly t
  # rows; from t = 4 up its ends round off.

  BAR_THICKNESS: 2 / 14   # the draft's stroke width, per px of S
  BAR_INSET: 1 / 14       # each end's inset from the box edge (caps included)

  # the geometry for an S x S device-px square, relative to its top-left
  # corner: the thickness t and the bar's box [left, top, width, height]
  _glyphMetrics: (S) ->
    parity = S % 2
    t = Math.max 2 - parity, 2 * Math.round((S * @BAR_THICKNESS - parity) / 2) + parity
    m = Math.max 1, Math.round S * @BAR_INSET
    { t, bars: [[m, (S - t) / 2, S - 2 * m, t]] }

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 5
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    [[left, top, width, height]] = @_glyphMetrics(S).bars

    @_useInk ctx
    ctx.fillStadium x + left, y + top, width, height
