class FolderIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE folder (2026-07-21, converted with /convert-icon-size-aware; the
  # reference implementation and idiom docs are TypewriterIconAppearance and
  # docs/plans/pixel-icons-plan.md §5b). The old fixed-100-space version drew
  # its line-work at ~2.45 design units, fractional at every real display size
  # — on the non-AA backend different edges of the same path rounded to
  # different widths (thin top/left and tab lines, owner-reported). Here every
  # border is exactly t device pixels by construction, at every size.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, fractions of the inner square --------------------------
  SIDE_MARGIN: 0.05   # glyph left/right inset
  TAB_TOP:     0.13   # where the tab starts
  BODY_TOP:    0.25   # where the body starts (= the tab's height budget)
  BOTTOM_UP:   0.14   # bottom margin (the folder is wider than tall)
  TAB_WIDTH:   0.34
  CORNER:      0.05   # body corner radius (the tab uses half)

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 6

    t = Math.max 1, Math.round S / 32          # the line unit
    o = t                                      # halo/envelope thickness
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    ix = x + o
    iy = y + o
    iS = S - 2 * o

    ink = @_iconColorString()
    halo = @_outlineColorString()

    m = Math.round iS * @SIDE_MARGIN
    gx = ix + m                                # glyph x-range (symmetric)
    gw = iS - 2 * m
    bodyTop = iy + Math.round iS * @BODY_TOP
    tabTop = Math.min iy + Math.round(iS * @TAB_TOP), bodyTop - 2 * t
    bottom = iy + iS - Math.round iS * @BOTTOM_UP
    tabW = Math.min gw, Math.round(iS * @TAB_WIDTH)
    r = Math.max t, Math.round iS * @CORNER    # body corner radius
    rTab = Math.max 1, Math.round r / 2

    # ---- halos first (lesson 13: light must never be drawn over sibling ink;
    # painting every envelope before any ink makes that impossible)
    @_pxRoundRect ctx, gx - o, bodyTop - o, gw + 2 * o, (bottom - bodyTop) + 2 * o, r + o, halo
    @_pxRoundRect ctx, gx - o, tabTop - o, tabW + 2 * o, (bodyTop - tabTop) + 2 * o, rTab + o, halo

    # ---- the tab: its own bordered box; the parts reaching below bodyTop are
    # deliberately overpainted by the body, so only its top corners round
    @_pxRoundRect ctx, gx, tabTop, tabW, (bodyTop - tabTop) + r + t, rTab, ink
    @_pxRoundRect ctx, gx + t, tabTop + t, tabW - 2 * t, (bodyTop - tabTop) + r, Math.max(0, rTab - t), halo

    # ---- the body: bordered box over the tab's lower reaches; its top edge is
    # the full-width line the tab visibly sits on (as in the original)
    @_pxRoundRect ctx, gx, bodyTop, gw, bottom - bodyTop, r, ink
    @_pxRoundRect ctx, gx + t, bodyTop + t, gw - 2 * t, (bottom - bodyTop) - 2 * t, Math.max(0, r - t), halo
