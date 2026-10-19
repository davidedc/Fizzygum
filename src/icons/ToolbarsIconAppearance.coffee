class ToolbarsIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE super-toolbar icon in the design's style, the launcher icon of
  # the Super toolbar and its info doc's icon: the draft's "superToolbar" glyph
  # (docs/plans/redesign/desktop-canvas.html), drawn by the idiom of
  # docs/plans/pixel-icons-plan.md §5b. Line art in ink, every line on the
  # glyph line unit t (SizeAwareIconAppearance._glyphLineUnit), with paper
  # interiors and no halo envelope (the tile the icon stands on is its ground):
  #   - the COLUMN is one rounded outline, a tall box in the middle of the
  #     square;
  #   - in it, BUTTON LINES one under another, t tall;
  #   - three STARS sparkle round it: two on its left, a high one and a low
  #     one, and the biggest on its right; each one an outlined 5-point star.
  #   The column is the border idiom: its ink (fillRoundRect), then the same
  #   box inset by t in paper, its corner radius t less, so its corners stay
  #   concentric and every wall is t thick by construction, horizontal and
  #   vertical alike; the lines are fillRects of ink on that paper.
  #   A star is the border idiom for oblique edges: its ink polygon, then its
  #   paper polygon, each edge of the ink moved t px inward along the axis
  #   nearest its normal -- across for a steep edge, down for a shallow one --
  #   and the paper's vertices where the moved edges meet (_toolbarsInset).
  #   Each moved edge is its ink edge shifted a whole t px along one axis, so
  #   the non-AA backend quantises the two alike (lesson 29): every row of a
  #   steep wall and every column of a shallow one is exactly t, one connected
  #   wall all round. The draft's stars are regular 5-point stars (to the 0.1
  #   unit its vertices are written in), so each one here is the regular star
  #   at the draft's spot, span and slant. Toward its tip a paper arm narrows
  #   to nothing, and there the non-AA backend breaks it into specks of paper
  #   apart from the rest: the paper arm is cut across where it is
  #   MIN_STAR_ARM px wide, and the star's points are solid ink from there.
  #   Placement: the column is centred in S both ways (its width and height
  #   are spans of S's parity); its lines are centred in its paper both ways
  #   (half a px up where the leftover is odd). Each star is centred on the
  #   draft's spot, rounded to whole px.
  #   Clearance is a spec: a line keeps a px of paper from the column's walls
  #   and from the next line; a star keeps a px clear of the column and of the
  #   other stars, and stays inside the square -- it moves by whole px away
  #   from what it would reach, and where no whole-px spot is clear, it
  #   shrinks.
  #   Detail by rule: a corner radius under MIN_CORNER px rounds nothing on the
  #   non-AA backend, so below it the corners are square. The lines' pitch
  #   shrinks to fit the column's paper, down to its least (a px of paper
  #   between two lines); below that the bottom-most line drops, down to
  #   MIN_BUTTONS (the column grows to hold them). A star whose paper would
  #   keep less than MIN_STAR_HOLE px round its centre, or whose arms would
  #   fold back past that paper, is FILLED, its ink alone; one spanning less
  #   than MIN_STAR px drops, and the stars drop smallest first -- the low
  #   left one, then the high left one -- so the right one, the biggest, is
  #   the last kept. At these proportions: five lines from S = 17 (four
  #   below); the right star from S = 19, the high left one from 21 and the
  #   low left one from 26, each filled at first and outlined from S = 27,
  #   30 and 37.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, in GLYPH_GRID units: u units are round(S * u /
  # GLYPH_GRID) px at a glyph square of S px. The INK extents of a one-unit
  # line on the draft glyph's path (its centre line moved out by half a unit;
  # a button line's round caps reach half a unit past its ends). The column is
  # centred in S, so two opposite edges count only by their span.
  COLUMN_LEFT: 16.5     # the column's outer ink edges (path rect (17, 6) 10 x 32)
  COLUMN_RIGHT: 27.5
  COLUMN_TOP: 5.5
  COLUMN_BOTTOM: 38.5
  COLUMN_CORNER: 2.5    # its outer corner radius (path radius 2; the inner one is t less)
  BUTTONS: 5            # the button lines (path M20 11h4 M20 17h4 M20 23h4 M20 29h4 M20 35h4)
  BUTTON_LENGTH: 5      # a line's ink length (path h4, its round caps half a unit past each end)
  BUTTON_PITCH: 6       # from a line's top to the next one's
  # the stars: each a regular 5-point star, its tips on a circle and its inner vertices on a smaller
  # one, the draft's (paths A, B, C: tip radii 5.4, 6.6, 4.2 about (8, 10), (36, 18), (9, 32), inner
  # radii 0.45 of them, the first tip about 20 degrees clockwise from straight up)
  STARS: [[8, 10, 5.4], [36, 18, 6.6], [9, 32, 4.2]]   # [centre across, centre down, tip radius] on the path: the high left star, the right one, the low left one
  STAR_INNER: 0.45      # the inner vertices' radius, as a fraction of the tips'
  STAR_TILT: 20         # degrees clockwise from straight up to the first tip
  # ---- detail tiers -----------------------------------------------------------
  MIN_CORNER: 2         # px: a smaller corner radius is square
  MIN_CLEARANCE: 1      # px of paper a line keeps from the column's walls and the next line, and the clear a star keeps from the column and the other stars
  MIN_BUTTON: 1         # px: the shortest button line
  MIN_BUTTONS: 2        # the fewest button lines; the column grows to hold them
  MIN_STAR: 6           # px: the smallest star's span, across or down; a smaller one drops
  MIN_STAR_HOLE: 0.71   # px: the least paper an outlined star keeps round its centre (half a pixel's diagonal: a disc that wide always holds a pixel's centre); with less it is filled
  MIN_STAR_ARM: 1.25    # px: the narrowest a star's paper arm runs; past that the arm is solid ink to its tip (measured: from 0.75 down, an arm's tip breaks off into specks of paper at some S)

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_toolbarsMetrics x0, y0, wDev, hDev
    @_toolbarsColumn ctx, m
    @_toolbarsStar ctx, star for star in m.stars
    return

  # every measurement the icon is built from, in whole device px but for the
  # stars' vertices
  _toolbarsMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    px = (units) => Math.round S * units / @GLYPH_GRID
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    m =
      S: S
      t: t
      square: {left: x, top: y, right: x + S, bottom: y + S}
    @_toolbarsColumnMetrics m, px
    @_toolbarsButtonMetrics m, px
    @_toolbarsStarMetrics m
    m

  # the column, onto m: a box whose width and height have S's parity, so it
  # sits on the exact centre of S; at least wide enough for a MIN_BUTTON px
  # line with a px of paper each side, and tall enough for MIN_BUTTONS lines
  _toolbarsColumnMetrics: (m, px) ->
    {S, t, square} = m
    ofParity = (n) -> if (S - n) % 2 is 0 then n else n + 1
    walls = 2 * t + 2 * @MIN_CLEARANCE
    w = ofParity Math.max px(@COLUMN_RIGHT - @COLUMN_LEFT), walls + @MIN_BUTTON
    h = ofParity Math.max px(@COLUMN_BOTTOM - @COLUMN_TOP), walls + (@MIN_BUTTONS - 1) * (t + @MIN_CLEARANCE) + t
    r = px @COLUMN_CORNER
    left = square.left + (S - w) / 2
    top = square.top + (S - h) / 2
    m.column =
      left: left
      top: top
      right: left + w
      bottom: top + h
      r: if r < @MIN_CORNER then 0 else r

  # the button lines, onto m: their length -- the whole px nearest the
  # draft's with the paper's parity, so they sit on its exact centre across,
  # a px of paper each side at least -- and their tops. The pitch shrinks to
  # fit the paper with a px of it above the first line and below the last,
  # never under t + MIN_CLEARANCE; where it would, the bottom-most line drops.
  # The lines are centred down the paper, half a px up where that is odd
  _toolbarsButtonMetrics: (m, px) ->
    {S, t, column} = m
    inside = column.right - column.left - 2 * t
    length = 2 * Math.round((S * @BUTTON_LENGTH / @GLYPH_GRID - inside) / 2) + inside
    length += 2 while length < @MIN_BUTTON
    m.buttonLength = Math.min length, inside - 2 * @MIN_CLEARANCE
    m.buttonLeft = column.left + t + (inside - m.buttonLength) / 2
    down = column.bottom - column.top - 2 * t - 2 * @MIN_CLEARANCE
    least = t + @MIN_CLEARANCE
    for n in [@BUTTONS..@MIN_BUTTONS] by -1
      pitch = Math.min Math.max(least, px @BUTTON_PITCH), Math.floor (down - t) / (n - 1)
      break if pitch >= least
    first = column.top + t + @MIN_CLEARANCE + Math.floor (down - (n - 1) * pitch - t) / 2
    m.buttonTops = (first + i * pitch for i in [0...n])

  # the stars, onto m: each one's centre, size, ink polygon, and paper polygon
  # or undefined where it is filled. They are placed in their keep order, the
  # right one first: the high left one is drawn only with it, and the low left
  # one only with both
  _toolbarsStarMetrics: (m) ->
    {S, t, square, column} = m
    s = S / @GLYPH_GRID
    unit = @_toolbarsUnitStar()
    [high, right, low] = @STARS
    m.stars = []
    place = (spot, left, right, top) =>
      star = @_toolbarsPlaceStar unit, s, square, spot, left, right, top
      return undefined unless star?
      star.paper = @_toolbarsStarPaper star, t
      m.stars.push star
      star
    return unless place right, column.right + @MIN_CLEARANCE, square.right, square.top
    above = place high, square.left, column.left - @MIN_CLEARANCE, square.top
    return unless above?
    # the low left star stands a px of clear under the high one
    place low, square.left, column.left - @MIN_CLEARANCE, above.rowsEnd + @MIN_CLEARANCE
    return

  # the unit star: its ten vertices about (0, 0), each tip at radius 1 and
  # each inner vertex at STAR_INNER, the first tip STAR_TILT degrees clockwise
  # from straight up; its extents; and how far its edges stand from its
  # centre (all ten alike), by which a star grows when each edge moves out
  _toolbarsUnitStar: ->
    tilt = @STAR_TILT * Math.PI / 180
    points = for k in [0...10]
      angle = tilt - Math.PI / 2 + k * Math.PI / 5
      r = if k % 2 is 0 then 1 else @STAR_INNER
      [r * Math.cos(angle), r * Math.sin(angle)]
    [[x1, y1], [x2, y2]] = points
    xs = (x for [x, y] in points)
    ys = (y for [x, y] in points)
    points: points
    left: Math.min xs...
    right: Math.max xs...
    top: Math.min ys...
    bottom: Math.max ys...
    edge: Math.abs(x1 * y2 - y1 * x2) / Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))

  # one star's ink polygon (or undefined, dropped), at s px per unit, lighting
  # only the room's pixels -- columns left to right, rows top to the square's
  # bottom (right and bottom exclusive): the path's star with each edge moved
  # out half a unit, its centre at the draft's spot rounded to whole px, moved
  # by whole px to keep it in its room, so it keeps its pixel pattern wherever
  # it is moved to. A pixel lights where its centre is inside the polygon, so
  # the polygon may reach half a px past the room's pixels. Where no whole-px
  # centre keeps it in its room, it shrinks to leave a px of play. A star that
  # then spans less than MIN_STAR px drops
  _toolbarsPlaceStar: (unit, s, square, spot, left, right, top) ->
    [cu, cv, radius] = spot
    left -= 0.5
    right += 0.5
    top -= 0.5
    bottom = square.bottom + 0.5
    # the whole-px centres keeping a star of radius r in the room, across or down
    least = (r, lo, unitLo) -> Math.ceil lo - r * unitLo
    most = (r, hi, unitHi) -> Math.floor hi - r * unitHi
    r = s * (radius + 0.5 / unit.edge)
    unless least(r, left, unit.left) <= most(r, right, unit.right) and least(r, top, unit.top) <= most(r, bottom, unit.bottom)
      r = Math.min r, (right - left - 1) / (unit.right - unit.left), (bottom - top - 1) / (unit.bottom - unit.top)
    return undefined if r * Math.max(unit.right - unit.left, unit.bottom - unit.top) < @MIN_STAR
    cx = Math.max least(r, left, unit.left), Math.min most(r, right, unit.right), square.left + Math.round s * cu
    cy = Math.max least(r, top, unit.top), Math.min most(r, bottom, unit.bottom), square.top + Math.round s * cv
    cx: cx
    cy: cy
    r: r
    # the first row under it that it cannot light
    rowsEnd: Math.ceil cy + r * unit.bottom - 0.5
    ink: ([cx + r * x, cy + r * y] for [x, y] in unit.points)

  # a star's paper polygon: its ink inset by t (_toolbarsInset), each arm cut
  # across where it narrows under MIN_STAR_ARM px -- past that the arm is
  # solid ink to its tip -- and an arm narrower than that where it leaves the
  # pentagon of inner vertices dropped whole. Undefined (the star is filled)
  # where the paper would keep less than MIN_STAR_HOLE px round the centre --
  # the distance from it to the nearest side of that pentagon -- or an arm
  # has folded back past the pentagon
  _toolbarsStarPaper: (star, t) ->
    inner = @_toolbarsInset star.ink, star.cx, star.cy, t
    paper = []
    for i in [1...10] by 2
      [x1, y1] = inner[i]
      [tx, ty] = inner[(i + 1) % 10]
      [x2, y2] = inner[(i + 2) % 10]
      side = Math.sqrt (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)
      # signed: positive where the centre, and the arm's tip, stand on the
      # sides of that pentagon side the ink star's do
      hole = ((x2 - x1) * (star.cy - y1) - (y2 - y1) * (star.cx - x1)) / side
      reach = ((x2 - x1) * (ty - y1) - (y2 - y1) * (tx - x1)) / side
      return undefined unless hole >= @MIN_STAR_HOLE and reach < 0
      paper.push [x1, y1]
      # the arm, a triangle on that side, is f of the side wide at f of the
      # way from its tip
      f = @MIN_STAR_ARM / side
      if f < 1
        paper.push [tx + f * (x1 - tx), ty + f * (y1 - ty)], [tx + f * (x2 - tx), ty + f * (y2 - ty)]
    paper

  # the polygon points with each edge moved t px inward along the axis
  # nearest its normal -- across where the edge is steep, down where it is
  # shallow -- and its vertices where the moved edges meet. A moved edge is
  # its edge shifted a whole t px along one axis, so the non-AA backend
  # quantises the two alike: every row of a steep wall between them, and
  # every column of a shallow one, is exactly t px
  _toolbarsInset: (points, cx, cy, t) ->
    n = points.length
    lines = for [x1, y1], i in points
      [x2, y2] = points[(i + 1) % n]
      dx = x2 - x1
      dy = y2 - y1
      # the inward normal: the side of the edge the centre lies on
      inward = if (cx - x1) * -dy + (cy - y1) * dx > 0 then 1 else -1
      if Math.abs(dy) >= Math.abs(dx)
        [x1 + t * inward * Math.sign(-dy), y1, dx, dy]
      else
        [x1, y1 + t * inward * Math.sign(dx), dx, dy]
    for i in [0...n]
      [px1, py1, dx1, dy1] = lines[(i + n - 1) % n]
      [px2, py2, dx2, dy2] = lines[i]
      a = ((px2 - px1) * dy2 - (py2 - py1) * dx2) / (dx1 * dy2 - dy1 * dx2)
      [px1 + a * dx1, py1 + a * dy1]

  # the column: its ink, then its paper inset by t (the corner radius t less,
  # so its corners stay concentric), then each button line, a t-tall bar of
  # ink on that paper
  _toolbarsColumn: (ctx, m) ->
    {t, column} = m
    w = column.right - column.left
    h = column.bottom - column.top
    @_useInk ctx
    ctx.fillRoundRect column.left, column.top, w, h, column.r
    @_usePaper ctx
    ctx.fillRoundRect column.left + t, column.top + t, w - 2 * t, h - 2 * t, Math.max 0, column.r - t
    @_useInk ctx
    for top in m.buttonTops
      ctx.fillRect m.buttonLeft, top, m.buttonLength, t
    return

  # a star: its ink polygon, then its paper polygon over it where it has one
  _toolbarsStar: (ctx, star) ->
    @_useInk ctx
    @_toolbarsPolygon ctx, star.ink
    return unless star.paper?
    @_usePaper ctx
    @_toolbarsPolygon ctx, star.paper

  # one closed polygon through points, filled
  _toolbarsPolygon: (ctx, points) ->
    ctx.beginPath()
    for [x, y], i in points
      if i is 0 then ctx.moveTo x, y else ctx.lineTo x, y
    ctx.closePath()
    ctx.fill()
