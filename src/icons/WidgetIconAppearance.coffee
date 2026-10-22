class WidgetIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE picture of "a widget", in the design's style: what
  # Widget.representativeIcon answers for a widget with no art of its own --
  # four shapes in a 2 x 2 grid (a square and a triangle over a circle and a
  # square), on ONE shape size and ONE gap, the grid centred in the glyph
  # square. It shows INSIDE the object frame, at the frame's middle 50% (20 px
  # at the 40 px desktop glyph, 40 at dpr 2), and alone wherever a
  # representativeIcon is shown bare. Line art, every line t, paper
  # interiors, no halo:
  #   - the SQUARE: a round-rect, ink then paper inset t, corners concentric;
  #   - the TRIANGLE: apex up, as tall as it is wide (each flank rises two px
  #     per px across), ink then the same triangle with each flank moved t
  #     across (the axis nearest a steep flank's normal) and the base moved t
  #     up -- t per row on both flanks, tie-free by construction (an
  #     integer-cornered 2:1 flank never meets a pixel centre);
  #   - the CIRCLE: a paper disc, then a mid-radius strokeCircle ring over its
  #     edge (the exact annulus): a paper interior like the other two.
  # Every shape is an ODD number of px across (a one-pixel apex, a centre
  # pixel), and the grid's span has S's parity, so it sits on S's exact centre.
  #   The small-feature rule (the family's one rule): the shapes tier on their
  # size k, read on the SMALLER of the rounded and the exact size -- the
  # circle is a ring when k >= MIN_RING and its hole keeps MIN_RING_HOLE px,
  # else a dot (fillCircle) from MIN_DOT px, else a square; the square and the
  # triangle keep a paper interior while their holes keep MIN_HOLE + 1 px,
  # else they are solid. Shapes keep at least MIN_GAP px of paper between
  # them; under S 8 nothing is drawn.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, GLYPH_GRID units ------------------------------------------
  SHAPE: 15             # one shape's outer ink size, across and down
  GAP: 4                # the paper between two shapes
  SHAPE_CORNER: 2.5     # the square's outer corner radius (the Folder's)
  # ---- detail tiers -----------------------------------------------------------
  MIN_RING: 6           # px: the smallest circle drawn as a ring ...
  MIN_RING_HOLE: 2      # px: ... whose hole keeps this much
  MIN_DOT: 4            # px: the smallest circle drawn as a dot (else a square)
  MIN_HOLE: 1           # px: a square / triangle keeps a paper interior while its hole is over this
  MIN_GAP: 1            # px: the least paper between two shapes
  MIN_CORNER: 2         # px: a smaller corner radius is square

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 8
    m = @_widgetMetrics x0, y0, wDev, hDev
    tiers = @_shapeTiers m.k, m.exact, m.t
    # square, triangle / circle, square
    @_square ctx, m.left, m.top, m.k, m.t, m.r, tiers.hollow
    @_triangle ctx, m.secondLeft, m.top, m.k, m.t, tiers.hollow
    @_circle ctx, m.left, m.secondTop, m.k, m.t, tiers
    @_square ctx, m.secondLeft, m.secondTop, m.k, m.t, m.r, tiers.hollow

  # the grid in whole device px: the line unit, the shape size k (odd), the
  # gap, the square's corner radius, the exact (unrounded) shape size the tiers
  # read, and the two columns' and the two rows' first px
  _widgetMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    x = x0 + Math.floor((wDev - S) / 2)
    y = y0 + Math.floor((hDev - S) / 2)
    px = (units) => Math.round S * units / @GLYPH_GRID
    k = Math.max 1, px(@SHAPE)
    # an ODD shape size, so the triangle has a one-pixel apex and the circle a centre pixel
    k++ if k % 2 is 0
    gap = Math.max @MIN_GAP, px(@GAP)
    # the grid's span has S's parity: it sits on the exact centre
    gap++ if (S - (2 * k + gap)) % 2 isnt 0
    r = px @SHAPE_CORNER
    r = 0 if r < @MIN_CORNER
    r = Math.min r, Math.floor(k / 2) - t
    r = 0 if r < @MIN_CORNER
    span = 2 * k + gap
    left = x + Math.floor((S - span) / 2)
    top = y + Math.floor((S - span) / 2)
    m =
      t: t
      k: k
      gap: gap
      r: r
      exact: S * @SHAPE / @GLYPH_GRID
      left: left
      top: top
      secondLeft: left + k + gap
      secondTop: top + k + gap
    m

  # the shape tiers, on the smaller of the rounded size k and the exact size
  _shapeTiers: (k, exact, t) ->
    n = Math.min k, exact
    tiers =
      ring: n >= @MIN_RING and k - 2 * t >= @MIN_RING_HOLE
      dot: n >= @MIN_DOT
      # a hole of at least MIN_HOLE + 1 px reads as a hole
      hollow: k - 2 * t >= @MIN_HOLE + 1
    tiers

  # the square in the k x k box at (x, y): ink, then paper inset t
  _square: (ctx, x, y, k, t, r, hollow) ->
    @_useInk ctx
    ctx.fillRoundRect x, y, k, k, r
    return unless hollow
    @_usePaper ctx
    ctx.fillRoundRect x + t, y + t, k - 2 * t, k - 2 * t, Math.max(0, r - t)

  # the triangle in the k x k box at (x, y): apex at the top middle, base on
  # the bottom row. The paper triangle is the ink one's flanks moved t across,
  # cut by its base moved t up: for a 2:1 flank its apex then drops 2t, and
  # its base corners sit t / 2 further in
  _triangle: (ctx, x, y, k, t, hollow) ->
    @_useInk ctx
    ctx.beginPath()
    ctx.moveTo x, y + k
    ctx.lineTo x + k / 2, y
    ctx.lineTo x + k, y + k
    ctx.closePath()
    ctx.fill()
    return unless hollow
    @_usePaper ctx
    ctx.beginPath()
    ctx.moveTo x + t + t / 2, y + k - t
    ctx.lineTo x + k / 2, y + 2 * t
    ctx.lineTo x + k - t - t / 2, y + k - t
    ctx.closePath()
    ctx.fill()

  # the circle in the k x k box at (x, y): a ring over a paper disc, a dot, or
  # a square, by its tier
  _circle: (ctx, x, y, k, t, tiers) ->
    if tiers.ring
      # a paper interior like every family shape: the paper disc, then the
      # exact annulus over its edge
      @_usePaper ctx
      ctx.fillCircle x + k / 2, y + k / 2, k / 2
      @_useInk ctx
      ctx.lineWidth = t
      ctx.strokeCircle x + k / 2, y + k / 2, (k - t) / 2
    else if tiers.dot
      @_useInk ctx
      ctx.fillCircle x + k / 2, y + k / 2, k / 2
    else
      @_useInk ctx
      ctx.fillRect x, y, k, k
