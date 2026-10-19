class DashboardsIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE dashboards icon in the design's style, the launcher icon of the
  # Dashboards maker, the Examples folder's "Dashboard" opener and a
  # dashboard's shortcut icon: the draft's "dashboards" charts
  # (docs/plans/redesign/desktop-canvas.html) on the family's card, drawn by
  # the idiom of docs/plans/pixel-icons-plan.md §5b. Line art in ink, every
  # line on the glyph line unit t (SizeAwareIconAppearance._glyphLineUnit),
  # with paper interiors and no halo envelope (the tile the icon stands on is
  # its ground):
  #   - the CARD is the design's content card (SizeAwareIconAppearance.
  #     _contentCard): one rounded outline, its four walls t thick;
  #   - inside it, one chart in each QUARTER of its paper, with no line
  #     between them:
  #       - top-left, a SCATTER of four dots;
  #       - top-right, a LINE CHART: a zigzag of three segments, rising, dipping
  #         and rising again;
  #       - bottom-left, a BAR CHART: three solid bars on one baseline, the
  #         middle one the tallest;
  #       - bottom-right, a PIE: a ring whose quarter from 12 to 3 o'clock is
  #         filled.
  #   The quarters: the card's paper split at its middle both ways, each
  # chart's ROOM a quarter less PAD px of paper all round -- from the card's
  # walls and from the paper's middle lines. The rooms stand ONE gutter apart
  # across and down, 2 PAD px (a px more where the paper's span is odd: its
  # middle column or row belongs to no room), and are measured on the card's
  # spans as rounded, before the px the card takes to share S's parity: those
  # spans never shrink as S grows, so neither do the rooms (but where t or PAD
  # steps up), and the tiers below cannot flicker with the card's parity. The
  # paper left over goes equally to the margins between the rooms and the
  # walls, so the four sit symmetric about the card's middle. Each chart is
  # centred in its room (half a px left or up where a span is odd), stepped a
  # px at a time toward the card's middle where it would reach a corner arc
  # (_dashboardPlace); the scatter's dots stretch over their room, less
  # SCATTER_INSET across each side, so the lowest-left dot keeps PAD +
  # SCATTER_INSET px of paper from the card's left wall.
  #   The charts, every line t:
  #   - a dot is a fillCircle from MIN_ROUND_DOT px across, a hand-placed square
  #     below it (the non-AA backend draws a 2 px circle as one row of 2 and a
  #     3 px one as a plus), all four one size. The dots are two pairs, each a
  #     lower dot and an upper one up and right of it; they sit at the draft's
  #     spots stretched over the room (less SCATTER_INSET across), moved apart
  #     only as far as a px of paper between each two needs: the right pair's
  #     lower dot a px right of the left pair, and in each pair the upper dot a
  #     px above the lower one and a px right of it;
  #   - the zigzag is the polyline swept t px to the RIGHT, each segment one
  #     filled band (a fill, never a round-capped stroke: the non-AA backend
  #     leaves the overlap of two round caps in one stroke unpainted). The two
  #     edges of a band are parallel at an integer offset, which the non-AA
  #     backend quantises identically (lesson 29), so every row of a segment is
  #     exactly t wide; two bands meeting at a joint share its row, so the line
  #     runs on unbroken. Each segment's run and rise are the draft's, rounded
  #     to whole px each (the middle one stays at 45 degrees);
  #   - a bar is a solid block BAR_WIDTH_IN_LINES line units wide (2t: the
  #     owner's choice for the Slides bars), every bar a px of paper from the
  #     next;
  #   - the pie's ring is a mid-radius strokeCircle -- the exact annulus [k/2 -
  #     t, k/2], so its wall is t -- and its filled quarter a wedge out to the
  #     ring's middle line, so the two close with no paper between them, while
  #     the other three quarters of the ring keep their paper. The ring is k px
  #     across with k even, so its centre is a pixel corner.
  #   Clearance is a spec: every chart keeps PAD px of paper (at least
  # MIN_CLEARANCE) from the card's walls and from the paper's middle lines,
  # keeps clear of the card's corner arcs (_dashboardClearOfArcs), and its own
  # parts keep a px of paper from each other.
  #   Detail by rule, each chart degrading by dropping members, never by
  # crowding or flattening them: the scatter loses dots (SCATTER_TIERS: all
  # four, then three, then the two outermost) where its dots cannot keep their
  # px of paper in its room, or a pair's upper dot would stand no further right
  # than its lower one (the scatter keeps its rise); the zigzag shrinks to fit
  # its room, and loses its first segment where a segment would be left with
  # less than MIN_SEGMENT px of run or of rise (a smaller dip merges into the
  # rows beside it and does not show); the chart loses its right bar where
  # three bars do not fit across or their heights cannot keep the draft's
  # order, each bar taller than it is wide; the pie is a ring only when it is
  # at least MIN_RING px across and its hole keeps MIN_RING_HOLE px (the ring
  # gate of PatchProgrammingIconAppearance's node), else a solid dot; a pie
  # that cannot stand clear of a corner arc shrinks by 2 px at a time.
  #   EMPTY below the size the four charts fit in together: where any chart is
  # left with nothing to draw, none is drawn -- the card stands empty, its
  # outline and its paper (one-pixel members that cannot coexist drop
  # together, lesson 25). At these proportions the charts are drawn from
  # S = 28, with four dots and three segments from there; two bars up to
  # S = 29, three from 30; the pie a solid dot up to S = 30, a ring from 31.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, in GLYPH_GRID units: u units are round(S * u /
  # GLYPH_GRID) px at a glyph square of S px; the card's are the base's
  # CONTENT_CARD_*. The charts are the draft's, each measured from the middle
  # of its draft tile (path rects (3, 3), (24, 3), (3, 24) and (24, 24), 17 x
  # 17, their middles (11.5, 11.5), (32.5, 11.5), (11.5, 32.5) and (32.5,
  # 32.5)) and drawn in its room: the line chart, the bars and the pie at the
  # draft's scale, centred, shrunk to fit where the room cannot hold them; the
  # scatter's spots in their proportions, stretched over the room less
  # SCATTER_INSET across.
  PAD: 1                    # the paper between a chart's room and the card's walls, and between the room and the paper's middle lines
  # the scatter: each dot's centre from its tile's middle (path circles (7.5, 15), (10.5, 10.5),
  # (13, 13.5) and (15.5, 7.5) r 1.5), left to right: the left pair's lower and upper dot, the right
  # pair's lower and upper dot
  SCATTER_DOTS: [[-4, 3.5], [-1, -1], [1.5, 2], [4, -4]]
  DOT: 3                    # a dot's size, across (path r 1.5)
  SCATTER_INSET: 1          # the paper the scatter keeps inside its room across, each side: its lowest-left dot stands PAD + SCATTER_INSET from the card's left wall
  # the line chart: each segment's run across and rise (up positive), left to right (path M27 16l4-5 3 3 4-6)
  ZIGZAG_STEPS: [[4, 5], [3, -3], [4, 6]]
  # the bar chart: each bar's ink height, left to right (path M8 37v-4 M11.5 37v-8 M15 37v-6 at width
  # 2.5, each round cap 1.25 units past its end)
  BAR_HEIGHTS: [6.5, 10.5, 8.5]
  BAR_PITCH: 3.5            # from a bar's left edge to the next one's (path x 8, 11.5 and 15)
  PIE_SIZE: 11              # the ring's outer ink size, across (path circle (32.5, 32.5) r 5; the wedge reaches that path radius, the ring's middle line)
  # ---- in line units t --------------------------------------------------------
  BAR_WIDTH_IN_LINES: 2     # a bar's width in line units: a solid block two lines wide (the owner's choice for the Slides bars)
  # ---- detail tiers -----------------------------------------------------------
  MIN_CLEARANCE: 1          # px: the least PAD, and the paper each part of a chart keeps from the next
  MIN_DOT: 2                # px: the smallest dot, across
  MIN_ROUND_DOT: 4          # px: the smallest dot drawn round; a smaller one is a square
  MIN_RING: 6               # px: the smallest pie drawn as a ring, across ...
  MIN_RING_HOLE: 2          # px: ... and the smallest hole a ring keeps; a smaller pie is a solid dot
  MIN_SEGMENT: 2            # px: the least run and rise of a zigzag segment (a 1 px rise merges into its neighbours' rows: the dip does not show)
  # which dots each scatter keeps (indices into SCATTER_DOTS): all four, then all but
  # the left pair's upper dot, then the two outermost
  SCATTER_TIERS: [[0, 1, 2, 3], [0, 2, 3], [0, 3]]
  # the pairs of dots set a px of paper apart by construction, as [first, second, axis]:
  # the second stands at least k + 1 px past the first along the axis (0 across, 1
  # down) -- the right pair's lower dot right of both dots of the left pair, and in
  # each pair the lower dot under the upper one
  SCATTER_APART: [[1, 2, 0], [0, 2, 0], [1, 0, 1], [3, 2, 1]]
  # which segments each zigzag keeps (indices into ZIGZAG_STEPS): all three, then the
  # dip and the last rise
  ZIGZAG_TIERS: [[0, 1, 2], [1, 2]]
  # which bars each chart keeps (indices into BAR_HEIGHTS): all three, then the left two
  BAR_TIERS: [[0, 1, 2], [0, 1]]

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_dashboardMetrics x0, y0, wDev, hDev
    @_contentCard ctx, m.card
    return unless m.hasCharts
    @_dashboardScatter ctx, m
    @_dashboardLineChart ctx, m
    @_dashboardBars ctx, m
    @_dashboardPie ctx, m

  # every measurement the icon is built from, in whole device px
  _dashboardMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    s = S / @GLYPH_GRID   # px per draft unit
    card = @_contentCardMetrics x0 + Math.floor((wDev - S) / 2), y0 + Math.floor((hDev - S) / 2), S, t
    pad = Math.max @MIN_CLEARANCE, Math.round S * @PAD / @GLYPH_GRID
    # the card's paper, across and down, and each room in it: a quarter less
    # pad all round. A room is measured on the card's spans as rounded,
    # before the px the card takes to share S's parity -- those spans never
    # shrink as S grows, so neither do the rooms (but where t or pad steps
    # up). The rooms stand one gutter apart, 2 pad px, a px more where the
    # paper's span is odd (its middle column or row in no room), and the
    # paper left over goes equally to the margins between them and the walls:
    # the four sit symmetric about the card's middle
    across = card.right - card.left - 2 * t
    down = card.bottom - card.top - 2 * t
    w = Math.floor (Math.round(S * (@CONTENT_CARD_RIGHT - @CONTENT_CARD_LEFT) / @GLYPH_GRID) - 2 * t - 4 * pad) / 2
    h = Math.floor (Math.round(S * (@CONTENT_CARD_BOTTOM - @CONTENT_CARD_TOP) / @GLYPH_GRID) - 2 * t - 4 * pad) / 2
    marginX = Math.floor (across - 2 * w - 2 * pad) / 2
    marginY = Math.floor (down - 2 * h - 2 * pad) / 2
    m =
      t: t
      card: card
      pad: pad
      rooms: []
    for row in [0, 1]
      for col in [0, 1]
        m.rooms.push
          left: card.left + t + marginX + col * (across - 2 * marginX - w)
          top: card.top + t + marginY + row * (down - 2 * marginY - h)
          w: w
          h: h
    @_dashboardScatterMetrics m, s
    @_dashboardLineMetrics m, s
    @_dashboardBarMetrics m, s
    @_dashboardPieMetrics m, S
    m.hasCharts = m.scatter? and m.line? and m.bars? and m.pie?
    m

  # the scatter, onto m (or undefined, with no room for its fewest dots): the
  # dots' size k and their top-left corners. Each dot starts at its draft spot
  # stretched over its range -- the room, less SCATTER_INSET each side across:
  # across and down, the dots keep the draft's proportions, the outermost two
  # on the range's edges. Each pair in SCATTER_APART then moves apart, half
  # the shortfall each, until a px of paper parts them; the dots go into the
  # range (clamped as k x k boxes, not as centres -- a centre clamp lets a box
  # escape by k / 2), a partner following where it must; the first tier whose
  # every two dots keep a px of paper between them, across or down, that keeps
  # its rise and stays clear of the card's corner arcs, is drawn
  _dashboardScatterMetrics: (m, s) ->
    room = m.rooms[0]
    k = Math.max @MIN_DOT, Math.round s * @DOT
    # the range of a dot's top-left corner, across and down: across, the room
    # less SCATTER_INSET each side, so the outermost dots keep that much more
    # paper than the room's from the card's left wall and from the gutter
    inset = Math.max @MIN_CLEARANCE, Math.round s * @SCATTER_INSET
    lo = [room.left + inset, room.top]
    hi = [room.left + room.w - inset - k, room.top + room.h - k]
    ideal = ([] for i in @SCATTER_DOTS)
    for axis in [0, 1]
      units = (spot[axis] for spot in @SCATTER_DOTS)
      least = Math.min units...
      most = Math.max units...
      ideal[i][axis] = lo[axis] + Math.round (u - least) / (most - least) * (hi[axis] - lo[axis]) for u, i in units
    for keep in @SCATTER_TIERS
      at = @_dashboardSpreadDots m, ideal, keep, k, lo, hi
      if at?
        m.scatter =
          k: k
          dots: (at[i] for i in keep)
        return
    return

  # the kept dots' top-left corners spread apart and put into the room (lo and
  # hi bound them, across and down); undefined where two of them cannot keep a
  # px of paper between them there, a pair's upper dot would stand no further
  # right than its lower one, or a dot would reach a corner arc
  _dashboardSpreadDots: (m, ideal, keep, k, lo, hi) ->
    return undefined if hi[0] < lo[0] or hi[1] < lo[1]
    at = {}
    at[i] = ideal[i].slice() for i in keep
    # [first, second, axis, least]: the second stands at least least px past
    # the first -- a px of paper between the pairs SCATTER_APART names, and
    # the rise: in each pair the upper dot a px right of the lower one
    pairs = ([a, b, axis, k + 1] for [a, b, axis] in @SCATTER_APART when at[a]? and at[b]?)
    pairs = pairs.concat([b, a, 0, 1] for [a, b, axis] in pairs when axis is 1)
    for [a, b, axis, least] in pairs
      short = at[a][axis] + least - at[b][axis]
      if short > 0
        at[a][axis] -= short >> 1
        at[b][axis] += short - (short >> 1)
    for [a, b, axis, least] in pairs
      if at[a][axis] < lo[axis]
        at[a][axis] = lo[axis]
        at[b][axis] = Math.max at[b][axis], lo[axis] + least
      if at[b][axis] > hi[axis]
        at[b][axis] = hi[axis]
        at[a][axis] = Math.min at[a][axis], hi[axis] - least
    for i in keep
      at[i] = (Math.min(hi[axis], Math.max(lo[axis], v)) for v, axis in at[i])
    for i in keep
      for j in keep when j > i
        return undefined if Math.max(Math.abs(at[i][0] - at[j][0]), Math.abs(at[i][1] - at[j][1])) < k + 1
    for [a, b, axis, least] in pairs when least is 1
      return undefined unless at[b][0] > at[a][0]
    for i in keep
      return undefined unless @_dashboardClearOfArcs m, at[i][0], at[i][1], k, k
    at

  # whether a w x h box at (x, y) keeps a px of paper from the card's corner
  # arcs: at each corner, the pixel diagonally past the box's corner nearest it
  # lies inside the paper's arc (its centre nearer the arc's centre than the
  # paper's radius, less a quarter px for the backend's rounding) wherever it
  # is past that centre both ways. The rooms already keep a px from the
  # straight walls
  _dashboardClearOfArcs: (m, x, y, w, h) ->
    {card, t} = m
    inner = card.r - t
    return true if inner <= 0
    for [sx, sy] in [[-1, -1], [1, -1], [-1, 1], [1, 1]]
      # this corner's arc centre
      ax = if sx > 0 then card.right - card.r else card.left + card.r
      ay = if sy > 0 then card.bottom - card.r else card.top + card.r
      dx = sx * ((if sx > 0 then x + w else x - 1) + 0.5 - ax)
      dy = sy * ((if sy > 0 then y + h else y - 1) + 0.5 - ay)
      return false if dx > 0 and dy > 0 and dx * dx + dy * dy > (inner - 0.25) * (inner - 0.25)
    true

  # the top-left corner of a w x h box in room: centred (half a px left or up
  # where a span is odd), then moved toward the card's middle a px at a time,
  # across and down in turn as the room allows, while it would reach a corner
  # arc; undefined where the room cannot hold it clear of the arcs
  _dashboardPlace: (m, room, w, h) ->
    return undefined if w > room.w or h > room.h
    left = room.left + Math.floor (room.w - w) / 2
    top = room.top + Math.floor (room.h - h) / 2
    dx = if 2 * room.left + room.w < m.card.left + m.card.right then 1 else -1
    dy = if 2 * room.top + room.h < m.card.top + m.card.bottom then 1 else -1
    across = true
    until @_dashboardClearOfArcs m, left, top, w, h
      canAcross = room.left <= left + dx and left + dx + w <= room.left + room.w
      canDown = room.top <= top + dy and top + dy + h <= room.top + room.h
      return undefined unless canAcross or canDown
      if canAcross and (across or not canDown) then left += dx else top += dy
      across = not across
    [left, top]

  # the line chart, onto m (or undefined): its vertices, left to right. The
  # segments are the draft's, each run and rise scaled and rounded to whole
  # px; the scale shrinks (half a px of the whole run at a time) until the
  # line, swept t to the right, fits the room clear of the corner arcs
  # (_dashboardPlace). The first tier whose every segment keeps MIN_SEGMENT px
  # of run and of rise is drawn
  _dashboardLineMetrics: (m, s) ->
    {t} = m
    room = m.rooms[1]
    for keep in @ZIGZAG_TIERS
      steps = (@ZIGZAG_STEPS[i] for i in keep)
      units = 0
      units += run for [run, rise] in steps
      scale = s
      loop
        points = [[0, 0]]
        for [run, rise] in steps
          [x, y] = points[points.length - 1]
          dy = Math.round(Math.abs(rise) * scale)
          points.push [x + Math.round(run * scale), (if rise > 0 then y - dy else y + dy)]
        width = points[points.length - 1][0] + t
        ys = (y for [x, y] in points)
        height = Math.max(ys...) - Math.min(ys...)
        at = @_dashboardPlace m, room, width, height
        break if at? or scale <= 0
        scale -= 0.5 / units
      continue unless at?
      short = (true for i in [1...points.length] when points[i][0] - points[i - 1][0] < @MIN_SEGMENT or Math.abs(points[i][1] - points[i - 1][1]) < @MIN_SEGMENT)
      continue if short.length > 0
      m.line =
        points: ([at[0] + x, at[1] - Math.min(ys...) + y] for [x, y] in points)
      return
    return

  # the bar chart, onto m (or undefined): the bars' width, the paper between
  # them, their heights and the chart's top-left corner. The heights are the
  # draft's, scaled to fit the room; the first tier that fits across, clear of
  # the corner arcs (_dashboardPlace), and keeps the draft's order of heights,
  # each bar taller than it is wide, is drawn
  _dashboardBarMetrics: (m, s) ->
    {t} = m
    room = m.rooms[2]
    width = @BAR_WIDTH_IN_LINES * t
    gap = Math.max @MIN_CLEARANCE, Math.round(s * @BAR_PITCH) - width
    scale = Math.min s, room.h / Math.max @BAR_HEIGHTS...
    for keep in @BAR_TIERS
      heights = (Math.round @BAR_HEIGHTS[i] * scale for i in keep)
      across = keep.length * width + (keep.length - 1) * gap
      tallest = Math.max heights...
      at = @_dashboardPlace m, room, across, tallest
      continue unless at?
      continue if (true for h in heights when h <= width).length > 0
      ordered = true
      for a in [0...keep.length]
        for b in [a + 1...keep.length]
          wanted = @BAR_HEIGHTS[keep[a]] - @BAR_HEIGHTS[keep[b]]
          got = heights[a] - heights[b]
          ordered = false unless got isnt 0 and (got > 0) is (wanted > 0)
      continue unless ordered
      m.bars =
        width: width
        gap: gap
        heights: heights
        left: at[0]
        baseline: at[1] + tallest
      return
    return

  # the pie, onto m (or undefined): its size k -- even, so its centre is a
  # pixel corner, and at most the room's either way -- placed in the room
  # (_dashboardPlace), 2 px smaller where it cannot stand clear of the corner
  # arcs; a ring where the gate allows, else a dot
  _dashboardPieMetrics: (m, S) ->
    {t} = m
    room = m.rooms[3]
    k = 2 * Math.floor Math.min(room.w, room.h, 2 * Math.round S * @PIE_SIZE / @GLYPH_GRID / 2) / 2
    loop
      return if k < @MIN_DOT
      at = @_dashboardPlace m, room, k, k
      break if at?
      k -= 2
    m.pie =
      k: k
      cx: at[0] + k / 2
      cy: at[1] + k / 2
      isRing: k >= @MIN_RING and k - 2 * t >= @MIN_RING_HOLE
    return

  # each dot fills its k x k box: a fillCircle, or -- under MIN_ROUND_DOT px,
  # an extra-small feature no circle command expresses -- the solid k x k
  # square, hand-placed
  _dashboardScatter: (ctx, m) ->
    {k, dots} = m.scatter
    @_useInk ctx
    for [x, y] in dots
      if k >= @MIN_ROUND_DOT
        ctx.fillCircle x + k / 2, y + k / 2, k / 2
      else
        ctx.fillRect x, y, k, k
    return

  # each segment one filled band: the segment and its copy t px to the right
  _dashboardLineChart: (ctx, m) ->
    {t} = m
    {points} = m.line
    @_useInk ctx
    for i in [1...points.length]
      [x1, y1] = points[i - 1]
      [x2, y2] = points[i]
      ctx.beginPath()
      ctx.moveTo x1, y1
      ctx.lineTo x2, y2
      ctx.lineTo x2 + t, y2
      ctx.lineTo x1 + t, y1
      ctx.closePath()
      ctx.fill()
    return

  # the bars, standing on one baseline, left to right
  _dashboardBars: (ctx, m) ->
    {width, gap, heights, left, baseline} = m.bars
    @_useInk ctx
    for h, i in heights
      ctx.fillRect left + i * (width + gap), baseline - h, width, h
    return

  # the pie: a mid-radius strokeCircle ring (the exact annulus [k/2 - t, k/2],
  # so its wall is t) and its quarter from 12 to 3 o'clock filled out to the
  # ring's middle line; below the ring gate, a solid dot -- a fillCircle, or a
  # hand-placed square under MIN_ROUND_DOT px
  _dashboardPie: (ctx, m) ->
    {t} = m
    {k, cx, cy} = m.pie
    @_useInk ctx
    if m.pie.isRing
      ctx.lineWidth = t
      ctx.strokeCircle cx, cy, (k - t) / 2
      ctx.beginPath()
      ctx.moveTo cx, cy
      ctx.arc cx, cy, (k - t) / 2, -Math.PI / 2, 0
      ctx.closePath()
      ctx.fill()
    else if k >= @MIN_ROUND_DOT
      ctx.fillCircle cx, cy, k / 2
    else
      ctx.fillRect cx - k / 2, cy - k / 2, k, k
