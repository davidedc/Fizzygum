class AnalogClockWdgt extends Widget

  hoursHandAngle: 0
  minutesHandAngle: 0
  secondsHandAngle: 0
  strokeSizeToClockDimensionRatio: 1/250
  dateLastTicked: nil

  constructor: ->

    @fps = 1
    @synchronisedStepping = true
    @dateLastTicked = WorldMorph.currentDate
    world.steppingWdgts.add @

    super()
    @setColor new Color 255, 125, 125
    @rawSetExtent new Point 200, 200
    return

  colloquialName: ->
    "analog clock"

  widthWithoutSpacing: ->
    Math.min @width(), @height()

  rawResizeToWithoutSpacing: ->
    @rawSetExtent new Point @widthWithoutSpacing(), @widthWithoutSpacing()

  initialiseDefaultWindowContentLayoutSpec: ->
    super
    @layoutSpecDetails.canSetHeightFreely = false

  rawSetWidthSizeHeightAccordingly: (newWidth) ->
    @rawSetExtent new Point newWidth, newWidth


  # This method only paints this very morph's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this morph might paint something on the screen even if
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
      aContext.useLogicalPixelsUntilRestore()

      morphPosition = @position()
      aContext.translate morphPosition.x, morphPosition.y

      @renderingHelper aContext, Color.WHITE, appliedShadow

      aContext.restore()

      # paintHighlight here is made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, this is why
      # it's called outside the effect of the scaling
      # (after the restore).
      @paintHighlight aContext, al, at, w, h

  step: ->
    @dateLastTicked = WorldMorph.currentDate
    @changed()

  calculateHandsAngles: ->

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

  renderingHelper: (context, color, appliedShadow) ->
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

    # hour face ticks
    context.save()
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

    context.fillStyle = Color.BLACK.toString()

    @calculateHandsAngles()

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

