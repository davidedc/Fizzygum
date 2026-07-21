class SimpleSlideIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE simple-slide icon (2026-07-21, converted with
  # /convert-icon-size-aware; idiom docs: docs/plans/pixel-icons-plan.md §5b):
  # the family's shared slide-card panel (the base's _pxSlideCard) holding
  # slide content -- a left column of text rows and a right column with a
  # rising 3-bar chart over two more text rows. All content is integer runs
  # on the lighter tc unit: the old 1.5-design-unit strokes land around one
  # device pixel at the real display sizes and dropped out, or dashed,
  # under the non-AA backend. Fully integer-painted, so the whole image is
  # byte-identical across backends.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, fractions of the glyph square (numbers from the
  # original 100-space drawing) ----------------------------------------------
  LINE_YS: [0.336, 0.4534, 0.5608, 0.6736]  # the slide's 4 text rows
  COL1_X: 0.17        # left text column
  COL2_X: 0.54        # right column (the chart + its 2 text rows)
  LINE_LEN: 0.28
  COL2_FROM_ROW: 2    # the right column joins at the 3rd text row
  BAR_BASE: 0.46      # the chart's common baseline
  BAR_W: 0.085
  BAR_GAP: 0.025
  BAR_HS: [0.11, 0.14, 0.19]                # rising bar heights

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 10
    # center the square glyph box in the widget box
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2

    t = Math.max 1, Math.round S / 32   # structural unit: the card border
    tc = Math.max 1, Math.round S / 45  # lighter unit: all slide content
    o = t                               # halo/envelope thickness
    ink = @_iconColorString()
    light = @_outlineColorString()

    [px, py, pw, ph, r] = @_pxSlideCard ctx, x, y, S, t, o, ink, light

    # the content clearance box: >=1px of light inside the card ring
    # (rounding otherwise parks content ON the border at small sizes)
    cxMin = px + t + 1
    cxMax = px + pw - t - 2             # last usable column
    lx1 = Math.max x + Math.round(S * @COL1_X), cxMin
    lx2 = Math.max x + Math.round(S * @COL2_X), cxMin

    yB = @_paintBarChart ctx, y, S, tc, lx2, cxMax, py, t, ink, light
    @_paintTextRows ctx, y, S, tc, lx1, lx2, cxMax, py, t, yB, ink

  # the rising bar chart: uniform-width bars (walls tc, hollow when the
  # hole keeps 1px, solid below) sharing one baseline, left-anchored on the
  # right text column. Heights derive right-to-left, each strictly shorter
  # than its taller neighbour and capped under the card's top clearance; a
  # bar that can't stay both >=1 tall and strictly shorter DROPS and the
  # survivors compact left -- the rise is the chart's identity, so at tiny
  # sizes fewer still-rising bars beat a flattened row. A bar that would
  # cross the clearance box is dropped too. Returns the baseline.
  _paintBarChart: (ctx, y, S, tc, lx2, cxMax, py, t, ink, light) ->
    yB = y + Math.round S * @BAR_BASE
    bw = Math.max 1, Math.round S * @BAR_W
    gap = Math.max 1, Math.round S * @BAR_GAP
    hMax = yB - (py + t + 1)
    hs = []
    hNext = hMax + 1
    for i in [@BAR_HS.length - 1 .. 0] by -1
      h = Math.min Math.round(S * @BAR_HS[i]), hMax, hNext - 1
      break if h < 1
      hs.unshift h
      hNext = h
    for h, i in hs
      bx = lx2 + i * (bw + gap)
      break if bx + bw - 1 > cxMax
      ctx.fillStyle = ink
      ctx.fillRect bx, yB - h, bw, h
      if bw - 2 * tc >= 2 and h - 2 * tc >= 2
        ctx.fillStyle = light
        ctx.fillRect bx + tc, yB - h + tc, bw - 2 * tc, h - 2 * tc
    yB

  # the text rows, computed ONCE and shared by both columns so surviving
  # rows stay aligned across them: a row that can't keep 1px of light from
  # the previous one is dropped (min-pitch rule); the right column draws
  # its subset only below the chart's baseline
  _paintTextRows: (ctx, y, S, tc, lx1, lx2, cxMax, py, t, yB, ink) ->
    len = Math.round S * @LINE_LEN
    ctx.fillStyle = ink
    prevY = -99
    for f, i in @LINE_YS
      yy = Math.max y + Math.round(S * f) - Math.round(tc / 2), py + t + 1
      continue if yy < prevY + tc + 1
      prevY = yy
      ctx.fillRect lx1, yy, Math.min(len, cxMax - lx1 + 1), tc
      if i >= @COL2_FROM_ROW and yy > yB
        ctx.fillRect lx2, yy, Math.min(len, cxMax - lx2 + 1), tc
