# The USEFUL SNIPPETS tool's face: ONE PAGE WITH A HEART -- the snippets
# window (TemplatesWindowWdgt) is a page of useful ready-made pieces to drag
# into a document. Drawn as a SIZE-AWARE icon in the text toolbar's
# style (docs/architecture/visual-design-system.md §4.6), worn by the Docs
# Maker's TemplatesButtonWdgt (the whole 44 x 44 tool cell, its 24 px
# picture on the toolbar's overflow menu, and the info doc's 50 px cell),
# the Super toolbar's UsefulTextSnippetsToolbarCreatorButtonWdgt and the
# demo TemplatesIconWdgt.
#   INK ONLY (a tool cell's plate shows through), on ONE LINE t: LINE grid
# units of the square (SizeAwareIconAppearance._controlGlyphLine, 2 units:
# 2 px in the 44 cell, 4 at dpr 2, 1 in the 24 px picture), every part a
# fill:
#   - THE PAGE: a portrait sheet PAGE_W x PAGE_H units (spans of S's parity,
#     centred by whole px), its corners rounded at the family page's
#     PAGE_CORNER (square under PAGE_MIN_CORNER px, never under t), its top
#     right corner FOLDED: the family page's 45-degree chamfer, FOLD_CUT
#     units off the top wall and the right wall, its edges half a px off the
#     pixel diagonals. The sheet is an ink RING -- its outline and the same
#     outline inset t, one even-odd fill -- so every wall is t, the slanted
#     one included. The FLAP (the folded-over corner) is an L of two t lines
#     abutting the ring's inner edges, so no px is painted twice; it is drawn
#     from FLAP_MIN_SIZE, where it keeps MIN_FLAP_CLEAR px of clear along each
#     leg at every larger size (below, the corner is a plain cut).
#     It is not SizeAwareIconAppearance._page: that page has a PAPER
#     interior (which would show as a patch on a cell's plate), its own
#     proportions, and a fold kept above the square's middle half, where the
#     object frame lays its picture.
#   - THE HEART, FILLED: two LOBES (circles of radius LOBE x a, centred a
#     either side of the page's axis on one row) and two 45-degree FLANKS
#     tangent to them, meeting in the TIP on the axis -- ONE polygon whose
#     lobe boundaries are sampled on the ROW CENTRES (the rows the backend
#     fills by), its left half the exact mirror of its right (2 cx - x), so
#     the heart is mirror-exact at every size. No pixel centre ties an edge:
#     a lobe sample landing on one moves 1/64 px into the heart, and the
#     flanks x +/- y = c run with c a half-integer.
#   SIZE: the widest heart up to HEART_W units across, an eighth of a px at a
# time, whose ink fits the ROOM inside the page with at least 1 px of clear
# on every side (below the flap; diagonals included) AND whose top row shows
# the NOTCH (the cleft between the lobes: without it a small heart reads as
# a shield). Centred across on the page's axis, down by whole px in the room
# (lifted HEART_RAISE units).
#   DETAIL BY RULE: the heart from HEART_MIN_SIZE (the smallest square from
# which every larger one fits a notched heart), never narrower than
# HEART_MIN px; below, the page alone; below MIN_SIZE px nothing.
#   Proportions are in GLYPH_GRID units of the square the icon paints in
# (one unit is one px in the 44 cell).

