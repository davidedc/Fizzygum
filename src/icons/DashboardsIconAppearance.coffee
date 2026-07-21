class DashboardsIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE dashboards icon (2026-07-21, converted with
  # /convert-icon-size-aware; idiom docs: docs/plans/pixel-icons-plan.md §5b):
  # the family's shared slide-card panel holding four quadrant mini-charts --
  # a scatter plot, a zigzag line chart, a bar chart and a small node graph.
  # All content is integer runs: axes on the hairline td unit (the old
  # 1.2-design-unit fills), data ink on tc, dots as small squares. The old
  # drawing's sub-pixel letter glyphs at the graph's spoke ends (0.4 design
  # units -- under half a device pixel even at 128px) become end DOTS. Fully
  # integer-painted, so the whole image is byte-identical across backends.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, fractions of the glyph square (numbers from the
  # original 100-space drawing) ----------------------------------------------
  # per-quadrant L-axes: [corner x, top y, right x, bottom y]
  Q1_AXES: [0.22, 0.27, 0.46, 0.48]   # scatter, top-left
  Q2_AXES: [0.56, 0.27, 0.794, 0.48]  # line chart, top-right
  Q3_AXES: [0.22, 0.53, 0.46, 0.74]   # bar chart, bottom-left
  SCATTER_DOTS: [[0.365, 0.315], [0.285, 0.415], [0.285, 0.305], [0.325, 0.365],
    [0.385, 0.365], [0.445, 0.345], [0.445, 0.295]]
  DOT_K: 0.03
  ZIGZAG: [[0.615, 0.435], [0.665, 0.345], [0.715, 0.385], [0.79, 0.28]]
  BARS: [[0.26, 0.07], [0.32, 0.05], [0.37, 0.07], [0.43, 0.15]]  # [x, height]
  BAR_W: 0.035
  GRAPH_C: [0.69, 0.645]              # 3D axes, bottom-right: the origin
  GRAPH_B: 0.72                       # the glyph's bottom -- a touch higher
                                      #   than the plots' 0.74 (the design's
                                      #   letters end at 72)

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 10
    # center the square glyph box in the widget box
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2

    t = Math.max 1, Math.round S / 32   # structural unit: the card border
    tc = Math.max 1, Math.round S / 45  # data ink: zigzag line
    td = Math.max 1, Math.round S / 64  # hairline: axes, graph spokes
    o = t
    ink = @_iconColorString()
    light = @_outlineColorString()

    [px, py, pw, ph, r] = @_pxSlideCard ctx, x, y, S, t, o, ink, light

    # the content clearance box: >=1px of light inside the card ring; every
    # coordinate below goes through these clamps (the bottom quadrants sit
    # right at the clearance edge at some sizes)
    cxMin = px + t + 1
    cxMax = px + pw - t - 2
    cyMin = py + t + 1
    cyMax = py + ph - t - 2
    m =
      S: S, t: t, tc: tc, td: td, ink: ink, light: light
      cxMin: cxMin, cxMax: cxMax, cyMin: cyMin, cyMax: cyMax
      fx: (f) => Math.min Math.max(x + Math.round(S * f), cxMin), cxMax
      fy: (f) => Math.min Math.max(y + Math.round(S * f), cyMin), cyMax
      # clamp a k-sized square's TOP-LEFT so the whole square stays in the
      # content box (a center-derived rect otherwise escapes the center
      # clamp by k>>1)
      dotX: (cx2, k) => Math.min Math.max(cx2 - (k >> 1), cxMin), cxMax - k + 1
      dotY: (cy2, k) => Math.min Math.max(cy2 - (k >> 1), cyMin), cyMax - k + 1

    # under 20px the four real mini-charts -- a dozen one-pixel elements in
    # a ~10x7 interior -- collide into soup (swept: every size 14..19 broke
    # some element invariant, 20+ none); the honest miniature is four solid
    # chart TILES in the quadrant footprints
    if S < 20
      @_paintChartTiles ctx, m
      return

    ctx.fillStyle = ink
    q1Bot = @_paintScatter ctx, m
    q2Bot = @_paintLineChart ctx, m
    q3Right = @_paintBars ctx, m, q1Bot
    @_paintNodeGraph ctx, m, q2Bot, q3Right

  # the under-20px miniature: solid tiles on the quadrant footprints,
  # kept apart by explicit >=1px gaps; tiles that can't fit drop
  _paintChartTiles: (ctx, m) ->
    ctx.fillStyle = m.ink
    x1 = m.fx 0.22
    r1 = m.fx 0.46
    x2 = Math.max m.fx(0.56), r1 + 2
    r2 = m.fx 0.794
    yT = m.fy 0.27
    yM = m.fy 0.48
    yB2 = Math.max m.fy(0.53), yM + 2
    yBot = m.fy 0.74
    ctx.fillRect x1, yT, r1 - x1 + 1, yM - yT + 1
    ctx.fillRect x2, yT, r2 - x2 + 1, yM - yT + 1 if r2 >= x2
    if yBot >= yB2
      ctx.fillRect x1, yB2, r1 - x1 + 1, yBot - yB2 + 1
      ctx.fillRect x2, yB2, r2 - x2 + 1, yBot - yB2 + 1 if r2 >= x2

  # a td-thick L: vertical axis down into a horizontal axis, sharing the
  # corner; the horizontal arm runs through axEnd INCLUSIVE -- callers
  # extend it to their content's right edge, so the axis always reaches
  # the end of the graph
  _paintAxes: (ctx, m, ax, ayTop, axEnd, ayBot) ->
    ctx.fillStyle = m.ink
    ctx.fillRect ax, ayTop, m.td, ayBot - ayTop
    ctx.fillRect ax, ayBot - m.td, axEnd - ax + 1, m.td

  # squares stamped along a straight segment, w thick (diagonal steps are
  # fine -- 8-connected, like any quantized arc)
  _stampSegment: (ctx, x1, y1, x2, y2, w) ->
    n = Math.max Math.abs(x2 - x1), Math.abs(y2 - y1), 1
    for i in [0..n]
      f = i / n
      ctx.fillRect Math.round(x1 + (x2 - x1) * f - w / 2),
        Math.round(y1 + (y2 - y1) * f - w / 2), w, w

  # top-left: scatter dots + L-axes extended under them; a dot that can't
  # keep 1px of light from an already-placed dot is dropped (they'd read
  # as one blob)
  _paintScatter: (ctx, m) ->
    [ax, ayTop, axRight, ayBot] = [m.fx(@Q1_AXES[0]), m.fy(@Q1_AXES[1]),
      m.fx(@Q1_AXES[2]), m.fy(@Q1_AXES[3])]
    k = Math.max 2, Math.round m.S * @DOT_K
    placed = []
    for [fdx, fdy] in @SCATTER_DOTS
      dx = Math.max m.dotX(m.fx(fdx), k), ax + m.td + 1
      dy = Math.min m.dotY(m.fy(fdy), k), ayBot - m.td - 1 - k
      continue if placed.some ([ox, oy]) -> Math.abs(ox - dx) <= k and Math.abs(oy - dy) <= k
      placed.push [dx, dy]
    axEnd = axRight
    for [dx2] in placed
      axEnd = Math.max axEnd, dx2 + k - 1
    @_paintAxes ctx, m, ax, ayTop, axEnd, ayBot
    ctx.fillStyle = m.ink
    for [dx2, dy2] in placed
      ctx.fillRect dx2, dy2, k, k
    ayBot

  # top-right: L-axes + the zigzag data line, stamped tc thick; vertices
  # keep 1px of light off both axes
  _paintLineChart: (ctx, m) ->
    [ax, ayTop, axRight, ayBot] = [m.fx(@Q2_AXES[0]), m.fy(@Q2_AXES[1]),
      m.fx(@Q2_AXES[2]), m.fy(@Q2_AXES[3])]
    # stamp-safe vertex clamps: a stamped square extends ceil(tc/2) beyond
    # its vertex, so the vertex must sit that far inside every bound
    vs = for [fvx, fvy] in @ZIGZAG
      [Math.min(Math.max(m.fx(fvx), ax + m.td + 1 + (m.tc >> 1)), m.cxMax - (m.tc >> 1)),
       Math.min(Math.max(m.fy(fvy), m.cyMin + Math.ceil(m.tc / 2)), ayBot - m.td - 2 - (m.tc >> 1))]
    axEnd = Math.max axRight, Math.round(vs[vs.length - 1][0] - m.tc / 2) + m.tc - 1
    @_paintAxes ctx, m, ax, ayTop, axEnd, ayBot
    ctx.fillStyle = m.ink
    for i in [1...vs.length]
      @_stampSegment ctx, vs[i - 1][0], vs[i - 1][1], vs[i][0], vs[i][1], m.tc
    ayBot

  # bottom-left: L-axes + solid bars standing on the horizontal axis; the
  # quadrant's top clamps below the scatter quadrant (their fractions
  # round onto each other at small sizes), and a bar that can't keep 1px
  # of light from the previous one is dropped
  _paintBars: (ctx, m, q1Bot) ->
    ax = m.fx @Q3_AXES[0]
    ayTop = Math.max m.fy(@Q3_AXES[1]), q1Bot + 1
    axRight = m.fx @Q3_AXES[2]
    ayBot = Math.max m.fy(@Q3_AXES[3]), ayTop + 2 * m.td
    bw = Math.max 1, Math.round m.S * @BAR_W
    prevRight = ax + m.td
    bars = []
    for [fbx, fh] in @BARS
      bx = Math.max m.fx(fbx), prevRight + 2   # >=1px of light between bars
      h = Math.max 1, Math.round m.S * fh
      top = Math.max ayBot - m.td - h, ayTop
      continue if bx + bw - 1 > axRight
      prevRight = bx + bw - 1
      bars.push [bx, top]
    axEnd = Math.max axRight, prevRight
    @_paintAxes ctx, m, ax, ayTop, axEnd, ayBot
    ctx.fillStyle = m.ink
    for [bx, top] in bars
      ctx.fillRect bx, top, bw, ayBot - m.td - top
    axEnd

  # bottom-right: 3D AXES -- three td spokes (X, Y, Z) radiating from the
  # origin. The original's tiny letter labels (sub-pixel at every real
  # size) render as dots sitting AT the quadrant box's edges -- top center,
  # bottom-left and bottom-right corners, where the letters sit in the
  # design -- and each axis stops 1px + a stamp-half short of its label:
  # separated (connected they'd read as part of the axis) but near, and
  # the WHOLE glyph stays inside the same footprint as the other three
  # plots. A spoke with no room for a separated label draws bare to the
  # box edge instead.
  _paintNodeGraph: (ctx, m, q2Bot, q3Right) ->
    k = Math.max 2, Math.round m.S * 0.02
    hs = Math.ceil m.td / 2
    # the quadrant box: Q2's width, clamped clear of both neighbours; the
    # bottom sits at the glyph's own, slightly higher line
    qL = Math.max m.fx(@Q2_AXES[0]), q3Right + 2
    qR = m.fx @Q2_AXES[2]
    qT = Math.max m.fy(@Q3_AXES[1]), q2Bot + 1
    qB = m.fy @GRAPH_B
    cx = m.fx @GRAPH_C[0]
    cy = Math.max m.fy(@GRAPH_C[1]), qT + hs
    ctx.fillStyle = m.ink
    # per spoke: [label x, label y, axis tip x, axis tip y], then the bare
    # box-edge endpoint used when the label can't fit separated
    spokes = [
      [cx - (k >> 1), qT, cx, qT + k + 1 + hs]
      [qL, qB - k + 1, qL + k + 1 + hs, qB - k - hs]
      [qR - k + 1, qB - k + 1, qR - k - hs, qB - k - hs]
    ]
    bare = [[cx, qT], [qL, qB], [qR, qB]]
    for [lx, ly, tipX, tipY], i in spokes
      outward = if i is 0 then tipY < cy \
        else tipY > cy and (if i is 1 then tipX < cx else tipX > cx)
      if outward
        @_stampSegment ctx, cx, cy, tipX, tipY, m.td
        ctx.fillRect lx, ly, k, k
      else
        @_stampSegment ctx, cx, cy, bare[i][0], bare[i][1], m.td
