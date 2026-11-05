class ObjectIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE object frame in the design's style: the FRAME of a document, a
  # filed or an aliased widget (GenericObjectIconWdgt), which lays the widget's
  # own picture (its representativeIcon -- for a document, its kind's glyph) in
  # the page's PICTURE square, PAGE_PICTURE of the glyph square's 44 units
  # centred in it -- 28 px at the desktop's 40 px glyph. The frame is the
  # family's document PAGE (SizeAwareIconAppearance._pageMetrics / _page): a
  # portrait sheet with a folded top-right corner, one line t, paper inside, no
  # halo, as tall as the glyph square and 35 units wide around the 31-unit
  # picture square, so the picture stands on a unit of paper either side, and
  # the page's fold stays above that square. Tiers are the page's own (the flap
  # drops to a plain cut where its paper triangle would be under 2 px; a corner
  # under 2 px is square); under S 10 nothing is drawn.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    page = @_pageMetrics x0 + Math.floor((wDev - S) / 2), y0 + Math.floor((hDev - S) / 2), S, t
    @_page ctx, page