class TemplatesIconAppearance extends SizeAwareIconAppearance

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  LINE: 2               # the line, in grid units (see the header)
  PAGE_W: 16            # the page (units)
  PAGE_H: 20
  FOLD_CUT: 6           # what the fold's chamfer cuts off the top wall and the right wall (units)
  MIN_FLAP_CLEAR: 1     # px of clear the flap's triangle keeps along each leg, or no flap
  FLAP_MIN_SIZE: 37     # S: no flap below it (see the header)
  HEART_W: 9            # the heart's width across its lobes (units)
  LOBE: 1.05            # a lobe's radius over its centre's distance from the axis (sqrt 2 = the
                        # square-and-two-semicircles heart, whose cleft is too shallow to survive a
                        # small size; 1 = two circles touching on the axis)
  HEART_MIN: 4          # px: a narrower heart is not drawn
  HEART_MIN_SIZE: 23    # S: no heart below it (see the header)
  HEART_RAISE: 0        # units: lift the heart above the room's centre
  MIN_SIZE: 12

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < @MIN_SIZE
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    m = @_heartPageMetrics S
    @_useInk ctx
    @_foldedPage ctx, x, y, m
    return unless m.heart?
    ctx.beginPath()
    @_addClockwisePolygonSubpath ctx, x, y, m.heart.outline.points
    ctx.fill()

  # THE GEOMETRY in a glyph square of S px, relative to its top-left corner:
  # the line t, the page [L, T, W, H] and its corner radius r, its axis cx,
  # the fold, the ROOM left for the heart (inclusive-exclusive px bounds,
  # at least 1 px clear of every wall and of the flap), and the heart
  # (undefined where none is drawn)
  _heartPageMetrics: (S) ->
    px = (units) => Math.round S * units / @GLYPH_GRID
    # a span of S's parity: the rounded span, a px longer where that has the other parity
    span = (units) ->
      n = px units
      n++ if (S - n) % 2 isnt 0
      n
    t = @_controlGlyphLine S, @LINE / @GLYPH_GRID
    W = span @PAGE_W
    H = span @PAGE_H
    L = Math.floor (S - W) / 2
    T = Math.floor (S - H) / 2
    r = px @PAGE_CORNER
    r = if r < @PAGE_MIN_CORNER then 0 else Math.max r, t
    cx = L + W / 2
    # the fold: the chamfer's two ends (half a px along the walls it cuts),
    # and the flap's L -- its vertical line's columns [flapX, flapX + t)
    # hanging from the top wall, its horizontal line's rows [flapY, flapY + t)
    # meeting the right wall
    cut = Math.max 1, Math.floor S * @FOLD_CUT / @GLYPH_GRID
    fold =
      cut: cut
      chamferX: L + W - cut - 0.5
      chamferY: T + cut + 0.5
      flapX: L + W - cut - t
      flapY: T + cut
      hasFlap: S >= @FLAP_MIN_SIZE and cut - 2 * t >= @MIN_FLAP_CLEAR
    roomTop = (if fold.hasFlap then fold.flapY + t else T + cut + 1) + 1
    room = {L: L + t + 1, R: L + W - t - 1, T: roomTop, B: T + H - t - 1}
    heart = if S >= @HEART_MIN_SIZE then @_heartInRoom S, cx, room else undefined
    {S, t, W, H, L, T, r, cx, fold, room, heart}

  # the widest heart that fits the room and shows its notch, from HEART_W
  # units down an eighth of a px at a time, or undefined when none does
  _heartInRoom: (S, cx, room) ->
    raise = Math.round S * @HEART_RAISE / @GLYPH_GRID
    width = Math.round S * @HEART_W / @GLYPH_GRID
    while width >= @HEART_MIN
      heart = @_heartOfWidth width, cx, room, raise
      return heart if heart?
      width -= 0.125
    undefined

  # the heart `width` px across its lobes on the axis cx, moved down by whole
  # px to the room's centre (raised `raise` px), as {box, outline}: its ink
  # box and its outline (_heartOutline); undefined where it does not fit the
  # room or shows no notch
  _heartOfWidth: (width, cx, room, raise) ->
    a = width / (2 * (1 + @LOBE))
    R = a * @LOBE
    # provisional: the lobes' top at y 0; then the flank (tangent to the
    # lobe, at R from its centre) onto a half-integer c, the lobes with it
    cyL = R
    c0 = cx + cyL + a + R * Math.SQRT2
    c = Math.floor(c0) + 0.5
    cyL += c - c0
    outline = @_heartOutline cx, cyL, a, R, c
    return undefined unless outline?
    box = @_heartInkBox outline.rows
    return undefined unless box?
    return undefined if box.L < room.L or box.R > room.R or box.B - box.T > room.B - room.T
    return undefined unless @_heartHasNotch outline
    dy = room.T + Math.floor((room.B - room.T - (box.B - box.T)) / 2) - raise - box.T
    dy = Math.max room.T - box.T, Math.min dy, room.B - box.B
    box: {L: box.L, R: box.R, T: box.T + dy, B: box.B + dy}
    outline: @_heartOutline cx, cyL + dy, a, R, c + dy

  # a heart's outline on the axis cx: lobes of radius R centred a either side
  # of it on row cyL, flanks x + y = c (right) and x - y = 2 cx - c (left),
  # as {points, rows}: the polygon (the lobes sampled on the row centres) and
  # the ink it fills, per device row [row centre, [[first, end), ...]] (a px
  # inks where its centre lies inside). Where the lobes do not meet above
  # their centres' row, the cleft is that row. Undefined where no row centre
  # crosses a lobe.
  _heartOutline: (cx, cyL, a, R, c) ->
    return undefined unless R > 0
    cxR = cx + a
    yCleft = if R > a then cyL - Math.sqrt(R * R - a * a) else cyL
    top = cyL - R
    yTan = cyL + R * Math.SQRT1_2
    tipY = c - cx
    # a sample landing on a pixel centre moves 1/64 px into the heart
    nudgeIn = (x, isLeftEdge) ->
      f = x - Math.floor x
      if Math.abs(f - 0.5) < 1e-9 then x + (if isLeftEdge then 1 / 64 else -1 / 64) else x
    halfChord = (yc) -> Math.sqrt Math.max 0, R * R - (yc - cyL) * (yc - cyL)
    innerRows = []   # the right lobe's inner side, from the cleft upward
    yc = Math.ceil(yCleft - 0.5) - 0.5
    while yc > top
      innerRows.push yc if yc < yCleft
      yc -= 1
    outerRows = []   # its outer side, from the top downward
    yc = Math.floor(top + 0.5) + 0.5
    while yc < yTan
      outerRows.push yc if yc > top
      yc += 1
    return undefined if outerRows.length is 0
    right = [[cx, yCleft]]
    right.push [(nudgeIn cxR - halfChord(row), true), row] for row in innerRows
    right.push [cxR, top]
    right.push [(nudgeIn cxR + halfChord(row), false), row] for row in outerRows
    right.push [cxR + R * Math.SQRT1_2, yTan]
    right.push [cx, tipY]
    left = ([2 * cx - x, y] for [x, y] in right.slice(1, -1).reverse())
    # the ink rows, predicted from the same numbers
    inkOf = (xl, xr) -> [Math.ceil(xl - 0.5), Math.ceil(xr - 0.5)]
    rows = []
    yc = Math.floor(top + 0.5) + 0.5
    while yc < tipY
      if yc > top
        if yc < yTan
          chord = halfChord yc
          xr = nudgeIn cxR + chord, false
          if yc < yCleft
            # above the cleft: two lobes, mirrored
            xl = nudgeIn cxR - chord, true
            rows.push [yc, [inkOf(2 * cx - xr, 2 * cx - xl), inkOf(xl, xr)]]
          else
            rows.push [yc, [inkOf(2 * cx - xr, xr)]]
        else
          xr = c - yc
          rows.push [yc, [inkOf(2 * cx - xr, xr)]]
      yc += 1
    {points: right.concat(left), rows}

  # the ink box {L, R, T, B} of a heart's rows (R and B exclusive), or
  # undefined where they ink nothing
  _heartInkBox: (rows) ->
    L = Infinity
    R = -Infinity
    T = Infinity
    B = -Infinity
    for [yc, intervals] in rows
      for [first, end] in intervals when end > first
        L = Math.min L, first
        R = Math.max R, end
        T = Math.min T, yc - 0.5
        B = Math.max B, yc + 0.5
    return undefined if L is Infinity
    {L, R, T, B}

  # THE NOTCH: the heart's top ink row is two runs with at least 1 px of
  # clear between them (across the axis)
  _heartHasNotch: (outline) ->
    topRow = outline.rows.find (row) -> row[1].some ([first, end]) -> end > first
    return false unless topRow?
    runs = topRow[1].filter ([first, end]) -> end > first
    runs.length is 2 and runs[1][0] - runs[0][1] >= 1

  # the page: its outline and the same outline inset t, one even-odd fill
  # (an ink ring), then the flap's L abutting the ring's inner edges
  _foldedPage: (ctx, x, y, m) ->
    {t, fold} = m
    ctx.beginPath()
    @_foldedPageOutline ctx, x, y, m, 0
    @_foldedPageOutline ctx, x, y, m, t
    ctx.fill "evenodd"
    return unless fold.hasFlap
    flapX = x + fold.flapX
    flapY = y + fold.flapY
    top = y + m.T
    right = x + m.L + m.W
    ctx.beginPath()
    ctx.rect flapX, top + t, t, flapY - top
    ctx.rect flapX + t, flapY, right - t - flapX - t, t
    ctx.fill()

  # the folded sheet's outline inset by d, as one more subpath: the chamfer
  # keeps its two ends' coordinates, so its inset copy is the edge moved d
  # down (and, at 45 degrees, d to the left); each rounded corner turns about
  # ONE centre (radius r - d)
  _foldedPageOutline: (ctx, x, y, m, d) ->
    left = x + m.L + d
    top = y + m.T + d
    right = x + m.L + m.W - d
    bottom = y + m.T + m.H - d
    r = Math.max 0, m.r - d
    chamferX = x + m.fold.chamferX
    chamferY = y + m.fold.chamferY
    ctx.moveTo left + r, top
    ctx.lineTo chamferX, top
    ctx.lineTo right, chamferY
    ctx.arcTo right, bottom, left, bottom, r
    ctx.arcTo left, bottom, left, top, r
    ctx.arcTo left, top, chamferX, top, r
    ctx.closePath()
