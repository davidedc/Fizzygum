class ShortcutArrowIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE shortcut badge in the design's style: the badge a reference
  # SHORTCUT (a "Create shortcut" alias) wears over its referent's art.
  # GenericShortcutIconWdgt places it in the bottom-left HOST_SHARE of the
  # glyph square (12 px at the 40 px desktop glyph, 24 at dpr 2). Line art in
  # ink with a paper interior, like every family icon:
  #   - the BOX is one rounded outline, its walls t thick (ink, then paper
  #     inset by t, the corner radius t less, concentric);
  #   - a KNOCKOUT ring of paper, t wide, parts the box from the art under it
  #     (the badge's ground is the referent's art, not the tile, so this one
  #     family member needs a paper margin: without it an art line running
  #     beside the box doubles into a 2t band). On the tile it is invisible;
  #   - the ARROW inside, on the same t: a 45-degree north-east arrow. Its HEAD
  #     is two axis-aligned arms meeting at the tip in the arrow area's
  #     top-right corner; its SHAFT is a 45-degree band, t per row, from the
  #     area's bottom-left corner into the head's corner.
  # THE LINE UNIT IS THE HOST'S: my square is HOST_SHARE of the glyph it
  # badges, so my line unit is _glyphLineUnit of round(S / HOST_SHARE), the
  # host square -- 1 px on the 40 px glyph, 2 at dpr 2, exactly the art's.
  # Every proportion is in GLYPH_GRID units of that HOST square.
  #   Tie-free 45-degree edges: the shaft's two edges run half a pixel off the
  # pixel grid's diagonals (x + y = integer + 0.5), so no row's centre ever
  # lies on an edge and the band is exactly t px on every row (the Floppy's
  # chamfer does the same).
  #   Detail by rule: the arrow area is what the box's paper leaves after
  # ARROW_CLEARANCE -- grown where the box's rounded corner reaches nearer, so
  # the tip and the foot keep a px of paper from the corner's inner arc too
  # (sqrt(2) (ri - c) <= ri - 1, ri = r - t); the head's arms are HEAD_SHARE of
  # it, at least 2t + 1 (the shaft must leave the arms' corner below their
  # feet, or the head is a blot); with an area under MIN_ARROW px the arrow
  # drops and the badge is its box. A corner radius under MIN_CORNER px is
  # square; under S 6 nothing is drawn.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, in GLYPH_GRID units of the HOST glyph square --------------
  # my side over my host glyph's: GenericShortcutIconWdgt reads it to size and
  # place me, so the share I read my host's line unit back from is the share
  # I am laid out at
  HOST_SHARE: 0.3
  CORNER: 2.5             # the box's outer corner radius (the Folder's corner; the inner one t less)
  ARROW_CLEARANCE: 1      # paper between the box's walls and the arrow
  # ---- in line units t / fractions of the arrow area ----------------------------
  KNOCKOUT_IN_LINES: 1    # the paper ring outside the box
  HEAD_SHARE: 0.55        # a head arm's length over the arrow area's side
  # ---- detail tiers -------------------------------------------------------------
  MIN_ARROW: 4            # px: the smallest arrow area; under it the badge is its box
  MIN_CORNER: 2           # px: a smaller corner radius is square

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 6
    m = @_badgeMetrics x0, y0, wDev, hDev
    @_badgeBox ctx, m
    @_straightArrow ctx, m if m.hasArrow

  # every measurement the badge is built from, in whole device px: my square
  # S and my host's H, the line unit t (the host's), the knockout k, the box
  # (its side and corner radius r), the clearance c, the arrow area (side a,
  # top-left (ax, ay)) and the head's arm length
  _badgeMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    H = Math.round S / @HOST_SHARE
    t = @_glyphLineUnit H
    px = (units) => Math.round H * units / @GLYPH_GRID
    k = @KNOCKOUT_IN_LINES * t
    x = x0 + Math.floor((wDev - S) / 2)
    y = y0 + Math.floor((hDev - S) / 2)
    side = S - 2 * k
    r = Math.min px(@CORNER), Math.floor(side / 2) - t
    r = 0 if r < @MIN_CORNER
    # the clearance from the walls; grown where the box's rounded corner reaches nearer: the
    # arrow's tip (top-right) and foot (bottom-left) sit in the area's corners, and each must keep
    # a px of paper from the corner's inner arc (radius r - t about the corner's centre) too
    c = Math.max 1, px(@ARROW_CLEARANCE)
    ri = Math.max 0, r - t
    # the area's corner lies (ri - cc, ri - cc) from the arc's centre; the tip pixel keeps a px of
    # paper from the arc when that corner is within ri - 1 of the centre (or outside its square)
    arcClear = (cc) -> cc >= ri or Math.SQRT2 * (ri - cc) <= ri - 1
    c++ while !arcClear(c) and c < side
    a = side - 2 * t - 2 * c
    # a head arm is at least 2t + 1 (the shaft must leave the arms' corner below and left of
    # their feet, or the head reads as a blot), at most the area
    head = Math.min a, Math.max(2 * t + 1, Math.round(a * @HEAD_SHARE))
    m =
      S: S
      t: t
      k: k
      x: x
      y: y
      side: side
      r: r
      boxLeft: x + k
      boxTop: y + k
      ax: x + k + t + c
      ay: y + k + t + c
      a: a
      hasArrow: a >= @MIN_ARROW
      head: head
    m

  # the knockout ring (paper), the box's ink, its paper inset by t: three
  # concentric round-rects
  _badgeBox: (ctx, m) ->
    {x, y, S, k, side, r, t, boxLeft, boxTop} = m
    if k > 0
      @_usePaper ctx
      ctx.fillRoundRect x, y, S, S, (if r > 0 then r + k else 0)
    @_useInk ctx
    ctx.fillRoundRect boxLeft, boxTop, side, side, r
    @_usePaper ctx
    ctx.fillRoundRect boxLeft + t, boxTop + t, side - 2 * t, side - 2 * t, Math.max(0, r - t)

  # the head: two arms meeting at the area's top-right corner; the shaft: a
  # 45-degree band of t px per row from the area's bottom-left corner up into
  # the head's corner, clipped at the area's right edge (the clipped rows lie
  # inside the head's vertical arm)
  _straightArrow: (ctx, m) ->
    {ax, ay, a, t, head} = m
    @_useInk ctx
    ctx.fillRect ax + a - head, ay, head, t
    ctx.fillRect ax + a - t, ay, t, head
    # the shaft's left edge: x + y = K + 0.5 with K = ax + ay + a - 1, so row j holds
    # [K - j, K - j + t)
    K = ax + ay + a - 1
    ctx.beginPath()
    ctx.moveTo K + 0.5 - (ay + a), ay + a           # bottom edge, left end (ax - 0.5)
    ctx.lineTo K + 0.5 - (ay + a) + t, ay + a       # bottom edge, right end
    ctx.lineTo ax + a, K + 0.5 + t - (ax + a)       # the right edge meets the area's right side
    ctx.lineTo ax + a, ay                           # up the area's right side
    ctx.lineTo K + 0.5 - ay, ay                     # the left edge at the area's top
    ctx.closePath()
    ctx.fill()
