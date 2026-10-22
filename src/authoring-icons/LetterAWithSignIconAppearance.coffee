# THE LETTER A WITH A SIGN: a sans capital A, DRAWN (never typed: the
# letter is the tool's mark), with a small PLUS (DIR "up") or MINUS (DIR
# "down") at its top right -- the bar's own + and − at a glyph's scale. Drawn
# as a SIZE-AWARE icon in the text toolbar's style (docs/architecture/
# visual-design-system.md §4.6), the face of the two font-size tools
# (Increase / DecreaseFontSizeIconAppearance, each naming its DIR): the
# whole 44 x 44 tool cell, and a 24 px picture on the toolbar's overflow
# menu. The two draw the very same letter at every size.
#   INK ONLY (a tool cell's plate shows through), on ONE LINE t: LINE grid
# units of the square (SizeAwareIconAppearance._controlGlyphLine, 2 units:
# 2 px in the 44 cell, 4 at dpr 2, 1 in the 24 px picture), every part a
# fill and all of them ONE path and one fill:
#   - the LETTER (_letterA), CAP units tall: two LEGS, parallelograms whose
#     slanted edges run SLOPE px across per px down -- at 1/2 every edge sits
#     a quarter px off a pixel centre on every row and never ties, so the
#     legs mirror exactly about the letter's axis at every size -- each t px
#     across on every row; their tops coincide in a flat apex t wide, and
#     the counter opens t rows below it. The CROSSBAR, t rows from A_BAR of
#     the cap height down, runs between the legs' OUTER edges, so it adds no
#     edge of its own; it is drawn only where the counter stays open above
#     it and it clears the feet. The cap is never under 3t + 1 px.
#   - the SIGN: a plus or a minus SIGN units across, a span of t's parity
#     (so a bar t thick sits exactly on its axis), its bars t thick with
#     round ends, its top on the apex's row, SIGN_GAP clear of the right
#     leg's ink on the sign's bottom row (at least 1 px).
#   The group -- the letter's ink and the sign -- is centred in the square
# by whole px (a whole shift keeps every slanted edge off the pixel
# centres). Below MIN_SIZE px nothing is drawn; the sign is never dropped
# (it carries the meaning).
#   Proportions are in GLYPH_GRID units of the square the icon paints in
# (one unit is one px in the 44 cell).

class LetterAWithSignIconAppearance extends SizeAwareIconAppearance

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # the sign: "up" a plus (bigger), "down" a minus (smaller). Each subclass
  # names its own.
  DIR: "up"

  LINE: 2         # the line, in grid units (see the header)
  CAP: 14         # the letter's cap height (units)
  SLOPE: 0.5      # the legs' run across per px down
  A_BAR: 0.62     # the crossbar's top, as a share of the cap height down from the apex
  SIGN: 8         # the plus / minus span (units)
  SIGN_GAP: 1     # the clear between the letter and the sign (units, at least 1 px)
  MIN_SIZE: 12

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < @MIN_SIZE
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    m = @_letterAWithSignMetrics S
    X = x + m.dx
    Y = y + m.dy
    @_useInk ctx
    ctx.beginPath()
    for points in m.letter.polygons
      @_addClockwisePolygonSubpath ctx, X, Y, points
    for [left, top, width, height] in m.signBars
      @_addBarSubpath ctx, X + left, Y + top, width, height, true
    ctx.fill()

  # the face in a glyph square of S px: the line t, the letter (_letterA,
  # its apex's left edge at x 0 and its top at y 0), the sign's bars as
  # [left, top, width, height] in the same frame, and the whole-px shift
  # (dx, dy) that centres the group in the square
  _letterAWithSignMetrics: (S) ->
    px = (units) => Math.round S * units / @GLYPH_GRID
    t = @_controlGlyphLine S, @LINE / @GLYPH_GRID
    letter = @_letterA t, Math.max 3 * t + 1, px @CAP
    span = @_spanOfParity S, @SIGN, t % 2, t + 2
    # clear of the right leg's ink on the sign's bottom row
    signLeft = Math.ceil(t + @SLOPE * (span - 0.5) - 0.5) + Math.max 1, px @SIGN_GAP
    c = (span - t) / 2
    signBars = [[signLeft, c, span, t]]
    signBars.push [signLeft + c, 0, t, span] if @DIR is "up"
    # the group spans the letter's ink to the sign's right end
    groupWidth = signLeft + span - letter.inkLeft
    dx = Math.round((S - groupWidth) / 2) - letter.inkLeft
    dy = Math.floor (S - letter.H) / 2
    {t, letter, signBars, dx, dy}

  # THE LETTER A on line t, H px tall, as polygons with its apex's left edge
  # at x 0 and its top at y 0 (the legs, then the crossbar where it is
  # drawn), and its ink's left column inkLeft: the first column whose centre
  # the left foot's bottom row covers (what the group is centred by)
  _letterA: (t, H) ->
    k = @SLOPE
    outerLeft = (y) -> -k * y         # the left leg's outer edge, y px below the apex
    outerRight = (y) -> t + k * y     # the right leg's outer edge
    polygons = [
      [[outerLeft(0), 0], [outerLeft(0) + t, 0], [outerLeft(H) + t, H], [outerLeft(H), H]]
      [[outerRight(0) - t, 0], [outerRight(0), 0], [outerRight(H), H], [outerRight(H) - t, H]]
    ]
    barTop = Math.round H * @A_BAR
    barBottom = barTop + t
    # the crossbar only where the counter is open above it (rows below the
    # apex's solid t) and it fits above the feet
    if barTop >= 2 * t and barBottom <= H - 1
      polygons.push [[outerLeft(barTop), barTop], [outerRight(barTop), barTop], [outerRight(barBottom), barBottom], [outerLeft(barBottom), barBottom]]
    {polygons, H, inkLeft: Math.ceil outerLeft(H - 0.5) - 0.5}
