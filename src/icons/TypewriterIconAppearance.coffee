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
  # never a defect). Useful side effect, kept as a verification gate rather
  # than being a goal: both backends render it byte-identically at every size
  # and dpr. Conversion lessons + process: docs/plans/pixel-icons-plan.md §5b.
  #
  # The drawing idiom (a vocabulary for future size-aware icons):
  #   - two line units: t = round(S/32) for paper/document-lines/chassis/knobs,
  #     and the slightly lighter tc = round(S/45) for the keys (owner call:
  #     full-t keys read too heavy); every band is an integer multiple of its
  #     unit; the light halo "envelope" around the glyph is o = t thick
  #   - regions paint a solid-ink silhouette, then repaint their interior in
  #     the light color inset by t — so borders can never thin below t
  #   - curves are integer runs: the slot mouth is a column-stepped ellipse
  #     (each dark run extends to its deeper neighbour so the steep ends never
  #     dash), keys are row-span discs (Math.sqrt is IEEE-exact, hence the
  #     same pixels on every JS engine)
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
    return nil if S < 6

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
      ink: @_iconColorString()
      halo: @_outlineColorString()

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
    ctx.fillStyle = m.halo
    ctx.fillRect paperX - o, iy - o, paperW + 2 * o, carriageTop - iy + 2 * o
    ctx.fillStyle = m.ink
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
    ctx.fillStyle = m.halo
    ctx.fillRect cL - o, carriageTop - o, paperX - (cL - o), o
    ctx.fillRect paperX + paperW, carriageTop - o, (cR + o) - (paperX + paperW), o
    ctx.fillRect cL - o, carriageTop, o, deckTop - carriageTop
    ctx.fillRect cR, carriageTop, o, deckTop - carriageTop
    ctx.fillStyle = m.ink
    ctx.fillRect cL, carriageTop, cR - cL, deckTop - carriageTop
    ctx.fillStyle = m.halo
    ctx.fillRect cL + t, carriageTop + t, (cR - t) - (cL + t), deckTop - (carriageTop + t)

  # the slot mouth: a column-stepped ellipse punched through the lip. Per
  # mirrored column pair, a light run opens the mouth and a dark run traces
  # the curve, each dark run extended down to its deeper neighbour's top so
  # the steep ends stay solid instead of breaking into dashes.
  _paintSlotMouth: (ctx, m) ->
    {t, ix, iS, carriageTop} = m
    {R, D} = m.mouth
    cxRight = ix + (iS >> 1)                   # right-of-center column
    cxLeft = cxRight - 1 + (iS % 2)            # same column when iS is odd
    depths = for dx in [0..R]
      Math.round D * Math.sqrt Math.max 0, 1 - (dx * dx) / (R * R)
    ctx.fillStyle = m.halo
    for dx in [0..R] when depths[dx] > 0
      ctx.fillRect cxLeft - dx, carriageTop, 1, depths[dx]
      ctx.fillRect cxRight + dx, carriageTop, 1, depths[dx]
    ctx.fillStyle = m.ink
    for dx in [0..R]
      d = depths[dx]
      deeper = if dx is 0 then d else depths[dx - 1]
      runH = Math.max t, deeper - d + t
      ctx.fillRect cxLeft - dx, carriageTop + d, 1, runH
      ctx.fillRect cxRight + dx, carriageTop + d, 1, runH

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
    ctx.fillStyle = m.halo
    ctx.fillRect cL - knobW - o, knobY - o, knobW + o, knobH + 2 * o
    ctx.fillRect cR, knobY - o, knobW + o, knobH + 2 * o
    ctx.fillStyle = m.ink
    ctx.fillRect cL - knobW, knobY, knobW, knobH
    ctx.fillRect cR, knobY, knobW, knobH
    if knobW - bt >= 1 and knobH - 2 * bt >= 2
      ctx.fillStyle = m.halo
      ctx.fillRect cL - knobW + bt, knobY + bt, knobW - bt, knobH - 2 * bt
      ctx.fillRect cR, knobY + bt, knobW - bt, knobH - 2 * bt

  # the lower body: flares from carriage width to the full base width as a
  # 1-px-per-band staircase, then runs straight to the bottom. Three passes:
  #   halo — each band expanded o sideways; bands after the first also extend
  #     UP by o (the band above's ink covers that everywhere except the
  #     exposed step ledges, exactly where the envelope is needed; the first
  #     band must not, or it would punch light into the carriage's side
  #     borders) and the last extends DOWN by o
  #   ink — the bands themselves
  #   interior — lags ONE band behind the ink on the flank (and insets t), so
  #     the stepped border never thins below t
  _paintLowerBody: (ctx, m) ->
    {t, o, bodyX, bodyW, deckTop, bottom, inset} = m
    deckH = bottom - deckTop
    # the base (last, full-width band) is RESERVED, never a remainder: clamping
    # the step height guarantees it stays >= 2*t (a t bottom edge + interior
    # above it). An unreserved remainder made the bottom edge's thickness vary
    # erratically with size — whenever it landed below the line unit, the band
    # was too short for its interior repaint and rendered solid.
    bands = []                                 # [inset-from-bodyX, yTop, height]
    maxStep = Math.floor (deckH - 2 * t) / inset
    if maxStep < 1                             # even 1-px steps don't fit: no flare
      bands.push [0, deckTop, deckH]
    else
      stepH = Math.min Math.max(t, Math.floor(deckH * @FLARE_HEIGHT / inset)), maxStep
      yb = deckTop
      for i in [0..inset]
        s = inset - i
        hBand = if i < inset then stepH else bottom - yb
        bands.push [s, yb, hBand]
        yb += hBand
    last = bands.length - 1
    ctx.fillStyle = m.halo
    for [s, yT, hBand], i in bands
      # the up-extension rims the exposed step ledge; it must never rise past
      # the band above's own height, or it punches light through whatever sits
      # above (with steps shorter than o, that was the CARRIAGE's side borders
      # — the "top of the chassis doesn't connect" bug)
      upExt = if i is 0 then 0 else Math.min o, bands[i - 1][2]
      hH = hBand + upExt + (if i is last then o else 0)
      ctx.fillRect bodyX + s - o, yT - upExt, bodyW - 2 * s + 2 * o, hH
    ctx.fillStyle = m.ink
    for [s, yT, hBand] in bands
      ctx.fillRect bodyX + s, yT, bodyW - 2 * s, hBand
    ctx.fillStyle = m.halo
    for [s, yT, hBand], i in bands
      sIn = (if i is 0 then s else bands[i - 1][0]) + t
      yIn = if i is 0 then yT + t else yT      # keeps the divider under the carriage
      hIn = hBand - (if i is 0 then t else 0)
      hIn -= t if i is last                    # keeps the base's bottom edge
      continue if hIn <= 0 or bodyW - 2 * sIn <= 0
      ctx.fillRect bodyX + sIn, yIn, bodyW - 2 * sIn, hIn

  # the keyboard: rows computed from the deck's inner budget. Keys are pixel
  # discs (ringed while the hole survives) from diameter 5 up, square rings /
  # dots below; the spacebar is a stadium spanning 3 OR 4 middle slots —
  # whichever lets the remaining keys split evenly — and a plain bar when the
  # row can't host bar + side keys.
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
        @_pxDisc ctx, kx, ky, k, m.ink
        @_pxDisc ctx, kx + tc, ky + tc, k - 2 * tc, m.halo if isRing
      else if isRing
        ctx.fillStyle = m.ink
        @_pxBorder ctx, kx, ky, k, k, tc
      else
        ctx.fillStyle = m.ink
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
        @_pxStadium ctx, sbX, y2, sbW, k, m.ink
        @_pxStadium ctx, sbX + tc, y2 + tc, sbW - 2 * tc, k - 2 * tc, m.halo if isRing
      else if isRing
        ctx.fillStyle = m.ink
        @_pxBorder ctx, sbX, y2, sbW, k, tc
      else
        ctx.fillStyle = m.ink
        ctx.fillRect sbX, y2, sbW, k
      for i in [0...nk] when i < sbSlot or i >= sbSlot + sbCount
        drawKey kx0 + i * (k + g), y2
    else
      ctx.fillStyle = m.ink
      sbW = Math.max 2 * k, Math.round deckW * 0.5
      sbX = deckX + Math.floor (deckW - sbW) / 2
      ctx.fillRect sbX, y2, sbW, k
