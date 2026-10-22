class BinIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE bin in the design's style: the draft's "bin" glyph
  # (docs/archive/redesign/desktop-canvas.html), drawn by the idiom of
  # docs/plans/pixel-icons-plan.md §5b. Line art in ink, every line on the
  # glyph line unit t (SizeAwareIconAppearance._glyphLineUnit), with paper
  # interiors and no halo envelope (the tile the icon stands on is its ground):
  #   - the LID is one t-thick line across the bin;
  #   - the HANDLE is a box standing on the lid line with no bottom of its own:
  #     the lid line closes it (adjacent outlined shapes share ONE line -- a
  #     drawn bottom would double it into a thicker band);
  #   - the BODY hangs from the lid line, which is its top, and tapers down to
  #     its bottom wall;
  #   - three RIDGES, t-wide vertical lines inside the body.
  #   The border idiom: the ink silhouette, then each interior in paper inset by
  # t. The body's paper is its trapezoid with each side moved t inward, between
  # the lid line and the bottom wall (_binBody, twice): two parallel edges at an
  # integer offset quantise identically under the non-AA backend (lesson 29), so
  # every row of a slanted wall is exactly t wide and touches the next -- one
  # connected wall, as thick as every straight one.
  #   ONE axis: every width shares t's parity, so the centre ridge (t wide) sits
  # on the axis and the bin is its own mirror image. Where S and t differ in
  # parity the axis cannot be the square's centre, and the bin sits half a px
  # left of it (floor centring); vertically it is centred exactly.
  #   Detail by rule: a ridge keeps MIN_CLEARANCE px of paper from the lid line,
  # the bottom wall, the other ridges and the slanted walls (measured at its
  # lowest row, where the taper brings the walls nearest). The outer pair drops
  # together, never one side, and then the centre one by the same rule. The
  # handle keeps at least a px of paper inside it, across and down.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions: the INK edges of a one-unit line on the draft glyph's
  # path (its centre line moved out by half a unit; the lid's and the ridges'
  # round caps reach half a unit past their ends), in GLYPH_GRID units: u units
  # are round(S * u / GLYPH_GRID) px at a glyph square of S px. The bin is
  # symmetric about the path's x 22 and centred in S, so two opposite edges
  # count only by their span.
  HANDLE_TOP: 6.5          # the handle's top ink edge (path y 7)
  LID_TOP: 10.5            # the lid line's top ink edge (path y 11)
  BOTTOM: 37.5             # the bottom wall's lower ink edge (path y 37)
  LID_LEFT: 7.5            # the lid line's ends (path x 8 and 36)
  LID_RIGHT: 36.5
  HANDLE_LEFT: 16.5        # the handle's outer ink edges (path x 17 and 27)
  HANDLE_RIGHT: 27.5
  BODY_TOP_LEFT: 10.5      # the body's outer ink edges at the lid line (path x 11 and 33)
  BODY_TOP_RIGHT: 33.5
  BODY_TAPER: 2            # how far each side moves in, lid line to bottom (path x 11 to 13)
  RIDGE_PITCH: 4           # ridge centre to ridge centre (path x 18, 22, 26)
  RIDGE_TOP: 16.5          # the ridges' ink ends (path y 17 and 31)
  RIDGE_BOTTOM: 31.5
  # ---- detail tiers -----------------------------------------------------------
  MIN_CLEARANCE: 1         # px of paper a ridge keeps from every other ink

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_binMetrics x0, y0, wDev, hDev
    @_binSilhouette ctx, m
    @_binInteriors ctx, m
    @_binRidges ctx, m

  # every measurement the bin is built from, in whole device px (each slanted
  # side is the exact line between two of them)
  _binMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    px = (units) => Math.round S * units / @GLYPH_GRID
    # a width of t's parity: centred on the axis, its edges land on whole px
    width = (n) ->
      n++ if (n - t) % 2 isnt 0
      n
    # the axis: the square's centre when S and t share parity, else half a px
    # left of it
    axis = x0 + Math.floor((wDev - S) / 2) + (S - (S - t) % 2) / 2
    # a height of S's parity, so the bin is centred in S vertically
    h = px @BOTTOM - @HANDLE_TOP
    h++ if (S - h) % 2 isnt 0
    top = y0 + Math.floor((hDev - S) / 2) + (S - h) / 2
    bottom = top + h
    lidTop = top + Math.max t + 1, px @LID_TOP - @HANDLE_TOP
    handleWidth = width Math.max 2 * t + 1, px @HANDLE_RIGHT - @HANDLE_LEFT
    topWidth = width px @BODY_TOP_RIGHT - @BODY_TOP_LEFT
    run = Math.max 1, px @BODY_TAPER   # the body always tapers
    lidWidth = width Math.max topWidth + 2, px @LID_RIGHT - @LID_LEFT
    # the slanted sides start on the lid line's top row, unless their run and
    # rise then share their largest power of two (x & -x): such a side crosses
    # a pixel centre exactly on some row, where the backend may break the tie
    # either way -- the two walls would stop mirroring each other there, and a
    # wall's two edges could round apart. One row lower is tie-free, and still
    # on the lid line or directly under it, so the walls still meet it.
    edgeTop = lidTop
    edgeTop++ if (run & -run) is ((bottom - edgeTop) & -(bottom - edgeTop))
    m =
      t: t
      axis: axis
      top: top
      lidTop: lidTop
      bottom: bottom
      handleLeft: axis - handleWidth / 2
      handleWidth: handleWidth
      lidLeft: axis - lidWidth / 2
      lidWidth: lidWidth
      topWidth: topWidth
      run: run
      edgeTop: edgeTop
    @_binRidgeMetrics m, px
    m

  # the ridges, onto m: a length of the interior's parity centred in it (clear
  # of the lid line and of the bottom wall), and the ridges that keep their
  # clearance from the walls at their lowest row, where the paper is narrowest
  _binRidgeMetrics: (m, px) ->
    t = m.t
    interior = m.bottom - m.lidTop - 2 * t
    length = px @RIDGE_BOTTOM - @RIDGE_TOP
    length++ if (interior - length) % 2 isnt 0
    length = Math.min length, interior - 2 * @MIN_CLEARANCE
    m.ridgeTop = m.lidTop + t + (interior - length) / 2
    m.ridgeBottom = m.ridgeTop + length
    room = @_binHalfWidthAt(m, m.ridgeBottom) - t   # the paper's half-width there
    pitch = Math.max t + @MIN_CLEARANCE, px @RIDGE_PITCH
    offsets = []
    if length >= 2 and room - t / 2 >= @MIN_CLEARANCE
      offsets = if room - pitch - t / 2 >= @MIN_CLEARANCE then [-pitch, 0, pitch] else [0]
    m.ridgeLefts = (m.axis + offset - t / 2 for offset in offsets)

  # the body's outer half-width at row boundary y: its sides run from the top
  # corners (axis -/+ topWidth / 2, edgeTop) inward by run at the bottom
  _binHalfWidthAt: (m, y) ->
    m.topWidth / 2 - m.run * (y - m.edgeTop) / (m.bottom - m.edgeTop)

  # the ink silhouette: the handle as a solid box down to the lid line, the lid
  # line, the body's trapezoid
  _binSilhouette: (ctx, m) ->
    @_useInk ctx
    ctx.fillRect m.handleLeft, m.top, m.handleWidth, m.lidTop - m.top
    ctx.fillRect m.lidLeft, m.lidTop, m.lidWidth, m.t
    @_binBody ctx, m, 0, m.edgeTop, m.bottom

  # the paper interiors, each its ink shape inset by t: the handle's runs down
  # to the lid line that closes it, the body's from under the lid line (its
  # top) to above the bottom wall
  _binInteriors: (ctx, m) ->
    @_usePaper ctx
    ctx.fillRect m.handleLeft + m.t, m.top + m.t, m.handleWidth - 2 * m.t, m.lidTop - m.top - m.t
    @_binBody ctx, m, m.t, m.lidTop + m.t, m.bottom - m.t

  _binRidges: (ctx, m) ->
    @_useInk ctx
    for left in m.ridgeLefts
      ctx.fillRect left, m.ridgeTop, m.t, m.ridgeBottom - m.ridgeTop
    return

  # the body's trapezoid between rows yTop and yBottom, each side its outer side
  # moved d inward: d = 0 is the ink silhouette, d = t the paper interior
  _binBody: (ctx, m, d, yTop, yBottom) ->
    halfTop = @_binHalfWidthAt(m, yTop) - d
    halfBottom = @_binHalfWidthAt(m, yBottom) - d
    ctx.beginPath()
    ctx.moveTo m.axis - halfTop, yTop
    ctx.lineTo m.axis + halfTop, yTop
    ctx.lineTo m.axis + halfBottom, yBottom
    ctx.lineTo m.axis - halfBottom, yBottom
    ctx.closePath()
    ctx.fill()
