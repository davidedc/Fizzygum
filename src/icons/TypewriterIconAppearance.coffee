class TypewriterIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE typewriter in the design's style, the icon of the Docs Maker (its
  # launcher, its info doc), of the Examples folder's "Document" and
  # "Spreadsheet" openers and of a document's shortcut: the draft's "docs"
  # glyph (docs/archive/redesign/desktop-canvas.html), drawn by the idiom of
  # docs/plans/pixel-icons-plan.md §5b. Line art in ink, every line on the
  # glyph line unit t (SizeAwareIconAppearance._glyphLineUnit), with paper
  # interiors and no halo envelope (the tile the icon stands on is its ground):
  #   - the SHEET is a box with no bottom of its own, standing behind the
  #     carriage: the carriage's top line closes it (adjacent outlined shapes
  #     share ONE line -- a drawn bottom would double it into a thicker band);
  #     on it, two TEXT LINES, t tall, the second shorter;
  #   - the CARRIAGE is a bar with round ends across the machine's top;
  #   - a KNOB at each end of it, as tall as the bar or a little less and
  #     tangent to its end: the knob's inner wall IS the bar's end wall where
  #     they meet;
  #   - the LEVER, a t-thick bent line: an arm rising from the left knob's top
  #     up and out to the left, then a short stub back to the right;
  #   - the BODY, flaring downward from its top line, which is the carriage's
  #     bottom line (one line, never a doubled band), its bottom corners
  #     rounded;
  #   - the KEYS, solid ink, two rows of five on the body's paper.
  #   The border idiom: each shape's ink, then its paper inset by t. The
  # carriage is two stadiums (fillStadium), so its round ends stay concentric
  # and every wall is t thick, horizontal and vertical alike. The body is two
  # polygons (_typewriterBodyOutline, twice): its paper's flanks are the ink's
  # moved t across, two parallel edges at an integer offset, which the non-AA
  # backend quantises identically (lesson 29) -- every row of a slanted wall is
  # exactly t wide and touches the next, one connected wall from the top line
  # to the bottom one, as thick as every straight one; each bottom corner is
  # an arc tangent to its flank and to the bottom line, the ink's and the
  # paper's about ONE centre, so the wall stays t round the corner. Its
  # flanks' run and rise never share their largest power of two (the Bin's
  # tie rule: such a flank crosses a pixel centre exactly on some row, where
  # the backend may break the tie either way and the two flanks stop
  # mirroring each other); where they would, the flanks leave the top line a
  # row lower. A knob is a ring -- a mid-radius strokeCircle over a paper
  # disc, the exact annulus [k/2 - t, k/2], so its wall is t -- or a solid
  # dot. The lever is fills: the stub a fillRect, the slanted arm a band whose
  # two edges are parallel at a t offset across, so every row of it is exactly
  # t (lesson 29) and shifts at most a px from the next: one connected line (a
  # fill, never a round-capped stroke: the non-AA backend leaves the overlap
  # of two round caps in one stroke unpainted).
  #   ONE axis: every width shares the key size k's parity, so the middle key
  # sits on the axis and the machine (but for its lever and its text lines) is
  # its own mirror image. The draft's carriage and knobs sit a unit right of
  # its axis, which balances the lever on the left; here they stand on the
  # axis, and the machine and its lever are centred in S as ONE composition
  # instead: the axis stands half the lever's overhang right of the square's
  # centre, or half a px left of that where widths of k's parity would not
  # land on whole px (floor centring). Vertically the machine is centred
  # exactly.
  #   Clearance is a spec: the sheet stands on the straight of the carriage's
  # top line, a px clear of its round ends. The body's top corners tuck in
  # under the carriage's round ends, no further out than where those cross
  # the top of the carriage's bottom line, so the bar's lower arcs, the knobs
  # and the body's corners never close a pocket of clear between them. The
  # carriage is never so wide that a knob leaves the square. The lever's arm
  # stands on the middle of the left knob's top (a knob's top row is inked
  # across its middle, whatever way the backend rounds the rest of its rim);
  # the arm and the stub touch nothing else, and the stub reaches a px past
  # the arm below it, so its end is free.
  #   Detail by rule: a corner radius under MIN_CORNER px rounds nothing on the
  # non-AA backend, so below it the body's corners are square. The text lines
  # keep a px of paper from the sheet's walls, from each other and from the
  # carriage; their gaps close up to fit (to a px of paper each), then the
  # second line drops, then the first. The first line is centred across the
  # paper; the second, from the same left end, is at least a px shorter. A
  # knob is a ring only when it is at least MIN_RING px across and its hole
  # keeps MIN_RING_HOLE px (the ring gate of PatchProgrammingIconAppearance's
  # node, read on its exact span too, so the ring never turns back into a dot
  # as S grows), else a solid dot: a fillCircle from MIN_ROUND_KNOB px, a
  # hand-placed square below it. The lever's arm shifts at most a px a row
  # (its outer corner moves right to hold that); with no row for the arm
  # under the stub, there is no lever. The keys are all one size and one
  # shape: a fillCircle from MIN_ROUND_KEY px, a hand-placed square below it
  # (the non-AA backend draws a 2 px circle as one row of 2 and a 3 px one as
  # a plus). They keep a px of paper from each other and from the body's
  # walls, and are centred in its paper both ways (half a px up where the
  # leftover is odd); where the flanks leave them too little paper there,
  # their gaps close up to a px, then they move down a row at a time, then the
  # keyboard thins by KEY_TIERS -- to one row of five, then to the middle
  # three -- never by shrinking its keys; with room for none, the body is
  # drawn empty. At these proportions: no keys up to S = 15, three from 16,
  # five from 23, two rows of five from 24.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions: the INK edges of a one-unit line on the draft glyph's
  # path (its centre line moved out by half a unit; a text line's round caps
  # reach half a unit past its ends), in GLYPH_GRID units: u units are round(S
  # * u / GLYPH_GRID) px at a glyph square of S px. The machine is centred in
  # S, so a symmetric part counts only by its span, and every height by its
  # distance from the sheet's top.
  TOP: 2.5                # the sheet's top ink edge (path y 3): the machine's top
  BOTTOM: 38.5            # the body's bottom ink edge (path y 38): the machine's bottom
  SHEET_WIDTH: 21         # the sheet's outer ink span (path M12 18V3h20v15)
  LINES: 2                # the text lines (path M15 7h14 M15 11h8.4)
  LINE_LENGTH: 15         # the first line's ink length, centred across the sheet's paper
  SHORT_LINE_LENGTH: 9.4  # the second line's, from the same left end
  LINE_TOP: 6.5           # the first line's top ink edge (path y 7)
  LINE_PITCH: 4           # from a line's top to the next one's
  CARRIAGE_WIDTH: 31      # the carriage's outer ink span (path rect (8, 16) 30 x 5 r 2.5, a stadium; here centred on the axis, path x 7..37)
  CARRIAGE_TOP: 15.5      # its top ink edge (path y 16)
  CARRIAGE_HEIGHT: 6      # its ink height
  KNOB_SIZE: 5            # a knob's ink diameter (path circles r 2 two units past the carriage's ends, tangent to them)
  LEVER_TOP: 10.5         # the lever stub's top ink edge (path M8 17L3 11h4, here a unit left with the knob)
  LEVER_OVERHANG: 1       # how far the lever's outer corner stands left of the knob's ink (path x 2, the knob's ink from 2.5)
  LEVER_STUB: 4           # from the knob's ink left edge to the stub's ink end (path x 6)
  BODY_TOP_WIDTH: 30.8    # the body's outer ink span along its top line (path M7 21h30: its flanks' outer edges cross that line at x 6.6 and 37.4)
  BODY_BOTTOM_WIDTH: 38   # its flanks' outer span continued to the bottom ink edge (path l3 15: 3 units out over 15 down)
  BODY_CORNER: 2.5        # its bottom corners' outer radius (path radius 2; the inner one is t less)
  KEY_SIZE: 3.5           # a key's size across and down (the draft's dots are 2.6 across; the owner asked for bigger, heavier keys)
  KEY_PITCH: 5.5          # from a key's left edge to the next one's
  KEY_ROW_PITCH: 5        # from a key row's top to the next one's
  # ---- detail tiers -----------------------------------------------------------
  MIN_CORNER: 2           # px: a smaller corner radius is square
  MIN_CLEARANCE: 1        # px of paper a text line or a key keeps from every other ink
  MIN_LINE: 2             # px: the shortest first text line; with less the sheet is blank
  MIN_KNOB: 2             # px: the smallest knob, across
  MIN_ROUND_KNOB: 4       # px: the smallest knob drawn round; a smaller one is a square
  MIN_RING: 6             # px: the smallest knob drawn as a ring, across ...
  MIN_RING_HOLE: 2        # px: ... and the smallest hole a ring keeps; a smaller knob is a solid dot
  MIN_KEY: 2              # px: the smallest key, across
  MIN_ROUND_KEY: 4        # px: the smallest key drawn round; a smaller one is a square
  KEY_TIERS: [[2, 5], [1, 5], [1, 3]]   # the keyboards the keys thin through, as [rows, keys a row], the draft's first (path dots x 11, 16.5, 22, 27.5 and 33, y 27 and 32); each row's keys the middle ones of a full row

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_typewriterMetrics x0, y0, wDev, hDev
    @_typewriterSheet ctx, m
    @_typewriterCarriage ctx, m
    @_typewriterBody ctx, m
    @_typewriterKnobs ctx, m
    @_typewriterLever ctx, m
    @_typewriterKeys ctx, m

  # every measurement the typewriter is built from, in whole device px but for
  # the axis (half a px off the grid where S and k differ in parity), the
  # bottom corners' centre and the lever's step
  _typewriterMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    px = (units) => Math.round S * units / @GLYPH_GRID
    k = Math.max @MIN_KEY, px @KEY_SIZE
    # a width of k's parity: centred on the axis, its edges land on whole px
    width = (units, least = 1) ->
      n = Math.max least, px units
      n++ if (n - k) % 2 isnt 0
      n
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    # the axis: the machine and its lever are centred in S as ONE composition
    # -- the lever's corner stands LEVER_OVERHANG further out on the left than
    # the right knob does on the right, so the axis is half that right of the
    # square's centre -- where widths of k's parity have whole-px edges: half a
    # px left of there where it is not such a place
    reach = S + px @LEVER_OVERHANG
    axis = x + (reach - (reach - k) % 2) / 2
    # a height of S's parity, so the machine is centred in S vertically
    h = px @BOTTOM - @TOP
    h++ if (S - h) % 2 isnt 0
    top = y + (S - h) / 2
    bottom = top + h
    carriageHeight = Math.max 2 * t + 1, px @CARRIAGE_HEIGHT
    # the body keeps a px of paper under the carriage
    carriageTop = Math.min top + px(@CARRIAGE_TOP - @TOP), bottom - t - 1 - carriageHeight
    m =
      S: S
      t: t
      k: k
      square: {left: x, top: y, right: x + S, bottom: y + S}
      axis: axis
      top: top
      bottom: bottom
      carriageTop: carriageTop
      carriageBottom: carriageTop + carriageHeight
      bodyTop: carriageTop + carriageHeight - t   # the carriage's bottom line
    @_typewriterKnobSize m
    # the carriage leaves room in the square for its knobs (twice the axis's
    # distance from either side of the square has k's parity, and so does the
    # cap)
    carriageWidth = Math.min width(@CARRIAGE_WIDTH), 2 * Math.min(axis - x, x + S - axis) - 2 * (m.knob - t)
    # the sheet stands on the straight of the carriage's top line, a px clear
    # of its round ends
    sheetWidth = Math.min width(@SHEET_WIDTH, 2 * t + 1), carriageWidth - 2 * Math.ceil(carriageHeight / 2) - 2
    # the body's top corners stand no further out than where the carriage's
    # round ends cross the top of its bottom line: so the carriage's lower
    # arcs, the knobs and the body's corners never close a pocket between them
    half = carriageHeight / 2
    tuck = Math.ceil half - Math.sqrt(half * half - (half - t) * (half - t))
    topWidth = Math.min width(@BODY_TOP_WIDTH), carriageWidth - 2 * tuck
    bottomWidth = width @BODY_BOTTOM_WIDTH, topWidth + 2   # the body always flares
    radius = px @BODY_CORNER
    m.carriageLeft = axis - carriageWidth / 2
    m.carriageRight = axis + carriageWidth / 2
    m.sheetLeft = axis - sheetWidth / 2
    m.sheetRight = axis + sheetWidth / 2
    m.bodyLeft = axis - topWidth / 2                # the body's top-left outer corner
    m.run = (bottomWidth - topWidth) / 2            # how far each flank travels out, top to bottom
    m.r = if radius < @MIN_CORNER then 0 else radius
    # the flanks start on the top line, unless their run and rise share their
    # largest power of two (x & -x): one row lower is tie-free, and still on
    # the top line or directly under it
    m.flankTop = m.bodyTop
    m.flankTop++ if (m.run & -m.run) is ((bottom - m.flankTop) & -(bottom - m.flankTop))
    # the bottom-left corner's centre (the right one mirrors it): r inside the
    # ink flank and r above the bottom ink edge; and the flank's length from
    # flankTop to the bottom ink edge, so (-rise, -run) / length is the unit
    # normal pointing out of the left flank
    m.flankLength = Math.sqrt m.run * m.run + (bottom - m.flankTop) * (bottom - m.flankTop)
    m.cornerY = bottom - m.r
    m.cornerX = @_typewriterFlankAt(m, m.cornerY, 0) + m.r * m.flankLength / (bottom - m.flankTop)
    @_typewriterLineMetrics m, px
    @_typewriterKnobMetrics m
    @_typewriterLeverMetrics m, px
    @_typewriterKeyMetrics m, px
    m

  # the text lines, onto m: the first line's length -- the whole px nearest
  # the draft's with the sheet paper's parity, so it sits on its exact centre
  # across, a px of paper each side at least -- the second's, their left end
  # and their tops. Their gaps close up to fit above the carriage (to a px of
  # paper each); where they still do not, the second line drops, then the
  # first
  _typewriterLineMetrics: (m, px) ->
    {S, t} = m
    paper = m.sheetRight - m.sheetLeft - 2 * t
    length = 2 * Math.round((S * @LINE_LENGTH / @GLYPH_GRID - paper) / 2) + paper
    m.lineLength = Math.min length, paper - 2 * @MIN_CLEARANCE
    m.shortLength = Math.min px(@SHORT_LINE_LENGTH), m.lineLength - 1
    m.lineLeft = m.sheetLeft + t + (paper - m.lineLength) / 2
    m.lineTops = []
    return if m.lineLength < @MIN_LINE
    paperTop = m.top + t
    spacings = [[Math.max(@MIN_CLEARANCE, px(@LINE_TOP - @TOP) - t), Math.max(t + @MIN_CLEARANCE, px @LINE_PITCH)], [@MIN_CLEARANCE, t + @MIN_CLEARANCE]]
    for n in [@LINES..1] by -1
      for [gap, pitch] in spacings
        first = paperTop + gap
        if first + (n - 1) * pitch + t + @MIN_CLEARANCE <= m.carriageTop
          m.lineTops = (first + i * pitch for i in [0...n])
          break
      break if m.lineTops.length
    return

  # the knobs' size and shape, onto m: the whole px nearest the draft's size
  # with the carriage height's parity, so each is centred on the carriage's
  # height, and no taller than it
  _typewriterKnobSize: (m) ->
    {S, t} = m
    height = m.carriageBottom - m.carriageTop
    exact = S * @KNOB_SIZE / @GLYPH_GRID
    k = 2 * Math.round((exact - height) / 2) + height
    k += 2 while k < @MIN_KNOB
    k = Math.min k, height
    m.knob = k
    # read on the smaller of k and the knob's exact size, which k follows a px
    # either way as the carriage height's parity alternates: the knob never
    # turns back from a ring into a dot, or a dot into a square, as S grows
    least = Math.min k, exact
    m.knobIsRing = least >= @MIN_RING and k - 2 * t >= @MIN_RING_HOLE
    m.knobIsRound = least >= @MIN_ROUND_KNOB

  # the knobs' place, onto m: the left one's top-left corner (the right one
  # mirrors it), its inner wall on the carriage's end wall at the carriage's
  # middle row
  _typewriterKnobMetrics: (m) ->
    m.knobTop = m.carriageTop + (m.carriageBottom - m.carriageTop - m.knob) / 2
    m.knobLeft = m.carriageLeft + m.t - m.knob

  # the lever, onto m: its top row, the outer corner (the stub's left end and
  # the arm's left edge on that row), the arm's left edge on its last row --
  # the row on the left knob's top, centred on the knob (half a px left where
  # the parities differ) -- the arm's step a row, and the stub's right end.
  # The arm's left edge moves from the corner to that last place by the same
  # amount every row, at most a px (the corner moves right to hold that); the
  # stub reaches at least a px past the arm on the row under it, so its end
  # is free. With no row for the arm below the stub, there is no lever
  _typewriterLeverMetrics: (m, px) ->
    {t, knob, knobLeft, knobTop} = m
    top = m.top + px(@LEVER_TOP - @TOP)
    last = knobTop - 1
    m.hasLever = last - top >= t
    return unless m.hasLever
    base = knobLeft + Math.floor (knob - t) / 2
    left = Math.max m.square.left, knobLeft - px(@LEVER_OVERHANG), base - (last - top)
    step = (base - left) / (last - top)
    m.leverTop = top
    m.leverLeft = left
    m.leverBase = base
    m.leverStep = step
    m.leverEnd = Math.max left + t + 1, knobLeft + px(@LEVER_STUB), Math.ceil(left + step * t) + t + 1

  # the keys, onto m: each key's top-left corner, all k px square. The first
  # keyboard of KEY_TIERS that fits with a px of paper from the body's walls
  # and between its keys -- at the draft's pitches, else with its gaps closed
  # up to a px -- centred in the body's paper both ways (half a px up where
  # the leftover is odd), or as little below the centre as the flanks need
  _typewriterKeyMetrics: (m, px) ->
    {t, k, axis} = m
    gap = Math.max @MIN_CLEARANCE, px(@KEY_PITCH) - k
    rowGap = Math.max @MIN_CLEARANCE, px(@KEY_ROW_PITCH) - k
    paperTop = m.carriageBottom
    paperHeight = m.bottom - t - paperTop
    m.keys = []
    for [rows, n] in @KEY_TIERS
      for [across, down] in [[gap, rowGap], [@MIN_CLEARANCE, @MIN_CLEARANCE]]
        blockHeight = rows * k + (rows - 1) * down
        continue if blockHeight > paperHeight - 2 * @MIN_CLEARANCE
        left = axis - (n * k + (n - 1) * across) / 2
        lowest = paperTop + paperHeight - @MIN_CLEARANCE - blockHeight
        top = paperTop + Math.floor (paperHeight - blockHeight) / 2
        # the flanks flare out downward, so the narrowest paper by a key is on
        # the row above the first one (a wall px there touches the key's
        # corner); where it is too narrow, the keys move down a row at a time
        top++ while top <= lowest and left < @_typewriterPaperLeft(m, top - 1) + @MIN_CLEARANCE
        continue if top > lowest
        for row in [0...rows]
          for i in [0...n]
            m.keys.push [left + i * (k + across), top + row * (k + down)]
        return
    return

  # the body's first paper column at row y, left of the axis: the first pixel
  # whose centre lies right of the left flank moved t across
  _typewriterPaperLeft: (m, y) ->
    Math.ceil @_typewriterFlankAt(m, y + 0.5, m.t) - 0.5

  # the left flank at row boundary y (or a pixel centre's y), moved d inward:
  # straight down to flankTop, then out by run to the bottom ink edge
  _typewriterFlankAt: (m, y, d) ->
    out = if y > m.flankTop then m.run * (y - m.flankTop) / (m.bottom - m.flankTop) else 0
    m.bodyLeft + d - out

  # the sheet: its ink down into the carriage's top line, its paper inset by t
  # on the three sides it shows (the carriage paints over its bottom), the
  # text lines on that paper
  _typewriterSheet: (ctx, m) ->
    {t, top, sheetLeft, carriageTop} = m
    w = m.sheetRight - sheetLeft
    @_useInk ctx
    ctx.fillRect sheetLeft, top, w, carriageTop + t - top
    @_usePaper ctx
    ctx.fillRect sheetLeft + t, top + t, w - 2 * t, carriageTop - top
    @_useInk ctx
    for lineTop, i in m.lineTops
      ctx.fillRect m.lineLeft, lineTop, (if i is 0 then m.lineLength else m.shortLength), t
    return

  # the carriage: its ink stadium, then the stadium inset by t in paper, so its
  # round ends stay concentric and every wall is t
  _typewriterCarriage: (ctx, m) ->
    {t, carriageLeft, carriageTop} = m
    w = m.carriageRight - carriageLeft
    h = m.carriageBottom - carriageTop
    @_useInk ctx
    ctx.fillStadium carriageLeft, carriageTop, w, h
    @_usePaper ctx
    ctx.fillStadium carriageLeft + t, carriageTop + t, w - 2 * t, h - 2 * t

  # the body: its ink, then its paper, the outline inset by t
  _typewriterBody: (ctx, m) ->
    @_useInk ctx
    @_typewriterBodyOutline ctx, m, 0
    @_usePaper ctx
    @_typewriterBodyOutline ctx, m, m.t

  # the body's outline inset by d, filled: d = 0 is the ink silhouette, d = t
  # its paper. Every edge moves d inward: the top line and the bottom one d
  # down and up, each flank d across, so each row of a slanted wall is d wide.
  # A bottom corner is an arcTo corner (built the way fillRoundRect builds its
  # own) at radius r - d about ONE centre for both outlines, so its wall is t
  # all round: the arc is tangent to the bottom line and to the flank moved d
  # along its normal, and it leaves the flank moved d across a fraction of a
  # px from it (the across move is a little the longer). A 0 radius is a
  # square corner
  _typewriterBodyOutline: (ctx, m, d) ->
    {axis} = m
    top = m.bodyTop + d
    bottom = m.bottom - d
    bend = Math.max top, m.flankTop
    left = (y) => @_typewriterFlankAt m, y, d
    right = (y) -> 2 * axis - left y
    ctx.beginPath()
    ctx.moveTo left(top), top
    ctx.lineTo right(top), top
    ctx.lineTo right(bend), bend
    if m.r is 0
      ctx.lineTo right(bottom), bottom
      ctx.lineTo left(bottom), bottom
    else
      r = m.r - d
      rise = m.bottom - m.flankTop
      # where the arc leaves the flank: r from the centre along the flank's
      # normal; and the corner the arc rounds, where the flank through that
      # point meets the bottom line
      x = m.cornerX - r * rise / m.flankLength
      y = m.cornerY - r * m.run / m.flankLength
      corner = x - (bottom - y) * m.run / rise
      ctx.lineTo right(y), y
      ctx.lineTo 2 * axis - x, y
      ctx.arcTo 2 * axis - corner, bottom, corner, bottom, r
      ctx.arcTo corner, bottom, x, y, r
      ctx.lineTo left(y), y
    ctx.lineTo left(bend), bend
    ctx.closePath()
    ctx.fill()

  # each knob fills its k x k box: a ring -- the box's disc in paper, then
  # over it a mid-radius strokeCircle, the exact annulus [k/2 - t, k/2], so
  # its wall is t and its hole paper (the disc and the ring both cover
  # exactly their whole-px boxes, so nothing between them is left unpainted;
  # where the disc reaches the carriage's end wall, the ring inks it again) --
  # a fillCircle dot, or, under MIN_ROUND_KNOB px (an extra-small feature no
  # circle command expresses), the solid k x k square, hand-placed
  _typewriterKnobs: (ctx, m) ->
    {t, knob, knobTop} = m
    for left in [m.knobLeft, m.carriageRight - t]
      cx = left + knob / 2
      cy = knobTop + knob / 2
      if m.knobIsRing
        @_usePaper ctx
        ctx.fillCircle cx, cy, knob / 2
        @_useInk ctx
        ctx.lineWidth = t
        ctx.strokeCircle cx, cy, (knob - t) / 2
      else if m.knobIsRound
        @_useInk ctx
        ctx.fillCircle cx, cy, knob / 2
      else
        @_useInk ctx
        ctx.fillRect left, knobTop, knob, knob
    return

  # the lever: the arm, a band t across from the stub's row down to the row
  # above the knob, its two edges parallel -- each passes the pixel centres
  # of its top row at the corner and of its last row at the base, so those
  # rows ink exactly [leverLeft, + t) and [leverBase, + t) -- then the stub, t
  # tall, from the corner back to the right
  _typewriterLever: (ctx, m) ->
    return unless m.hasLever
    {t, leverLeft, leverTop, leverBase, leverStep, knobTop} = m
    @_useInk ctx
    ctx.beginPath()
    ctx.moveTo leverLeft - leverStep / 2, leverTop
    ctx.lineTo leverLeft - leverStep / 2 + t, leverTop
    ctx.lineTo leverBase + leverStep / 2 + t, knobTop
    ctx.lineTo leverBase + leverStep / 2, knobTop
    ctx.closePath()
    ctx.fill()
    ctx.fillRect leverLeft, leverTop, m.leverEnd - leverLeft, t

  # each key fills its k x k box: a fillCircle, or -- under MIN_ROUND_KEY px,
  # an extra-small feature no circle command expresses -- the solid k x k
  # square, hand-placed
  _typewriterKeys: (ctx, m) ->
    k = m.k
    @_useInk ctx
    for [x, y] in m.keys
      if k >= @MIN_ROUND_KEY
        ctx.fillCircle x + k / 2, y + k / 2, k / 2
      else
        ctx.fillRect x, y, k, k
    return
