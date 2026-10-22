# RAGGED LINES: the classic face of a paragraph's alignment -- ALIGN_LINES
# bars, ALIGN_GAP apart, alternating LONG and SHORT (ALIGN_PATTERN), every bar
# standing at ANCHOR in the long bars' span: at its left end, its middle or
# its right end. Drawn as a SIZE-AWARE icon in the text toolbar's style
# (docs/architecture/visual-design-system.md §4.6), the face of the three
# align tools (AlignLeft / AlignCenter / AlignRightIconAppearance, each
# naming its ANCHOR): the whole 44 x 44 tool cell, and a 24 px picture on
# the toolbar's overflow menu.
#   INK ONLY: a tool cell's plate follows its state (none at rest, desk
# hovered and active), so a paper interior would show as a patch on it.
#   ONE LINE t: LINE grid units of the square (SizeAwareIconAppearance.
# _controlGlyphLine, 2 units: 2 px in the 44 cell, 4 at dpr 2, 1 in the 24 px
# picture) -- the weight of the bar's control glyphs beside it. Every bar is
# t thick, a stadium with round ends (ROUND_ENDS: square ends up to t = 2,
# a corner px off at 4), and all of them are ONE path and one fill.
#   SPANS: the long span and the short one are the spans of S's parity
# nearest their units (_spanOfParity), so a centred bar sits on the exact
# centre column and the right-anchored face is the exact mirror of the
# left-anchored one; the rag keeps its proportion (10 / 6 at 24, 18 / 12 at
# 44, 36 / 24 at 88).
#   DETAIL BY RULE: the short bar stays at least 2 px shorter than the long
# one, so the rag never vanishes; the count never changes (four bars ARE the
# paragraph); a square under MIN_SIZE px draws nothing.
#   Proportions are in GLYPH_GRID units of the square the icon paints in
# (one unit is one px in the 44 cell).

class RaggedLinesIconAppearance extends SizeAwareIconAppearance

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # where each bar stands in the long bars' span, as the share of the rag
  # left of it: 0 its left end (align left), 1/2 its middle (centre), 1 its
  # right end (right). Each subclass names its own.
  ANCHOR: 0

  LINE: 2                               # the line, in grid units (see the header)
  ALIGN_LONG: 18                        # the long bars' span (units)
  ALIGN_SHORT: 12                       # the short bars' span
  ALIGN_LINES: 4
  ALIGN_GAP: 2                          # the clear between two bars (units; at least 1 px)
  ALIGN_PATTERN: ["L", "S", "L", "S"]   # long and short, from the top
  ROUND_ENDS: true
  MIN_SIZE: 10

  # the bars' geometry in a glyph square of S px, relative to its top-left
  # corner: the line t, the gap g, the long span W and the short one s, the
  # bar count n and the stack's height H, and the long span's left end and
  # the top bar's top
  _raggedLinesMetrics: (S) ->
    t = @_controlGlyphLine S, @LINE / @GLYPH_GRID
    g = Math.max 1, Math.round S * @ALIGN_GAP / @GLYPH_GRID
    W = @_spanOfParity S, @ALIGN_LONG, S % 2, 2
    s = @_spanOfParity S, @ALIGN_SHORT, S % 2, 1
    s = W - 2 if s > W - 2
    n = @ALIGN_LINES
    H = n * t + (n - 1) * g
    {S, t, g, W, s, n, H, left: (S - W) / 2, top: Math.floor (S - H) / 2}

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < @MIN_SIZE
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    m = @_raggedLinesMetrics S
    @_useInk ctx
    ctx.beginPath()
    for i in [0...m.n]
      span = if @ALIGN_PATTERN[i % @ALIGN_PATTERN.length] is "L" then m.W else m.s
      @_addBarSubpath ctx, x + m.left + (m.W - span) * @ANCHOR, y + m.top + i * (m.t + m.g), span, m.t, @ROUND_ENDS
    ctx.fill()
