class PatchProgrammingIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE patch-programming icon (2026-07-21, converted with
  # /convert-icon-size-aware; idiom docs: docs/plans/pixel-icons-plan.md §5b):
  # the family's shared slide-card panel (the base's _pxSlideCard) holding
  # the patch motif -- a circle node wired to a square node, all on the t
  # unit: a mid-radius strokeCircle ring (the old 3.5-unit stroked oval
  # rendered ragged under non-AA), a border-idiom square, and
  # a wire that meets each node's outer wall exactly (the old wire crossed
  # INTO both nodes' interiors, leaving stubs). Each backend rasterizes the
  # circle its own way (the geometry-vs-rendering doctrine in
  # SizeAwareIconAppearance's header).

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, fractions of the glyph square (numbers from the
  # original 100-space drawing) ----------------------------------------------
  NODE_K: 0.235       # node outer size (circle diameter = square side): the
                      #   design's 20-unit nodes + their centered 3.5 stroke
  CIRCLE_CX: 0.30     # circle node center
  SQUARE_CX: 0.69     # square node center
  NODES_CY: 0.50      # the motif's shared vertical center

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 10
    # center the square glyph box in the widget box
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2

    t = Math.max 1, Math.round S / 32   # the line unit: card border, node
                                        #   walls, wire
    o = t                               # halo/envelope thickness

    [px, py, pw, ph, r] = @_pxSlideCard ctx, x, y, S, t, o

    # both nodes share one size and one vertical band, so the wire lines up
    # by construction; each keeps >=1px of light from the card's border ink
    # (rounding lands the circle ON the border around 17px without the
    # clamps)
    k = Math.max 3, Math.round S * @NODE_K
    top = y + Math.round S * @NODES_CY - k / 2
    cl = x + Math.round S * @CIRCLE_CX - k / 2
    cl = Math.max cl, px + t + 1
    sl = x + Math.round S * @SQUARE_CX - k / 2
    sl = Math.min sl, px + pw - t - 1 - k

    # circle node: a mid-radius strokeCircle ring — the exact analytic
    # annulus [(k - 2t)/2, k/2], walls t by construction, same spelling as
    # the title-bar rings. The hollow needs k >= 6 and a surviving hole;
    # below that the node stays a solid fillCircle dot
    if k - 2 * t >= 2 and k >= 6
      @_useInk ctx
      ctx.lineWidth = t
      ctx.strokeCircle cl + k / 2, top + k / 2, (k - t) / 2
    else
      @_useInk ctx
      ctx.fillCircle cl + k / 2, top + k / 2, k / 2

    # square node: same border idiom
    @_useInk ctx
    ctx.fillRect sl, top, k, k
    if k - 2 * t >= 2
      @_useLight ctx
      ctx.fillRect sl + t, top + t, k - 2 * t, k - 2 * t

    # the wire: t thick, vertically centered on the nodes, spanning exactly
    # from the circle's outer wall to the square's -- touching both, never
    # crossing inside
    wx = cl + k
    wLen = sl - wx
    if wLen >= 1
      @_useInk ctx
      ctx.fillRect wx, top + Math.round((k - t) / 2), wLen, t
