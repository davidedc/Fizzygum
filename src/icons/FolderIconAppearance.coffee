class FolderIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE folder in the design's style: the draft's "examples" glyph
  # (docs/archive/redesign/desktop-canvas.html), drawn by the idiom of
  # docs/plans/pixel-icons-plan.md §5b. ONE outline, in ink on the glyph line
  # unit t (SizeAwareIconAppearance._glyphLineUnit): a body with four rounded
  # corners whose top-left rises into a TAB, the tab's top running right from
  # the left wall until a STEP takes it down to the body's top line along a
  # slant. The tab and the body are one region -- no line runs between them --
  # with a paper interior and no halo envelope (the tile the icon stands on is
  # its ground).
  #   The border idiom: the ink silhouette, then the SAME outline inset by t in
  # paper (_folderOutline, twice), so every straight wall is t thick by
  # construction, horizontal and vertical alike. The slant's inset copy is the
  # slant moved t to the LEFT: two parallel edges at an integer offset, which
  # the non-AA backend quantises identically (lesson 29), so every row of the
  # slanted wall is exactly t wide and overlaps the next -- one connected wall.
  #   Tiers, by rule: a step whose slant would travel less than MIN_SLANT_RUN px
  # falls straight down instead (at these proportions, below S = 22): a slant
  # of one pixel reads as a jog, not a slope. The tab never needs to merge into
  # the body: at every S from 10, where the icon bails, its paper keeps at
  # least a pixel under its top wall.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions: the INK edges of a one-unit line on the draft glyph's
  # path (its centre line moved out by half a unit), in GLYPH_GRID units: u
  # units are round(S * u / GLYPH_GRID) px at a glyph square of S px. The
  # folder is centred in S both ways, so two opposite edges count only by
  # their span.
  BODY_LEFT: 4.5      # the left ink edge, the tab's and the body's alike (path x 5)
  BODY_RIGHT: 39.5    # the right ink edge (path x 39)
  TAB_TOP: 10.5       # the tab's top ink edge (path y 11)
  BODY_TOP: 14.5      # the body's top ink edge right of the step (path y 15); the tab rises BODY_TOP - TAB_TOP
  BODY_BOTTOM: 35.5   # the bottom ink edge (path y 35)
  TAB_WIDTH: 12.75    # from the left ink edge to where the slant's outer edge leaves the tab's top
  SLANT_RUN: 3        # how far right the step's slant travels while it falls the tab's rise
  CORNER: 2.5         # the four rounded corners' outer radius (path radius 2; the inner one is t less)
  # ---- detail tiers -----------------------------------------------------------
  MIN_SLANT_RUN: 2    # px: a step whose slant would travel less falls straight down

  # The art is computed with my box at (0, 0) and translated to it: the slant's inset copy
  # lies a non-dyadic fraction (run / rise) along a row, so computed at the box's absolute
  # device position its rounding, and with it a pixel centre exactly on the slant, would depend
  # on where the box is -- a back buffer or a drag image would disagree with the desktop.
  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    ctx.translate x0, y0
    m = @_folderMetrics wDev, hDev
    @_useInk ctx
    @_folderOutline ctx, m, 0
    @_usePaper ctx
    @_folderOutline ctx, m, m.t

  # every measurement the outline is built from, in whole device px from my
  # box's origin (the step's slant is the exact line between two of them)
  _folderMetrics: (wDev, hDev) ->
    S = Math.min wDev, hDev
    px = (units) => Math.round S * units / @GLYPH_GRID
    # a span of S's parity, so the folder sits on the exact centre of S
    span = (units) ->
      n = px units
      n++ if (S - n) % 2 isnt 0
      n
    w = span @BODY_RIGHT - @BODY_LEFT
    h = span @BODY_BOTTOM - @TAB_TOP
    left = Math.floor((wDev - S) / 2) + (S - w) / 2
    top = Math.floor((hDev - S) / 2) + (S - h) / 2
    rise = px @BODY_TOP - @TAB_TOP
    run = px @SLANT_RUN
    run = 0 if run < @MIN_SLANT_RUN
    t = @_glyphLineUnit S
    m =
      t: t
      left: left
      right: left + w
      top: top
      bodyTop: top + rise
      bottom: top + h
      stepX: left + px @TAB_WIDTH   # where the step leaves the tab's top (its outer corner)
      run: run
      rise: rise
      r: Math.max t, px @CORNER
    m

  # the folder's outline inset by d, filled: d = 0 is the ink silhouette, d = t
  # its paper interior. Every edge moves d inward, the step's slant too: its
  # inset copy is the same line moved d to the LEFT, x at row y being
  # stepX - d + (y - top) * run / rise, so each row of the slanted wall is d
  # wide. (The copy starts on another row than the ink's slant, so where a row
  # crosses a pixel centre exactly the two could round apart in float; at
  # these proportions none does, measured for every S up to 3000.) The
  # rounded corners are arcTo corners, built the way fillRoundRect builds its
  # own, at radius r - d (a 0 radius is a square corner).
  _folderOutline: (ctx, m, d) ->
    left = m.left + d
    right = m.right - d
    top = m.top + d
    bottom = m.bottom - d
    bodyTop = m.bodyTop + d
    r = Math.max 0, m.r - d
    slantX = (y) -> m.stepX - d + (if m.run is 0 then 0 else (y - m.top) * m.run / m.rise)
    ctx.beginPath()
    ctx.moveTo slantX(top), top
    ctx.lineTo slantX(bodyTop), bodyTop
    ctx.arcTo right, bodyTop, right, bottom, r
    ctx.arcTo right, bottom, left, bottom, r
    ctx.arcTo left, bottom, left, top, r
    ctx.arcTo left, top, slantX(top), top, r
    ctx.closePath()
    ctx.fill()
