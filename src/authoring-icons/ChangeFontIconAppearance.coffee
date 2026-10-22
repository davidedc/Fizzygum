# The FONT tool's face: ONE script capital "A", drawn as a SIZE-AWARE icon in
# the design's style (docs/architecture/visual-design-system.md §4.6) after the
# draft's Snell Roundhand "A" (docs/archive/redesign/desktop-canvas.html
# drawDocsMaker: italic, 30 units of the 44-unit cell at 34 px) -- drawn, not
# typed: no atlas carries the face, and the letter is the tool's mark. Worn by
# the text toolbar's font tool (ChangeFontButtonWdgt, the whole 44 x 44 tool
# cell) and its demo icon (ChangeFontIconWdgt); the toolbar's overflow menu
# shows it as a 24 px picture.
#   THE LETTER is the draft's three strokes, in ink only (a letter has no
# interior to paper over), on the family's line unit t
# (SizeAwareIconAppearance._glyphLineUnit):
#   - the MAIN DOWNSTROKE, from the apex at the top right down to the foot at
#     the baseline: t wide at the apex, swelling to SHADE line units (2t)
#     where the draft shades it (the thick of the letter's thick-and-thin; its
#     hairlines are t).
#     Its centre line is a cubic fitted to the draft's, no flatter than 45
#     degrees where the stroke is t wide (so its one-px rows stay connected).
#     On every device row it is ONE run of exactly its width, centred on that
#     line -- the outline is sampled on the rows' centres, the rows the backend
#     fills by, so the width holds on every row, and the AA backend draws the
#     straight edges between the samples as a smooth stroke.
#   - the HOOK at the foot: the EXIT hairline leaves the foot as a band t tall
#     that runs along the baseline for EXIT_FLAT, then rises to its tip, so the
#     stroke turns up and right with a cup of clear inside the turn.
#   - the left HAIRLINE, from the apex down to the baseline, where it runs
#     left into the BALL terminal. A band t tall around a cubic within a unit
#     of the draft's line, its upper half held a little further from the main
#     stroke than the draft's, so the counter under the apex opens at the
#     family's weights (the draft's strokes are half as heavy) and never
#     pinches shut on its way down. Every column of it is exactly t.
#   - the CROSSBAR, t tall, from the hairline to the main stroke.
#   - the BALL: a square under MIN_ROUND_BALL px, a round dot from it (the
#     family's small-feature rule), standing on the baseline.
#   Every stroke overlaps the strokes it meets -- the hairline starts on the
#   main stroke's centre line, the crossbar runs centre line to centre line,
#   the exit starts on the main stroke's foot, the hairline ends under the
#   ball's middle -- so the letter is one connected region at every size, and
#   all of it is fills: no overlapping round-capped stroke() (SWCanvas leaves
#   such an overlap unpainted).
#   DETAIL DROPS BY RULE: in smaller squares the legs meet on the row above
# the crossbar's at some sizes, where a crossbar would only thicken their
# join; a detail never comes back and goes again as the size grows, so the
# crossbar starts at MIN_CROSSBAR_SIZE, the smallest size from which the
# counter above it is open at every larger size. The exit, the ball and the
# swell stay at every size from MIN_SIZE.
#   PLACEMENT (ALT): "draft" puts the ink where the draft does -- the letter in
# the right of the cell, its ink about 3.5 px right of the centre at 44 (the
# draft centres the glyph's advance, and the swash runs right), half a unit
# left of the draft's (the apex a unit) so the ink stays inside the draft's
# 34 px box at 44 and 88; "centred" centres the ink box both ways.
#   Proportions are in GLYPH_GRID units of the square the icon paints in (the
# 44 x 44 cell: one unit is one px at 44), rounded to whole device px where
# they place a row or a column (the top, the baseline, the crossbar, the
# ball), exact where they shape a curve.

