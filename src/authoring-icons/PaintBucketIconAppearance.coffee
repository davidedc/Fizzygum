# THE PAINT BUCKET: the face of the sheet toolbar's fill-colour tool (FillColorButtonWdgt) and of the
# demo menu's "Paint bucket icon" -- an upright pail seen a little from above, its bail standing over
# it, and one drop of paint beside it. Drawn as a SIZE-AWARE icon in the text toolbar's style
# (docs/architecture/visual-design-system.md §4.6), beside the ragged lines and the A with its sign:
# the whole 44 x 44 tool cell, and a 24 px picture on the toolbar's overflow menu.
#   INK ONLY: a tool cell's plate follows its state (none at rest, desk hovered and active), so a paper
# interior would show as a patch on it.
#   ONE LINE t: LINE grid units of the square (SizeAwareIconAppearance._controlGlyphLine, 2 units: 2 px
# in the 44 cell, 4 at dpr 2, 1 in the 24 px picture). The rim is a FILLED elliptical ring (its outer
# ellipse less its inner one, t in from it), because a stroke along a flat ellipse bulges into points at
# its tight ends; the body is one open line (a wall, the bottom's arc, the other wall) and the bail one
# arch, each stroked with butt ends, so no round cap meets another anywhere (SWCanvas leaves the overlap
# of round-capped subpaths unpainted).
#   SHARED LINES: the walls and the bail both start on the middle of the rim's ends, the walls going
# down and the bail going up, so through each end of the rim runs one line.
#   DETAIL BY RULE: the drop is a dot from DROP_MIN_DOT px across and a square below that; a square
# under MIN_SIZE px draws nothing.
#   Proportions are in GLYPH_GRID units of the square the icon paints in (one unit is one px in the
# 44 cell); the pail is drawn left of centre so that pail and drop together sit on the square's centre.
class PaintBucketIconAppearance extends SizeAwareIconAppearance

  # natural/layout size (IconWdgt._resizeToWithoutSpacing aspect-fits this)
  preferredSize: new Point 100, 100

  LINE: 2              # the line, in grid units (see the header)
  PAIL_CENTRE: 19      # the pail's axis
  RIM_Y: 16            # the rim ellipse's centre line
  RIM_HALF_WIDTH: 11   # the rim's outer half width
  RIM_HALF_DEPTH: 3    # the rim's outer half height: how much of the top we see
  BOTTOM_Y: 36         # the bottom ellipse's centre line
  BOTTOM_HALF_WIDTH: 8.5
  BOTTOM_HALF_DEPTH: 3
  BAIL_RISE: 12        # how far above the rim's centre line the bail's top stands
  DROP_X: 35           # the drop's centre
  DROP_Y: 33
  DROP_DIAMETER: 6
  DROP_TIP: 6          # how far above the drop's centre its tip rises
  DROP_MIN_DOT: 4
  MIN_SIZE: 12

  _paintBucketMetrics: (S) ->
    u = S / @GLYPH_GRID
    t = @_controlGlyphLine S, @LINE / @GLYPH_GRID
    {S, u, t}

  _paintSizeAware: (ctx, x0, y0, wDev, hDev) ->
    S = Math.min wDev, hDev
    return if S < @MIN_SIZE
    x = x0 + Math.floor (wDev - S) / 2
    y = y0 + Math.floor (hDev - S) / 2
    m = @_paintBucketMetrics S
    @_useInk ctx
    @_paintRim ctx, x, y, m
    @_paintBody ctx, x, y, m
    @_paintBail ctx, x, y, m
    @_paintDrop ctx, x, y, m
    return

  # the pail's axis in device px: on a pixel centre when t is odd, on a pixel edge when even, so a
  # stroke t thick on either side of it mirrors exactly
  _axis: (x, m) ->
    a = Math.round x + @PAIL_CENTRE * m.u
    a += 0.5 if m.t % 2 is 1
    a

  # a half width whose stroke (centred t / 2 inside it) keeps the outer edge on a whole px
  _strokeHalf: (outerHalf, m) ->
    Math.max m.t / 2, Math.round(outerHalf * m.u) - m.t / 2

  _paintRim: (ctx, x, y, m) ->
    cx = @_axis x, m
    cy = @_rimY y, m
    outerX = Math.round(@RIM_HALF_WIDTH * m.u)
    outerY = Math.max m.t + 1, Math.round(@RIM_HALF_DEPTH * m.u)
    ctx.beginPath()
    ctx.ellipse cx, cy, outerX, outerY, 0, 0, 2 * Math.PI
    ctx.ellipse cx, cy, outerX - m.t, outerY - m.t, 0, 2 * Math.PI, 0, true
    ctx.fill()

  # the rim's centre line: on a pixel centre when t is odd, on a pixel edge when even, as the axis
  _rimY: (y, m) ->
    Math.round(y + @RIM_Y * m.u) + (if m.t % 2 is 1 then 0.5 else 0)

  _paintBody: (ctx, x, y, m) ->
    cx = @_axis x, m
    rimY = @_rimY y, m
    botY = Math.round(y + @BOTTOM_Y * m.u) + (if m.t % 2 is 1 then 0.5 else 0)
    rimHalf = Math.round(@RIM_HALF_WIDTH * m.u) - m.t / 2
    botHalf = @_strokeHalf @BOTTOM_HALF_WIDTH, m
    ctx.lineWidth = m.t
    ctx.lineCap = 'butt'
    ctx.lineJoin = 'miter'
    ctx.beginPath()
    ctx.moveTo cx - rimHalf, rimY
    ctx.lineTo cx - botHalf, botY
    # anticlockwise from the left end through the lowest point to the right end
    ctx.ellipse cx, botY, botHalf, (@_strokeHalf @BOTTOM_HALF_DEPTH, m), 0, Math.PI, 0, true
    ctx.lineTo cx + rimHalf, rimY
    ctx.stroke()

  # the bail: the upper half of an ellipse standing on the middle of the rim's ends, where the walls
  # start, so each end of the rim carries one line straight through it
  _paintBail: (ctx, x, y, m) ->
    cx = @_axis x, m
    rimY = @_rimY y, m
    half = Math.round(@RIM_HALF_WIDTH * m.u) - m.t / 2
    rise = Math.round(@BAIL_RISE * m.u) - m.t / 2
    ctx.lineWidth = m.t
    ctx.lineCap = 'butt'
    ctx.beginPath()
    ctx.ellipse cx, rimY, half, rise, 0, Math.PI, 2 * Math.PI
    ctx.stroke()

  # the drop: a dot with a pointed top, or a plain square where a dot would be too small to read
  _paintDrop: (ctx, x, y, m) ->
    d = Math.round @DROP_DIAMETER * m.u
    left = Math.round(x + @DROP_X * m.u - d / 2)
    top = Math.round(y + @DROP_Y * m.u - d / 2)
    if d < @DROP_MIN_DOT
      ctx.fillRect left, top, Math.max(2, d), Math.max(2, d)
      return
    cx = left + d / 2
    cy = top + d / 2
    ctx.fillCircle cx, cy, d / 2
    tip = Math.round @DROP_TIP * m.u
    ctx.beginPath()
    ctx.moveTo cx - d / 2, cy
    ctx.lineTo cx, cy - tip
    ctx.lineTo cx + d / 2, cy
    ctx.closePath()
    ctx.fill()
