class ObjectIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE object frame in the design's style: the FRAME of a filed or
  # aliased widget (GenericObjectIconWdgt), which lays the widget's own picture
  # (its representativeIcon) in the MIDDLE 50% of the glyph square -- 20 px at
  # the desktop's 40 px glyph. The frame is the family's document PAGE
  # (SizeAwareIconAppearance._pageMetrics / _page): a portrait sheet with a
  # folded top-right corner, one line t, paper inside, no halo. Its sheet is
  # 28 units wide around the 22-unit picture square, so the picture stands on
  # paper with 2.5 units to spare either side, and the page's fold stays above
  # that square. Tiers are the page's own (the flap drops to a plain cut where
  # its paper triangle would be under 2 px; a corner under 2 px is square);
  # under S 10 nothing is drawn.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 10
    S = Math.min wDev, hDev
    t = @_glyphLineUnit S
    page = @_pageMetrics x0 + Math.floor((wDev - S) / 2), y0 + Math.floor((hDev - S) / 2), S, t
    @_page ctx, page

