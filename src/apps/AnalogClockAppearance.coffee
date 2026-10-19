# Paints the AnalogClockWdgt in the draft's look (docs/plans/redesign/UI-guidelines.md §5.5, drawn
# on its 120-unit face): an opaque FACE disc with no border, four MARK dots at 12, 3, 6 and 9, then
# the hour, minute and second hands and the centre dot over them. The hand-drawing methods
# themselves (drawHoursHand / drawMinutesHand / drawSecondsHand / drawDotInMiddleOfFace and their
# shared _drawHand core) stay PUBLIC on the widget -- they are the classic live-edit demo target
# (SystemTest_macroAnalogClockInspectEdit edits drawSecondsHand in the inspector) -- and all clock
# STATE (the hand angles, dateLastTicked) stays widget-side too: this appearance computes into
# @widget fields and dispatches to @widget methods, so an inspector edit of a hand method takes
# effect on the next repaint.
#
# I paint in DEVICE pixels, by declaration (the appearance paint convention's exception for
# dpr-conditional pixel work, docs/architecture/appearance-paint-convention.md): every piece of the
# face is a whole number of device pixels, sized from the side of the clock's square in device
# pixels by ONE rule (pixelsForUnits), so the non-anti-aliased backend draws the same clean,
# symmetric shapes at every size and density. Each paint computes it all afresh from my widget's
# box -- six discs and three strokes -- so nothing is cached, and nothing is placed relative to the
# damage rect.
#
# My SHAPE and my SILHOUETTE are both the face's disc: a press in my box's corners, outside the face,
# reaches whatever lies behind the clock (shapeContainsPoint), and every piece of the clock lies on
# the opaque face, so the one shadow it casts is that disc.

class AnalogClockAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->
    keyValues = @_calculateKeyValuesOrNil aContext, clippingRectangle
    return undefined unless keyValues?
    [damageBox,sl,st,al,at,w,h] = keyValues

    # the face, the marks and the hands set their own colours, so the shadow pass renders the
    # whole clock to a scratch and blits its black silhouette (the shadow-pass paint contract). The
    # opaque face counts as coverage there like every other piece -- nothing of mine erases
    # coverage, as a size-aware icon's light role does -- so the silhouette is the face's disc.
    if appliedShadow?
      @_paintDamagedAreaAsBlackSilhouette aContext, al, at, w, h, appliedShadow, (sctx) =>
        @_paintColoredClock sctx, al, at, w, h
      return undefined

    @_paintColoredClock aContext, al, at, w, h
    return undefined

  # Keeps its OWN paint preamble instead of Appearance._paintInLocalScope: its body draws in device
  # pixels (the header), so it opens no logical-pixels scope, and the background fill shares the
  # preamble's device-space damage clip.
  _paintColoredClock: (aContext, al, at, w, h) ->
    aContext.save()

    # clip out the damage rectangle as we are
    # going to paint the whole of the box
    aContext.clipToRectangle al,at,w,h

    # the background, filling the damage box (al/at/w/h: device pixels). backgroundColor is
    # undefined unless the user sets one (the base Widget default), so this fill is usually
    # skipped: around the face my box shows whatever lies behind it. `? 1`: an absent
    # backgroundTransparency means fully opaque (Widget's class-level default) -- never hand the
    # canvas an undefined (see StringWdgt::_prepareTextBufferContext).
    if @widget.backgroundColor?
      aContext.globalAlpha = @widget.backgroundTransparency ? 1
      aContext.fillStyle = @widget.backgroundColor.toString()
      aContext.fillRect al, at, w, h

    aContext.globalAlpha = @widget.alpha

    # deliberately NO useLogicalPixelsUntilRestore(): device pixels, with the origin moved to the
    # face's centre, which is anchored to my widget's box -- never to the damage rect's corner
    # (al/at), which shifts under partial repaints. Every piece is drawn around (0, 0), the
    # widget's hands included.
    face = @_faceGeometry()
    aContext.translate @widget.left() * ceilPixelRatio + face.centreX, @widget.top() * ceilPixelRatio + face.centreY

    aContext.fillStyle = WorldWdgt.theme.clockFace.toString()
    aContext.fillCircle 0, 0, face.diameter / 2
    @_paintMarks aContext, face.side

    @_calculateHandsAngles()
    @widget.drawHoursHand aContext, face.side
    @widget.drawMinutesHand aContext, face.side
    @widget.drawSecondsHand aContext, face.side
    @widget.drawDotInMiddleOfFace aContext, face.side

    aContext.restore()

  # MY FACE, in device pixels from my widget's top-left corner: the side of its square (the shorter
  # side of my box; a box that is not square shows the square centred in it, at a whole device
  # pixel), the square's centre, and the face's diameter, 116 units (the draft's radius 58).
  #   The centre lies on a pixel boundary when the side is even and on a pixel centre when it is
  # odd, and the diameter has the side's parity (pixelsForUnits), so the face is the circle
  # inscribed in a whole-pixel box -- the crisp fillCircle spelling
  # (CanvasRenderingContext2D-extensions) -- inset by the whole number (side - diameter) / 2 from
  # each side of the square.
  _faceGeometry: ->
    boxWidth = @widget.width() * ceilPixelRatio
    boxHeight = @widget.height() * ceilPixelRatio
    side = Math.min boxWidth, boxHeight
    {
      side: side
      centreX: Math.floor((boxWidth - side) / 2) + side / 2
      centreY: Math.floor((boxHeight - side) / 2) + side / 2
      diameter: @pixelsForUnits side, 116, 1
    }

  # THE PIXEL RULE every piece of the face is sized by: `units` of the draft's 120-unit face, at a
  # square of `side` device pixels, as the nearest whole number of device pixels with the PARITY of
  # `side` (an exact half-way value takes the larger), and never less than `least` (taken up to that
  # parity). It sizes the face's and the dots' diameters here and the hands' widths
  # (AnalogClockWdgt._drawHand).
  #   Why the parity: the face's centre lies on a pixel boundary when the side is even and on a
  # pixel centre when it is odd, and only a span of the same parity sits symmetrically about it.
  # SWCanvas draws a circle whose diameter has the other parity half a pixel off-centre, and a
  # stroke whose width has the other parity a pixel thinner where it points left -- a 1 px hand on a
  # whole-pixel centre vanishes at :45.
  #   The answer never decreases as `units` grows, so a piece of more units is never the narrower of
  # two; at `least` 1 the smallest answer is 2 on an even side and 1 on an odd one.
  pixelsForUnits: (side, units, least) ->
    parity = side % 2
    nearest = 2 * Math.round((units * side / 120 - parity) / 2) + parity
    Math.max nearest, least + (least + parity) % 2

  # the four MARK dots, at 12, 3, 6 and 9 o'clock: each centred 44 units out, a whole number of
  # device pixels from the face's centre (so it has the centre's phase), and a disc 6 units across:
  # at least 4 device pixels on an even side (SWCanvas draws a 2-pixel circle as a 2x1 dash) and 3
  # on an odd one (a plus), so no size needs a hand-placed dot.
  _paintMarks: (context, side) ->
    distance = Math.round 44 * side / 120
    radius = (@pixelsForUnits side, 6, 3) / 2
    context.fillStyle = WorldWdgt.theme.clockMark.toString()
    context.fillCircle 0, (-distance), radius
    context.fillCircle distance, 0, radius
    context.fillCircle 0, distance, radius
    context.fillCircle (-distance), 0, radius

  # My SHAPE: the face's disc. The logical pixel a point falls in is mine iff its CENTRE lies inside
  # the face's circle (BoxyAppearance's rounded-box test samples pixel centres the same way, as
  # SWCanvas's fill does), so a press in my box's corners, outside the face, reaches whatever lies
  # behind the clock. TOTAL (see Appearance): nothing outside my bounds is mine.
  shapeContainsPoint: (aPoint) ->
    return false unless @widget.boundsContainPoint aPoint
    face = @_faceGeometry()
    # that pixel centre, in device pixels from the face's centre
    x = (Math.floor(aPoint.x) + 0.5 - @widget.left()) * ceilPixelRatio - face.centreX
    y = (Math.floor(aPoint.y) + 0.5 - @widget.top()) * ceilPixelRatio - face.centreY
    radius = face.diameter / 2
    x * x + y * y <= radius * radius

  # The hand angles, 0 at 12 o'clock and growing clockwise, into my widget's fields, from its
  # dateLastTicked -- which a playing SystemTest pins (under
  # AutomatorEventCommandTurnOnAnimationsPacingControl) to 10:08:37 on a fixed day: a time with no
  # hand on an axis and no two hands together, so every hand shows, and an edit that mirrors the
  # second hand (macroAnalogClockInspectEdit) moves it.
  _calculateHandsAngles: ->

    if Automator? and
     Automator.animationsPacingControl and
     Automator.state == Automator.PLAYING
      @widget.dateLastTicked = new Date 2011,10,30,10,8,37

    sec = @widget.dateLastTicked.getSeconds() + @widget.dateLastTicked.getMilliseconds()/1000
    min = @widget.dateLastTicked.getMinutes()
    hr = @widget.dateLastTicked.getHours()
    hr = if hr >= 12 then hr - 12 else hr
    @widget.hoursHandAngle = hr * Math.PI / 6 + Math.PI / 360 * min + Math.PI / 21600 * sec
    @widget.minutesHandAngle = Math.PI / 30 * min + Math.PI / 1800 * sec
    @widget.secondsHandAngle = sec * Math.PI / 30
