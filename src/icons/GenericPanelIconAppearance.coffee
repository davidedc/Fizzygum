class GenericPanelIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE generic-panel icon in the design's style, the launcher icon of
  # the Generic panel maker and a generic panel's shortcut icon: the draft's
  # "panel" glyph (docs/archive/redesign/desktop-canvas.html), drawn by the idiom
  # of docs/plans/pixel-icons-plan.md §5b. Line art in ink, every line on the
  # glyph line unit t (SizeAwareIconAppearance._glyphLineUnit), with paper
  # interiors and no halo envelope (the tile the icon stands on is its ground):
  #   - the CARD is the design's content card (SizeAwareIconAppearance.
  #     _contentCard): one rounded outline, its four walls t thick;
  #   - two TOOLBARS lie on it, each a rounded box across one of its corners:
  #     the LEFT one across its bottom-left corner, out past its left edge and
  #     down past its bottom edge; the RIGHT one across its top-right corner,
  #     up past its top edge and out past its right edge;
  #   - in each toolbar, BUTTON LINES one under another, t tall: three in the
  #     left toolbar, two in the right one.
  #   A toolbar is the border idiom: its ink, then the same box inset by t in
  #   paper, its corner radius t less, so its walls are t and its corners
  #   concentric. Its paper covers the card inside it, so each of the card's
  #   walls it crosses passes UNDER it: the wall runs into one of the toolbar's
  #   walls and out of the next, a T where they meet, and the toolbar's wall
  #   there stays one t line.
  #   The two toolbars are one width, and their button lines one layout, so
  #   they read as one family: the lines centred across the toolbar's paper,
  #   the first a step below its top, the rest one pitch apart. The layout
  #   also PLACES the toolbars down the card: where the card's wall passes
  #   under a toolbar it keeps a gap of paper from the button line nearest it,
  #   so it never reads as a line running on through the toolbar -- the left
  #   toolbar's lines all stand above the card's bottom wall, and the card's
  #   top wall passes under the right toolbar between its two lines.
  #   Clearance is a spec: a card wall passing under a toolbar keeps a px of
  #   paper from the toolbar's walls that run beside it, crosses the
  #   toolbar's walls clear of their rounded corners, and on its own straight
  #   (never on the card's corner arc); where the draft's measures fall short
  #   of that, the toolbar reaches further out past the card, or is wider. A
  #   button line keeps a px of paper from its toolbar's walls and from the
  #   next line.
  #   Detail by rule: the step shrinks where the right toolbar's top would
  #   leave the glyph square. The left toolbar's top sits no higher than where
  #   the card's left wall runs straight; where its lines would put it higher,
  #   the step shrinks, then the left toolbar's lines close up (its pitch
  #   alone shrinks), then its bottom-most line drops. The right toolbar keeps
  #   its second line only where the pitch leaves room for the card's wall
  #   between its lines and the line keeps a px of paper above its bottom
  #   wall. A toolbar whose paper is too narrow for MIN_BUTTON px of line with
  #   a px of paper each side holds no lines. A toolbar that would leave the
  #   glyph square drops, the right one first: it is drawn only with the left
  #   one.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, in GLYPH_GRID units: u units are round(S * u /
  # GLYPH_GRID) px at a glyph square of S px; the card's are the base's
  # CONTENT_CARD_*. The INK extents of a one-unit line on the draft glyph's
  # path (its centre line moved out by half a unit; a button line's round caps
  # reach half a unit past its ends), each toolbar measured from the card edges
  # it crosses, as the card is centred in S; a toolbar's top follows from the
  # button layout, and its fourth side from the width.
  TOOLBAR_WIDTH: 9          # both toolbars' outer ink width (path rects 8 wide)
  TOOLBAR_CORNER: 2.5       # their outer corner radius (path radius 2; the inner one is t less)
  LEFT_TOOLBAR_OUT: 3       # how far the left toolbar reaches out past the card's left edge (path x 2 against 5)
  LEFT_TOOLBAR_BELOW: 5     # how far it hangs below the card's bottom edge (path y 39 against 34)
  RIGHT_TOOLBAR_OUT: 1      # how far the right toolbar reaches out past the card's right edge (path x 40 against 39)
  RIGHT_TOOLBAR_BOTTOM: 13  # its bottom edge, below the card's top edge (path y 22 against 10)
  BUTTON_LENGTH: 4          # a button line's ink length (path h3, its round caps half a unit past each end)
  BUTTON_TOP: 5             # the step from a toolbar's top edge to its first button line's top (path y 15 to 20, and 4 to 9)
  BUTTON_PITCH: 6           # from a button line's top to the next one's (path y 20, 26, 32 and 9, 15)
  BUTTON_TO_CARD: 1         # the paper between the card's wall passing under a toolbar and the button line nearest it (the left toolbar's, path y 32 against 34; the draft's right toolbar has its first line flush on the card's top line, so here it rises a unit higher)
  LEFT_BUTTONS: 3           # the left toolbar's button lines (path M4.5 20h3 M4.5 26h3 M4.5 32h3)
  RIGHT_BUTTONS: 2          # the right toolbar's (path M34.5 9h3 M34.5 15h3)
  # ---- detail tiers -----------------------------------------------------------
  MIN_CORNER: 2             # px: a smaller corner radius is square
  MIN_CLEARANCE: 1          # px of paper a card wall keeps from a toolbar's walls beside it, and a button line from its toolbar's walls and the next line
  MIN_BUTTON: 1             # px: the shortest button line

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_panelMetrics x0, y0, wDev, hDev
    @_contentCard ctx, m.card
    @_panelToolbar ctx, m, toolbar for toolbar in m.toolbars
    return

  # every measurement the icon is built from, in whole device px
  _panelMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    card = @_contentCardMetrics x, y, S, t
    px = (units) => Math.round S * units / @GLYPH_GRID
    r = px @TOOLBAR_CORNER
    r = 0 if r < @MIN_CORNER
    m =
      t: t
      card: card
      r: r
      # how far a card wall passing under a toolbar stands from the toolbar's
      # outer edges beside it: past its wall and a px of paper, and past its
      # corner's arc
      clear: Math.max t + @MIN_CLEARANCE, r
      toolbars: []
    m.leftOut = Math.max m.clear, px @LEFT_TOOLBAR_OUT
    m.rightOut = Math.max m.clear, px @RIGHT_TOOLBAR_OUT
    # one width for both: the draft's, or wider where the card's wall passing
    # under would not keep its clearance from the far side, or would leave the
    # toolbar on the card's corner arc
    m.width = Math.max px(@TOOLBAR_WIDTH), Math.max(m.leftOut, m.rightOut) + t + Math.max(m.clear, card.r)
    @_panelButtonMetrics m, S, px, y
    left = @_panelLeftToolbar m, px
    right = @_panelRightToolbar m, px
    if left.left >= x and left.bottom <= y + S and left.top >= m.leftTopLeast
      m.toolbars.push left
      m.toolbars.push right if right.top >= y and right.right <= x + S
    m

  # the button lines, onto m: their length, and their layout down a toolbar --
  # the first line's step below the toolbar's top and the paper gap from the
  # card's wall, one for both toolbars, and the pitch. The step shrinks where
  # the right toolbar's top would leave the square. The left toolbar's lines
  # stand above the card's bottom wall, its top the step above them and no
  # higher than where the card's left wall runs straight (leftTopLeast):
  # where it would be, the step shrinks, then the left toolbar's lines close
  # up (leftPitch), then its bottom-most line drops
  _panelButtonMetrics: (m, S, px, y) ->
    {t, card} = m
    inside = m.width - 2 * t
    across = inside - 2 * @MIN_CLEARANCE
    # the nearest whole px to the line's length with the paper's parity, so
    # the line sits on its exact centre
    length = 2 * Math.round((S * @BUTTON_LENGTH / @GLYPH_GRID - inside) / 2) + inside
    length += 2 while length < @MIN_BUTTON
    m.buttonLength = if across >= @MIN_BUTTON then Math.min length, across else 0
    m.buttonInset = t + (inside - m.buttonLength) / 2
    least = t + @MIN_CLEARANCE
    m.buttonGap = Math.max @MIN_CLEARANCE, px @BUTTON_TO_CARD
    m.buttonPitch = Math.max least, px @BUTTON_PITCH
    step = Math.max least, Math.min px(@BUTTON_TOP), card.top - m.buttonGap - t - y
    m.leftTopLeast = card.top + Math.max card.r, least
    # from that highest top to the left toolbar's last line's top
    room = card.bottom - t - m.buttonGap - t - m.leftTopLeast
    pitch = m.buttonPitch
    n = @LEFT_BUTTONS
    until n is 1 or step + (n - 1) * pitch <= room
      if step > least
        step = Math.max least, room - (n - 1) * pitch
      else if pitch > least
        pitch = Math.max least, Math.floor (room - step) / (n - 1)
      else
        n--
    m.buttonStep = step
    m.leftPitch = pitch
    m.leftButtons = n

  # the left toolbar's box and its lines' tops: out past the card's left edge
  # and down past its bottom one, its lines standing a gap of paper above the
  # card's bottom wall and its top the first line's step above them
  _panelLeftToolbar: (m, px) ->
    {t, card} = m
    lastTop = card.bottom - t - m.buttonGap - t
    firstTop = lastTop - (m.leftButtons - 1) * m.leftPitch
    toolbar =
      left: card.left - m.leftOut
      top: firstTop - m.buttonStep
      bottom: card.bottom + Math.max m.clear, px @LEFT_TOOLBAR_BELOW
      lineTops: (firstTop + i * m.leftPitch for i in [0...m.leftButtons])
    toolbar.right = toolbar.left + m.width
    toolbar.lineTops = [] unless m.buttonLength > 0
    toolbar

  # the right toolbar's box and its lines' tops: up past the card's top edge
  # and out past its right one, the card's top wall passing under it a gap of
  # paper below its first line. Its second line stands below that wall, where
  # the pitch leaves it a gap of paper too, and above the toolbar's bottom
  # wall, keeping a px of paper from it
  _panelRightToolbar: (m, px) ->
    {t, card} = m
    firstTop = card.top - m.buttonGap - t
    toolbar =
      right: card.right + m.rightOut
      top: firstTop - m.buttonStep
      # the card's right wall leaves it from its straight, clear of the
      # toolbar's corner
      bottom: card.top + Math.max px(@RIGHT_TOOLBAR_BOTTOM), t + Math.max(m.clear, card.r)
      lineTops: [firstTop]
    toolbar.left = toolbar.right - m.width
    for i in [1...@RIGHT_BUTTONS]
      top = firstTop + i * m.buttonPitch
      break unless top >= card.top + t + m.buttonGap and top + t + @MIN_CLEARANCE <= toolbar.bottom - t
      toolbar.lineTops.push top
    toolbar.lineTops = [] unless m.buttonLength > 0
    toolbar

  # a toolbar: its ink, then its paper inset by t (the corner radius t less, so
  # the corners stay concentric), which covers the card under it; then its
  # button lines, each a t-tall bar of ink on that paper
  _panelToolbar: (ctx, m, toolbar) ->
    {t, r} = m
    w = toolbar.right - toolbar.left
    h = toolbar.bottom - toolbar.top
    @_useInk ctx
    ctx.fillRoundRect toolbar.left, toolbar.top, w, h, r
    @_usePaper ctx
    ctx.fillRoundRect toolbar.left + t, toolbar.top + t, w - 2 * t, h - 2 * t, Math.max 0, r - t
    @_useInk ctx
    for top in toolbar.lineTops
      ctx.fillRect toolbar.left + m.buttonInset, top, m.buttonLength, t
    return
