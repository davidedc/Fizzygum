class ShortcutArrowIconAppearance extends SizeAwareIconAppearance

  # SIZE-AWARE shortcut/reference arrow badge (2026-07-21, converted with
  # /convert-icon-size-aware; reference implementation + idiom docs are
  # TypewriterIconAppearance and docs/plans/pixel-icons-plan.md §5b). A rounded
  # square ring with the classic "alias" swoosh arrow: a scanline-filled head
  # triangle plus a tapered tail band along a quarter-ellipse — both integer
  # runs, so the non-AA backend renders them cleanly at every size (its usual
  # display is the ~29px badge on shortcut composites).

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

    ink = @_iconColorString()
    halo = @_outlineColorString()

    # ---- the badge: halo, dark rounded ring, light interior. The ring is 2t
    # thick — the original's band is ~8% of the design space, double the
    # standard line unit
    tb = 2 * t
    r = Math.max tb, Math.round iS * @BADGE_RADIUS
    @_pxRoundRect ctx, ix - o, iy - o, iS + 2 * o, iS + 2 * o, r + o, halo
    @_pxRoundRect ctx, ix, iy, iS, iS, r, ink
    @_pxRoundRect ctx, ix + tb, iy + tb, iS - 2 * tb, iS - 2 * tb, Math.max(0, r - tb), halo

    # ---- the swoosh arrow; from 24px up the whole glyph grows 15% about the
    # badge center (the base proportions read small once there is room)
    g = if S >= 24 then 1.15 else 1
    px = (f) => ix + Math.round iS * (0.5 + (f - 0.5) * g)
    py = (f) => iy + Math.round iS * (0.5 + (f - 0.5) * g)

    ctx.fillStyle = ink
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
      # scanline-filled triangle at the original free angles
      ax = px(@HEAD_A[0]); ay = py(@HEAD_A[1])
      bx = px(@HEAD_B[0]); by2 = py(@HEAD_B[1])
      cx = px(@HEAD_C[0]); cy = py(@HEAD_C[1])
      topY = Math.min ay, by2, cy
      botY = Math.max ay, by2, cy
      edges = [[ax, ay, bx, by2], [bx, by2, cx, cy], [cx, cy, ax, ay]]
      for yy in [topY...botY]
        yc = yy + 0.5
        xs = []
        for [x1, y1, x2, y2] in edges
          continue if (yc < Math.min(y1, y2)) or (yc >= Math.max(y1, y2))
          xs.push x1 + (x2 - x1) * (yc - y1) / (y2 - y1)
        continue if xs.length < 2
        xL = Math.round Math.min xs...
        xR = Math.round Math.max xs...
        ctx.fillRect xL, yy, Math.max(1, xR - xL), 1

    # tail: tapered square stamps evenly spaced (by ANGLE) along a quarter-
    # ellipse — vertical tangent at the tip, horizontal into the join. Angle
    # parameterization keeps the sampling uniform along the arc; the previous
    # per-COLUMN sampling degenerated at small sizes (few columns, so the
    # bottom flattened into a rightward "curl" foot). Math.sin/cos are safe
    # here: the build prepends the deterministic-trig shim to every page, so
    # they are engine-exact.
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
      nSteps = Math.max 8, 2 * (rx + ry)
      for i in [0..nSteps]
        f = i / nSteps
        theta = f * Math.PI / 2
        xx = jx - rx * Math.sin theta          # theta 0 = join, PI/2 = tip
        yy = ty - ry * Math.cos theta
        w = Math.max 1, Math.round wMax * (1 - f) + f   # tapers to a 1px POINT
        ctx.fillRect Math.round(xx - w / 2), Math.round(yy - w / 2), w, w
