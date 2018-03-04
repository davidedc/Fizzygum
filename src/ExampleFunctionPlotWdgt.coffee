class ExampleFunctionPlotWdgt extends Widget


  constructor: ->
    super()
    @setColor new Color 255, 125, 125
    @setExtent new Point 200, 200
    return

  colloquialName: ->
    "Function plot"


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
      aContext.scale pixelRatio, pixelRatio

      morphPosition = @position()
      aContext.translate morphPosition.x, morphPosition.y

      @renderingHelper aContext, new Color(255, 255, 255), appliedShadow

      aContext.restore()

      # paintHighlight here is made to work with
      # al, at, w, h which are actual pixels
      # rather than logical pixels, this is why
      # it's called outside the effect of the scaling
      # (after the restore).
      @paintHighlight aContext, al, at, w, h



  renderingHelper: (context, color, appliedShadow) ->
    seed = 1

    # see https://stackoverflow.com/a/19303725
    seededRandom = ->
      x = Math.sin(seed++) * 10000
      return x - Math.floor(x)

    # Standard Normal variate using Box-Muller transform
    # see https://stackoverflow.com/a/36481059
    seeded_randn_bm = ->
      u = 0
      v = 0
      while u == 0
        u = seededRandom()
      #Converting [0,1) to (0,1)
      while v == 0
        v = seededRandom()
      return Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v)


    circleRadius = 5

    height = @height()
    width = @width()

    availableHeight = height - 2 * circleRadius
    availableWidth = width - 2 * circleRadius

    context.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha

    context.fillStyle = '#325FA2'
    for i in [0..1000]
      xPos = (i/1000)*width
      heightPerc = 0.4 + Math.sin(i/100)/3 - i/10000 + seeded_randn_bm() / 70
      context.fillRect xPos, availableHeight * heightPerc, 2,2
