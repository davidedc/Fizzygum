class SprayCanIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE spray can in the design's style, the icon of Draw (its launcher,
  # its info doc, a drawing's shortcut): the draft's "draw" glyph
  # (docs/archive/redesign/desktop-canvas.html), drawn by the idiom of
  # docs/plans/pixel-icons-plan.md §5b. Line art in ink, every line on the
  # glyph line unit t (SizeAwareIconAppearance._glyphLineUnit), with paper
  # interiors and no halo envelope (the tile the icon stands on is its ground):
  #   - the BODY is ONE rounded outline, a tall box;
  #   - the CAP is a box standing on the body's top line with no bottom of its
  #     own: the top line closes it (adjacent outlined shapes share ONE line --
  #     a drawn bottom would double it into a thicker band); only its top
  #     corners round;
  #   - the NOZZLE is a t-wide stem rising from the cap's top line;
  #   - the SPRAY is a fan of six ink dots to the right of the can, its middle
  #     row level with the nozzle's tip: the draft's pattern, which lies on a
  #     lattice of two steps -- a PITCH across and a RISE up or down -- spread
  #     wider than the draft's so that its dots can be bigger and heavier
  #     (owner).
  #   The body, the cap and the nozzle share ONE axis: their widths share t's
  # parity, so the stem sits on it and the can is its own mirror image.
  #   The border idiom: the body's ink silhouette (fillRoundRect), then the same
  # box inset by t in paper, its corner radius t less, so the corners stay
  # concentric and every straight wall is t thick by construction, horizontal
  # and vertical alike; the cap the same way, its paper stopping on the body's
  # top line.
  #   Placement: the can and its spray are centred in S as ONE composition,
  # exactly, both ways: the gap between the body and the spray, and the body's
  # height, are each the nearest whole px to their span that gives the
  # composition's width and height S's parity.
  #   Detail by rule: a corner radius under MIN_CORNER px rounds nothing on the
  # non-AA backend, so below it a corner is square. The cap stands on the
  # straight of the body's top line, so the line shows past it on each side
  # (the body widens for it where it must). A dot is never smaller than
  # MIN_DOT px across, and all of them are one size and one shape: a
  # fillCircle from MIN_ROUND_DOT px, a hand-placed square below it (the
  # non-AA backend draws a 2 px circle as one row of 2 and a 3 px one as a
  # plus). Two dots a step apart on the lattice keep a px of clear between
  # them (the pitch is at least a dot and a px, the rise at least half that),
  # and the spray keeps at least a px of clear from the body (the cap and the
  # nozzle stand inside the body's columns). Where the composition does not
  # fit in S, the spray thins by dropping dots, outermost first and keeping
  # the fan's shape (SPRAY_COUNTS: six, five, then the three nearest), never
  # by shrinking them; then the nozzle drops, then the cap. Below the size
  # the barest composition fits in (S = 11), nothing is drawn.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions: the INK edges of a one-unit line on the draft glyph's
  # path (its centre line moved out by half a unit), in GLYPH_GRID units: u
  # units are round(S * u / GLYPH_GRID) px at a glyph square of S px. The can
  # and its spray are centred in S as one composition, so every edge counts
  # only by its span, measured from the body's edges.
  BODY_LEFT: 9.5        # the body's outer ink edges (path x 10 and 24, y 17 and 40)
  BODY_RIGHT: 24.5
  BODY_TOP: 16.5
  BODY_BOTTOM: 40.5
  CORNER: 3.5           # the body's outer corner radius (path radius 3; the inner one is t less)
  CAP_LEFT: 12.5        # the cap's outer ink edges (path x 13 and 21, y 11); its bottom is the body's top line
  CAP_RIGHT: 21.5
  CAP_TOP: 10.5
  CAP_CORNER: 1.5       # the cap's top corners' outer radius (path radius 1)
  NOZZLE_TOP: 7.5       # the stem's ink tip (path y 8, plus its round cap's half unit)
  # the spray: the draft's dots are 2.4 units across, on a lattice of 4 units across and 3 up or
  # down (path (28, 8), (32, 5), (32, 11), (36, 8), (36, 14), (39, 4)); the owner asked for
  # bigger, heavier dots, so they grow and the lattice spreads with them
  DOT: 4                # a dot's size, across (the draft's 2.4)
  SPRAY_PITCH: 5.5      # the lattice's step across (the draft's 4)
  SPRAY_RISE: 0.75      # its step up or down, as a fraction of the pitch (the draft's 3 / 4)
  SPRAY_GAP: 2          # the clear between the body's right wall and the nearest dot
  SPRAY_ROW: 8          # the fan's middle row, through its nearest dot's centre (path y 8: the nozzle's tip)
  # ---- detail tiers -----------------------------------------------------------
  MIN_CORNER: 2         # px: a smaller corner radius is square
  MIN_DOT: 2            # px: the smallest dot, across
  MIN_ROUND_DOT: 4      # px: the smallest dot drawn round; a smaller one is a square
  SPRAY_COUNTS: [6, 5, 3]   # the fans the spray thins through: each is the nearest dots of the full one

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_sprayCanMetrics x0, y0, wDev, hDev
    return unless m?
    @_sprayCanBody ctx, m
    @_sprayCanCap ctx, m
    @_sprayCanNozzle ctx, m
    @_sprayCanSpray ctx, m

  # every measurement the can and its spray are built from, in whole device px
  _sprayCanMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    px = (units) => Math.round S * units / @GLYPH_GRID
    corner = (units) =>
      radius = px units
      if radius < @MIN_CORNER then 0 else radius
    r = corner @CORNER
    # the can's widths take t's parity, so they are centred on its axis with
    # their edges on whole px. The cap stands on the straight of the body's
    # top line: a px past where the corner's arc comes within half a px of
    # that line (about r - sqrt(r) in from the side), so a px of the line
    # shows past the cap on each side
    shoulder = if r > 0 then Math.round(r - Math.sqrt r) + 1 else 1
    capWidth = @_nearestOfParity S * (@CAP_RIGHT - @CAP_LEFT) / @GLYPH_GRID, t, 2 * t + 1
    # the cap's height down to the lower edge of the body's top line, which it
    # shares: its paper is at least a px tall
    capHeight = Math.max 2 * t + 1, px(@BODY_TOP - @CAP_TOP) + t
    m =
      S: S
      t: t
      r: r
      capWidth: capWidth
      bodyWidth: @_nearestOfParity S * (@BODY_RIGHT - @BODY_LEFT) / @GLYPH_GRID, t, capWidth + 2 * shoulder
      capHeight: capHeight
      capR: Math.min corner(@CAP_CORNER), capHeight - t
      nozzleHeight: px @CAP_TOP - @NOZZLE_TOP
      rowDrop: px @SPRAY_ROW - @NOZZLE_TOP
    @_sprayCanDotMetrics m, px
    # the first composition that fits, thinning the spray, then dropping the
    # nozzle, then the cap; below the size the barest one fits in, nothing is
    # drawn
    fewest = @SPRAY_COUNTS[@SPRAY_COUNTS.length - 1]
    tiers = ([n, true, true] for n in @SPRAY_COUNTS).concat [[fewest, false, true], [fewest, false, false]]
    for [n, hasNozzle, hasCap] in tiers
      @_sprayCanCompose m, n, hasNozzle, hasCap
      break if m.width <= S and m.height <= S
    return undefined if m.width > S or m.height > S
    @_sprayCanPlace m, x0 + Math.floor((wDev - S) / 2) + (S - m.width) / 2, y0 + Math.floor((hDev - S) / 2) + (S - m.height) / 2
    m

  # the whole number nearest to exact that has the parity of like, and is at
  # least least
  _nearestOfParity: (exact, like, least) ->
    n = 2 * Math.round((exact - like) / 2) + like
    n += 2 while n < least
    n

  # the spray's dot, onto m: its size and shape, and the lattice's two steps.
  # Two dots a step across, or a step and a rise, apart keep a px of clear
  # between them, and so do two a rise above and below a third
  _sprayCanDotMetrics: (m, px) ->
    k = Math.max @MIN_DOT, px @DOT
    m.dotSize = k
    m.dotIsRound = k >= @MIN_ROUND_DOT
    m.pitch = Math.max k + 1, px @SPRAY_PITCH
    m.rise = Math.max Math.ceil((k + 1) / 2), Math.round m.pitch * @SPRAY_RISE

  # the composition of the can and an n-dot fan, onto m, before it is placed:
  # which parts it has, its spans, the height of its parts above the body's
  # top line, and each dot's top-left corner relative to the body's top-left
  # corner. The fan's lattice, nearest dot first: the middle row's dot, a
  # step across and a rise up and down, two steps across on the middle row and
  # two rises down, and the farthest a rise further across and a whole step up.
  #   Centred exactly: the gap between the body and the spray, and the body's
  # height, are each the nearest whole px to their span that gives the
  # composition's width and height S's parity
  _sprayCanCompose: (m, n, hasNozzle, hasCap) ->
    {S, t, pitch, rise} = m
    k = m.dotSize
    m.hasNozzle = hasNozzle
    m.hasCap = hasCap
    m.capRise = if hasCap then m.capHeight - t else 0
    tip = m.capRise + (if hasNozzle then m.nozzleHeight else 0)
    dotTop = m.rowDrop - tip - Math.floor k / 2
    lattice = [[0, 0], [pitch, -rise], [pitch, rise], [2 * pitch, 0], [2 * pitch, 2 * rise], [2 * pitch + rise, -pitch]]
    fan = ([x, dotTop + y] for [x, y] in lattice[0...n])
    sprayWidth = Math.max((x + k for [x, y] in fan)...)
    m.above = Math.max tip, -Math.min((y for [x, y] in fan)...)
    m.gap = @_nearestOfParity S * @SPRAY_GAP / @GLYPH_GRID, S - m.bodyWidth - sprayWidth, 1
    m.bodyHeight = @_nearestOfParity S * (@BODY_BOTTOM - @BODY_TOP) / @GLYPH_GRID, S - m.above, 2 * t + 1
    m.width = m.bodyWidth + m.gap + sprayWidth
    m.height = m.above + m.bodyHeight
    m.dotsAt = ([m.bodyWidth + m.gap + x, y] for [x, y] in fan)

  # m's parts in device px, the composition's top-left corner at (left, top)
  _sprayCanPlace: (m, left, top) ->
    {t} = m
    m.left = left
    m.right = left + m.bodyWidth
    m.bodyTop = top + m.above
    m.bottom = m.bodyTop + m.bodyHeight
    m.capLeft = left + (m.bodyWidth - m.capWidth) / 2
    m.capRight = m.capLeft + m.capWidth
    m.capTop = m.bodyTop - m.capRise
    m.nozzleLeft = left + (m.bodyWidth - t) / 2
    m.nozzleTop = m.capTop - m.nozzleHeight
    m.dots = ([left + x, m.bodyTop + y] for [x, y] in m.dotsAt)

  # the body: the ink silhouette, its paper inset by t (the corner radius t
  # less, so the corners stay concentric)
  _sprayCanBody: (ctx, m) ->
    {t, left, bodyTop, r} = m
    w = m.right - left
    h = m.bottom - bodyTop
    @_useInk ctx
    ctx.fillRoundRect left, bodyTop, w, h, r
    @_usePaper ctx
    ctx.fillRoundRect left + t, bodyTop + t, w - 2 * t, h - 2 * t, Math.max 0, r - t

  # the cap: its ink down to the lower edge of the body's top line, which it
  # shares -- its walls there ARE that line, painted over in the same ink --
  # then its paper inset by t, stopping on that line. Only its top corners
  # round (radii in roundRect's order: top-left, top-right, bottom-right,
  # bottom-left)
  _sprayCanCap: (ctx, m) ->
    return unless m.hasCap
    {t, capLeft, capTop, capR} = m
    w = m.capRight - capLeft
    inner = Math.max 0, capR - t
    @_useInk ctx
    ctx.fillRoundRect capLeft, capTop, w, m.bodyTop + t - capTop, [capR, capR, 0, 0]
    @_usePaper ctx
    ctx.fillRoundRect capLeft + t, capTop + t, w - 2 * t, m.bodyTop - capTop - t, [inner, inner, 0, 0]

  # the nozzle: a t-wide stem on the axis, from its tip down through the cap's
  # top line, so it meets that line
  _sprayCanNozzle: (ctx, m) ->
    return unless m.hasNozzle
    @_useInk ctx
    ctx.fillRect m.nozzleLeft, m.nozzleTop, m.t, m.nozzleHeight + m.t

  # each dot fills its k x k box: a fillCircle, or -- under MIN_ROUND_DOT px,
  # an extra-small feature no circle command expresses -- the solid k x k
  # square, hand-placed
  _sprayCanSpray: (ctx, m) ->
    k = m.dotSize
    @_useInk ctx
    for [x, y] in m.dots
      if m.dotIsRound
        ctx.fillCircle x + k / 2, y + k / 2, k / 2
      else
        ctx.fillRect x, y, k, k
    return

