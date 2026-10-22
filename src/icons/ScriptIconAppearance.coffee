class ScriptIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE script in the design's style: a script (ScriptWdgt's
  # representativeIcon) and its shortcut (ScriptShortcutWdgt's art, 40 px on the
  # desktop and in a folder, 80 at dpr 2; arrow'd when it is an alias). Line
  # art on t, paper inside, no halo:
  #   - the PAGE: the family's document page (SizeAwareIconAppearance.
  #     _pageMetrics / _page), the very sheet the object frame stands on, so a
  #     script and a filed widget read as one kind of thing;
  #   - CODE LINES on it: t-tall bars at three indents (CODE_ROWS), one pitch
  #     apart, from under the page's top wall down; a line keeps CODE_MARGIN of
  #     paper from the page's walls and from the flap's L (a row beside the
  #     flap ends short of it);
  #   - the RUN BADGE across the page's bottom-right corner: a ring (a
  #     mid-radius strokeCircle, the exact annulus, wall t) over a paper disc
  #     that covers the page under it, and a solid PLAY triangle in it pointing
  #     right. Rows the badge's box reaches end short of it.
  #   Detail by rule: ALL the rows while they fit -- the pitch closes up to
  # t + 1 and the gap under the top wall to a px before the bottom row drops
  # (so the count never turns back as S grows); a bar the flap or the badge
  # would cut under MIN_CODE px ends the code there (it and the rows under it
  # drop as a unit); the badge is a ring holding a play triangle while it is
  # MIN_RING px across, its hole keeps MIN_PLAY_HOLE px and the (even)
  # triangle MIN_PLAY_RING px -- else the play triangle stands on the page's
  # paper at its bottom-right (no ring, no paper disc), and drops under
  # MIN_PLAY px. Under S 10 nothing is drawn.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, GLYPH_GRID units ------------------------------------------
  CODE_MARGIN: 2.5      # paper between a code line and the page's walls / the flap / the badge
  CODE_TOP: 3           # from the page's top wall's inner edge to the first line's top
  CODE_PITCH: 4         # from one line's top to the next one's
  # each row: [indent, length], in units, from the code's left edge (a 3-level indent pattern)
  CODE_ROWS: [[0, 13], [3, 12], [3, 8], [6, 10], [6, 6], [3, 11], [0, 7], [3, 9]]
  RUN_SIZE: 14          # the run badge's outer ink diameter (an even px, its middle on a pixel boundary)
  RUN_RIGHT: 43         # its right and bottom ink edges (it overhangs the page's corner)
  RUN_BOTTOM: 43
  PLAY_SHARE: 0.42      # the play triangle's height over the badge's diameter
  PLAY_SIZE: 9          # below the ring tier: the play triangle's height on the page, units
  # ---- detail tiers -----------------------------------------------------------
  MIN_CODE: 2           # px: a shorter code line drops
  MIN_RING: 6           # px: the smallest badge drawn as a ring (the family's ring rule) ...
  MIN_PLAY_HOLE: 5      # px: ... and the least ring hole that holds a play triangle; else no ring
  MIN_PLAY: 3           # px: the least play-triangle height on the page
  MIN_PLAY_RING: 4      # px: the least (even) play-triangle height inside the ring

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_scriptMetrics x0, y0, wDev, hDev
    @_page ctx, m.page
    @_scriptCode ctx, m
    @_scriptBadge ctx, m if m.badge?
    @_scriptPlay ctx, m.play if m.play?

  # every measurement the script is built from, in device px: the page, the
  # badge's box (undefined below its ring tier), the play triangle's box
  # (undefined when it drops) and the code rows {left, top, w}
  _scriptMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    x = x0 + Math.floor((wDev - S) / 2)
    y = y0 + Math.floor((hDev - S) / 2)
    px = (units) => Math.round S * units / @GLYPH_GRID
    page = @_pageMetrics x, y, S, t
    m =
      t: t
      page: page
    margin = Math.max 1, px(@CODE_MARGIN)
    # ---- the run badge, or the play triangle alone: their box first, the code avoids it
    avoid = undefined   # {left, top}: rows reaching below top end short of left
    # an EVEN badge (its middle on a pixel boundary), so an even play triangle's tip lies
    # between two rows that mirror each other -- no single spike row at the tip
    k = px @RUN_SIZE
    k++ if k % 2 isnt 0
    badgeRight = x + Math.min(S, px(@RUN_RIGHT))
    badgeBottom = y + Math.min(S, px(@RUN_BOTTOM))
    hole = k - 2 * t
    # the play triangle: an even height near PLAY_SHARE of the badge, at least MIN_PLAY_RING,
    # keeping a px of paper inside the ring; the ring tier needs that triangle
    playRoom = (hole - 2) - (hole - 2) % 2
    h = Math.min playRoom, Math.max(@MIN_PLAY_RING, 2 * Math.round(k * @PLAY_SHARE / 2))
    if Math.min(k, S * @RUN_SIZE / @GLYPH_GRID) >= @MIN_RING and hole >= @MIN_PLAY_HOLE and h >= @MIN_PLAY_RING
      badgeLeft = badgeRight - k
      badgeTop = badgeBottom - k
      m.badge = {left: badgeLeft, top: badgeTop, k: k}
      m.play = @_playBox badgeLeft + k / 2, badgeTop + k / 2, h
      avoid = {left: badgeLeft - margin, top: badgeTop - margin}
    unless m.badge?
      # below the ring tier: the play triangle on the page's paper, bottom-right
      h = Math.max @MIN_PLAY, px(@PLAY_SIZE)
      h-- if h % 2 isnt 0
      playRight = page.right - t - margin
      playBottom = page.bottom - t - margin
      w = @_playWidth h
      if h >= @MIN_PLAY
        m.play = {left: playRight - w, top: playBottom - h, w: w, h: h}
        avoid = {left: playRight - w - margin, top: playBottom - h - margin}
    # ---- the code: rows from under the top wall, each a bar of t. ALL the rows while they fit:
    # the pitch closes up to fit the page (never under t + 1, a px of paper between two bars),
    # and only then do rows drop, the bottom one first; a bar the flap or the badge would cut
    # under MIN_CODE ends the code there (it and every row under it drop as a unit)
    codeLeft = page.left + t + margin
    codeRight = page.right - t - margin
    # the gap under the top wall is SOFT (it closes to a px before a row drops); the margin over
    # the bottom wall and a px between bars are hard
    gapTop = Math.max 1, px(@CODE_TOP)
    lastTop = page.bottom - t - margin - t   # the last bar's top keeps the margin
    n = @CODE_ROWS.length
    pitch = Math.max t + 1, px(@CODE_PITCH)
    fits = -> page.top + t + gapTop + (n - 1) * pitch <= lastTop
    while n > 1 and !fits()
      codeRoom = lastTop - page.top - t - 1   # with the top gap closed to a px
      pitch = Math.min Math.max(t + 1, px(@CODE_PITCH)), Math.floor(codeRoom / (n - 1))
      if pitch >= t + 1
        gapTop = Math.max 1, Math.min(gapTop, lastTop - page.top - t - (n - 1) * pitch)
      if pitch < t + 1 or !fits()
        n--
        pitch = Math.max t + 1, px(@CODE_PITCH)
        gapTop = Math.max 1, px(@CODE_TOP)
    firstTop = page.top + t + gapTop
    n = 0 if firstTop > lastTop
    m.rows = []
    for i in [0...n]
      top = firstTop + i * pitch
      [rowIndent, rowLength] = @CODE_ROWS[i]
      left = codeLeft + px(rowIndent)
      right = Math.min codeRight, left + Math.max(1, px(rowLength))
      # beside the flap's L (its rows reach the flap's foot line + t): end a margin short of it
      if page.hasFlap and top < page.flapY + t + margin
        right = Math.min right, page.flapX - margin
      else if !page.hasFlap and top < page.top + page.cut + t + margin
        right = Math.min right, page.right - page.cut - t - margin
      right = Math.min right, avoid.left if avoid? and top + t > avoid.top
      break if right - left < @MIN_CODE
      m.rows.push {left: left, top: top, w: right - left}
    m

  # the play triangle's width for a height h, pointing right.
  #   TIE-FREE: a flank from the box's top-left corner to the tip crosses row
  # centre j + 0.5 at x = w (2j + 1) / h px in from the left edge; a
  # half-integer there lies on a pixel centre, where the backend may break the
  # tie differently on the two flanks, so w steps down from the nearest to
  # 0.8 h until no row ties (w = h never ties)
  _playWidth: (h) ->
    ties = (w) ->
      j = 0
      while j < h / 2
        crossing = w * (2 * j + 1) / h
        return true if Math.abs(crossing - Math.floor(crossing) - 0.5) < 1e-9
        j++
      false
    w = Math.max 2, Math.round(h * 0.8)
    w-- while w > 2 and ties(w)
    w

  # the play triangle h tall (its middle row on cy), _playWidth(h) across,
  # centred on (cx, cy) by its box -- optically: the box a px right of centre
  # when w and the badge differ in parity
  _playBox: (cx, cy, h) ->
    w = @_playWidth h
    {left: Math.ceil(cx - w / 2), top: cy - h / 2, w: w, h: h}

  _scriptCode: (ctx, m) ->
    @_useInk ctx
    for row in m.rows
      ctx.fillRect row.left, row.top, row.w, m.t

  # the paper disc covering the page, then the ink ring (the exact annulus)
  _scriptBadge: (ctx, m) ->
    {left, top, k} = m.badge
    t = m.t
    @_usePaper ctx
    ctx.fillCircle left + k / 2, top + k / 2, k / 2
    @_useInk ctx
    ctx.lineWidth = t
    ctx.strokeCircle left + k / 2, top + k / 2, (k - t) / 2

  _scriptPlay: (ctx, p) ->
    @_useInk ctx
    ctx.beginPath()
    ctx.moveTo p.left, p.top
    ctx.lineTo p.left + p.w, p.top + p.h / 2
    ctx.lineTo p.left, p.top + p.h
    ctx.closePath()
    ctx.fill()

