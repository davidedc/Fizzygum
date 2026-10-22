class GraphsPlotsChartsWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  drawOnlyPartOfBoundingRect: false
  graphNumber: 1
  # PRNG seed for the sample data, set by each Example*PlotWdgt subclass
  seed: undefined

  constructor: (@drawOnlyPartOfBoundingRect)->
    super()
    @appearance = new GraphsPlotsChartsAppearance @
    @_applyExtent new Point 200, 200
    world.steppingWdgts.add @

  # true while a SystemTest replays with animations-pacing control on -- animated widgets must then
  # render a FIXED, deterministic frame (mirrors AnalogClockAppearance._calculateHandsAngles, which pins
  # @dateLastTicked to a fixed date under the same condition). Turned on by the macro's
  # AutomatorEventCommandTurnOnAnimationsPacingControl.
  _animationFrozenForDeterministicReplay: ->
    Automator? and Automator.animationsPacingControl and Automator.state == Automator.PLAYING

  # The example plots animate by advancing @graphNumber each step (each concrete plot's
  # drawPlot tail seeds its RNG off @graphNumber). Freeze that advance under replay so the plot
  # renders a fixed frame. Subclasses that animate differently (Example3DPlotWdgt, via @currentAngle)
  # override step() but reuse the guard above. (@graphNumber is declared on this base; each concrete
  # plot supplies only its own @fps and drawPlot — the PUBLIC drawing tail
  # GraphsPlotsChartsAppearance dispatches to — the shared ctor adds them to steppingWdgts.)
  step: ->
    @graphNumber++ unless @_animationFrozenForDeterministicReplay()
    @_changed()


  # see https://stackoverflow.com/a/19303725
  seededRandom: ->
    x = Math.sin(@seed++) * 10000
    return x - Math.floor(x)

  # Standard Normal variate using Box-Muller transform
  # see https://stackoverflow.com/a/36481059
  seeded_randn_bm: ->
    u = 0
    v = 0
    while u == 0
      u = @seededRandom()
    #Converting [0,1) to (0,1)
    while v == 0
      v = @seededRandom()
    return Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v)

  simpleShadow: (context, appliedShadow) ->

    height = @height()
    width = @width()

    if appliedShadow?
      context.globalAlpha = appliedShadow.alpha * @alpha
      # shadow-pass paint contract (Widget.coffee "How the shadow painting works"):
      # the plot box's shadow is BLACK, like every other caster's
      context.fillStyle = WorldWdgt.theme.shadowColor.toString()
      context.fillRect 0, 0, width, height
      # let's avoid paint 3d stuff twice because
      # of the shadow
  
  # My BOX, the 1 px line round my area, in the theme's plotFrameStroke: along my top and my right
  # when I stand in a plot with axes, whose axes run along the other two (drawOnlyPartOfBoundingRect),
  # all round otherwise. Stroked inset half a pixel, the house crisp spelling, so each side is exactly
  # my outermost row or column of pixels at every dpr; the top stops where the right side starts, so
  # no pixel is stroked twice. The normal pass only: the shadow pass fills my silhouette instead.
  drawBoundingBox: (context) ->

    height = @height()
    width = @width()

    context.strokeStyle = WorldWdgt.theme.plotFrameStroke.toString()
    context.lineWidth = 1
    if @drawOnlyPartOfBoundingRect
      context.beginPath()
      context.moveTo 0, 0.5
      context.lineTo width - 1, 0.5
      context.moveTo width - 0.5, 0
      context.lineTo width - 0.5, height
      context.stroke()
    else
      context.strokeRect 0.5, 0.5, width - 1, height - 1
