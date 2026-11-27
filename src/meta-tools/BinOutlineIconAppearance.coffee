# A BIN, IN OUTLINE: a lidded can, the mark a list's REMOVE button wears (ListVerbsBandWdgt). Not the
# desktop's bin (BinIconAppearance): that one is an icon in the design's style, its interiors paper,
# which would show as patches on a button's hover and pressed fills, its lines the desktop's glyph
# line unit, a hairline beside a control glyph. A PLACEHOLDER: the list verbs' final icons are the
# owner's, still to be drawn.
#   A SIZE-AWARE control glyph (visual-design-system §4.6), INK ONLY -- the button's fill shows
# through it -- on ONE line t, the control glyph's (SizeAwareIconAppearance._controlGlyphLine: LINE of
# my GRID units, 2 px in my 16 px square, 4 at dpr 2), every part a FILL, no round cap anywhere, the
# whole mirrored exactly about the square's vertical axis (it paints in the parity fit of its square,
# SizeAwareIconAppearance._parityFitSide, where every span centres on that axis):
#   - THE HANDLE, HANDLE units wide, t tall, sitting on the lid's middle;
#   - THE LID, as wide as the ink, t tall;
#   - THE CAN, LID_GAP units below the lid: two walls t wide, WALL_X units in from each side, and a
#     bottom bar across them as low as the ink goes, the walls standing on it;
#   - A RIB down the can's middle, t wide, RIB_CLEAR units clear of the can's top and of its bottom
#     bar, drawn only where it keeps a px of clear from each wall.
# Every bar is a rect, and no two overlap, so no px is painted twice.
#   Proportions are in GRID units of the square I paint in: one unit is one px of my 16 px square, and
# the ink keeps MARGIN clear of the square on every side, as the plus beside me does.
class BinOutlineIconAppearance extends SizeAwareIconAppearance

  GRID: 16          # my design square, in units
  LINE: 2           # the line (units)
  MARGIN: 1         # the ink's clear from my square's edges (units)
  HANDLE: 4         # the handle's width (units)
  LID_GAP: 1        # the clear between the lid and the can (units)
  WALL_X: 3         # a wall's outer edge, in from my square's side (units)
  RIB_CLEAR: 2      # the rib's clear from the can's top and from its bottom bar (units)
  MIN_SIZE: 8       # px: below it nothing is drawn

  # THE GEOMETRY in the parity fit F of a glyph square of S px, relative to its top-left corner: the
  # line t, the margin m, and every bar's box [left, top, width, height], each span about F's vertical
  # axis mirrored exactly
  _glyphMetrics: (S) ->
    px = (units) => Math.round S * units / @GRID
    t = @_controlGlyphLine S, @LINE / @GRID
    F = @_parityFitSide S, t
    m = Math.max 1, px @MARGIN
    # a span `width` wide centred on F's vertical axis, its width made F's parity so it centres exactly
    centred = (width) -> width + ((F - width) % 2)
    handleW = centred px @HANDLE
    wallX = px @WALL_X
    canTop = m + 2 * t + Math.max 1, px @LID_GAP
    bottomTop = F - m - t
    ribClear = Math.max 1, px @RIB_CLEAR
    ribTop = canTop + ribClear
    bars = [
      [(F - handleW) / 2, m, handleW, t]                 # the handle
      [m, m + t, F - 2 * m, t]                           # the lid
      [wallX, canTop, t, bottomTop - canTop]             # the left wall
      [F - wallX - t, canTop, t, bottomTop - canTop]     # the right wall
      [wallX, bottomTop, F - 2 * wallX, t]               # the bottom bar
    ]
    innerWidth = F - 2 * wallX - 2 * t
    if innerWidth - t >= 2 and bottomTop - ribClear > ribTop
      bars.push [(F - t) / 2, ribTop, t, bottomTop - ribClear - ribTop]   # the rib
    {t, F, bars}

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < @MIN_SIZE
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    @_useInk ctx
    ctx.beginPath()
    for [left, top, width, height] in @_glyphMetrics(S).bars
      ctx.rect x + left, y + top, width, height
    ctx.fill()
