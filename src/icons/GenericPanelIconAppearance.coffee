class GenericPanelIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE generic-panel icon (2026-07-21, converted with
  # /convert-icon-size-aware; idiom docs: docs/plans/pixel-icons-plan.md §5b):
  # a rounded panel -- the slide-card shape shared with the SimpleSlide /
  # Dashboards / PatchProgramming icons, drawn through the base's reusable
  # _pxPanel so every corner carries the same quantized ring -- with two
  # small floating toolbars overlapping its edges. The toolbars follow the
  # super-toolbar column's recipe at the finer tc weight but stay LOCAL:
  # they are thinner and smaller than the super-toolbar's column, not worth
  # a shared abstraction. Fully integer-painted, so unlike the hybrid
  # Toolbars icon the whole image is byte-identical across backends.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, fractions of the glyph square (numbers from the
  # original 100-space drawing) ----------------------------------------------
  PANEL_L: 0.09       # panel ink rect (9..92 x 20..80)
  PANEL_T: 0.20
  PANEL_R: 0.92
  PANEL_B: 0.80
  PANEL_RADIUS: 0.06  # the design's ~6-unit corner, fraction of S
  # the two mini toolbars: [frame left, frame top, design box count, hangs
  # below the panel]. The 4-vs-3 length asymmetry is part of the design --
  # box count only drops when even a shrunk column can't fit
  TOOLBARS: [[0.17, 0.32, 4, true], [0.71, 0.05, 3, false]]
  TB_IW: 0.13         # toolbar interior width (the 13-unit box column)
  TB_HEADER_H: 0.07   # gray header interior height (~7 units)
  BOX_K: 0.45         # inner square side, fraction of the box interior (5/13
                      #   in the original, nudged up because the size-aware
                      #   ring walls are thicker than the original 1px stroke)
  HEADER_LINE_W: 0.7  # white title-line width, fraction of interior
  HEADER_BG: 'rgb(170, 170, 170)'

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < 10
    # center the square glyph box in the widget box
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2

    u =
      S: S
      t: Math.max 1, Math.round S / 32  # structural unit: panel border
      tc: Math.max 1, Math.round S / 45 # lighter unit: all toolbar line work
      td: Math.max 1, Math.round S / 64 # detail unit: the tool-box rings
      ink: @_iconColorString()
      light: @_outlineColorString()
    u.o = u.t                           # halo/envelope thickness

    # the landscape rounded card
    px = x + Math.round S * @PANEL_L
    py = y + Math.round S * @PANEL_T
    pw = Math.round(S * @PANEL_R) - Math.round(S * @PANEL_L)
    ph = Math.round(S * @PANEL_B) - Math.round(S * @PANEL_T)
    r = Math.max u.t, Math.round(S * @PANEL_RADIUS)
    @_pxPanel ctx, px, py, pw, ph, r, u.t, u.o, u.ink, u.light

    # a toolbar's light backing may punch the panel's TOP border (right
    # toolbar) and BOTTOM border (left toolbar) -- that's the design -- but
    # must never eat a border it isn't meant to cross: the backing is capped
    # short of each such border's ink (crossing the ink is a defect, and
    # rounding at small sizes does cross without the clamps). On the RIGHT
    # the cap keeps an extra o of interior beyond the backing, so the
    # toolbar's frame shows 2o of light before the panel border instead of
    # sitting right next to it. The left toolbar may run to the glyph
    # bottom; the right one stops above the panel's bottom border.
    # Both toolbars paint at ONE shared column width -- the narrower of
    # their two shrink-fits -- so they read as the same family. Each also
    # clamps clear of the PREVIOUS one's frame (at tiny sizes the border
    # clamps squeeze them into each other), and a toolbar that still can't
    # keep every hard clearance is dropped rather than painted overlapping.
    yMaxFor = (hangsBelow) => if hangsBelow then y + S else py + ph - u.t
    iw = nil
    for [fx, fy, nBoxes, hangsBelow] in @TOOLBARS
      fit = @_toolbarFitIW u, fy, nBoxes, y, yMaxFor hangsBelow
      iw = fit if not iw? or fit < iw
    # the min clamp starts past the panel's corner-arc region (px + r, not
    # just past the border ink): the left toolbar punches the BOTTOM border,
    # and crossing it inside the rounded corner mangles the arc
    prevFrameRight = 0
    for [fx, fy, nBoxes, hangsBelow] in @TOOLBARS
      frameRight = @_paintMiniToolbar ctx, x, y, u, iw, fx, fy, nBoxes,
        Math.max(px + r, prevFrameRight), px + pw - u.t - u.o, yMaxFor hangsBelow
      prevFrameRight = frameRight if frameRight?

  # the shrink-to-fit column width for one toolbar: boxes are square
  # (side = iw), so the column narrows first (down to a floor) to keep the
  # design's box count -- the 4-box left toolbar would otherwise lose its
  # length asymmetry at every real display size -- and only then would
  # boxes drop
  _toolbarFitIW: (u, fy, nDesign, y, yMaxBacking) ->
    {S, tc} = u
    iw = Math.max Math.round(S * @TB_IW), 2
    hH = Math.round S * @TB_HEADER_H
    hH = 0 if hH < 2
    headerSpan = if hH > 0 then hH + tc else 0
    avail = yMaxBacking - (y + Math.round S * fy) - u.o
    n = nDesign
    while (2 * tc + headerSpan + n * iw + (n - 1) * tc) > avail and (iw > 4 or n > 1)
      if iw > 4 then iw-- else n--
    iw

  # one floating mini toolbar at glyph fraction (fx, fy): light backing
  # (the halo), tc frame and dividers, gray header band with white title
  # line, then square tool boxes. Each box glyph is a hollow ring on the td
  # unit when its hole survives, a solid dot when smaller, nothing once
  # even a dot can't keep 1px of clearance.
  _paintMiniToolbar: (ctx, x, y, u, iw, fx, fy, nDesign, xMinBacking, xMaxBacking, yMaxBacking) ->
    {S, tc, td, o, ink, light} = u
    hH = Math.round S * @TB_HEADER_H
    hH = 0 if hH < 2                    # too thin to read as the title bar
    headerSpan = if hH > 0 then hH + tc else 0
    yT = y + Math.round S * fy
    avail = yMaxBacking - yT - o

    # the column width iw arrives shared across both toolbars; only the
    # box count still adapts here
    n = nDesign
    frameH = -> 2 * tc + headerSpan + n * iw + (n - 1) * tc
    n-- while frameH() > avail and n > 1
    return if iw < 2 or n < 1
    boxH = iw

    W = iw + 2 * tc
    xL = x + Math.round S * fx
    xL = Math.min xL, xMaxBacking - W - o
    xL = Math.max xL, xMinBacking + o
    # the min-clamp (border/previous-toolbar clearance) may push past the
    # soft max-clamp; the o of extra border clearance folded into
    # xMaxBacking is allowed to give, but the backing crossing the border
    # ink itself never is -- drop the toolbar instead
    return nil if xL + W > xMaxBacking

    # backing/halo, then the frame: ink silhouette, light interior
    fh = frameH()
    ctx.fillStyle = light
    ctx.fillRect xL - o, yT - o, W + 2 * o, fh + 2 * o
    ctx.fillStyle = ink
    ctx.fillRect xL, yT, W, fh
    ctx.fillStyle = light
    ctx.fillRect xL + tc, yT + tc, iw, fh - 2 * tc

    cy = yT + tc
    if hH > 0
      ctx.fillStyle = @HEADER_BG
      ctx.fillRect xL + tc, cy, iw, hH
      # the white line keeps >=1px of gray on every side (clearance is a
      # spec: rounding can otherwise land its end on the frame's ink)
      lw = Math.min Math.round(iw * @HEADER_LINE_W), iw - 2
      if hH >= 3 * tc and lw >= 1
        ctx.fillStyle = Color.WHITE.toString()
        ctx.fillRect xL + tc + Math.round((iw - lw) / 2),
          cy + Math.round((hH - tc) / 2), lw, tc
      ctx.fillStyle = ink
      ctx.fillRect xL + tc, cy + hH, iw, tc
      cy += hH + tc

    for i in [0...n]
      if i > 0
        ctx.fillStyle = ink
        ctx.fillRect xL + tc, cy - tc, iw, tc
      k = Math.min Math.round(iw * @BOX_K), iw - 2, boxH - 2
      if k >= 2
        kx = xL + tc + Math.round (iw - k) / 2
        ky = cy + Math.round (boxH - k) / 2
        ctx.fillStyle = ink
        ctx.fillRect kx, ky, k, k
        if k - 2 * td >= 2
          ctx.fillStyle = light
          ctx.fillRect kx + td, ky + td, k - 2 * td, k - 2 * td
      cy += boxH + tc
    xL + W                              # my frame's right edge, for the
                                        # next toolbar's clearance clamp
