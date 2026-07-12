class AnalogClockWdgt extends Widget

  hoursHandAngle: 0
  minutesHandAngle: 0
  secondsHandAngle: 0
  strokeSizeToClockDimensionRatio: 1/250
  dateLastTicked: nil

  constructor: ->

    @fps = 1
    @synchronisedStepping = true
    # you could be constructing this widget at boot,
    # in which case you just put a mock a date here
    @dateLastTicked = WorldWdgt.dateOfCurrentCycleStart or new Date
    world.steppingWdgts.add @

    super()
    @setColor Color.create 255, 125, 125
    @_applyExtent new Point 200, 200
    return

  colloquialName: ->
    "analog clock"

  widthWithoutSpacing: ->
    Math.min @width(), @height()

  _resizeToWithoutSpacing: ->
    @_applyExtent new Point @widthWithoutSpacing(), @widthWithoutSpacing()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false
    # FIXED (elasticity 0): the clock keeps its own square size as window content; it does NOT
    # stretch to fill a larger (e.g. nested) window. This makes its width CONVERGENCE-INDEPENDENT:
    # at elasticity 0, getWidthInStack = wEl + 0*(availW*wEl/widthOfStackWhenAdded - wEl) =
    # min(wEl, availW) -- the widthOfStackWhenAdded term is multiplied out, so the clock no longer
    # depends on the stack width sampled at RECORD time (which, for a clock nested in a
    # window-in-window, was the ancestor-cascade-converged width and drove the deferred-layout
    # runaway). The clock's square aspect is preserved by _setWidthSizeHeightAccordingly.
    @layoutSpecDetails.elasticity = 0

  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_applyExtent new Point newWidth, newWidth
    @height()  # Path B: hand the (square) height back so a container needn't read it off me. See Widget.

  # §4.1 pure measure: the clock is square, so its preferred height equals the width
  # (mirrors _setWidthSizeHeightAccordingly above). No mutation, no seam.
  preferredExtentForWidth: (availW) ->
    new Point availW, availW


  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    if area.isNotEmpty()
      if w < 1 or h < 1
        return nil

      aContext.save()

      # clip out the dirty rectangle as we are
      # going to paint the whole of the box
      aContext.clipToRectangle al,at,w,h

      aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @backgroundTransparency

      # paintRectangle here is made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, this is why
      # it's called before the scaling.
      @paintRectangle aContext, al, at, w, h, @backgroundColor

      # C1: blit the cached STATIC face (the 12 hour + 48 minute tick marks) instead of
      # re-stroking all 60 marks every repaint. It's rendered once per size into an
      # immutable back buffer (see _getFaceBuffer) and blitted here in DEVICE space,
      # integer-aligned to the SAME al/at/sl/st as the background rect — so, with
      # SWCanvas's hard-edged (non-AA) rasterisation and integer widget positions, it
      # lands byte-for-byte where the old in-_renderingHelper tick strokes did. The ticks
      # are the BOTTOM layer (drawn first, under the hands); the dynamic hands and the
      # centre dot + outer arc that sit IN FRONT of the hands are still drawn live by
      # _renderingHelper, so the z-order is unchanged. globalAlpha matches the ticks' old
      # alpha (_renderingHelper uses appliedShadowAlpha * @alpha), and the blit works
      # identically in the shadow pass — the caller has already translated the context
      # by the shadow offset, and drawImage rides that translate like any other draw.
      faceBuffer = @_getFaceBuffer()
      aContext.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha
      aContext.drawImage faceBuffer,
        Math.round(sl), Math.round(st), Math.round(w), Math.round(h),
        Math.round(al), Math.round(at), Math.round(w), Math.round(h)

      aContext.useLogicalPixelsUntilRestore()

      widgetPosition = @position()
      aContext.translate widgetPosition.x, widgetPosition.y

      @_renderingHelper aContext, Color.WHITE, appliedShadow

      aContext.restore()

      # paintHighlight here is made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, this is why
      # it's called outside the effect of the scaling
      # (after the restore).
      @paintHighlight aContext, al, at, w, h

  step: ->
    @dateLastTicked = WorldWdgt.dateOfCurrentCycleStart
    @changed()

  _calculateHandsAngles: ->

    if Automator? and
     Automator.animationsPacingControl and
     Automator.state == Automator.PLAYING
      @dateLastTicked = new Date 2011,10,30

    #sec = @dateLastTicked.getSeconds()
    sec = @dateLastTicked.getSeconds() + @dateLastTicked.getMilliseconds()/1000
    min = @dateLastTicked.getMinutes()
    hr = @dateLastTicked.getHours()
    hr = if hr >= 12 then hr - 12 else hr
    @hoursHandAngle = hr * Math.PI / 6 + Math.PI / 360 * min + Math.PI / 21600 * sec
    @minutesHandAngle = Math.PI / 30 * min + Math.PI / 1800 * sec
    @secondsHandAngle = sec * Math.PI / 30

  _renderingHelper: (context, color, appliedShadow) ->
    height = @height()
    width = @width()

    context.lineWidth = 1 * Math.min(width,height) * @strokeSizeToClockDimensionRatio
    context.lineCap = "round"

    context.save()
    context.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha

    squareDim = Math.min width/2, height/2

    context.translate width/2, height/2
    context.scale 0.9, 0.9

    context.rotate -Math.PI / 2
    context.strokeStyle = Color.BLACK.toString()
    context.fillStyle = Color.WHITE.toString()
    context.lineWidth = 6 * Math.min(width,height) * @strokeSizeToClockDimensionRatio
    context.lineCap = 'round'

    # C1: the 12 hour + 48 minute tick marks (the STATIC face) are no longer stroked
    # here — they are pre-rendered once per size into a cached back buffer and blitted
    # in paintIntoAreaOrBlitFromBackBuffer BEFORE this method runs, so they remain the
    # bottom layer (under the hands). _renderStaticFace reproduces exactly the strokes
    # that used to be here. What follows (hands + centre dot + outer arc) is the dynamic
    # / front content and is still drawn live, preserving the original z-order.

    context.fillStyle = Color.BLACK.toString()

    @_calculateHandsAngles()

    @drawHoursHand context, squareDim
    @drawMinutesHand context, squareDim
    @drawSecondsHand context, squareDim
    @drawDotInMiddleOfFace context, squareDim

    context.beginPath()
    context.lineWidth = 10 * Math.min(width,height) * @strokeSizeToClockDimensionRatio
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
    cacheKey = "AnalogClockWdgtFace-" + @extent().toString()
    cacheHit = world.cacheForImmutableBackBuffers.get cacheKey
    if cacheHit? then return cacheHit

    faceBuffer = HTMLCanvasElement.createOfPhysicalDimensions @extent().scaleBy ceilPixelRatio
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
    height = @height()
    width = @width()
    squareDim = Math.min width/2, height/2

    context.translate width/2, height/2
    context.scale 0.9, 0.9
    context.rotate -Math.PI / 2
    context.strokeStyle = Color.BLACK.toString()
    context.lineCap = 'round'

    # hour face ticks
    context.save()
    context.lineWidth = 6 * Math.min(width,height) * @strokeSizeToClockDimensionRatio
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
    context.lineWidth = 5 * Math.min(width,height) * @strokeSizeToClockDimensionRatio
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


  drawHoursHand: (context, squareDim) ->
    height = @height()
    width = @width()
    context.save()
    context.rotate @hoursHandAngle
    context.lineWidth = 8 * Math.min(width,height) * @strokeSizeToClockDimensionRatio
    context.beginPath()
    context.moveTo -squareDim/7, 0
    context.lineTo squareDim/2, 0
    context.stroke()
    context.restore()


  drawMinutesHand: (context, squareDim) ->
    height = @height()
    width = @width()
    context.save()
    context.rotate @minutesHandAngle
    context.lineWidth = 5 * Math.min(width,height) * @strokeSizeToClockDimensionRatio
    context.beginPath()
    context.moveTo -squareDim/5, 0
    context.lineTo squareDim/1.3, 0
    context.stroke()
    context.restore()

  drawSecondsHand: (context, squareDim) ->
    height = @height()
    width = @width()
    context.save()
    context.rotate @secondsHandAngle
    context.strokeStyle = '#D40000'
    context.fillStyle = '#D40000'
    context.lineWidth = 6 * Math.min(width,height) * @strokeSizeToClockDimensionRatio
    context.beginPath()
    context.moveTo -squareDim/5, 0
    context.lineTo squareDim/1.3, 0
    context.stroke()
    context.restore()

  drawDotInMiddleOfFace: (context, squareDim) ->
    height = @height()
    width = @width()
    context.save()
    context.fillStyle = '#D40000'
    context.lineWidth = 6 * Math.min(width,height) * @strokeSizeToClockDimensionRatio
    context.beginPath()
    context.arc 0, 0, Math.min(width,height)/30, 0, Math.PI * 2
    context.fill()
    context.restore()

