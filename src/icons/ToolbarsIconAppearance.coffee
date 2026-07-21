class ToolbarsIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE "super toolbar" icon (2026-07-21, converted with
  # /convert-icon-size-aware; reference implementation + idiom docs are
  # TypewriterIconAppearance and docs/plans/pixel-icons-plan.md §5b).
  # HYBRID: the cape and the flexing arms keep the original fractional
  # bezier artwork -- big fills and >=1-device-px strokes render fine on the
  # non-AA backend at every size -- while the toolbar column is REDRAWN in
  # integer device pixels: a 1px-in-design-space stroke scales to ~half a
  # device pixel at the real display sizes (launcher 60px, info-doc 85px),
  # and sub-pixel strokes drop out, or dash, under the non-AA backend.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, fractions of the glyph square (numbers from the
  # original 100-space drawing) ----------------------------------------------
  COL_W: 0.17         # toolbar column width (41.5..58.5)
  COL_TOP: 0.065      # column top edge (6.5)
  COL_BOT: 0.925      # column bottom edge (92.5)
  HEADER_H: 0.105     # gray title-bar band height (7.5..16.5)
  BOX_K: 0.4          # tool-box square side, fraction of column width (6/17
                      #   in the original, nudged up because the size-aware
                      #   ring walls are thicker than the original 1px stroke)
  HEADER_LINE_W: 0.65 # white title-line width, fraction of column interior
  N_COMPARTMENTS: 5   # the design's tool-box count -- fewer only when they
                      #   stop fitting (clearance rule, not a cap)
  HEADER_BG: 'rgb(170, 170, 170)'

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 10
    # center the square glyph box in the widget box
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2

    @_paintCapeAndArms ctx, x, y, S / 100
    m = @_toolbarsMetrics S
    return unless m?
    @_paintColumn ctx, x, y, m
    @_paintHeader ctx, x, y, m
    @_paintCompartments ctx, x, y, m

  # every shared measurement of the integer-pixel column, computed once from
  # the glyph size S (device px)
  _toolbarsMetrics: (S) ->
    t = Math.max 1, Math.round S / 32   # structural line unit: column border
    tc = Math.max 1, Math.round S / 45  # lighter unit: dividers, box rings,
                                        #   header line (visual hierarchy)
    o = t                               # halo/envelope thickness
    Wc = Math.max Math.round(S * @COL_W), 2 * t + 2
    xL = Math.round (S - Wc) / 2
    yT = Math.max o, Math.round(S * @COL_TOP)
    yB = Math.round S * @COL_BOT
    H = yB - yT
    return nil if H < 4 * t

    hH = Math.round S * @HEADER_H
    hH = 0 if hH < 2                    # too thin to read as the title bar
    innerH = H - 2 * t
    headerSpan = if hH > 0 then hH + tc else 0
    compTop = yT + t + headerSpan
    compAvail = innerH - headerSpan

    # as many of the design's compartments as actually fit -- one shorter
    # than minComp reads as a line, not a box
    minComp = 4
    n = @N_COMPARTMENTS
    loop
      compH = Math.floor (compAvail - (n - 1) * tc) / n
      break if compH >= minComp or n is 1
      n--
    n = 0 if compH < 2

    # hand the leftover pixels, one each, to the bottommost compartments
    leftover = compAvail - (n - 1) * tc - n * compH
    comps = []
    cy = compTop
    for i in [0...n]
      h = compH + (if i >= n - leftover then 1 else 0)
      comps.push [cy, h]
      cy += h + tc

    { S, t, tc, o, Wc, xL, yT, H, hH, comps }

  # the cape + flexing arms, kept as the ORIGINAL fractional bezier artwork
  # in the scaled 100-wide design space: the light silhouette (fill + wide
  # stroke -- this IS the halo envelope), the two dark cape triangles, the
  # two arm strokes. The one size-aware touch: the arms' design lineWidth 3
  # falls below one device pixel when the scale drops under ~1/3, and a
  # sub-pixel stroke shreds under the non-AA backend -- clamp it to one
  # device pixel.
  _paintCapeAndArms: (ctx, x, y, sc) ->
    ctx.save()
    ctx.translate x, y
    ctx.scale sc, sc

    # silhouette: column + arms + cape outline, filled and thickly stroked
    # in the light color
    ctx.beginPath()
    ctx.moveTo 41.5, 6.5
    ctx.lineTo 58.5, 6.5
    ctx.lineTo 58.5, 28.5
    ctx.bezierCurveTo 58.5, 28.5, 62.75, 24, 66.5, 23.5
    ctx.bezierCurveTo 70.25, 23, 75.5, 29.5, 75.5, 26.5
    ctx.bezierCurveTo 75.5, 23.5, 78.25, 22, 76.5, 19.5
    ctx.bezierCurveTo 74.75, 17, 70.25, 18, 68.5, 16.5
    ctx.bezierCurveTo 66.75, 15, 67.75, 14.25, 69.5, 13.5
    ctx.bezierCurveTo 71.25, 12.75, 72, 10.25, 75.5, 13.5
    ctx.bezierCurveTo 79, 16.75, 81.5, 21.5, 83.5, 26.5
    ctx.bezierCurveTo 85.5, 31.5, 83.5, 33.5, 83.5, 33.5
    ctx.lineTo 60.5, 40.5
    ctx.lineTo 76.5, 84.5
    ctx.lineTo 58.5, 82.5
    ctx.lineTo 58.5, 92.5
    ctx.lineTo 39.5, 92.5
    ctx.lineTo 39.5, 82.5
    ctx.lineTo 22.5, 84.5
    ctx.lineTo 37.5, 40.5
    ctx.lineTo 30.5, 40.5
    ctx.lineTo 15.5, 33.5
    ctx.bezierCurveTo 15.5, 33.5, 15.75, 24.5, 18.5, 19.5
    ctx.bezierCurveTo 21.25, 14.5, 23.5, 14.25, 26.5, 13.5
    ctx.bezierCurveTo 29.5, 12.75, 31.5, 15, 30.5, 16.5
    ctx.bezierCurveTo 29.5, 18, 24.5, 17, 22.5, 19.5
    ctx.bezierCurveTo 20.5, 22, 20.5, 25.5, 22.5, 26.5
    ctx.bezierCurveTo 24.5, 27.5, 26, 23, 30.5, 23.5
    ctx.bezierCurveTo 35, 24, 41.5, 28.5, 41.5, 28.5
    ctx.lineTo 41.5, 6.5
    ctx.closePath()
    ctx.fillStyle = @_outlineColorString()
    ctx.fill()
    ctx.strokeStyle = @_outlineColorString()
    ctx.lineWidth = 7
    ctx.stroke()

    # the two dark cape triangles
    ctx.beginPath()
    ctx.moveTo 38.85, 36.81
    ctx.lineTo 22.35, 84.12
    ctx.bezierCurveTo 22.35, 84.12, 28.76, 82.81, 38.85, 82.22
    ctx.lineTo 38.85, 36.81
    ctx.closePath()
    ctx.moveTo 60.15, 36.81
    ctx.lineTo 60.15, 82.22
    ctx.bezierCurveTo 70.24, 82.81, 76.65, 84.12, 76.65, 84.12
    ctx.lineTo 60.15, 36.81
    ctx.closePath()
    ctx.fillStyle = @_iconColorString()
    ctx.fill()

    # the two flexing arms
    ctx.strokeStyle = @_iconColorString()
    ctx.lineWidth = Math.max 3, 1 / sc  # never below one device pixel
    ctx.miterLimit = 4
    ctx.lineCap = 'round'
    ctx.beginPath()
    ctx.moveTo 37.99, 38.14
    ctx.bezierCurveTo 36.88, 38.4, 35.77, 38.4, 34.83, 38.4
    ctx.bezierCurveTo 30.29, 38.4, 27.21, 37.19, 24.39, 36.06
    ctx.bezierCurveTo 21.91, 35.11, 15.67, 33.9, 15.58, 33.29
    ctx.bezierCurveTo 14.73, 29.22, 19.09, 16.93, 24.13, 13.56
    ctx.bezierCurveTo 25.93, 12.35, 27.81, 12.35, 29.35, 13.47
    ctx.bezierCurveTo 30.55, 14.34, 30.89, 15.63, 30.38, 16.85
    ctx.bezierCurveTo 29.78, 18.32, 23.98, 19.44, 22.1, 19.7
    ctx.bezierCurveTo 22.36, 21.61, 22.5, 24.5, 23.33, 26.9
    ctx.bezierCurveTo 25.38, 25.6, 29.78, 22.91, 32, 23.51
    ctx.bezierCurveTo 33.46, 23.94, 37.85, 25.24, 38.45, 29.57
    ctx.stroke()
    ctx.beginPath()
    ctx.moveTo 60.96, 38.14
    ctx.bezierCurveTo 62.07, 38.4, 63.18, 38.4, 64.12, 38.4
    ctx.bezierCurveTo 68.66, 38.4, 71.73, 37.19, 74.56, 36.06
    ctx.bezierCurveTo 77.04, 35.11, 83.28, 33.9, 83.37, 33.29
    ctx.bezierCurveTo 84.22, 29.22, 79.86, 16.93, 74.81, 13.56
    ctx.bezierCurveTo 73.02, 12.35, 71.14, 12.35, 69.6, 13.47
    ctx.bezierCurveTo 68.4, 14.34, 68.06, 15.63, 68.57, 16.85
    ctx.bezierCurveTo 69.17, 18.32, 74.96, 19.44, 76.85, 19.7
    ctx.bezierCurveTo 76.59, 21.61, 76.45, 24.5, 75.62, 26.9
    ctx.bezierCurveTo 73.56, 25.6, 69.17, 22.91, 66.95, 23.51
    ctx.bezierCurveTo 65.49, 23.94, 61.1, 25.24, 60.5, 29.57
    ctx.stroke()
    ctx.restore()

  # the column: its own light halo envelope, dark border (fill-then-inset
  # idiom -- the border can never thin below t), light interior
  _paintColumn: (ctx, x, y, m) ->
    {t, o, Wc, xL, yT, H} = m
    ctx.fillStyle = @_outlineColorString()
    ctx.fillRect x + xL - o, y + yT - o, Wc + 2 * o, H + 2 * o
    ctx.fillStyle = @_iconColorString()
    ctx.fillRect x + xL, y + yT, Wc, H
    ctx.fillStyle = @_outlineColorString()
    ctx.fillRect x + xL + t, y + yT + t, Wc - 2 * t, H - 2 * t

  # the gray title-bar band with its white title line, plus the divider
  # separating it from the first compartment
  _paintHeader: (ctx, x, y, m) ->
    {t, tc, Wc, xL, yT, hH} = m
    return if hH is 0
    iw = Wc - 2 * t
    ctx.fillStyle = @HEADER_BG
    ctx.fillRect x + xL + t, y + yT + t, iw, hH
    ctx.fillStyle = @_iconColorString()
    ctx.fillRect x + xL + t, y + yT + t + hH, iw, tc
    # the white line keeps >=1px of gray on every side (clearance is a
    # spec: rounding can otherwise land its end on the column's ink)
    lw = Math.min Math.round(iw * @HEADER_LINE_W), iw - 2
    if hH >= 3 * tc and lw >= 1
      ctx.fillStyle = Color.WHITE.toString()
      ctx.fillRect x + xL + t + Math.round((iw - lw) / 2),
        y + yT + t + Math.round((hH - tc) / 2), lw, tc

  # the tool-box compartments: tc-thick dividers between them, a square tool
  # glyph centered in each -- a hollow ring when the hole survives, a solid
  # dot when smaller, nothing once even a dot can't keep 1px of clearance
  _paintCompartments: (ctx, x, y, m) ->
    {t, tc, Wc, xL, comps} = m
    iw = Wc - 2 * t
    ink = @_iconColorString()
    light = @_outlineColorString()
    for [cy, ch], i in comps
      if i > 0
        ctx.fillStyle = ink
        ctx.fillRect x + xL + t, y + cy - tc, iw, tc
      k = Math.min Math.round(Wc * @BOX_K), iw - 2, ch - 2
      continue if k < 2
      kx = x + xL + t + Math.round((iw - k) / 2)
      ky = y + cy + Math.round((ch - k) / 2)
      ctx.fillStyle = ink
      ctx.fillRect kx, ky, k, k
      if k - 2 * tc >= 2
        ctx.fillStyle = light
        ctx.fillRect kx + tc, ky + tc, k - 2 * tc, k - 2 * tc
