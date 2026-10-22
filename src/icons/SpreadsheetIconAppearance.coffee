class SpreadsheetIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE spreadsheet in the design's style: the spreadsheet's own icon
  # (SpreadsheetIconWdgt -- the Examples folder's Spreadsheet launcher through
  # AppCatalog, and a filed or aliased sheet through SimpleSpreadsheetWdgt's
  # representativeIcon), 40 px on the desktop and in a folder, 80 at dpr 2.
  # It stands on the family's shared CONTENT CARD (_contentCardMetrics /
  # _contentCard), ruled as a sheet:
  #   - the CARD: one rounded outline, its walls t;
  #   - the GRID on the card's paper: t-wide GRIDLINES, each running wall to
  #     wall (it meets the card's walls in a T and shares their line: one
  #     line, never a doubled band), so every cell is a paper box between
  #     lines of one thickness: a narrow HEADER ROW and a narrow HEADER COLUMN,
  #     then BODY_COLUMNS x BODY_ROWS cells sharing the rest -- one size, the
  #     left-most (top-most) a px larger where the rest does not divide evenly,
  #     so the header bands stay narrow.
  # Clearance is a spec (GenericPanel's rule): a gridline crosses a wall on the
  # wall's STRAIGHT, never on the card's corner arc -- so a header band is at
  # least the corner radius less t plus MIN_CLEARANCE px; where the header
  # bands' target is less, they take that.
  #   Detail by rule: a body cell keeps MIN_CELL px of paper across and down;
  # where the columns (or rows) would not, the grid loses a column (or a row)
  # -- body members drop, the headers stay, so the grid keeps its
  # header-and-body reading as long as one body cell fits; a body COLUMN is
  # always WIDER than the header column (a header as wide as a cell reads as a
  # cell), else the grid loses a column too (a body row may equal the header
  # row); with no body cell left the grid drops and the card is drawn empty.
  # Under S 10 nothing is drawn.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, GLYPH_GRID units; the card's are the base's CONTENT_CARD_* --
  HEADER_COLUMN: 4      # the header column's paper width (the row numbers)
  HEADER_ROW: 3.5       # the header row's paper height (the column letters)
  BODY_COLUMNS: 3       # body columns ...
  BODY_ROWS: 3          # ... and rows at the full size
  # ---- detail tiers -----------------------------------------------------------
  MIN_CELL: 2           # px of paper a body cell keeps across and down
  MIN_CLEARANCE: 1      # px of straight wall between a gridline and the card's corner arc

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    m = @_sheetMetrics x0, y0, wDev, hDev
    @_contentCard ctx, m.card
    @_sheetGrid ctx, m

  # the card, its paper's box, and each axis's gridline offsets from the
  # paper's left (xs) and top (ys) edges, in device px
  _sheetMetrics: (x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    card = @_contentCardMetrics x0 + Math.floor((wDev - S) / 2), y0 + Math.floor((hDev - S) / 2), S, t
    px = (units) => Math.round S * units / @GLYPH_GRID
    paperW = card.right - card.left - 2 * t
    paperH = card.bottom - card.top - 2 * t
    # the least band before a gridline: clear of the corner arc (the inner radius is r - t)
    least = Math.max @MIN_CELL, card.r - t + @MIN_CLEARANCE
    # the header COLUMN is always narrower than a body column (it is what says "spreadsheet");
    # the header row may equal a body row (rows are short anyway), so the row count does not
    # flicker with the corner radius that sets the header's least height
    xs = @_sheetAxis paperW, px(@HEADER_COLUMN), @BODY_COLUMNS, true, least, t
    ys = @_sheetAxis paperH, px(@HEADER_ROW), @BODY_ROWS, false, least, t
    # a header with no body has nothing to head: both axes need a body cell
    if xs.length is 0 or ys.length is 0
      xs = []
      ys = []
    m =
      t: t
      card: card
      paperL: card.left + t
      paperT: card.top + t
      paperW: paperW
      paperH: paperH
      xs: xs
      ys: ys
    m

  # one axis: a header band of its target `head` px (at least `least`), then
  # n body cells of one size sharing the rest of `room`, the first ones a px
  # larger where it does not divide evenly. A body cell under MIN_CELL -- or,
  # with cellOverHeader, no larger than its header band (a header as large as
  # a cell reads as no header) -- loses a body member. Answers the gridlines'
  # offsets (one before each body cell), empty when no body cell fits.
  _sheetAxis: (room, head, n, cellOverHeader, least, t) ->
    while n >= 1
      header = Math.max head, least
      body = room - header - n * t
      cell = Math.floor body / n
      if cell < @MIN_CELL or (cellOverHeader and cell <= header)
        n--
        continue
      extra = body - n * cell
      lines = []
      at = header
      for i in [0...n]
        lines.push at
        at += t + cell + (if i < extra then 1 else 0)
      return lines
    []

  # every gridline wall to wall across the paper, in ink, t wide
  _sheetGrid: (ctx, m) ->
    @_useInk ctx
    for dx in m.xs
      ctx.fillRect m.paperL + dx, m.paperT, m.t, m.paperH
    for dy in m.ys
      ctx.fillRect m.paperL, m.paperT + dy, m.paperW, m.t
