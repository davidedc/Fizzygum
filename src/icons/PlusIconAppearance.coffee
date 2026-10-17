class PlusIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE plus (+), a chrome control face — drawn, never typed (a symbol
  # that stands on its own is an icon). The redesign draft's `minimise` bar
  # (docs/plans/redesign/desktop-canvas.html GLYPH) plus its vertical twin:
  # 14-unit viewBox, M7 2 v10 + M2 7 h10, 2 units wide, round caps, as integer
  # device-pixel geometry. Ink only, no halo: chrome glyphs sit on a bar or a
  # row, never on art.
  #
  # The line unit is MinusIconAppearance's: each bar's thickness t in device
  # rows is the draft's 2/14 of S rounded to the nearest integer of S's own
  # PARITY, so both bars centre exactly on the box's axes and the plus mirrors
  # about both axes and both diagonals. Each bar is a capsule (the draft's
  # round caps) ending 1/14 of S in from the box edges; the two share ONE
  # path, so where they cross a translucent widget blends once.

  BAR_THICKNESS: 2 / 14   # the draft's stroke width, per px of S
  BAR_INSET: 1 / 14       # each end's inset from the box edge (caps included)

  # the geometry for an S x S device-px square, relative to its top-left
  # corner: the thickness t and the two bars' boxes [left, top, width, height]
  _glyphMetrics: (S) ->
    parity = S % 2
    t = Math.max 2 - parity, 2 * Math.round((S * @BAR_THICKNESS - parity) / 2) + parity
    m = Math.max 1, Math.round S * @BAR_INSET
    c = (S - t) / 2
    { t, bars: [[m, c, S - 2 * m, t], [c, m, t, S - 2 * m]] }

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 5
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    m = @_glyphMetrics S

    @_useInk ctx
    ctx.beginPath()
    for [left, top, width, height] in m.bars
      ctx.roundRect x + left, y + top, width, height, m.t / 2
    ctx.fill()
