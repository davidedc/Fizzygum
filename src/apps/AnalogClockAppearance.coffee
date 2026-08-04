# Paints the AnalogClockWdgt: background rect, then the cached STATIC face (the tick
# marks, blitted from a per-size immutable back buffer — C1), then the dynamic content
# (hands + centre dot + outer arc) live. The hand-drawing methods themselves
# (drawHoursHand / drawMinutesHand / drawSecondsHand / drawDotInMiddleOfFace and their
# shared _drawHand core) stay PUBLIC on the widget — they are the classic live-edit
# demo target (SystemTest_macroAnalogClockInspectEdit edits drawSecondsHand in the
# inspector) — and all clock STATE (the hand angles, dateLastTicked) stays widget-side
# too: this appearance computes into @widget fields and dispatches to @widget methods,
# so an inspector edit of a hand method still takes effect on the next repaint.

class AnalogClockAppearance extends Appearance

  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @widget.preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @widget.calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil

      # the clock face + hands set their own colours (white face, black hands, blue arc),
      # so the shadow pass renders the whole clock to a scratch and blits the black
      # silhouette (the shadow-pass paint contract). The highlight overlay is not part of
      # the caster's ink, so it is skipped in the shadow pass (same rule as the editor
      # selection overlay).
      if appliedShadow?
        @_paintDamagedAreaAsBlackSilhouette aContext, al, at, w, h, appliedShadow, (sctx) =>
          @_paintColoredClock sctx, sl, st, al, at, w, h
        return

      @_paintColoredClock aContext, sl, st, al, at, w, h

      # _drawHighlightOverlay here is made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, this is why
      # it's called outside the effect of the scaling
      # (after the restore).
      @_drawHighlightOverlay aContext, al, at, w, h

  _paintColoredClock: (aContext, sl, st, al, at, w, h) ->
      aContext.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      aContext.clipToRectangle al,at,w,h

      aContext.globalAlpha = @widget.backgroundTransparency

      # paintRectangle here is made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, this is why
      # it's called before the scaling.
      @widget.paintRectangle aContext, al, at, w, h, @widget.backgroundColor

      # C1: blit the cached STATIC face (the 12 hour + 48 minute tick marks) instead of
      # re-stroking all 60 marks every repaint. It's rendered once per size into an
      # immutable back buffer (see _getFaceBuffer) and blitted here in DEVICE space,
      # integer-aligned to the SAME al/at/sl/st as the background rect — so, with
      # SWCanvas's hard-edged (non-AA) rasterisation and integer widget positions, it
      # lands byte-for-byte where the old in-_renderingHelper tick strokes did. The ticks
      # are the BOTTOM layer (drawn first, under the hands); the dynamic hands and the
      # centre dot + outer arc that sit IN FRONT of the hands are still drawn live by
      # _renderingHelper, so the z-order is unchanged.
      faceBuffer = @_getFaceBuffer()
      aContext.globalAlpha = @widget.alpha
      aContext.drawImage faceBuffer,
        Math.round(sl), Math.round(st), Math.round(w), Math.round(h),
        Math.round(al), Math.round(at), Math.round(w), Math.round(h)

      aContext.useLogicalPixelsUntilRestore()

      widgetPosition = @widget.position()
      aContext.translate widgetPosition.x, widgetPosition.y

      @_renderingHelper aContext, Color.WHITE

      aContext.restore()

  _calculateHandsAngles: ->

    if Automator? and
     Automator.animationsPacingControl and
     Automator.state == Automator.PLAYING
      @widget.dateLastTicked = new Date 2011,10,30

    sec = @widget.dateLastTicked.getSeconds() + @widget.dateLastTicked.getMilliseconds()/1000
    min = @widget.dateLastTicked.getMinutes()
    hr = @widget.dateLastTicked.getHours()
    hr = if hr >= 12 then hr - 12 else hr
    @widget.hoursHandAngle = hr * Math.PI / 6 + Math.PI / 360 * min + Math.PI / 21600 * sec
    @widget.minutesHandAngle = Math.PI / 30 * min + Math.PI / 1800 * sec
    @widget.secondsHandAngle = sec * Math.PI / 30

  # The shared clock-face transform: recentre to the clock's middle, scale to 0.9,
  # rotate so 12 o'clock points up, and set the black stroke. Used by both the live
  # _renderingHelper and the cached _renderStaticFace so the two stay pixel-identical
  # (the C1 face-buffer byte-identity invariant).
  _applyFaceTransform: (context) ->
    width = @widget.width()
    height = @widget.height()
    context.translate width/2, height/2
    context.scale 0.9, 0.9
    context.rotate -Math.PI / 2
    context.strokeStyle = Color.BLACK.toString()

  _renderingHelper: (context, color) ->
    height = @widget.height()
    width = @widget.width()

    context.lineWidth = 1 * Math.min(width,height) * @widget.strokeSizeToClockDimensionRatio
    context.lineCap = "round"

    context.save()
    context.globalAlpha = @widget.alpha

    squareDim = Math.min width/2, height/2

    @_applyFaceTransform context
    context.fillStyle = Color.WHITE.toString()
    context.lineWidth = 6 * Math.min(width,height) * @widget.strokeSizeToClockDimensionRatio
    context.lineCap = 'round'

    # C1: the 12 hour + 48 minute tick marks (the STATIC face) are no longer stroked
    # here — they are pre-rendered once per size into a cached back buffer and blitted
    # in paintIntoAreaOrBlitFromBackBuffer BEFORE this method runs, so they remain the
    # bottom layer (under the hands). _renderStaticFace reproduces exactly the strokes
    # that used to be here. What follows (hands + centre dot + outer arc) is the dynamic
    # / front content and is still drawn live, preserving the original z-order.

    context.fillStyle = Color.BLACK.toString()

    @_calculateHandsAngles()

    @widget.drawHoursHand context, squareDim
    @widget.drawMinutesHand context, squareDim
    @widget.drawSecondsHand context, squareDim
    @widget.drawDotInMiddleOfFace context, squareDim

    context.beginPath()
    context.lineWidth = 10 * Math.min(width,height) * @widget.strokeSizeToClockDimensionRatio
    context.strokeStyle = '#325FA2'
    context.arc 0, 0, squareDim, 0, Math.PI * 2
    context.stroke()


    context.restore()

    context.strokeStyle = color.toString()


  # C1: render the STATIC clock face (tick marks only) into an offscreen buffer, cached
  # by device size in world.cacheForImmutableBackBuffers. The face depends ONLY on the
  # clock's size (colours + strokeSizeToClockDimensionRatio are constants), so every
  # same-size clock shares one immutable buffer — cheap for the many-clocks scenes.
  # Blitted by paintIntoAreaOrBlitFromBackBuffer (see the byte-identity note there).
  _getFaceBuffer: ->
    cacheKey = "AnalogClockWdgtFace-" + @widget.extent().toString()
    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit? then return cacheHit

    faceBuffer = HTMLCanvasElement.createOfPhysicalDimensions @widget.extent().scaleBy ceilPixelRatio
    faceBufferContext = faceBuffer.getContext "2d"
    faceBufferContext.useLogicalPixelsUntilRestore()
    @_renderStaticFace faceBufferContext

    world.cacheForImmutableBackBuffers.set cacheKey, faceBuffer
    return faceBuffer

  # Draws ONLY the hour + minute tick marks, in the clock's local logical space (buffer
  # origin = clock origin). This is exactly the tick portion that used to live at the
  # top of _renderingHelper — identical transform, stroke widths, caps and iteration
  # order — so blitting the result is byte-identical to stroking them live. Drawn
  # pristine: globalAlpha 1, no shadow (opaque black on transparent); the clock's alpha
  # and any shadow are applied at blit time in paintIntoAreaOrBlitFromBackBuffer.
  _renderStaticFace: (context) ->
    height = @widget.height()
    width = @widget.width()
    squareDim = Math.min width/2, height/2

    @_applyFaceTransform context
    context.lineCap = 'round'

    # hour face ticks
    context.save()
    context.lineWidth = 6 * Math.min(width,height) * @widget.strokeSizeToClockDimensionRatio
    i = 0
    while i < 12
      context.beginPath()
      context.rotate Math.PI / 6
      context.moveTo squareDim*2.4/3, 0
      context.lineTo squareDim, 0
      context.stroke()
      i++
    context.restore()

    # minute face ticks
    context.save()
    context.lineWidth = 5 * Math.min(width,height) * @widget.strokeSizeToClockDimensionRatio
    i = 0
    while i < 60
      if i % 5 != 0
        context.beginPath()
        context.moveTo squareDim*2.7/3, 0
        context.lineTo squareDim, 0
        context.stroke()
      context.rotate Math.PI / 30
      i++
    context.restore()
