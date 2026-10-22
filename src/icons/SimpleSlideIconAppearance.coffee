class SimpleSlideIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE slide icon in the design's style, the launcher icon of the
  # Slides Maker: the draft's "slides" glyph
  # (docs/archive/redesign/desktop-canvas.html), drawn by the idiom of
  # docs/plans/pixel-icons-plan.md §5b. Line art in ink, every line on the
  # glyph line unit t (SizeAwareIconAppearance._glyphLineUnit), with paper
  # interiors and no halo envelope (the tile the icon stands on is its ground):
  #   - the CARD is the design's content card (SizeAwareIconAppearance.
  #     _contentCard): one rounded outline, its four walls t thick;
  #   - inside it, the slide's content on one band across the card's middle:
  #     three TEXT LINES on the left, t tall, at one left edge, the third
  #     shorter than the first two; and a rising CHART on the right, three
  #     BARS on one baseline, each taller than the one to its left by one step.
  #   One line unit for every part: the card's walls and the text lines are t,
  # and a bar is a solid block BAR_WIDTH_IN_LINES line units wide (2t), so no
  # horizontal line is heavier than a vertical one. The text and the chart
  # share the band: the tallest bar's top is the first line's top and the
  # baseline is the third line's bottom. Every line is a fillRect over the
  # card's paper.
  #   Placement: the content (the lines, the paper gap, the chart) is centred
  # in the card across -- the full lines' length is the whole px nearest their
  # span that gives the content S's parity -- and the band down, half a px
  # above the card's middle row where its height and S differ in parity. The
  # content keeps MIN_CLEARANCE px of paper from the card's walls, between its
  # lines, between its bars and between the text and the chart.
  #   Detail by rule: the line pitch shrinks to fit the card's paper, down to
  # its least (MIN_CLEARANCE px of paper between two lines); below that the
  # third line drops, then the second -- the rows drop as a unit, so the text
  # and the chart stay one band. The chart keeps its rise: its step shrinks to
  # fit the band (the shortest bar keeps t), and where even a one-px step does
  # not fit, or the text would be left less than MIN_LINE px across, the chart
  # loses a bar, its survivors still rising in equal steps to the band's top.
  # With room for fewer than MIN_BARS bars there is no rise to draw, and the
  # chart drops: the text lines take the card.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, in GLYPH_GRID units: u units are round(S * u /
  # GLYPH_GRID) px at a glyph square of S px; the card's are the base's
  # CONTENT_CARD_*. The INK extents of a one-unit line on the draft glyph's
  # path: a line's round caps reach half a unit past its ends, a bar's half
  # width either side of its path x. The content is centred in the card, so
  # it counts only by its lengths and gaps.
  LINES: 3               # the text lines (path y 17, 22 and 27)
  LINE_LENGTH: 15        # the first two lines' ink length (path M10 17h14 and M10 22h14)
  SHORT_LINE_LENGTH: 11  # the third line's (path M10 27h10)
  LINE_PITCH: 5          # from a line's top to the next one's
  TEXT_TO_CHART: 3       # the paper between the lines' right ends and the first bar (path x 24 to 28)
  BARS: 3                # the chart's bars (path M28 26v3 M31 23v6 M34 20v9)
  BAR_PITCH: 3           # from a bar's left edge to the next one's (path x 28, 31 and 34)
  BAR_STEP: 3            # how much taller each bar is than the one to its left (path tops y 26, 23 and 20)
  # ---- in line units t --------------------------------------------------------
  BAR_WIDTH_IN_LINES: 2  # a bar's width in line units: a solid block two lines wide (the owner's choice over 1, a bar as thin as a line)
  # ---- detail tiers -----------------------------------------------------------
  MIN_CLEARANCE: 1       # px of paper the content keeps from the card's walls, and each line and bar from the next
  MIN_LINE: 3            # px: the shortest full text line; the chart loses a bar before the text gets shorter
  MIN_BARS: 2            # the fewest bars that still rise; with room for fewer the chart drops

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_slideMetrics x0, y0, wDev, hDev
    @_contentCard ctx, m.card
    @_slideText ctx, m
    @_slideChart ctx, m

  # every measurement the icon is built from, in whole device px
  _slideMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    card = @_contentCardMetrics x0 + Math.floor((wDev - S) / 2), y0 + Math.floor((hDev - S) / 2), S, t
    m =
      t: t
      card: card
    px = (units) => Math.round S * units / @GLYPH_GRID
    # the room inside the card's walls, less the content's clearance on each side
    across = card.right - card.left - 2 * t - 2 * @MIN_CLEARANCE
    down = card.bottom - card.top - 2 * t - 2 * @MIN_CLEARANCE
    @_slideRowMetrics m, px, down
    @_slideChartMetrics m, px, across
    @_slideTextMetrics m, S, across
    m.textLeft = card.left + t + @MIN_CLEARANCE + (across - m.length - m.gap - m.chartWidth) / 2
    m.chartLeft = m.textLeft + m.length + m.gap
    m.bandTop = card.top + t + @MIN_CLEARANCE + Math.floor (down - m.band) / 2
    m

  # the text rows, onto m: how many, their pitch, and the band they fill. The
  # pitch shrinks to fit the room down, never under t + MIN_CLEARANCE; where
  # it would, the third line drops, then the second
  _slideRowMetrics: (m, px, down) ->
    {t} = m
    m.rows = 0
    m.pitch = 0
    for rows in [@LINES..1] by -1
      if rows is 1
        fits = down >= t
        pitch = 0
      else
        pitch = Math.min px(@LINE_PITCH), Math.floor (down - t) / (rows - 1)
        fits = pitch >= t + @MIN_CLEARANCE
      if fits
        m.rows = rows
        m.pitch = pitch
        break
    m.band = if m.rows > 0 then (m.rows - 1) * m.pitch + t else 0

  # the chart, onto m: its bars' width, the paper between them, their
  # heights, and the paper gap left of the chart. Its step shrinks to fit
  # the band (the shortest bar keeps t); a chart with no room for a one-px
  # step, or one that would leave the text less than MIN_LINE px across,
  # loses a bar -- its survivors still rise in equal steps to the band's top
  # -- and with room for fewer than MIN_BARS it drops
  _slideChartMetrics: (m, px, across) ->
    {t, band} = m
    m.barWidth = @BAR_WIDTH_IN_LINES * t
    m.barGap = Math.max @MIN_CLEARANCE, px(@BAR_PITCH) - m.barWidth
    m.gap = Math.max @MIN_CLEARANCE, px @TEXT_TO_CHART
    widthOf = (bars) => bars * m.barWidth + (bars - 1) * m.barGap
    stepFor = (bars) => Math.min px(@BAR_STEP), Math.floor (band - t) / (bars - 1)
    bars = @BARS
    bars-- while bars >= @MIN_BARS and (stepFor(bars) < 1 or across - m.gap - widthOf(bars) < @MIN_LINE)
    if bars < @MIN_BARS
      m.barHeights = []
      m.gap = 0
      m.chartWidth = 0
      return
    step = stepFor bars
    m.barHeights = (band - (bars - 1 - i) * step for i in [0...bars])
    m.chartWidth = widthOf bars

  # the text lines' lengths, onto m: the full lines' is the whole px nearest
  # their span whose parity puts the content on the card's centre, capped by
  # the room the chart leaves; the third line is shorter by at least a px
  _slideTextMetrics: (m, S, across) ->
    room = across - m.gap - m.chartWidth
    parity = room % 2
    length = 2 * Math.round((S * @LINE_LENGTH / @GLYPH_GRID - parity) / 2) + parity
    m.length = Math.min length, room
    m.shortLength = Math.min Math.round(S * @SHORT_LINE_LENGTH / @GLYPH_GRID), m.length - 1

  # the text lines, t tall, from one left edge; the third (the last) is the
  # short one
  _slideText: (ctx, m) ->
    @_useInk ctx
    for i in [0...m.rows]
      length = if i is @LINES - 1 then m.shortLength else m.length
      ctx.fillRect m.textLeft, m.bandTop + i * m.pitch, length, m.t
    return

  # the bars, standing on the band's bottom row and rising left to right
  _slideChart: (ctx, m) ->
    @_useInk ctx
    baseline = m.bandTop + m.band
    for h, i in m.barHeights
      ctx.fillRect m.chartLeft + i * (m.barWidth + m.barGap), baseline - h, m.barWidth, h
    return
