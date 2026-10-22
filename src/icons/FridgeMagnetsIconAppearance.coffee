class FridgeMagnetsIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE fridge in the design's style, the launcher icon of Fizzytiles
  # (the fridge-magnets app): the draft's "fizzytiles" glyph
  # (docs/archive/redesign/desktop-canvas.html), drawn by the idiom of
  # docs/plans/pixel-icons-plan.md §5b. Line art in ink, every line on the
  # glyph line unit t (SizeAwareIconAppearance._glyphLineUnit), with paper
  # interiors and no halo envelope (the tile the icon stands on is its ground):
  #   - the BODY is ONE rounded outline, a tall box;
  #   - the freezer DIVIDER is a t line across the body's paper that ends on
  #     the inner edges of both side walls: it joins them without thickening
  #     them (one line where they meet, never a doubled band), and parts the
  #     paper into the freezer above and the fridge below;
  #   - two door HANDLES, t-wide vertical bars in one column near the left
  #     wall: a short one low in the freezer, a longer one high in the fridge;
  #   - two MAGNETS sit in the fridge, the second one down and right of the
  #     first on a 45-degree diagonal.
  #   The border idiom: the ink silhouette (fillRoundRect), then the same box
  # inset by t in paper, its corner radius t less, so the corners stay
  # concentric and every straight wall is t thick by construction, horizontal
  # and vertical alike; the divider and the handles are fillRects of ink over
  # that paper.
  #   Detail by rule: a corner radius under MIN_CORNER px rounds nothing on the
  # non-AA backend, so below it the corners are square. A magnet is never
  # smaller than MIN_MAGNET px across (one lone px does not read as a magnet).
  # It is a ring -- a mid-radius strokeCircle, its wall t -- only when it is at
  # least MIN_RING px across and its hole keeps MIN_RING_HOLE px (the ring gate
  # of PatchProgrammingIconAppearance's node: a smaller ring reads as a blot or
  # breaks into arcs), else a solid dot: a fillCircle from MIN_ROUND_MAGNET px,
  # a hand-placed square below it. The magnets keep a px of paper from the
  # side walls, the divider, the bottom wall and each other (clamped into the
  # fridge, the diagonal kept); where the fridge cannot hold both with that
  # clearance the lower one drops, then the upper one -- the pair degrades by
  # dropping a member, never by crowding a wall. Each handle keeps a px of
  # paper from every other line too; the magnets have the first claim on the
  # fridge, so its handle stops short of a magnet in its column, and a handle
  # with no room for MIN_HANDLE px drops.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions: the INK edges of a one-unit line on the draft glyph's
  # path (its centre line moved out by half a unit), in GLYPH_GRID units: u
  # units are round(S * u / GLYPH_GRID) px at a glyph square of S px. The body
  # is centred in S both ways, so two opposite edges count only by their span;
  # the divider, the handles and the magnets are measured from the body's
  # top-left ink edges.
  BODY_LEFT: 13.5       # the body's outer ink edges (path x 14 and 30, y 5 and 39)
  BODY_RIGHT: 30.5
  BODY_TOP: 4.5
  BODY_BOTTOM: 39.5
  CORNER: 3.5           # the body's outer corner radius (path radius 3; the inner one is t less)
  DIVIDER_TOP: 15.5     # the divider's top ink edge (path y 16)
  MAGNET_LEFT: 18       # the upper magnet's outer ink edges (path circle (20, 28) r 1.5, a one-unit ring r 1 to 2)
  MAGNET_TOP: 26
  MAGNET_SIZE: 4        # a magnet's outer ink diameter
  MAGNET_PITCH: 5       # how far right AND down the lower magnet sits from the upper one (path circle (25, 33))
  # the door handles (the draft has none): one column 2 units in from the left wall's paper, and
  # the two bars straddle the door split as a fridge's do -- the freezer's ends a unit above the
  # divider, the fridge's starts 2 units under it
  HANDLE_LEFT: 16.5           # both handles' left ink edge (path x 17)
  FREEZER_HANDLE_TOP: 9.5     # the freezer handle's ink ends (5 units)
  FREEZER_HANDLE_BOTTOM: 14.5
  FRIDGE_HANDLE_TOP: 18.5     # the fridge handle's ink ends (7 units)
  FRIDGE_HANDLE_BOTTOM: 25.5
  # ---- detail tiers -----------------------------------------------------------
  MIN_CORNER: 2         # px: a smaller corner radius is square
  MIN_MAGNET: 2         # px: the smallest magnet, across
  MIN_ROUND_MAGNET: 4   # px: the smallest magnet drawn round; a smaller one is a square
  MIN_RING: 6           # px: the smallest magnet drawn as a ring, across ...
  MIN_RING_HOLE: 2      # px: ... and the smallest hole a ring keeps
  MIN_HANDLE: 2         # px: the shortest handle (and it is always longer than it is wide)

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_fridgeMetrics x0, y0, wDev, hDev
    @_fridgeBody ctx, m
    @_fridgeHandles ctx, m
    @_fridgeMagnets ctx, m

  # every measurement the fridge is built from, in whole device px
  _fridgeMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    px = (units) => Math.round S * units / @GLYPH_GRID
    # a span of S's parity, so the body sits on the exact centre of S
    span = (units) ->
      n = px units
      n++ if (S - n) % 2 isnt 0
      n
    w = span @BODY_RIGHT - @BODY_LEFT
    h = span @BODY_BOTTOM - @BODY_TOP
    left = x0 + Math.floor((wDev - S) / 2) + (S - w) / 2
    top = y0 + Math.floor((hDev - S) / 2) + (S - h) / 2
    r = px @CORNER
    r = 0 if r < @MIN_CORNER
    m =
      t: t
      left: left
      right: left + w
      top: top
      bottom: top + h
      r: r
      # under the corners' arcs (the divider meets straight walls), with a px of
      # the freezer's paper over it
      dividerTop: top + Math.max r, t + 1, px @DIVIDER_TOP - @BODY_TOP
    @_fridgeMagnetMetrics m, px
    @_fridgeHandleMetrics m, px
    m

  # the magnets, onto m: their size, their shape (ring, round dot or square
  # dot) and their top-left corners. The upper one sits at the draft's spot,
  # clamped so the magnets keep a px of paper from the side walls, the divider
  # and the bottom wall; where the fridge cannot hold both that way the lower
  # one drops, then the upper one
  _fridgeMagnetMetrics: (m, px) ->
    t = m.t
    k = Math.max @MIN_MAGNET, px @MAGNET_SIZE
    pitch = Math.max k + 1, px @MAGNET_PITCH   # a px of paper between the two, across and down
    m.magnetSize = k
    m.magnetIsRing = k >= @MIN_RING and k - 2 * t >= @MIN_RING_HOLE
    m.magnetIsRound = k >= @MIN_ROUND_MAGNET
    m.magnets = []
    for n in [2, 1]
      reach = (n - 1) * pitch + k   # the magnets' extent, across and down
      loX = m.left + t + 1
      hiX = m.right - t - 1 - reach
      loY = m.dividerTop + t + 1
      hiY = m.bottom - t - 1 - reach
      continue if loX > hiX or loY > hiY
      x = Math.min hiX, Math.max loX, m.left + px @MAGNET_LEFT - @BODY_LEFT
      y = Math.min hiY, Math.max loY, m.top + px @MAGNET_TOP - @BODY_TOP
      m.magnets = ([x + i * pitch, y + i * pitch] for i in [0...n])
      return
    return

  # the handles, onto m, as [left, top, bottom] (bottom exclusive): one t-wide
  # column at HANDLE_LEFT, a px of paper from the left wall; the freezer's
  # handle between the top wall and the divider, the fridge's between the
  # divider and the bottom wall, each with a px of paper from them (and from
  # the corners' arcs: neither reaches a row they round). The magnets come
  # first: the fridge handle stops a px above any magnet within a px of its
  # column. A handle left shorter than MIN_HANDLE px, or not longer than it
  # is wide (a dot, not a bar), drops
  _fridgeHandleMetrics: (m, px) ->
    t = m.t
    m.handles = []
    x = m.left + Math.max t + 1, px @HANDLE_LEFT - @BODY_LEFT
    return if x + t + 1 > m.right - t   # no px of paper between it and the right wall
    row = (units) => m.top + px units - @BODY_TOP
    inset = Math.max t + 1, m.r          # a px of paper inside the top or bottom wall, clear of the arcs
    freezer = [Math.max(m.top + inset, row @FREEZER_HANDLE_TOP), Math.min(m.dividerTop - 1, row @FREEZER_HANDLE_BOTTOM)]
    fridge = [Math.max(m.dividerTop + t + 1, row @FRIDGE_HANDLE_TOP), Math.min(m.bottom - inset, row @FRIDGE_HANDLE_BOTTOM)]
    k = m.magnetSize
    for [mx, my] in m.magnets when mx <= x + t and mx + k >= x and my + k >= fridge[0]
      fridge[1] = Math.min fridge[1], my - 1
    minLength = Math.max @MIN_HANDLE, t + 1
    for [top, bottom] in [freezer, fridge] when bottom - top >= minLength
      m.handles.push [x, top, bottom]
    return

  # the body: the ink silhouette, its paper inset by t (the corner radius t
  # less, so the corners stay concentric), the divider across the paper from
  # one wall to the other
  _fridgeBody: (ctx, m) ->
    {t, left, top, r} = m
    w = m.right - left
    h = m.bottom - top
    @_useInk ctx
    ctx.fillRoundRect left, top, w, h, r
    @_usePaper ctx
    ctx.fillRoundRect left + t, top + t, w - 2 * t, h - 2 * t, Math.max 0, r - t
    @_useInk ctx
    ctx.fillRect left + t, m.dividerTop, w - 2 * t, t

  # each handle a t-wide bar of ink on the paper
  _fridgeHandles: (ctx, m) ->
    @_useInk ctx
    for [x, top, bottom] in m.handles
      ctx.fillRect x, top, m.t, bottom - top
    return

  # each magnet fills its k x k box: a mid-radius strokeCircle ring (the exact
  # annulus [k/2 - t, k/2], so its wall is t), a fillCircle dot, or -- under
  # MIN_ROUND_MAGNET px, an extra-small feature no circle command expresses
  # (the non-AA backend draws a 2 px circle as one row of 2 and a 3 px one as
  # a plus) -- the solid k x k square, hand-placed
  _fridgeMagnets: (ctx, m) ->
    k = m.magnetSize
    @_useInk ctx
    ctx.lineWidth = m.t
    for [x, y] in m.magnets
      if m.magnetIsRing
        ctx.strokeCircle x + k / 2, y + k / 2, (k - m.t) / 2
      else if m.magnetIsRound
        ctx.fillCircle x + k / 2, y + k / 2, k / 2
      else
        ctx.fillRect x, y, k, k
    return
