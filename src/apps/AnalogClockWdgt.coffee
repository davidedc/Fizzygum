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
    @appearance = new AnalogClockAppearance @
    @setColor Color.create 255, 125, 125
    @_applyExtent new Point 200, 200
    return

  colloquialName: ->
    "analog clock"

  widthWithoutSpacing: ->
    Math.min @width(), @height()

  _resizeToWithoutSpacing: ->
    @_applyExtent new Point @widthWithoutSpacing(), @widthWithoutSpacing()

  initialiseDefaultFrameContentLayoutSpec: ->
    super
    @_contentStackSpec.canSetHeightFreely = false
    # FIXED (grow 0): the clock keeps its own square size as window content; it does NOT
    # stretch to fill a larger (e.g. nested) window. This makes its width CONVERGENCE-INDEPENDENT:
    # at grow 0, getWidthInStack = min(desiredWidth, availW) -- no term samples the stack width,
    # so the clock never depends on a container width sampled at capture time (under the old
    # proportional model that sample -- widthOfStackWhenAdded -- was, for a clock nested in a
    # window-in-window, the ancestor-cascade-converged width and drove the deferred-layout
    # runaway; U1 deleted that snapshot from the model entirely). The clock's square aspect is
    # preserved by _setWidthSizeHeightAccordingly.
    @_contentStackSpec.grow = 0

  _setWidthSizeHeightAccordingly: (newWidth) ->
    @_applyExtent new Point newWidth, newWidth
    @height()  # Path B: hand the (square) height back so a container needn't read it off me. See Widget.

  # §4.1 pure measure: the clock is square, so its preferred height equals the width
  # (mirrors _setWidthSizeHeightAccordingly above). No mutation, no seam.
  preferredExtentForWidth: (availW) ->
    new Point availW, availW


  step: ->
    @dateLastTicked = WorldWdgt.dateOfCurrentCycleStart
    @_changed()

  # Shared hand drawing. The three hands differ only in angle, stroke-width multiplier, the two
  # length divisors (inner tail / outer tip), and colour: hours & minutes inherit the black stroke/
  # fill set by _renderingHelper (color=nil → left untouched), the seconds hand alone sets its own
  # red. Every op is in the same order as the old per-hand bodies, and colour is scoped by save/
  # restore exactly as before, so the pixels are identical. (@width()/@height() are pure getters.)
  _drawHand: (context, squareDim, angle, widthMultiplier, innerDivisor, outerDivisor, color = nil) ->
    context.save()
    context.rotate angle
    if color?
      context.strokeStyle = color
      context.fillStyle = color
    context.lineWidth = widthMultiplier * Math.min(@width(), @height()) * @strokeSizeToClockDimensionRatio
    context.beginPath()
    context.moveTo -squareDim/innerDivisor, 0
    context.lineTo squareDim/outerDivisor, 0
    context.stroke()
    context.restore()

  drawHoursHand: (context, squareDim) ->
    @_drawHand context, squareDim, @hoursHandAngle, 8, 7, 2

  drawMinutesHand: (context, squareDim) ->
    @_drawHand context, squareDim, @minutesHandAngle, 5, 5, 1.3

  drawSecondsHand: (context, squareDim) ->
    @_drawHand context, squareDim, @secondsHandAngle, 6, 5, 1.3, '#D40000'

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

