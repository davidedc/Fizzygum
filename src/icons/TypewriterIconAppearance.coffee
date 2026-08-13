class TypewriterIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE icon (2026-07-21, the first of its kind). The old version was a
  # fixed 100-unit vector drawing (2-unit document lines filled at half-integer
  # offsets, eleven lineWidth-2.5 key strokes) that the icon pipeline scaled
  # arbitrarily, so no stroke ever landed on the pixel grid — the case study of
  # docs/measurements/vector-icon-crispness-audit-2026-07-19.md: ragged and
  # uneven under SWCanvas's non-AA rendering, its thin details washing out at
  # small sizes.
  #
  # This version never draws in design space at all: it reads its ACTUAL size
  # in device pixels and computes integer-pixel geometry from that budget.
  # THE POINT: the non-AA backend renders it cleanly at every size — no ragged
  # or uneven strokes, no dropouts — because the icon is smart about how it
  # uses its space and aligns integer-width strokes to the grid per size. The
  # same discipline makes the HTML5-canvas render neater too (AA itself was
  # never a defect). Conversion lessons + process: docs/plans/pixel-icons-plan.md
  # §5b; the geometry-vs-rendering doctrine (pixel-aligned geometry, standard
  # drawing commands, each backend rasterizes its own way) is in
  # SizeAwareIconAppearance's header.
  #
  # The drawing idiom (a vocabulary for future size-aware icons):
  #   - two line units: t = round(S/32) for paper/document-lines/chassis/knobs,
  #     and the slightly lighter tc = round(S/45) for the keys (owner call:
  #     full-t keys read too heavy); every band is an integer multiple of its
  #     unit; the light halo "envelope" around the glyph is o = t thick
  #   - regions paint a solid-ink silhouette, then repaint their interior in
  #     the light color inset by t — so borders can never thin below t
  #   - curves and oblique edges are drawing commands: the slot mouth is an
  #     elliptical arc (light punch + t-thick stroked lip), the flared lower
  #     body a filled hexagon path, keys are strokeCircle rings / fillCircle
  #     dots, the spacebar a fillStadium; only the sub-5px key squares/dots
  #     are hand-placed rects
  #   - detail adapts to the budget: document lines fill the paper only while
  #     they keep clearance, keys go disc-ring → dot, and the mouth / knob
  #     hollow / flare tiers drop out when they cannot render honestly
  # Colors keep the house two-tone: light "halo/base" in the outline color,
  # dark line-work in the icon color.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this);
  # specificationSize is irrelevant here — nothing below runs in design space.
  preferredSize: new Point 100, 100

  # ---- proportions, named so the painters below read as intent -------------
  # (fractions of the inner-square side unless noted otherwise)
  CARRIAGE_TOP:    0.38   # where the machine starts, below the paper
  CARRIAGE_HEIGHT: 0.20
  CHASSIS_MARGIN:  0.05   # the machine is narrower than the glyph square
                          # (each side; the paper keeps the full square)
  PAPER_MARGIN:    0.20   # the sheet's left/right inset
  INSET:           0.05   # carriage side inset = knob protrusion = flare travel
  FLARE_HEIGHT:    0.45   # of the lower body, before the straight base
  KNOB_HEIGHT:     0.78   # of the carriage height
  MOUTH_RADIUS:    0.26   # of the paper width
  MOUTH_DEPTH:     0.62   # of the mouth radius
  LINE_LENGTHS:    [1, 0.7, 0.85, 0.55, 0.8]   # document-line length rhythm

  # ---- the typewriter ------------------------------------------------------
  # (the paint entry point and the _px* drawing vocabulary live in
  # SizeAwareIconAppearance)

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    m = @_typewriterMetrics x0, y0, wDev, hDev
    return unless m?
    @_paintPaper ctx, m
    @_paintCarriage ctx, m
    @_paintSlotMouth ctx, m if m.mouth?
    @_paintKnobs ctx, m
    @_paintLowerBody ctx, m
    @_paintKeyboard ctx, m

  # every shared measurement, in integer device pixels; horizontal symmetry is
  # by construction (all widths derive from symmetric insets)
  _typewriterMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return undefined if S < 6

    t = Math.max 1, Math.round S / 32          # the line unit (paper, chassis, knobs)
    tc = Math.max 1, Math.round S / 45         # the KEYS line unit — a touch
                                               # lighter than t (owner call:
                                               # full-t keys read too heavy)
    o = t                                      # halo/envelope thickness
    # the glyph proper lives in an inner square, centered in the widget box,
    # so the halo never overflows the bounds
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    ix = x + o
    iy = y + o
    iS = S - 2 * o

    carriageTop = iy + Math.round iS * @CARRIAGE_TOP
    carriageH = Math.max 3 * t, Math.round(iS * @CARRIAGE_HEIGHT)
    inset = Math.max 1, Math.round iS * @INSET
    paperMargin = Math.round iS * @PAPER_MARGIN
    chassisM = Math.round iS * @CHASSIS_MARGIN

    m =
      S: S
      t: t
      tc: tc
      o: o
      ix: ix
      iy: iy
      iS: iS
      bottom: iy + iS
      carriageTop: carriageTop
      carriageH: carriageH
      deckTop: carriageTop + carriageH
      inset: inset
      bodyX: ix + chassisM                     # the machine's x-range (base width)
      bodyW: iS - 2 * chassisM
      cL: ix + chassisM + inset                # the carriage's x-range
      cR: ix + chassisM + (iS - 2 * chassisM) - inset
      paperX: ix + paperMargin
      paperW: iS - 2 * paperMargin

    # the slot mouth only exists when the budget gives it a recognizable curve
    mouthR = Math.round m.paperW * @MOUTH_RADIUS
    mouthD = Math.min Math.round(mouthR * @MOUTH_DEPTH), carriageH - 2 * t
    m.mouth = { R: mouthR, D: mouthD } if mouthR >= 3 * t and mouthD >= 2 * t
    m

  # the sheet: halo rim, dark edges landing ON the carriage lip (so the page
  # connects to the machine), and as many document lines as genuinely fit — a
  # line is drawn only while it keeps one inter-line gap of clearance to the
  # machine below, and the count reaches 0 when nothing fits
  _paintPaper: (ctx, m) ->
    {t, o, iy, carriageTop, paperX, paperW} = m
    @_useLight ctx
    ctx.fillRect paperX - o, iy - o, paperW + 2 * o, carriageTop - iy + 2 * o
    @_useInk ctx
    ctx.fillRect paperX, iy, paperW, t
    ctx.fillRect paperX, iy, t, carriageTop - iy
    ctx.fillRect paperX + paperW - t, iy, t, carriageTop - iy

    pad = 2 * t
    lineW = paperW - 2 * pad
    return if lineW < 2 * t
    pitch = if t is 1 then 3 else 2 * t        # keeps gaps >= 2px at t = 1
    lineGap = pitch - t
    firstY = iy + pad
    nLines = Math.max 0, Math.floor((carriageTop - firstY - t - lineGap) / pitch) + 1
    for i in [0...nLines]
      len = Math.max 2 * t, Math.round lineW * @LINE_LENGTHS[i % @LINE_LENGTHS.length]
      ctx.fillRect paperX + pad, firstY + i * pitch, len, t

  # the carriage bar: halo rims split around the page (a full-width rim would
  # overpaint the page's dark side edges and re-float the sheet), solid ink
  # bar, then the light interior. The bar's surviving top t rows ARE the slot
  # lip, running visibly beneath the paper as in the original.
  _paintCarriage: (ctx, m) ->
    {t, o, cL, cR, carriageTop, deckTop, paperX, paperW} = m
    @_useLight ctx
    ctx.fillRect cL - o, carriageTop - o, paperX - (cL - o), o
    ctx.fillRect paperX + paperW, carriageTop - o, (cR + o) - (paperX + paperW), o
    ctx.fillRect cL - o, carriageTop, o, deckTop - carriageTop
    ctx.fillRect cR, carriageTop, o, deckTop - carriageTop
    @_useInk ctx
    ctx.fillRect cL, carriageTop, cR - cL, deckTop - carriageTop
    @_useLight ctx
    ctx.fillRect cL + t, carriageTop + t, (cR - t) - (cL + t), deckTop - (carriageTop + t)

  # the slot mouth: a half-ellipse punched through the lip in the light color,
  # its curve traced by a t-thick elliptical stroke just below the punch (the
  # trace's semi-axes sit t/2 outside the punch's, so the ink band hangs off
  # the opening's rim). The ellipse is a drawing command — each backend
  # rasterizes the curve its own way. The arc's butt caps end exactly on the
  # lip's top row (the endpoints are the arc's topmost points).
  _paintSlotMouth: (ctx, m) ->
    {t, ix, iS, carriageTop} = m
    {R, D} = m.mouth
    cx = ix + iS / 2
    @_useLight ctx
    ctx.beginPath()
    ctx.ellipse cx, carriageTop, R, D, 0, 0, Math.PI
    ctx.fill()
    @_useInk ctx
    ctx.lineWidth = t
    ctx.beginPath()
    ctx.ellipse cx, carriageTop, R + t / 2, D + t / 2, 0, 0, Math.PI
    ctx.stroke()

  # platen knobs: thin, LIGHT "D"-tabs hanging off the carriage sides — a
  # bt-thin outline (thinner than the chassis line) OPEN toward the chassis,
  # so its top and bottom edges merge into the carriage's side line and the
  # light interior sits right beside it; degenerates to a solid thin nub when
  # the protrusion can't host a hollow. The height shares the carriage's
  # parity so the vertical centering is exact.
  _paintKnobs: (ctx, m) ->
    {t, o, cL, cR, carriageTop, carriageH, inset} = m
    bt = Math.max 1, Math.ceil t / 2
    knobW = Math.max 1, inset - 1
    knobH = Math.round carriageH * @KNOB_HEIGHT
    knobH += 1 if (carriageH - knobH) % 2 is 1
    knobH = Math.min knobH, carriageH
    knobY = carriageTop + Math.floor (carriageH - knobH) / 2
    @_useLight ctx
    ctx.fillRect cL - knobW - o, knobY - o, knobW + o, knobH + 2 * o
    ctx.fillRect cR, knobY - o, knobW + o, knobH + 2 * o
    @_useInk ctx
    ctx.fillRect cL - knobW, knobY, knobW, knobH
    ctx.fillRect cR, knobY, knobW, knobH
    if knobW - bt >= 1 and knobH - 2 * bt >= 2
      @_useLight ctx
      ctx.fillRect cL - knobW + bt, knobY + bt, knobW - bt, knobH - 2 * bt
      ctx.fillRect cR, knobY + bt, knobW - bt, knobH - 2 * bt

  # the lower body: flares from the carriage width out to the full base width
  # on an oblique flank, then runs straight to the bottom — one hexagonal
  # silhouette, filled three times: light halo (expanded o sideways and o
  # below; the top edge stays put, or it would punch light into the
  # carriage's side borders), ink, then the light interior (flank shifted t
  # inward, top edge t lower so the divider line under the carriage
  # survives, bottom edge t higher). The oblique flank is a path edge — each
  # backend rasterizes it its own way; the interior flank parallels the ink
  # flank at a t horizontal offset, so the slanted border reads t thick at
  # every row.
  _paintLowerBody: (ctx, m) ->
    {t, o, bodyX, bodyW, deckTop, bottom, inset} = m
    deckH = bottom - deckTop
    return if deckH < 1
    # the straight base keeps at least 2*t (a t bottom edge + the interior
    # above it); when even a 1px flare can't fit, the body is a plain box
    flareH = Math.min Math.round(deckH * @FLARE_HEIGHT), deckH - 2 * t
    flareH = 0 if flareH < 1 or inset < 1
    yFlare = deckTop + flareH
    body = (dx, yT, yB) ->
      # the silhouette shifted dx inward per side (negative = outward),
      # spanning yT..yB; the flank runs from inset at deckTop to 0 at yFlare.
      # A path with inverted or empty extent still fills (a negative-size
      # fillRect is a no-op, a path is not) — bail explicitly.
      return if yB <= yT
      hasFlank = flareH > 0 and yT < yFlare
      xTop = if hasFlank then dx + inset * (1 - (yT - deckTop) / flareH) else dx
      ctx.beginPath()
      ctx.moveTo bodyX + xTop, yT
      ctx.lineTo bodyX + bodyW - xTop, yT
      if hasFlank
        ctx.lineTo bodyX + bodyW - dx, yFlare
        ctx.lineTo bodyX + bodyW - dx, yB
        ctx.lineTo bodyX + dx, yB
        ctx.lineTo bodyX + dx, yFlare
      else
        ctx.lineTo bodyX + bodyW - dx, yB
        ctx.lineTo bodyX + dx, yB
      ctx.closePath()
      ctx.fill()
    @_useLight ctx
    body -o, deckTop, bottom + o
    @_useInk ctx
    body 0, deckTop, bottom
    @_useLight ctx
    body t, deckTop + t, bottom - t

  # the keyboard: rows computed from the deck's inner budget. Keys are
  # strokeCircle rings (fillCircle dots once the hole can't survive) from
  # diameter 5 up, hand-placed square rings / dots below (the extra-small
  # tier); the spacebar is a fillStadium spanning 3 OR 4 middle slots —
  # whichever lets the remaining keys split evenly — and a plain bar when
  # the row can't host bar + side keys.
  _paintKeyboard: (ctx, m) ->
    {S, t, tc, bodyX, bodyW, inset, deckTop, bottom} = m
    deckX = bodyX + inset + t
    deckW = bodyW - 2 * (inset + t)
    dyTop = deckTop + 2 * t
    deckInnerH = (bottom - 2 * t) - dyTop
    return if deckInnerH < 1 or deckW < 3

    k = Math.max t, Math.round S / 11          # key side/diameter
    isRound = k >= 5
    isRing = (k - 2 * tc) >= 2
    g = Math.max 1, Math.round k / 3           # key gap (tight, fits an extra key)
    rowGap = Math.max t, 2
    nRows = if deckInnerH >= 2 * k + rowGap then 2 else 1
    k = Math.min k, deckInnerH                 # tiny budgets: shrink before dropping
    nk = Math.min 8, Math.max 3, Math.floor((deckW + g) / (k + g))
    nk = Math.max 3, nk - 1 if S < 48          # the full count reads crowded when small
    rowW = nk * k + (nk - 1) * g
    kx0 = deckX + Math.floor (deckW - rowW) / 2
    rowsH = nRows * k + (nRows - 1) * rowGap
    ky0 = dyTop + Math.max 0, Math.floor((deckInnerH - rowsH) / 2)

    drawKey = (kx, ky) =>
      if isRound
        if isRing
          # a mid-radius strokeCircle renders the exact analytic annulus
          # [rMid - tc/2, rMid + tc/2] — the same spelling as the title-bar
          # rings (a fillCircle pair reads 4-petaled at these small radii
          # under the non-AA backend)
          @_useInk ctx
          ctx.lineWidth = tc
          ctx.strokeCircle kx + k / 2, ky + k / 2, (k - tc) / 2
        else
          @_useInk ctx
          ctx.fillCircle kx + k / 2, ky + k / 2, k / 2
      else if isRing
        @_useInk ctx
        @_pxBorder ctx, kx, ky, k, k, tc
      else
        @_useInk ctx
        ctx.fillRect kx, ky, k, k

    for i in [0...nk]
      drawKey kx0 + i * (k + g), ky0

    return unless nRows is 2
    y2 = ky0 + k + rowGap
    if nk >= 5
      sbCount = 3 + (nk - 3) % 2
      sbSlot = (nk - sbCount) / 2
      sbX = kx0 + sbSlot * (k + g)
      sbW = sbCount * k + (sbCount - 1) * g
      if isRound
        @_useInk ctx
        ctx.fillStadium sbX, y2, sbW, k
        if isRing
          @_useLight ctx
          ctx.fillStadium sbX + tc, y2 + tc, sbW - 2 * tc, k - 2 * tc
      else if isRing
        @_useInk ctx
        @_pxBorder ctx, sbX, y2, sbW, k, tc
      else
        @_useInk ctx
        ctx.fillRect sbX, y2, sbW, k
      for i in [0...nk] when i < sbSlot or i >= sbSlot + sbCount
        drawKey kx0 + i * (k + g), y2
    else
      @_useInk ctx
      sbW = Math.max 2 * k, Math.round deckW * 0.5
      sbX = deckX + Math.floor (deckW - sbW) / 2
      ctx.fillRect sbX, y2, sbW, k
