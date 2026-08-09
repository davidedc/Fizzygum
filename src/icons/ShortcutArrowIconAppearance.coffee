class ShortcutArrowIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE shortcut/reference arrow badge (2026-07-21, converted with
  # /convert-icon-size-aware; reference implementation + idiom docs are
  # TypewriterIconAppearance and docs/plans/pixel-icons-plan.md §5b). A rounded
  # square ring with the classic "alias" swoosh arrow: a filled head-triangle
  # path plus a tapered tail band along a quarter-ellipse, drawn as ONE
  # filled outline path — each backend rasterizes them its own way. At badge
  # sizes of 24px and under the glyph switches to a hand-placed exact-45°
  # pixel form (the extra-small tier: free angles at those sizes read as
  # messy jaggies). Its usual display is the ~29px badge on shortcut
  # composites.

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  # ---- proportions, fractions of the inner square (arrow points from the
  # original 100-space drawing) ----------------------------------------------
  BADGE_RADIUS: 0.16
  HEAD_A: [0.44, 0.25]    # head triangle: left vertex
  HEAD_B: [0.82, 0.34]    # right vertex
  HEAD_C: [0.63, 0.68]    # bottom vertex
  TAIL_TIP: [0.22, 0.80]  # tail end (bottom-left)
  TAIL_JOIN: [0.56, 0.46] # where the tail meets the head: the midpoint of the
                          # head's base edge A-C (0.535, 0.465), nudged just
                          # inside the triangle so the band overlaps it — the
                          # swoosh connects centered on the base
  TAIL_MAX: 0.16          # tail band thickness at the join (tapers to a 1px point)

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    return if Math.min(wDev, hDev) < 8
    # reserve a 1-px transparent rim all around: the glyph square shrinks by 2
    # and re-centers, so not even the halo touches the widget's bounds
    S = Math.min(wDev, hDev) - 2

    t = Math.max 1, Math.round S / 32          # the line unit
    o = t                                      # halo/envelope thickness
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    ix = x + o
    iy = y + o
    iS = S - 2 * o


    # ---- the badge: halo, dark rounded ring, light interior. The ring is 2t
    # thick — the original's band is ~8% of the design space, double the
    # standard line unit
    tb = 2 * t
    r = Math.max tb, Math.round iS * @BADGE_RADIUS
    @_pxPanel ctx, ix, iy, iS, iS, r, tb, o

    # ---- the swoosh arrow; from 24px up the whole glyph grows 15% about the
    # badge center (the base proportions read small once there is room)
    g = if S >= 24 then 1.15 else 1
    px = (f) => ix + Math.round iS * (0.5 + (f - 0.5) * g)
    py = (f) => iy + Math.round iS * (0.5 + (f - 0.5) * g)

    @_useInk ctx
    jxHead = nil
    jyHead = nil
    liftSmall = 0
    if S <= 24
      # small sizes: an EXACT 45-degree right triangle — horizontal top edge,
      # vertical right edge, equal legs, so the hypotenuse steps precisely one
      # pixel per row with no rounding irregularity (free angles at these
      # sizes read as messy jaggies)
      bx = px(@HEAD_B[0])
      # at these tight sizes, guarantee 1px of light between glyph and ring
      bx = Math.min bx, ix + iS - 2 * t - 1
      topY = py(@HEAD_A[1])
      side = Math.round (((bx - px(@HEAD_A[0])) + (py(@HEAD_C[1]) - topY)) / 2)
      # with the horizontal top edge there is headroom: lift the whole glyph
      # (head + swoosh) so it centers vertically in the badge instead of
      # crowding the bottom ring
      glyphH = (py(@TAIL_TIP[1]) + 1) - topY
      liftSmall = Math.max 0, topY - (iy + Math.round((iS - glyphH) / 2))
      topY -= liftSmall
      topY = Math.max topY, iy + 2 * t + 1
      for r in [0...side]
        ctx.fillRect bx - side + r, topY + r, side - r, 1
      # the tail joins the hypotenuse's midpoint, nudged just inside
      jxHead = bx - Math.round(side / 2) + 1
      jyHead = topY + Math.round(side / 2) - 1
    else
      # the head triangle at the original free angles, as one filled path
      ctx.beginPath()
      ctx.moveTo px(@HEAD_A[0]), py(@HEAD_A[1])
      ctx.lineTo px(@HEAD_B[0]), py(@HEAD_B[1])
      ctx.lineTo px(@HEAD_C[0]), py(@HEAD_C[1])
      ctx.closePath()
      ctx.fill()

    # tail: a quarter-ellipse spine — vertical tangent at the tip, horizontal
    # into the join — swept with a linearly tapering width. Math.sin/cos are
    # safe here: the reference-matched SWCanvas pages get the deterministic-
    # trig shim (engine-exact there), and the native page's pixels are never
    # reference-matched, so platform trig is fine on that page too.
    tx = px(@TAIL_TIP[0]); ty = py(@TAIL_TIP[1]) - liftSmall
    jx = jxHead ? px(@TAIL_JOIN[0])
    jy = jyHead ? py(@TAIL_JOIN[1])
    rx = Math.max 1, jx - tx
    ry = Math.max 1, ty - jy
    wMax = Math.max 1, Math.round iS * @TAIL_MAX * g
    if jxHead?
      # right-triangle sizes: a straight 45-degree shaft leaving the
      # hypotenuse's midpoint PERPENDICULARLY (down-left), stamped along the
      # exact diagonal — the curved arrival came in horizontally and read as
      # attaching above the diagonal's center
      # length clamped so the tip keeps 1px of light from the bottom AND left ring
      m = Math.min jx - tx, (iy + iS - 2 * t) - jy - 2, jx - (ix + 2 * t) - 1
      for i in [0..m]
        f = i / Math.max 1, m
        w = Math.max 1, Math.round wMax * (1 - f) + f   # tapers to a 1px POINT
        ctx.fillRect Math.round(jx - i - w / 2), Math.round(jy + i - w / 2), w, w
    else
      # canvas strokes cannot vary their width along a path, so the tapered
      # band is described as its OUTLINE — the spine's two offset edges,
      # sampled by angle and closed into one filled path
      nSteps = Math.max 8, 2 * (rx + ry)
      outerE = []
      innerE = []
      for i in [0..nSteps]
        f = i / nSteps
        theta = f * Math.PI / 2
        xx = jx - rx * Math.sin theta          # theta 0 = join, PI/2 = tip
        yy = ty - ry * Math.cos theta
        w = Math.max 1, wMax * (1 - f) + f     # tapers to a 1px point
        # unit normal of the spine (the tangent rotated a quarter turn)
        tvx = -rx * Math.cos theta
        tvy = ry * Math.sin theta
        nrm = Math.sqrt(tvx * tvx + tvy * tvy) or 1
        nx2 = -tvy / nrm
        ny2 = tvx / nrm
        outerE.push [xx + nx2 * w / 2, yy + ny2 * w / 2]
        innerE.push [xx - nx2 * w / 2, yy - ny2 * w / 2]
      ctx.beginPath()
      ctx.moveTo outerE[0][0], outerE[0][1]
      ctx.lineTo p[0], p[1] for p in outerE[1..]
      ctx.lineTo p[0], p[1] for p in innerE by -1
      ctx.closePath()
      ctx.fill()
