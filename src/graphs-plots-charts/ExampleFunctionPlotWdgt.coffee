class ExampleFunctionPlotWdgt extends Widget

  graphNumber: 1
  drawOnlyPartOfBoundingRect: false

  constructor: (@drawOnlyPartOfBoundingRect)->
    super()
    @setColor new Color 255, 125, 125
    @rawSetExtent new Point 200, 200

    @fps = 2
    world.addSteppingMorph @

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


  step: ->
    @graphNumber++
    @changed()

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

  renderingHelper: (context, color, appliedShadow) ->

    @seed = @graphNumber
    circleRadius = 5
    height = @height()
    width = @width()

    if appliedShadow?
      context.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha
      context.fillStyle = (new Color 80, 80, 80).toString()
      context.fillRect 0, 0, width, height
      # let's avoid paint 3d stuff twice because
      # of the shadow
      return

    context.fillStyle = (new Color 242,242,242).toString()
    context.fillRect 0, 0, width, height

    availableHeight = height - 2 * circleRadius
    availableWidth = width - 2 * circleRadius

    context.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha

    context.fillStyle = '#325FA2'
    angle = @seededRandom()
    for i in [0..1000]
      xPos = (i/1000)*width
      heightPerc = 0.5 + Math.sin(i/(100))/(3+3*@seededRandom()) - i/(5000+5000*angle) + @seeded_randn_bm() / 70
      context.fillRect xPos, availableHeight * heightPerc, 2,2

    context.strokeStyle = (new Color 30,30,30).toString()
    if @drawOnlyPartOfBoundingRect
      context.beginPath()
      context.moveTo 0, 0
      context.lineTo width, 0
      context.lineTo width, height
      context.stroke()
    else
      context.strokeRect 0, 0, width, height
