# REQUIRES KeepsRatioWhenInVerticalStackMixin

class GraphsPlotsChartsWdgt extends Widget

  @augmentWith KeepsRatioWhenInVerticalStackMixin, @name

  drawOnlyPartOfBoundingRect: false

  constructor: (@drawOnlyPartOfBoundingRect)->
    super()
    @setColor new Color 255, 125, 125
    @rawSetExtent new Point 200, 200


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
      context.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha
      context.fillStyle = (new Color 80, 80, 80).toString()
      context.fillRect 0, 0, width, height
      # let's avoid paint 3d stuff twice because
      # of the shadow
  
  drawBoundingBox: (context, color, appliedShadow) ->

    height = @height()
    width = @width()

    context.strokeStyle = (new Color 30,30,30).toString()
    if @drawOnlyPartOfBoundingRect
      context.beginPath()
      context.moveTo 0, 0
      context.lineTo width, 0
      context.lineTo width, height
      context.stroke()
    else
      context.strokeRect 0, 0, width, height
