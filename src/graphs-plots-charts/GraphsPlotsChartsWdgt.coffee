class GraphsPlotsChartsWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  drawOnlyPartOfBoundingRect: false

  constructor: (@drawOnlyPartOfBoundingRect)->
    super()
    @setColor Color.create 255, 125, 125
    @_applyExtent new Point 200, 200


  # This method only paints this very widget's "image",
  # it doesn't descend the children
  # recursively. The recursion mechanism is done by fullPaintIntoAreaOrBlitFromBackBuffer, which
  # eventually invokes paintIntoAreaOrBlitFromBackBuffer.
  # Note that this widget might paint something on the screen even if
  # it's not a "leaf".
  #
  # The whole plot/chart family shares this identical paint scaffold; each
  # concrete plot supplies only its renderingHelper (the drawing tail) plus its
  # backgroundColor / backgroundTransparency. (Example3DPlotWdgt keeps its own
  # copy because it extends Widget directly, not this base.)
  paintIntoAreaOrBlitFromBackBuffer: (aContext, clippingRectangle, appliedShadow) ->

    if @preliminaryCheckNothingToDraw clippingRectangle, aContext
      return

    [area,sl,st,al,at,w,h] = @calculateKeyValues aContext, clippingRectangle
    return nil if w < 1 or h < 1 or area.isEmpty()

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

    widgetPosition = @position()
    aContext.translate widgetPosition.x, widgetPosition.y

    @renderingHelper aContext, Color.WHITE, appliedShadow

    aContext.restore()

    # paintHighlight here is made to work with
    # al, at, w, h which are actual pixels
    # rather than logical pixels, this is why
    # it's called outside the effect of the scaling
    # (after the restore).
    @paintHighlight aContext, al, at, w, h


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

  simpleShadow: (context, color, appliedShadow) ->

    height = @height()
    width = @width()

    if appliedShadow?
      context.globalAlpha = appliedShadow.alpha * @alpha
      context.fillStyle = (Color.create 80, 80, 80).toString()
      context.fillRect 0, 0, width, height
      # let's avoid paint 3d stuff twice because
      # of the shadow
  
  drawBoundingBox: (context, color, appliedShadow) ->

    height = @height()
    width = @width()

    context.strokeStyle = (Color.create 30,30,30).toString()
    if @drawOnlyPartOfBoundingRect
      context.beginPath()
      context.moveTo 0, 0
      context.lineTo width, 0
      context.lineTo width, height
      context.stroke()
    else
      context.strokeRect 0, 0, width, height
