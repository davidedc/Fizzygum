# TWO OVERLAPPING SHEETS: a sheet and its copy laid over it, the mark a list's DUPLICATE button wears
# (ListVerbsBandWdgt). A PLACEHOLDER: the list verbs' final icons are the owner's, still to be drawn.
#   A SIZE-AWARE control glyph (visual-design-system §4.6), INK ONLY -- the button's fill shows
# through it -- on ONE line t, the control glyph's (SizeAwareIconAppearance._controlGlyphLine: LINE of
# my GRID units, 2 px in my 16 px square, 4 at dpr 2), every part a FILL, no round cap anywhere:
#   - THE FRONT SHEET: a square SHEET units on a side, MARGIN in from my square's bottom and right
#     edges, an ink RING of four bars that meet and never overlap, so no px is painted twice;
#   - THE BACK SHEET: the same square MARGIN in from my top and left edges, of which only its TOP and
#     LEFT bars show: its other two run behind the front sheet. Between the two sheets stands a clear
#     GAP, the room the front sheet's offset leaves past the back sheet's bars (t in my 16 px square);
#     the back sheet is drawn only where that gap keeps at least a px, else the front sheet alone.
# Square corners: at these sizes a rounded corner rounds nothing on the non-anti-aliased backend.
#   Proportions are in GRID units of the square I paint in: one unit is one px of my 16 px square, and
# the ink keeps MARGIN clear of the square on every side, as the plus beside me does.
class TwoSheetsIconAppearance extends SizeAwareIconAppearance

  GRID: 16      # my design square, in units
  LINE: 2       # the line (units)
  MARGIN: 1     # the ink's clear from my square's edges (units)
  SHEET: 10     # a sheet's side (units)
  MIN_SIZE: 8   # px: below it nothing is drawn

  #: geometry

  # THE GEOMETRY in a glyph square of S px, relative to its top-left corner: the line t, the margin
  # m, a sheet's side a, and f, where the front sheet's left and top edges stand
  _glyphMetrics: (S) ->
    px = (units) => Math.round S * units / @GRID
    t = @_controlGlyphLine S, @LINE / @GRID
    m = Math.max 1, px @MARGIN
    a = px @SHEET
    {t, m, a, f: S - m - a}

  #: drawing

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < @MIN_SIZE
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    {t, m, a, f} = @_glyphMetrics S
    @_useInk ctx
    ctx.beginPath()
    # the front sheet, a ring: its top and bottom bars across it, its sides between them
    ctx.rect x + f, y + f, a, t
    ctx.rect x + f, y + f + a - t, a, t
    ctx.rect x + f, y + f + t, t, a - 2 * t
    ctx.rect x + f + a - t, y + f + t, t, a - 2 * t
    # the back sheet's top bar, then its left bar under it, while a px of gap keeps them apart
    if f - m - t >= 1
      ctx.rect x + m, y + m, a, t
      ctx.rect x + m, y + m + t, t, a - t
    ctx.fill()
