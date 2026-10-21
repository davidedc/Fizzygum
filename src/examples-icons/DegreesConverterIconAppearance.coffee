class DegreesConverterIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE C-F converter in the design's style: the converter's opener in
  # the Examples folder (40 px glyph, 80 at dpr 2). Line art on t, paper
  # interiors, no halo:
  #   - the THERMOMETER on the square's middle column: a TUBE (a stadium,
  #     fillStadium) whose foot joins a round BULB. The border idiom with the
  #     exact annulus for the bulb: the tube's ink; the bulb's paper disc
  #     (covering the tube's walls inside it); the bulb's ring (a mid-radius
  #     strokeCircle, wall t); the tube's paper inset t (its foot opens the
  #     ring's top arc between the tube's walls: a T on each side, one t line
  #     each); then the MERCURY in ink: a disc in the bulb and a column up the
  #     tube, each keeping MERCURY_GAP of paper from the glass;
  #   - TICKS: short t lines right of the tube, one pitch apart;
  #   - the LETTERS, a degree sign and a C left of the tube, a degree sign and
  #     an F right of it, all on t: the C is a round-rect outline opened on its
  #     right, the F three bars, the degree sign a ring where the family's ring
  #     rule allows it.
  #   Detail by rule: the letters drop as a pair when their box is under
  # MIN_LETTER px tall or would leave the square (the thermometer stays); a
  # degree sign is a ring (k >= MIN_RING, hole >= MIN_RING_HOLE), else a dot
  # from MIN_DOT px (the family's small-feature rule, read on the smaller of
  # the rounded and the exact size), else it drops (a 3 px square reads as a
  # blot, not a degree); the bulb is solid ink when its mercury disc would be
  # under MIN_MERCURY px; the mercury column drops when the tube's paper is
  # under MIN_COLUMN_ROOM px; the ticks drop as a unit when a tick would be
  # shorter than MIN_TICK px. Under S 10 nothing is drawn.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, GLYPH_GRID units (INK edges) ------------------------------
  TUBE_WIDTH: 7         # the tube's outer width, on the square's middle column
  TUBE_TOP: 3.5         # its top ink edge (a round cap)
  BULB_SIZE: 13         # the bulb's outer diameter
  BULB_BOTTOM: 40.5     # its bottom ink edge
  MERCURY_GAP: 1        # paper between the mercury and the glass
  MERCURY_TOP: 17       # the column's top
  TICK_LENGTH: 3        # a tick's length
  TICK_GAP: 1.5         # paper between the tube and a tick
  TICK_TOP: 9           # the first tick's top (the scale runs from it down)
  TICK_PITCH: 4         # from one tick's top to the next one's
  TICKS: 4
  LETTER_TOP: 5         # the letters' top ink edge
  LETTER_HEIGHT: 9      # their ink height
  C_WIDTH: 7            # the C's outer width
  F_WIDTH: 6            # the F's
  F_BAR: 0.55           # the F's middle bar: its top over the letter's height, and ...
  F_MID_SHARE: 0.75     # ... its length over the F's width
  DEGREE_SIZE: 4.5      # the degree sign's outer size
  LETTER_GAP: 1         # paper between a degree sign and its letter
  LETTER_TO_TUBE: 2.5   # paper between the letters and the tube
  C_OPENING: 0.36       # the C's opening on its right: its height over the letter's
  C_CORNER: 3           # the C's outer corner radius
  # ---- detail tiers -----------------------------------------------------------
  MIN_LETTER: 6         # px: shorter letters drop (both sides)
  MIN_COLUMN_ROOM: 3    # px of tube paper the column needs (column + a px of paper each side)
  MIN_TICK: 2           # px: shorter ticks drop
  MIN_MERCURY: 4        # px: a smaller mercury disc makes the bulb solid
  MIN_RING: 6           # px: the smallest degree sign drawn as a ring ...
  MIN_RING_HOLE: 2      # px: ... whose hole keeps this much
  MIN_DOT: 4            # px: the smallest degree sign drawn as a dot (else it drops)

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_thermoMetrics x0, y0, wDev, hDev
    @_thermometer ctx, m
    @_ticks ctx, m
    @_letters ctx, m if m.letters?

  # every measurement the icon is built from, in device px: the tube and the
  # bulb (on the square's middle column), the mercury, the letters' box
  # (undefined where they drop) and the ticks' tops
  _thermoMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    x = x0 + Math.floor((wDev - S) / 2)
    y = y0 + Math.floor((hDev - S) / 2)
    px = (units) => Math.round S * units / @GLYPH_GRID
    # widths of S's parity, so the tube and the bulb share the square's exact middle column
    ofS = (units, least) ->
      n = Math.max least, px(units)
      n++ if (S - n) % 2 isnt 0
      n
    tw = ofS @TUBE_WIDTH, 2 * t + 1
    bd = Math.max tw + 2, ofS(@BULB_SIZE, 2 * t + 3)
    axis = x + S / 2
    bulbBottom = y + px(@BULB_BOTTOM)
    bulbTop = bulbBottom - bd
    tubeTop = y + px(@TUBE_TOP)
    g = Math.max 1, px(@MERCURY_GAP)
    m =
      t: t
      tw: tw
      bd: bd
      tubeLeft: axis - tw / 2
      tubeTop: tubeTop
      bulbCx: axis
      bulbCy: bulbTop + bd / 2
      g: g
    # the mercury: a disc of the bulb's paper less the gap, a column of the tube's paper less it.
    # The disc keeps g px of paper from the ring across, and (a quantised circle's shoulder being
    # nearer) a px DIAGONALLY too: an odd bulb's disc is two px smaller again
    m.mercuryD = bd - 2 * t - 2 * g - (if bd % 2 isnt 0 then 2 else 0)
    # a mercury disc under MIN_MERCURY px reads as a speck: the bulb is then solid ink. Gated on
    # the EXACT size (the drawn bulb alternates a px with S's parity, and the gate must not), half
    # a px up so the drawn disc is never under MIN_MERCURY where the gate lets it be hollow
    exactD = S * @BULB_SIZE / @GLYPH_GRID - 2 * t - 2 * g - 2
    m.solidBulb = exactD < @MIN_MERCURY + 0.5 or m.mercuryD < @MIN_MERCURY
    m.columnW = tw - 2 * t - 2 * g
    # gated on the smaller of the drawn and the exact tube (the drawn one alternates a px with S's
    # parity): the column never comes and goes as S grows
    m.hasColumn = Math.min(tw, S * @TUBE_WIDTH / @GLYPH_GRID) - 2 * t >= @MIN_COLUMN_ROOM and m.columnW >= 1
    m.columnTop = Math.min y + px(@MERCURY_TOP), bulbTop
    # ---- the letters
    lh = px @LETTER_HEIGHT
    lt = y + px(@LETTER_TOP)
    toTube = Math.max 1, px(@LETTER_TO_TUBE)
    lgap = Math.max 1, px(@LETTER_GAP)
    dk = Math.max 1, px(@DEGREE_SIZE)
    cw = Math.max 2 * t + 2, px(@C_WIDTH)
    fw = Math.max t + 2, px(@F_WIDTH)
    exactDeg = S * @DEGREE_SIZE / @GLYPH_GRID
    # the C sits right of its degree sign, ending toTube left of the tube; mirror for the F
    cRight = m.tubeLeft - toTube
    cLeft = cRight - cw
    dcLeft = cLeft - lgap - dk
    fLeft = m.tubeLeft + tw + toTube + dk + lgap
    dfLeft = fLeft - lgap - dk
    if lh >= @MIN_LETTER and dcLeft >= x and fLeft + fw <= x + S
      cr = Math.min px(@C_CORNER), Math.floor(cw / 2)
      cr = 0 if cr < 2
      degreeSize = Math.min dk, exactDeg
      degreeTier = 'none'
      degreeTier = 'dot' if degreeSize >= @MIN_DOT
      degreeTier = 'ring' if degreeSize >= @MIN_RING and dk - 2 * t >= @MIN_RING_HOLE
      # the opening has the letter's height parity, so it sits on the C's middle, and stays on
      # the right wall's straight (clear of the corner arcs)
      opening = Math.max 1, Math.round(lh * @C_OPENING)
      opening++ if (lh - opening) % 2 isnt 0
      opening -= 2 while opening > Math.max(1, lh - 2 * cr) and opening > 2
      m.letters =
        top: lt
        h: lh
        cLeft: cLeft
        cw: cw
        cr: cr
        fLeft: fLeft
        fw: fw
        dk: dk
        dcLeft: dcLeft
        dfLeft: dfLeft
        degreeTier: degreeTier
        opening: opening
    # ---- the ticks, right of the tube. The scale starts under the letters' band, whether or not
    # the letters are drawn, so the ticks do not jump when they arrive. HOW MANY is read on the
    # exact geometry (monotonic in S); WHERE on the rounded one, the pitch closing up a px where
    # the rounded room is short, a tick dropping only where even the least pitch (t + 1) cannot
    # hold them
    tl = px @TICK_LENGTH
    tg = Math.max 1, px(@TICK_GAP)
    # in GLYPH_GRID units, unrounded (a tick and its gaps one unit each): the same count at every
    # S, so the scale never loses a tick as the icon grows
    firstUnits = Math.max @TICK_TOP, @LETTER_TOP + @LETTER_HEIGHT + @TICK_GAP + 1
    lastUnits = @BULB_BOTTOM - @BULB_SIZE - @TICK_GAP - 1
    n = Math.max 0, Math.min(@TICKS, Math.floor((lastUnits - firstUnits) / @TICK_PITCH) + 1)
    firstTick = y + Math.max(px(@TICK_TOP), px(@LETTER_TOP) + px(@LETTER_HEIGHT) + tg + t)
    # the gap under the letters' band is SOFT: it closes to a px (the hard clearance) before a
    # tick drops; the pitch closes to t + 1 first
    firstLeast = y + px(@LETTER_TOP) + px(@LETTER_HEIGHT) + 1
    pitch = Math.max t + 1, px(@TICK_PITCH)
    m.ticks = []
    if tl >= @MIN_TICK
      last = -> firstTick + (n - 1) * pitch + t
      while n > 1 and last() > bulbTop - tg
        pitch = Math.max t + 1, Math.min(pitch, Math.floor((bulbTop - tg - t - firstTick) / (n - 1)))
        break if last() <= bulbTop - tg
        if firstTick > firstLeast
          firstTick--
          pitch = Math.max t + 1, px(@TICK_PITCH)
          continue
        n--
        pitch = Math.max t + 1, px(@TICK_PITCH)
      n = 0 if n is 1 and firstTick + t > bulbTop - tg
      for i in [0...n]
        m.ticks.push firstTick + i * pitch
    m.tickLength = tl
    m.tickGap = tg
    m

  _thermometer: (ctx, m) ->
    {t, tubeLeft, tubeTop, tw, bd, bulbCx, bulbCy, g} = m
    tubeH = bulbCy - tubeTop
    @_useInk ctx
    ctx.fillStadium tubeLeft, tubeTop, tw, tubeH
    @_usePaper ctx
    ctx.fillCircle bulbCx, bulbCy, bd / 2
    @_useInk ctx
    ctx.lineWidth = t
    ctx.strokeCircle bulbCx, bulbCy, (bd - t) / 2
    @_usePaper ctx
    ctx.fillStadium tubeLeft + t, tubeTop + t, tw - 2 * t, tubeH
    # the mercury
    @_useInk ctx
    # the solid tier: the WHOLE bulb in ink (an inner disc meeting the ring's inner edge would tie
    # on the shared radius and leave paper specks)
    if m.solidBulb
      ctx.fillCircle bulbCx, bulbCy, bd / 2
    else
      ctx.fillCircle bulbCx, bulbCy, m.mercuryD / 2
    ctx.fillRect tubeLeft + t + g, m.columnTop, m.columnW, bulbCy - m.columnTop if m.hasColumn

  _ticks: (ctx, m) ->
    @_useInk ctx
    left = m.tubeLeft + m.tw + m.tickGap
    for top in m.ticks
      ctx.fillRect left, top, m.tickLength, m.t

  # a degree sign in the k x k box at (left, top): a ring, a dot, or nothing,
  # by its tier
  _degree: (ctx, m, left, top, k, tier) ->
    t = m.t
    if tier is 'ring'
      ctx.lineWidth = t
      ctx.strokeCircle left + k / 2, top + k / 2, (k - t) / 2
    else if tier is 'dot'
      ctx.fillCircle left + k / 2, top + k / 2, k / 2

  # the C: ONE filled band, a round-rect outline opened on its right across
  # its middle -- the outer boundary, then the inner one traced back (corners
  # about one centre each, the inner radius t less)
  _cBand: (ctx, l, tp, r, b, cr, t, opening) ->
    ri = Math.max 0, cr - t
    yo1 = tp + (b - tp - opening) / 2
    yo2 = yo1 + opening
    ctx.beginPath()
    ctx.moveTo r, yo1
    ctx.arcTo r, tp, l, tp, cr
    ctx.arcTo l, tp, l, b, cr
    ctx.arcTo l, b, r, b, cr
    ctx.arcTo r, b, r, yo2, cr
    ctx.lineTo r, yo2
    ctx.lineTo r - t, yo2
    ctx.arcTo r - t, b - t, l + t, b - t, ri
    ctx.arcTo l + t, b - t, l + t, tp + t, ri
    ctx.arcTo l + t, tp + t, r - t, tp + t, ri
    ctx.arcTo r - t, tp + t, r - t, yo1, ri
    ctx.lineTo r - t, yo1
    ctx.closePath()
    ctx.fill()

  # the letters, ink only: no paper inside a glyph to leak out of its opening
  # onto a hovered or pressed tile. The C, the F (stem, top bar, middle bar),
  # then the degree signs, their tops on the letters' top
  _letters: (ctx, m) ->
    letters = m.letters
    t = m.t
    @_useInk ctx
    @_cBand ctx, letters.cLeft, letters.top, letters.cLeft + letters.cw, letters.top + letters.h, letters.cr, t, letters.opening
    ctx.fillRect letters.fLeft, letters.top, t, letters.h
    ctx.fillRect letters.fLeft, letters.top, letters.fw, t
    ctx.fillRect letters.fLeft, letters.top + Math.round(letters.h * @F_BAR) - t, Math.max(t + 1, Math.round(letters.fw * @F_MID_SHARE)), t
    @_degree ctx, m, letters.dcLeft, letters.top, letters.dk, letters.degreeTier
    @_degree ctx, m, letters.dfLeft, letters.top, letters.dk, letters.degreeTier
