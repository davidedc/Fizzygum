class PatchProgrammingIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE patch-programming icon in the design's style: the draft's
  # "patch" glyph (docs/archive/redesign/desktop-canvas.html), drawn by the idiom
  # of docs/plans/pixel-icons-plan.md §5b. Line art in ink, every line on the
  # glyph line unit t (SizeAwareIconAppearance._glyphLineUnit), with paper
  # interiors and no halo envelope (the tile the icon stands on is its ground):
  #   - the CARD is the design's content card (SizeAwareIconAppearance.
  #     _contentCard): one rounded outline, its four walls t thick;
  #   - inside it, the patch motif on one band across the card's middle: a RING
  #     node on the left and a rounded SQUARE node on the right, both k px
  #     across, joined by the WIRE, a t-thick bar from the ring's outer wall to
  #     the square's -- touching both, never reaching into either.
  #   The ring is a mid-radius strokeCircle: the exact annulus [k/2 - t, k/2],
  # so its wall is t (each backend rasterizes the circle its own way). The
  # square is the border idiom: its ink (fillRoundRect), then the same box
  # inset by t in paper, its corner radius t less, so its walls are t and its
  # corners concentric.
  #   Placement: the motif is centred in the card both ways. k and the wire's
  # length are each the nearest whole px to their span that has S's parity, so
  # the nodes sit on the card's middle row with equal margins across. Where k
  # and t differ in parity the wire cannot lie on the nodes' middle exactly and
  # sits half a px below it.
  #   Detail by rule: the ring is hollow only when it is at least MIN_RING px
  # across and its hole keeps MIN_RING_HOLE px (a smaller ring reads as a blot
  # or breaks into arcs); else it is a solid fillCircle dot. Its size is read
  # on its exact span too, so the ring never turns back into a dot as S grows
  # while k alternates a px with S's parity. The square keeps MIN_SQUARE_HOLE
  # px of paper or is solid, and a corner radius under MIN_CORNER px is
  # square. The motif keeps a px of paper from the card's
  # walls: where it cannot, the wire shortens to its least (1 px, or 2 where
  # S is even), then the nodes shrink a px at a time -- half a px above the
  # middle row where k loses S's parity; with no room for MIN_NODE px nodes
  # the motif drops and the card is drawn empty.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, in GLYPH_GRID units: u units are round(S * u /
  # GLYPH_GRID) px at a glyph square of S px; the card's are the base's
  # CONTENT_CARD_*. The motif is centred in the card, so the node centres
  # count only by their distance: on the draft's path the nodes sit on the
  # card's middle row (y 22), the ring and the square mirroring each other
  # about its middle column (x 22).
  RING_CENTRE: 15       # the ring node's centre, across (path circle (15, 22) r 4)
  SQUARE_CENTRE: 29     # the square node's centre, across (path rect (25, 18) 8 x 8)
  NODE_SIZE: 9          # both nodes' outer ink size, across and down (the ring's path radius 4 and the square's path side 8, moved out half a unit each side); the wire spans what is left of SQUARE_CENTRE - RING_CENTRE (path M19 22h6)
  NODE_CORNER: 2        # the square node's outer corner radius (path radius 1.5; the inner one is t less)
  # ---- detail tiers -----------------------------------------------------------
  MIN_NODE: 3           # px: the smallest node, across; a motif with no room for it drops
  MIN_RING: 6           # px: the smallest node drawn as a ring, across ...
  MIN_RING_HOLE: 2      # px: ... and the smallest hole a ring keeps; a smaller ring is a solid dot
  MIN_SQUARE_HOLE: 1    # px: the least paper the square node keeps; with less it is solid
  MIN_CORNER: 2         # px: a smaller corner radius is square

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_patchMetrics x0, y0, wDev, hDev
    @_contentCard ctx, m.card
    return unless m.hasMotif
    @_patchRing ctx, m
    @_patchSquare ctx, m
    @_patchWire ctx, m

  # every measurement the icon is built from, in whole device px
  _patchMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    card = @_contentCardMetrics x0 + Math.floor((wDev - S) / 2), y0 + Math.floor((hDev - S) / 2), S, t
    m =
      t: t
      card: card
    @_patchMotifMetrics m, S
    m

  # the motif, onto m: the nodes' size k, the wire's length, and where they
  # stand. Each length is the whole px nearest to its span that has S's
  # parity, so the motif is centred in S, and so in the card. It keeps a px
  # of paper from the card's walls: where it would not, the wire shortens,
  # then the nodes shrink; with no room for MIN_NODE px nodes it drops
  _patchMotifMetrics: (m, S) ->
    {t, card} = m
    ofParity = (units, least) =>
      n = 2 * Math.round((S * units / @GLYPH_GRID - S) / 2) + S
      n += 2 while n < least
      n
    # the room inside the card's walls, less a px of paper on each side
    across = card.right - card.left - 2 * t - 2
    down = card.bottom - card.top - 2 * t - 2
    k = Math.min down, ofParity @NODE_SIZE, @MIN_NODE
    wire = ofParity @SQUARE_CENTRE - @RING_CENTRE - @NODE_SIZE, 1
    if 2 * k + wire > across
      wire = Math.max 2 - S % 2, across - 2 * k
      k = Math.min k, Math.floor (across - wire) / 2
    m.hasMotif = k >= @MIN_NODE
    return unless m.hasMotif
    squareR = Math.round S * @NODE_CORNER / @GLYPH_GRID
    m.k = k
    m.wire = wire
    m.ringLeft = card.left + (card.right - card.left - 2 * k - wire) / 2
    m.squareLeft = m.ringLeft + k + wire
    m.nodesTop = card.top + Math.floor (card.bottom - card.top - k) / 2
    m.wireTop = m.nodesTop + Math.round (k - t) / 2
    # read on the smaller of k and the node's exact size, which k follows a
    # px either way as S's parity alternates: the ring never turns back into a
    # dot as S grows
    m.ringIsHollow = Math.min(k, S * @NODE_SIZE / @GLYPH_GRID) >= @MIN_RING and k - 2 * t >= @MIN_RING_HOLE
    m.squareIsHollow = k - 2 * t >= @MIN_SQUARE_HOLE
    m.squareR = if squareR < @MIN_CORNER then 0 else squareR

  # the ring node in its k x k box: a mid-radius strokeCircle -- the exact
  # annulus [k/2 - t, k/2], so its wall is t -- or, below the ring gate, a
  # solid fillCircle dot
  _patchRing: (ctx, m) ->
    {k, t} = m
    @_useInk ctx
    if m.ringIsHollow
      ctx.lineWidth = t
      ctx.strokeCircle m.ringLeft + k / 2, m.nodesTop + k / 2, (k - t) / 2
    else
      ctx.fillCircle m.ringLeft + k / 2, m.nodesTop + k / 2, k / 2

  # the square node: its ink, then its paper inset by t, the corner radius t
  # less, so its corners stay concentric and its walls are t
  _patchSquare: (ctx, m) ->
    {k, t, squareLeft, nodesTop, squareR} = m
    @_useInk ctx
    ctx.fillRoundRect squareLeft, nodesTop, k, k, squareR
    return unless m.squareIsHollow
    @_usePaper ctx
    ctx.fillRoundRect squareLeft + t, nodesTop + t, k - 2 * t, k - 2 * t, Math.max 0, squareR - t

  # the wire: t thick, from the ring's outer wall to the square's, touching
  # both and never reaching into either
  _patchWire: (ctx, m) ->
    @_useInk ctx
    ctx.fillRect m.ringLeft + m.k, m.wireTop, m.wire, m.t
