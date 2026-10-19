class FloppyDiskIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE floppy disk in the design's style: the draft's "save" glyph
  # (docs/plans/redesign/desktop-canvas.html), drawn by the idiom of
  # docs/plans/pixel-icons-plan.md §5b. Line art in ink, every line on the
  # glyph line unit t (SizeAwareIconAppearance._glyphLineUnit), with paper
  # interiors and no halo envelope (the tile the icon stands on is its ground):
  #   - the BODY is ONE outline: a square whose top-right corner is cut off by a
  #     45-degree CHAMFER;
  #   - the SHUTTER is a box hanging from the body's top line with no top of
  #     its own: the top line closes it (adjacent outlined shapes share ONE line
  #     -- a drawn top would double it into a thicker band);
  #   - the LABEL is a box standing on the body's bottom line, which closes it
  #     the same way; it is centred across the body, and its left wall lines up
  #     with the shutter's.
  #   The border idiom: the ink silhouette, then the SAME outline inset by t in
  # paper (_floppyBody, twice), then each box as ink with its paper inset by t
  # (_floppyBox), its open side lying on the body's own line. Every straight
  # wall is t thick by construction, horizontal and vertical alike. The
  # chamfer's paper edge is its ink edge moved t to the LEFT -- for a 45-degree
  # edge the same line as moved t down -- two parallel edges at an integer
  # offset, which the non-AA backend quantises identically (lesson 29): every
  # row AND every column of the slanted wall is exactly t, each row one px
  # right of the row above and touching it, one connected wall from the top
  # line to the right wall. Both edges cut the walls a whole number of px and
  # a half from the corner, so neither ever crosses a pixel centre: there is no
  # tie for the backend to break on any row.
  #   Detail by rule: the cut is the half pixel nearest S * CHAMFER /
  # GLYPH_GRID, so it shrinks with S and never vanishes: 1.5 px below S = 14,
  # where the chamfer is a ONE-PIXEL STEP (the body's corner pixel), and a
  # staircase of at least two steps from there up. Each box is at least 2t + 1
  # px down and stands at least t + 1 px in from the body's sides, so its paper
  # is never less than a px and a px of paper always parts its walls from the
  # body's. At these proportions that also keeps every box 2t + 1 px across and
  # a px of paper from the chamfer and from the other box: nothing ever merges,
  # measured for every S from 10, where the icon bails, up to 3000.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions: the INK edges of a one-unit line on the draft glyph's
  # path (its centre line moved out by half a unit), in GLYPH_GRID units: u
  # units are round(S * u / GLYPH_GRID) px at a glyph square of S px. The body
  # is centred in S both ways, so two opposite edges count only by their span;
  # each box is measured from the body edges it hangs from or stands on.
  BODY_LEFT: 6.5        # the body's outer ink edges (path x 7 and 37, y 7 and 37)
  BODY_RIGHT: 37.5
  BODY_TOP: 6.5
  BODY_BOTTOM: 37.5
  CHAMFER: 6.29         # what the chamfer's outer edge cuts off the top wall and the right wall (the path's 6-unit chamfer, (31,7) to (37,13), moved out half a unit)
  SHUTTER_LEFT: 12.5    # the shutter's outer ink edges (path x 13 and 27, its bottom y 16)
  SHUTTER_RIGHT: 27.5
  SHUTTER_BOTTOM: 16.5
  LABEL_LEFT: 12.5      # the label's outer ink edges (path x 13 and 31, its top y 25)
  LABEL_RIGHT: 31.5
  LABEL_TOP: 24.5

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_floppyMetrics x0, y0, wDev, hDev
    @_useInk ctx
    @_floppyBody ctx, m, 0
    @_usePaper ctx
    @_floppyBody ctx, m, m.t
    @_floppyBox ctx, m, m.shutterLeft, m.top, m.shutterRight, m.shutterBottom
    @_floppyBox ctx, m, m.labelLeft, m.labelTop, m.labelRight, m.bottom

  # every measurement the floppy is built from, in whole device px, but for the
  # chamfer's two ends, which sit half a px along the walls they cut
  _floppyMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    px = (units) => Math.round S * units / @GLYPH_GRID
    # a span of S's parity, so the body sits on the exact centre of S
    span = (units) ->
      n = px units
      n++ if (S - n) % 2 isnt 0
      n
    # a box's extent down from the line it hangs from (or up from the one it
    # stands on): its paper is at least a px tall
    extent = (units) -> Math.max 2 * t + 1, px units
    # a box's inset from a side of the body: a px of paper parts their walls
    inset = (units) -> Math.max t + 1, px units
    w = span @BODY_RIGHT - @BODY_LEFT
    h = span @BODY_BOTTOM - @BODY_TOP
    left = x0 + Math.floor((wDev - S) / 2) + (S - w) / 2
    top = y0 + Math.floor((hDev - S) / 2) + (S - h) / 2
    right = left + w
    bottom = top + h
    cut = Math.floor S * @CHAMFER / @GLYPH_GRID
    m =
      t: t
      left: left
      right: right
      top: top
      bottom: bottom
      cut: cut
      chamferX: right - cut - 0.5   # where the chamfer's outer edge leaves the top line
      chamferY: top + cut + 0.5     # where it meets the right wall
      shutterLeft: left + inset @SHUTTER_LEFT - @BODY_LEFT
      shutterRight: right - inset @BODY_RIGHT - @SHUTTER_RIGHT
      shutterBottom: top + extent @SHUTTER_BOTTOM - @BODY_TOP
      labelLeft: left + inset @LABEL_LEFT - @BODY_LEFT
      labelRight: right - inset @BODY_RIGHT - @LABEL_RIGHT
      labelTop: bottom - extent @BODY_BOTTOM - @LABEL_TOP
    m

  # the body's outline inset by d, filled: d = 0 is the ink silhouette, d = t
  # its paper interior. Every edge moves d inward, the chamfer too: its inset
  # copy is the same edge moved d to the LEFT, which for a 45-degree edge still
  # leaves the inset top line at x = chamferX and still meets the inset right
  # wall at y = chamferY: its upper end moves d down, its lower end d left.
  _floppyBody: (ctx, m, d) ->
    ctx.beginPath()
    ctx.moveTo m.left + d, m.top + d
    ctx.lineTo m.chamferX, m.top + d
    ctx.lineTo m.right - d, m.chamferY
    ctx.lineTo m.right - d, m.bottom - d
    ctx.lineTo m.left + d, m.bottom - d
    ctx.closePath()
    ctx.fill()

  # a box on the body: its ink, then its paper inset by t. One of its sides lies
  # on a line of the body, so its wall there IS the body's line, painted over in
  # the same ink -- one line, never a doubled band
  _floppyBox: (ctx, m, left, top, right, bottom) ->
    @_useInk ctx
    ctx.fillRect left, top, right - left, bottom - top
    @_usePaper ctx
    ctx.fillRect left + m.t, top + m.t, right - left - 2 * m.t, bottom - top - 2 * m.t

