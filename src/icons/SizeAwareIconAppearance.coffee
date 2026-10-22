class SizeAwareIconAppearance extends IconAppearance

  # Base for SIZE-AWARE icons (extracted 2026-07-21 from TypewriterIconAppearance,
  # the reference implementation, on the second conversion — see
  # docs/plans/pixel-icons-plan.md §5b).
  #
  # A size-aware icon never draws in a fixed design space: it reads its ACTUAL
  # size in device pixels and computes integer-pixel geometry from that budget.
  # THE POINT: the non-AA backend (SWCanvas) renders it cleanly at every size —
  # no ragged or uneven strokes, no dropouts — because the icon is smart about
  # how it uses its space and aligns integer-width strokes to the grid per
  # size. The same discipline makes the HTML5-canvas render neater too (AA
  # itself was never a defect).
  #
  # The GEOMETRY is pixel-aligned; the RENDERING is each backend's business.
  # Icon code issues standard drawing commands — rects, the direct-call shape
  # vocabulary (fillCircle / fillStadium / fillRoundRect / strokeCircle /
  # strokeLine — SWCanvas's dedicated crisp rasterizers, path-based polyfills
  # on the native context; docs/architecture/integer-pixel-placement-and-
  # sizing.md §7), and plain paths for oblique edges and free curves — and
  # lets each backend rasterize them: SWCanvas non-AA, native AA. The two
  # backends therefore need not (and generally do not) produce identical
  # pixels; re-implementing a rasterization algorithm in icon code to force
  # them to agree duplicates the engine and is a defect. Only an EXTRA-SMALL
  # feature (a few pixels, where no drawing command expresses the intended
  # pixel placement) may be hand-placed as fillRect runs — such a feature may
  # happen to coincide across backends, which is fine but never the goal.
  #
  # Subclasses implement _paintSizeAware (all drawing) and typically follow the
  # reference implementation's shape: a metrics method computing every shared
  # measurement (line units, inner square, named-fraction layout) and one named
  # painter per visual region.

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    keyValues = @_calculateKeyValuesOrNil aContext, clippingRectangle
    return undefined unless keyValues?
    [damageBox,sl,st,al,at,w,h] = keyValues

    # the icon art (_paintSizeAware) sets its own colours, so the shadow pass renders it to
    # a scratch and blits the black silhouette (the shadow-pass paint contract). In that
    # scratch the PAPER role ERASES coverage (see _usePaper): the paper interiors are
    # visually background, so the icon's shadow is its ink line-work — never a solid blob
    # of the whole shape.
    if appliedShadow?
      @_paintDamagedAreaAsBlackSilhouette aContext, al, at, w, h, appliedShadow, (sctx) =>
        @_paintingSilhouette = true
        try
          @_paintColoredIcon sctx, al, at, w, h, @widget.glyphSize
        finally
          @_paintingSilhouette = false
      return

    @_paintColoredIcon aContext, al, at, w, h, @widget.glyphSize
    return undefined

  # MY ART AS THE MARK ON ANOTHER APPEARANCE'S LOOK: an appearance that paints a look of its own
  # under a glyph (HandleAppearance's plate) wears me for the glyph instead of letting me be its
  # widget's appearance, and names the side my glyph square takes in my widget's box -- the square
  # a glyphSize of `side` names (_paintBoxInDevicePx), centred, my art clipped to it. The normal
  # pass only: the wearer casts the silhouette it wants (a plate's, under the whole glyph).
  paintAsMarkInSquare: (aContext, clippingRectangle, side) ->
    keyValues = @_calculateKeyValuesOrNil aContext, clippingRectangle
    return undefined unless keyValues?
    [damageBox,sl,st,al,at,w,h] = keyValues
    @_paintColoredIcon aContext, al, at, w, h, side
    return undefined

  # glyphSide: the side of the glyph square my art takes in my widget's box, or undefined for the
  # whole box (_paintBoxInDevicePx)
  _paintColoredIcon: (aContext, al, at, w, h, glyphSide) ->
    aContext.save()

    # clip out the damage rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    aContext.globalAlpha = @widget.alpha

    [x0, y0, wDev, hDev] = @_paintBoxInDevicePx glyphSide

    # a glyph square is a clip too: inside it the art must be pixel for pixel
    # this icon at size g, which is what a g x g widget box paints -- clipped by
    # its own bounds. (Unclipped, the bin at g = 20 overhangs its square by a
    # halo row.)
    aContext.clipToRectangle x0, y0, wDev, hDev if glyphSide?

    # deliberately NO useLogicalPixelsUntilRestore(): subclasses draw in
    # integer DEVICE pixels, anchored to the paint box's origin — never to the
    # damage rect's corner (al/at), which shifts under partial repaints.
    @_paintSizeAware aContext, x0, y0, wDev, hDev

    aContext.restore()

  # THE BOX my art is painted into, as integer DEVICE px [x0, y0, wDev, hDev].
  # _paintColoredIcon is its one reader, and both the normal pass and the
  # shadow-pass silhouette run that, so a glyph's shadow is cast by exactly the
  # art it shadows. glyphSide is my widget's glyphSize when I am its
  # appearance, and the wearer's side when I am the mark on its look
  # (paintAsMarkInSquare).
  #   No glyphSide (a desktop icon's glyph square, a toolbar thumbnail): my
  # widget's WHOLE box, and each subclass centres its own square in it with
  # Math.floor in device px -- which any box that is not square relies on.
  #   A glyphSide (a chrome button sized to its whole slot, ruling G3 -- see
  # IconButtonWdgt.glyphSize): the g x g square, g = min(glyphSide, width,
  # height) logical px, centred in my box the way calculateRectangleOfIcon
  # centres a legacy glyph (Math.round of the logical offset). It is computed
  # here in integers rather than read from calculateRectangleOfIcon, which
  # aspect-fits through preferredSize: g/100*100 is not exact in floating point
  # for every g, so a .5 offset can tip the other way and the box comes back a
  # pixel too wide (g = 14 in a 15 px box comes back 15 wide).
  #   The widget's bounds are integer logical px (integer-placement policy) and
  # g is rounded, so every product is an exact integer.
  _paintBoxInDevicePx: (glyphSide) ->
    left = @widget.left()
    top = @widget.top()
    width = @widget.width()
    height = @widget.height()
    if glyphSide?
      side = Math.round Math.min glyphSide, width, height
      left = Math.round left + (width - side) / 2
      top = Math.round top + (height - side) / 2
      width = height = side
    [left * ceilPixelRatio, top * ceilPixelRatio, width * ceilPixelRatio, height * ceilPixelRatio]

  # subclass responsibility: all-integer device-pixel drawing into the
  # (x0, y0, wDev, hDev) box _paintBoxInDevicePx hands over
  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->

  # ---- the line unit of an icon drawn in the design's style ----------------
  # The design draws its glyphs on a GLYPH_GRID-unit square, and the line of
  # an icon in its style is ONE grid unit: S/44 at a glyph square of S device
  # px, in whole px and never 0 -- 1 px at the desktop's 40 px glyph square,
  # 2 at dpr 2 (80), 1 up to S = 65 and 2 from 66. That is half the draft's
  # 2-unit stroke: the weight approved at the flagship size, with no floor
  # under it (1 px all the way down).
  GLYPH_GRID: 44
  _glyphLineUnit: (S) ->
    Math.max 1, Math.round S / @GLYPH_GRID

  # ---- a CONTROL glyph drawn as fills --------------------------------------
  # A control glyph that stands on a plate (a halo handle's four-way arrow,
  # double arrows and curled-arrows square; a text tool's face in its cell:
  # the ragged lines, the A with its sign, the snippets page) is drawn as
  # FILLS -- shafts and squares as rects, heads as polygons whose slanted
  # edges run half a pixel off the pixel lattice, arcs as a ring clipped to a
  # wedge -- on ONE line t: 2 logical px at the side the glyph is drawn at for
  # real (2 px at dpr 1, 4 at dpr 2), the weight of the bar's control glyphs.
  # No round cap or join anywhere: with fills no pixel centre ties an edge, so
  # a glyph mirrors exactly at every size, and SWCanvas's unpainted overlap of
  # round-capped subpaths cannot reach it.
  #   lineShare is t as a share of the side, 2 over the real side; t never
  # turns back as S grows.
  _controlGlyphLine: (S, lineShare) ->
    Math.max 1, Math.round S * lineShare

  # THE PARITY FIT: a line t thick sits exactly on the axis of a square whose
  # side has t's parity, so a control glyph paints in the square of side
  # S - ((S - t) % 2) at its square's top-left (one spare px right and below
  # when S and t disagree), where it mirrors exactly about both axes.
  _parityFitSide: (S, t) ->
    S - ((S - t) % 2)

  # a polygon's points, offset by (x, y), as one more subpath of the path
  # being built: the caller closes it and fills the path
  _addPolygonSubpath: (ctx, x, y, points) ->
    for [px, py], i in points
      if i is 0
        ctx.moveTo x + px, y + py
      else
        ctx.lineTo x + px, y + py
    return

  # the same polygon as one more CLOSED subpath, wound clockwise on screen
  # whichever way its points run, so the overlapping parts of one nonzero
  # fill (a letter's legs and its crossbar) add up and never cancel
  _addClockwisePolygonSubpath: (ctx, x, y, points) ->
    area = 0
    for [x1, y1], i in points
      [x2, y2] = points[(i + 1) % points.length]
      area += x1 * y2 - x2 * y1
    @_addPolygonSubpath ctx, x, y, (if area < 0 then points.slice().reverse() else points)
    ctx.closePath()

  # a BAR w x h at (x, y) as one more subpath of the path being built: a
  # stadium (its ends round, at half its thickness) where `round` asks and it
  # is at least 2 px thick, else a plain rect; an empty box adds nothing. The
  # caller fills the path.
  _addBarSubpath: (ctx, x, y, w, h, round) ->
    return if w <= 0 or h <= 0
    k = Math.min w, h
    if round and k >= 2
      ctx.roundRect x, y, w, h, k / 2
    else
      ctx.rect x, y, w, h

  # a span in a glyph square of S px with the given PARITY (0 even, 1 odd):
  # the whole px of that parity nearest S * units / GLYPH_GRID, never under
  # `least`. A part that must centre on an axis of that parity -- a bar t
  # thick across a plus, a row of bars on the square's centre column -- sits
  # on it exactly.
  _spanOfParity: (S, units, parity, least = 1) ->
    exact = S * units / @GLYPH_GRID
    n = 2 * Math.round((exact - parity) / 2) + parity
    n += 2 while n < least
    n

  # ---- colour roles --------------------------------------------------------
  # Every painter picks its colour through these — the ONE choke point that
  # keeps the shadow pass honest about the interiors. Painting normally, they
  # just set fill/stroke style to the role's colour. Painting the shadow-pass
  # silhouette scratch (_paintingSilhouette), the PAPER role switches the
  # context to destination-out so its paint ERASES coverage: the paper
  # interiors are visually background, not ink, so they must not cast shadow
  # — the border idiom's "ink silhouette, then paper interior" then leaves
  # exactly the ink line-work in the silhouette. Order matters and the
  # painters honour it (paper before ink erases nothing; paper after ink
  # punches through).
  #   INK is the icon's own colour (_iconColorString: my widget's, which a
  # desktop icon's holder sets to the desktop glyph role). PAPER
  # (Theme.iconPaper) is the light of an icon drawn in the design's style: its
  # interiors only, with no halo around the icon (the surface it stands on is
  # its ground).

  _useInk: (ctx) ->
    ctx.globalCompositeOperation = 'source-over' if @_paintingSilhouette
    s = @_iconColorString()
    ctx.fillStyle = s
    ctx.strokeStyle = s

  _usePaper: (ctx) ->
    ctx.globalCompositeOperation = 'destination-out' if @_paintingSilhouette
    s = WorldWdgt.theme.iconPaper.toString()
    ctx.fillStyle = s
    ctx.strokeStyle = s

  # ---- the content card of an icon drawn in the design's style -------------
  # The design's shared CONTENT card (docs/plans/redesign/desktop-canvas.html):
  # the landscape card the patch, slides and panel glyphs hold their content
  # in, path rect (5, 10) 34 x 24 radius 4, as one outline on the glyph line
  # unit t. Its proportions are the INK edges of a one-unit line on that path
  # (its centre line moved out by half a unit), in GLYPH_GRID units: u units
  # are round(S * u / GLYPH_GRID) px at a glyph square of S px. The card is
  # centred in S both ways -- its width and height are spans of S's parity --
  # so two opposite edges count only by their span.
  CONTENT_CARD_LEFT: 4.5      # the outer ink edges (path x 5 and 39, y 10 and 34)
  CONTENT_CARD_RIGHT: 39.5
  CONTENT_CARD_TOP: 9.5
  CONTENT_CARD_BOTTOM: 34.5
  CONTENT_CARD_CORNER: 4.5    # the outer corner radius (path radius 4; the inner one is t less)
  CONTENT_CARD_MIN_CORNER: 2  # px: a smaller corner radius rounds nothing on the non-AA backend, so the corners are square

  # the card in the glyph square of S px whose top-left corner is (x, y), on
  # line unit t, as {left, top, right, bottom, r, t}: its outer ink edges and
  # its outer corner radius, in whole device px. A span of S's parity is the
  # rounded span, a px longer where that has the other parity, so the card
  # sits on the exact centre of S. Callers lay their content out against it,
  # then paint it with _contentCard.
  _contentCardMetrics: (x, y, S, t) ->
    span = (units) =>
      n = Math.round S * units / @GLYPH_GRID
      n++ if (S - n) % 2 isnt 0
      n
    w = span @CONTENT_CARD_RIGHT - @CONTENT_CARD_LEFT
    h = span @CONTENT_CARD_BOTTOM - @CONTENT_CARD_TOP
    r = Math.round S * @CONTENT_CARD_CORNER / @GLYPH_GRID
    r = 0 if r < @CONTENT_CARD_MIN_CORNER
    left = x + (S - w) / 2
    top = y + (S - h) / 2
    {left, top, right: left + w, bottom: top + h, r, t}

  # the card: its ink silhouette, then the same box inset by t in paper, its
  # corner radius t less, so the corners stay concentric and every wall is t
  # thick by construction, horizontal and vertical alike
  _contentCard: (ctx, card) ->
    {left, top, r, t} = card
    w = card.right - left
    h = card.bottom - top
    @_useInk ctx
    ctx.fillRoundRect left, top, w, h, r
    @_usePaper ctx
    ctx.fillRoundRect left + t, top + t, w - 2 * t, h - 2 * t, Math.max 0, r - t

  # ---- the document page of an icon drawn in the design's style ------------
  # The family's DOCUMENT PAGE, the twin of the content card: a portrait sheet
  # whose top-right corner is FOLDED. The object frame (ObjectIconAppearance,
  # which holds a widget's own picture in its middle) and the script frame
  # (ScriptIconAppearance) stand on it, so a filed widget and a script read as
  # one kind of thing. One outline in ink on the glyph line unit t, a paper
  # interior inset t (the border idiom):
  #   - the SHEET: a portrait box, its bottom corners and its top-left corner
  #     rounded at PAGE_CORNER (the inner radius t less), its top-right corner
  #     cut by a 45-degree CHAMFER, the Floppy's idiom: the chamfer's two edges
  #     run half a pixel off the pixel diagonals, so no row ties and every row
  #     AND column of the slanted wall is exactly t;
  #   - the FLAP (the folded-over corner): an L of two t lines -- one hanging
  #     from the top wall where the chamfer leaves it, one running from its
  #     foot to the right wall where the chamfer meets it. Each shares its far
  #     end with the sheet's own line (adjacent outlined shapes share ONE
  #     line), and the triangle they close with the chamfer is paper.
  #   Detail by rule: the fold (the cut) is the half pixel nearest
  # S * PAGE_FOLD / GLYPH_GRID, never less than 1.5 px, and never so deep that
  # the flap's foot line reaches the glyph square's middle half (where the
  # object frame's picture lies); the flap is drawn only where its paper
  # triangle keeps MIN_FLAP_PAPER px along each leg (else the corner is a plain
  # cut, which still reads as a page). A corner radius under PAGE_MIN_CORNER
  # px is square. The sheet is centred in S both ways (spans of S's parity),
  # like the card.
  #   Proportions: the INK edges of a one-unit line on a 44-unit path (its
  # centre line moved out half a unit), in GLYPH_GRID units.
  PAGE_LEFT: 7.5        # path x 8 and 36: a 28-unit sheet, the 22-unit picture square (the
  PAGE_RIGHT: 36.5      #   composite's middle 50%) inside it with 2.5 units of paper either side
  PAGE_TOP: 3.5         # path y 4 and 40
  PAGE_BOTTOM: 40.5
  PAGE_FOLD: 7.5        # what the chamfer's outer edge cuts off the top wall and the right wall
  PAGE_CORNER: 2.5      # the rounded corners' outer radius (the Folder's; the inner one t less)
  MIN_FLAP_PAPER: 2     # px of paper the flap's triangle keeps along each leg, or no flap
  PAGE_MIN_CORNER: 2    # px: a smaller corner radius is square

  # the page in the glyph square of S px whose top-left corner is (x, y), on
  # line unit t: its outer ink edges, the chamfer's two ends (half a px along
  # the walls they cut), the flap's corner and whether it is drawn, and the
  # corner radius, in device px. Callers lay their content out against it,
  # then paint it with _page.
  _pageMetrics: (x, y, S, t) ->
    px = (units) => Math.round S * units / @GLYPH_GRID
    span = (units) ->
      n = px units
      n++ if (S - n) % 2 isnt 0
      n
    w = span @PAGE_RIGHT - @PAGE_LEFT
    h = span @PAGE_BOTTOM - @PAGE_TOP
    left = x + (S - w) / 2
    top = y + (S - h) / 2
    right = left + w
    bottom = top + h
    r = px @PAGE_CORNER
    r = 0 if r < @PAGE_MIN_CORNER
    r = Math.min r, Math.floor(w / 2) - t
    # the fold stays above the glyph square's MIDDLE HALF (the square GenericObjectIconWdgt lays
    # a widget's picture in: from round(S / 4), half of S): the flap's foot line ends above it
    cut = Math.max 1, Math.min(Math.floor(S * @PAGE_FOLD / @GLYPH_GRID), y + Math.round(S / 4) - top - t)
    # the flap's L: its vertical line's columns [flapX, flapX + t), hanging from the top wall at
    # the chamfer's start; its horizontal line's rows [flapY, flapY + t), meeting the right wall
    # at the chamfer's end. The paper triangle between the L and the chamfer has legs of
    # cut - 2t px (the chamfer's band eats a t, the L another)
    flapX = right - cut - t
    flapY = top + cut
    m =
      left: left
      top: top
      right: right
      bottom: bottom
      w: w
      h: h
      r: r
      t: t
      cut: cut
      chamferX: right - cut - 0.5   # where the chamfer's outer edge leaves the top line
      chamferY: top + cut + 0.5     # where it meets the right wall
      flapX: flapX
      flapY: flapY
      hasFlap: cut - 2 * t >= @MIN_FLAP_PAPER
    m

  # the sheet's outline inset by d, filled: d = 0 the ink, d = t the paper.
  # The chamfer's inset copy is the edge moved d to the LEFT (for 45 degrees,
  # also d down), so its ends stay on the inset walls; each corner is an arcTo
  # corner about ONE centre (radius r - d)
  _pageOutline: (ctx, p, d) ->
    left = p.left + d
    top = p.top + d
    right = p.right - d
    bottom = p.bottom - d
    r = Math.max 0, p.r - d
    ctx.beginPath()
    ctx.moveTo left + r, top
    ctx.lineTo p.chamferX, top
    ctx.lineTo right, p.chamferY
    ctx.arcTo right, bottom, left, bottom, r
    ctx.arcTo left, bottom, left, top, r
    ctx.arcTo left, top, p.chamferX, top, r
    ctx.closePath()
    ctx.fill()

  # the page: its ink, its paper inset t, then the flap's two lines (each
  # meeting the sheet's line)
  _page: (ctx, p) ->
    @_useInk ctx
    @_pageOutline ctx, p, 0
    @_usePaper ctx
    @_pageOutline ctx, p, p.t
    return unless p.hasFlap
    @_useInk ctx
    ctx.fillRect p.flapX, p.top, p.t, p.flapY + p.t - p.top
    ctx.fillRect p.flapX, p.flapY, p.right - p.flapX, p.t
