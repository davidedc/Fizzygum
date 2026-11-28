# A TEXT CURSOR IN A FIELD: a one-line field with the text cursor standing at the end of what is typed
# in it, the mark a list's RENAME button wears (ListVerbsBandWdgt) -- a name, typed again. Never a
# pencil: a pencil means "edit" in this house. A PLACEHOLDER: the list verbs' final icons are the
# owner's, still to be drawn.
#   A SIZE-AWARE control glyph (visual-design-system §4.6), INK ONLY -- the button's fill shows
# through it -- on ONE line t, the control glyph's (SizeAwareIconAppearance._controlGlyphLine: LINE of
# my GRID units, 2 px in my 16 px square, 4 at dpr 2), every part a FILL, no round cap anywhere:
#   - THE FIELD, a ring as wide as the ink -- two sides t wide, a top and a bottom bar t tall --
#     mirrored about my square's middle row: its top FIELD_TOP units down, or lower where the cursor's
#     serif and the row clear of it need the rows, and its bottom as far above my square's bottom;
#   - THE CURSOR, an I-beam as tall as the ink: a STEM t wide standing GAP units clear of the field's
#     right side, and a SERIF at its top and one at its bottom, each SERIF units wide and centred on the
#     stem (a span of t's parity, so it centres exactly), at least a row clear of the field above it
#     and below. The stem cuts the field's top and bottom bars GAP units clear of it on each side, so
#     right of it each bar is only the field's corner.
#   DETAIL BY RULE: the serifs wherever my square holds them, the field a row clear of each and a row
# inside its ring (at 8 and 12 px it does not); else the stem alone, as tall as the ink, at least a
# row of it above the field and below. Below MIN_SIZE px nothing is drawn.
#   Every place is DERIVED from what it must clear -- the stem from the field's right side, the bars'
# ends from the stem, the field's top from the serif -- never rounded off the grid on its own, so the
# gaps, the clear rows, the ring and the centring hold at every size I am drawn at, and in my 16 px
# square the stem's left edge is 10 units in. Every bar is a rect, and no two overlap, so no px is
# painted twice.
#   Proportions are in GRID units of the square I paint in: one unit is one px of my 16 px square, and
# the ink keeps MARGIN clear of the square on every side, as the plus beside me does.
class TextCursorIconAppearance extends SizeAwareIconAppearance

  GRID: 16          # my design square, in units
  LINE: 2           # the line (units)
  MARGIN: 1         # the ink's clear from my square's edges (units)
  SERIF: 6          # a serif's width (units)
  FIELD_TOP: 4      # the field's outer top edge, and its bottom's clear of my square's bottom (units)
  GAP: 1            # the clear between the stem and the field on each side of it (units)
  MIN_SIZE: 8       # px: below it nothing is drawn

  #: geometry

  # THE GEOMETRY in a glyph square of S px, relative to its top-left corner: the line t and the
  # margin m; across, the field's right side, the stem's left edge GAP clear of it, and where the
  # bars' left pieces end, GAP clear of the stem; down, whether the cursor has its serifs and the
  # field's top (its bottom as far above the square's bottom); and the serifs' left edge and width,
  # the stem's t and an overhang at each side of it
  _glyphMetrics: (S) ->
    px = (units) => Math.round S * units / @GRID
    t = @_controlGlyphLine S, @LINE / @GRID
    m = Math.max 1, px @MARGIN
    gap = Math.max 1, px @GAP
    rightSide = S - m - t
    stemX = rightSide - gap - t
    # the serifs while the field keeps a row clear of each and a row inside its ring; else the stem
    # alone, a row of it above the field and below
    fieldTop = Math.max px(@FIELD_TOP), m + t + 1
    serifs = S - 2 * fieldTop - 2 * t >= 1
    fieldTop = Math.max px(@FIELD_TOP), m + 1  unless serifs
    overhang = Math.max 1, Math.round (px(@SERIF) - t) / 2
    {t, m, rightSide, stemX, leftEnd: stemX - gap, serifs, fieldTop, serifX: stemX - overhang, serifW: t + 2 * overhang}

  #: drawing

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < @MIN_SIZE
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    {t, m, rightSide, stemX, leftEnd, serifs, fieldTop, serifX, serifW} = @_glyphMetrics S
    @_useInk ctx
    ctx.beginPath()
    # the cursor: its two serifs where it has them and its stem between them, else its stem as tall
    # as the ink
    stemTop = if serifs then m + t else m
    if serifs
      ctx.rect x + serifX, y + m, serifW, t
      ctx.rect x + serifX, y + S - m - t, serifW, t
    ctx.rect x + stemX, y + stemTop, t, S - 2 * stemTop
    # the field: its top and bottom bars from its left side to the stem's gap, its left side between
    # them, and its right side whole, the bars' corners on that side included
    for top in [fieldTop, S - fieldTop - t]
      ctx.rect x + m, y + top, leftEnd - m, t
    ctx.rect x + m, y + fieldTop + t, t, S - 2 * fieldTop - 2 * t
    ctx.rect x + rightSide, y + fieldTop, t, S - 2 * fieldTop
    ctx.fill()