class ChangeFontIconAppearance extends SizeAwareIconAppearance

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # where the letter sits: "draft" or "centred" (see the header)
  ALT: "draft"

  # ---- rows ------------------------------------------------------------------
  TOP: 13             # the apex's top edge
  BASELINE: 29.5      # the bottom edge of the foot, the hairline's run and the ball
  # ---- the main stroke's centre line: a cubic from the apex (MAIN_P0_X, TOP)
  # to the foot (MAIN_P3_X, BASELINE), fitted to the draft's (see the header)
  MAIN_P0_X: 38.25
  MAIN_P1_X: 32
  MAIN_P1_Y: 19.5
  MAIN_P2_X: 27
  MAIN_P2_Y: 24
  MAIN_P3_X: 27
  SWELL_TOP: 16       # the main stroke is t wide down to here...
  SWELL_BOTTOM: 22    # ...and SHADE line units from here down, swelling linearly between
  SHADE: 2            # the shaded width, in line units (rounded to whole px)
  # ---- the exit
  EXIT_FLAT: 1        # how far it runs along the baseline before it rises (at least t, so the hook's cup stays open)
  EXIT_TIP_X: 36.75   # its tip, the centre of its last column
  EXIT_TIP_Y: 23.5
  # ---- the hairline's centre line: a cubic from the main stroke's centre line
  # at HAIR_JOIN_Y down to the baseline's centre row at HAIR_P3_X, level there
  HAIR_JOIN_Y: 14.75
  HAIR_P1_X: 27.25
  HAIR_P1_Y: 16
  HAIR_P2_X: 22.5
  HAIR_P3_X: 14.5
  # ---- the ball and the crossbar
  BALL_LEFT: 12.5
  BALL: 2             # the ball's side (at least 2t)
  CROSSBAR_Y: 22      # the crossbar's middle row
  # ---- detail tiers (device px of the square)
  MIN_SIZE: 12            # smaller squares paint nothing
  MIN_CROSSBAR_SIZE: 23   # smaller squares draw no crossbar (see the header)
  MIN_ROUND_BALL: 4       # a smaller ball is a square

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < @MIN_SIZE
    m = @_scriptAMetrics x0, y0, wDev, hDev
    @_useInk ctx
    @_scriptAMainStroke ctx, m
    @_scriptAExit ctx, m
    @_scriptAHairline ctx, m
    @_scriptABall ctx, m
    @_scriptACrossbar ctx, m if m.hasCrossbar

  # every measurement the letter is built from, in device px, placed per ALT
  _scriptAMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    ox = x0 + Math.floor (wDev - S) / 2
    oy = y0 + Math.floor (hDev - S) / 2
    m = @_scriptAMetricsAt S, ox, oy
    return m unless @ALT is "centred"
    box = @_scriptAInkBox m
    dx = Math.round (S - (box.right - box.left)) / 2 - (box.left - ox)
    dy = Math.round (S - (box.bottom - box.top)) / 2 - (box.top - oy)
    @_scriptAMetricsAt S, ox + dx, oy + dy

  # the metrics with the square's top-left corner at (ox, oy)
  _scriptAMetricsAt: (S, ox, oy) ->
    px = (units) => Math.round S * units / @GLYPH_GRID
    exact = (units) => S * units / @GLYPH_GRID
    t = @_glyphLineUnit S
    top = oy + px @TOP
    base = oy + px @BASELINE
    main = [
      [ox + (exact @MAIN_P0_X), top]
      [ox + (exact @MAIN_P1_X), oy + exact @MAIN_P1_Y]
      [ox + (exact @MAIN_P2_X), oy + exact @MAIN_P2_Y]
      [ox + (exact @MAIN_P3_X), base]
    ]
    hairJoin = oy + exact @HAIR_JOIN_Y
    hairBase = base - t / 2
    ball = Math.max 2 * t, px @BALL
    m =
      S: S
      t: t
      top: top
      base: base
      main: main
      swellTop: oy + exact @SWELL_TOP
      swellBottom: oy + exact @SWELL_BOTTOM
      exitFlat: Math.max t, px @EXIT_FLAT
      exitTipX: ox + exact @EXIT_TIP_X
      exitTipY: oy + exact @EXIT_TIP_Y
      hair: [
        [(@_cubicXAtY main, hairJoin), hairJoin]
        [ox + (exact @HAIR_P1_X), oy + exact @HAIR_P1_Y]
        [ox + (exact @HAIR_P2_X), hairBase]
        [ox + (exact @HAIR_P3_X), hairBase]
      ]
      ballLeft: ox + px @BALL_LEFT
      ball: ball
      crossTop: oy + (px @CROSSBAR_Y) - Math.floor t / 2
      hasCrossbar: S >= @MIN_CROSSBAR_SIZE
    m

  # the ink's bounding box, from the metrics: the ball's left side, the apex's
  # top, the baseline, and the further right of the apex and the exit's tip
  _scriptAInkBox: (m) ->
    apexY = m.top + 0.5
    apexRight = (@_cubicXAtY m.main, apexY) + (@_mainWidthAt m, apexY) / 2
    left: m.ballLeft
    top: m.top
    right: Math.max apexRight, m.exitTipX + 0.5
    bottom: m.base

  # x on the cubic P (whose y only grows along it) at height y, by bisection
  # on its parameter
  _cubicXAtY: (P, y) ->
    at = (i, s) ->
      u = 1 - s
      u * u * u * P[0][i] + 3 * u * u * s * P[1][i] + 3 * u * s * s * P[2][i] + s * s * s * P[3][i]
    lo = 0
    hi = 1
    for i in [0...50]
      mid = (lo + hi) / 2
      if at(1, mid) < y then lo = mid else hi = mid
    at 0, (lo + hi) / 2

  # the main stroke's width in whole px on the device row whose centre is y:
  # t down to SWELL_TOP, the shaded width from SWELL_BOTTOM, a px at a time
  # between
  _mainWidthAt: (m, y) ->
    {t} = m
    ramp = (y - m.swellTop) / (m.swellBottom - m.swellTop)
    t + Math.round ((Math.round t * @SHADE) - t) * Math.max 0, Math.min 1, ramp

  # the main stroke: on every device row, the run of its width centred on its
  # centre line, the outline sampled on the rows' centres (see the header)
  _scriptAMainStroke: (ctx, m) ->
    {top, base} = m
    rights = []
    lefts = []
    for row in [top...base]
      y = row + 0.5
      c = @_cubicXAtY m.main, y
      half = (@_mainWidthAt m, y) / 2
      rights.push [c + half, y]
      lefts.unshift [c - half, y]
    ctx.beginPath()
    ctx.moveTo lefts[lefts.length - 1][0], top
    ctx.lineTo rights[0][0], top
    ctx.lineTo x, y for [x, y] in rights
    ctx.lineTo rights[rights.length - 1][0], base
    ctx.lineTo lefts[0][0], base
    ctx.lineTo x, y for [x, y] in lefts
    ctx.closePath()
    ctx.fill()

  # the exit: from the main stroke's foot, a band t tall along the baseline
  # for EXIT_FLAT, then rising to its tip; its top edge is its bottom edge
  # moved t up, so every column of it is exactly t
  _scriptAExit: (ctx, m) ->
    {base, t} = m
    x = @_cubicXAtY m.main, base - 0.5
    flatEnd = x + (@_mainWidthAt m, base - 0.5) / 2 + m.exitFlat
    ctx.beginPath()
    ctx.moveTo x, base
    ctx.lineTo flatEnd, base
    ctx.lineTo m.exitTipX + 0.5, m.exitTipY + t / 2
    ctx.lineTo m.exitTipX + 0.5, m.exitTipY - t / 2
    ctx.lineTo flatEnd, base - t
    ctx.lineTo x, base - t
    ctx.closePath()
    ctx.fill()

  # the hairline: its centre-line cubic moved t/2 down and t/2 up, joined by
  # its two ends -- the main stroke's centre line at the top, the ball's
  # middle column at the foot, where it runs level along the baseline
  _scriptAHairline: (ctx, m) ->
    {base, t} = m
    h = t / 2
    P = m.hair
    end = m.ballLeft + Math.floor m.ball / 2
    ctx.beginPath()
    ctx.moveTo P[0][0], P[0][1] + h
    ctx.bezierCurveTo P[1][0], P[1][1] + h, P[2][0], P[2][1] + h, P[3][0], P[3][1] + h
    ctx.lineTo end, base
    ctx.lineTo end, base - t
    ctx.lineTo P[3][0], P[3][1] - h
    ctx.bezierCurveTo P[2][0], P[2][1] - h, P[1][0], P[1][1] - h, P[0][0], P[0][1] - h
    ctx.closePath()
    ctx.fill()

  # the ball: a fillCircle, or -- under MIN_ROUND_BALL px, an extra-small
  # feature no circle command expresses -- the solid square, standing on the
  # baseline
  _scriptABall: (ctx, m) ->
    k = m.ball
    if k >= @MIN_ROUND_BALL
      ctx.fillCircle m.ballLeft + k / 2, m.base - k / 2, k / 2
    else
      ctx.fillRect m.ballLeft, m.base - k, k, k

  # the crossbar: t rows from the hairline's centre line to the main stroke's,
  # its two ends slanting with them
  _scriptACrossbar: (ctx, m) ->
    {t, crossTop} = m
    bottom = crossTop + t
    ctx.beginPath()
    ctx.moveTo (@_cubicXAtY m.hair, crossTop), crossTop
    ctx.lineTo (@_cubicXAtY m.main, crossTop), crossTop
    ctx.lineTo (@_cubicXAtY m.main, bottom), bottom
    ctx.lineTo (@_cubicXAtY m.hair, bottom), bottom
    ctx.closePath()
    ctx.fill()
