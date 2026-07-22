class BinIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE bin icon (2026-07-22, owner-redesigned from a reference
  # drawing): the bin is where discarded widgets go, and its icon is
  # now a simple BIN -- a small handle over a wider lid over a gently
  # tapered body with three inner ridges. Light line art: outlines on the
  # tc unit, ridges on the hairline td (the reference is thin uniform
  # strokes), halo envelope on o. The tapered sides are quantized per row
  # with the SAME taper on the outer and inner trapezoids, so the walls
  # are exactly tc on every row. Fully integer-painted: the whole image is
  # byte-identical across backends.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, fractions of the glyph square (from the owner's
  # reference drawing) --------------------------------------------------------
  HANDLE_W: 0.20
  HANDLE_H: 0.07
  LID_W: 0.62
  LID_H: 0.09
  BODY_TOP_W: 0.52
  BODY_BOT_W: 0.43
  BODY_H: 0.55
  RIDGE_XS: [-0.11, 0, 0.11]  # ridge centers, offsets from the bin's center
  RIDGE_TOP: 0.06             # ridge clearance below the body's top
  RIDGE_BOT: 0.05             # ridge clearance above the body's bottom border

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 10
    # center the square glyph box in the widget box
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2

    t = Math.max 1, Math.round S / 32   # halo/envelope unit
    # the outlines: the 2px weight of the desktop rendering (the 95 shortcut
    # holder paints this icon at 76px, where round(S/45) = 2) is the icon's
    # look -- keep it down to 20px; under that, 2px walls don't fit the
    # bin's proportions. The ridges stay one step lighter throughout.
    tc = if S >= 20 then Math.max 2, Math.round S / 45 else 1
    td = Math.max 1, Math.round S / 64  # the ridges
    o = t
    ink = @_iconColorString()
    light = @_outlineColorString()

    # widths parity-normalized to S so every shape shares ONE exact center
    cw = (f) =>
      w = Math.max 1, Math.round S * f
      w++ if (S - w) % 2 isnt 0
      w
    handleW = cw @HANDLE_W
    lidW = cw @LID_W
    bodyTopW = cw @BODY_TOP_W
    bodyBotW = cw @BODY_BOT_W
    bodyBotW -= 2 if bodyBotW >= bodyTopW  # cw's parity nudge must not untaper
    handleH = Math.max 2 * tc, Math.round S * @HANDLE_H
    lidH = Math.max 2 * tc, Math.round S * @LID_H
    bodyH = Math.max 2 * tc + 2, Math.round S * @BODY_H
    topY = y + Math.round (S - handleH - lidH - bodyH) / 2
    handleX = x + (S - handleW) // 2
    lidX = x + (S - lidW) // 2
    bodyX = x + (S - bodyTopW) // 2
    lidY = topY + handleH
    bodyY = lidY + lidH

    # ---- halos first: with every halo down before any ink, none can
    # punch a border ----------------------------------------------------------
    ctx.fillStyle = light
    ctx.fillRect handleX - o, topY - o, handleW + 2 * o, handleH + 2 * o
    ctx.fillRect lidX - o, lidY - o, lidW + 2 * o, lidH + 2 * o
    for [rl, rw], ri in @_binBodyRows bodyX - o, bodyTopW + 2 * o, bodyBotW + 2 * o, bodyH + 2 * o
      ctx.fillRect rl, bodyY - o + ri, rw, 1

    # ---- ink silhouettes, then light interiors (border idiom) ---------------
    ctx.fillStyle = ink
    ctx.fillRect handleX, topY, handleW, handleH
    ctx.fillRect lidX, lidY, lidW, lidH
    for [rl, rw], ri in @_binBodyRows bodyX, bodyTopW, bodyBotW, bodyH
      ctx.fillRect rl, bodyY + ri, rw, 1
    ctx.fillStyle = light
    # the handle is BOTTOMLESS -- its interior runs down to the lid, whose
    # own top line closes the shape (a drawn handle bottom would sit on the
    # lid's top border and read as one doubled, thicker line)
    if handleW - 2 * tc >= 1 and handleH - tc >= 1
      ctx.fillRect handleX + tc, topY + tc, handleW - 2 * tc, handleH - tc
    if lidW - 2 * tc >= 1 and lidH - 2 * tc >= 1
      ctx.fillRect lidX + tc, lidY + tc, lidW - 2 * tc, lidH - 2 * tc
    # the body has no top border of its own -- the lid's bottom edge is the
    # bin's top line -- so the interior starts at the body's first row and
    # stops above the tc bottom border
    for [rl, rw], ri in @_binBodyRows bodyX + tc, bodyTopW - 2 * tc, bodyBotW - 2 * tc, bodyH
      break if ri >= bodyH - tc
      ctx.fillRect rl, bodyY + ri, rw, 1

    # ---- the three ridges: td verticals, clear of the walls and of the
    # lid/bottom (a ridge that can't keep 1px of light off the slanted
    # wall at its lowest row is dropped) --------------------------------------
    rTop = bodyY + Math.max 1, Math.round S * @RIDGE_TOP
    rBot = bodyY + bodyH - tc - Math.max 1, Math.round S * @RIDGE_BOT
    return if rBot - rTop < 2
    innerHalfAtBot = (bodyBotW - 2 * tc) // 2
    ctx.fillStyle = ink
    for offF in @RIDGE_XS
      rx = x + Math.round((S - td) / 2) + Math.round offF * S
      halfSpan = Math.abs(rx + (if offF > 0 then td else 0) - (x + S / 2))
      continue if halfSpan + 1 > innerHalfAtBot
      ctx.fillRect rx, rTop, td, rBot - rTop

  # per-row [left x, width] spans of the tapered body (top wider than the
  # bottom), the slanted sides quantized one row at a time
  _binBodyRows: (bx, topW, botW, h) ->
    for r in [0...h]
      ins = Math.round (topW - botW) / 2 * (if h is 1 then 0 else r / (h - 1))
      [bx + ins, topW - 2 * ins]
