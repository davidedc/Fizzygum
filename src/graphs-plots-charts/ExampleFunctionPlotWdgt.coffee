class ExampleFunctionPlotWdgt extends GraphsPlotsChartsWdgt

  graphNumber: 1
  drawOnlyPartOfBoundingRect: false

  constructor: (@drawOnlyPartOfBoundingRect)->
    super()
    @fps = 2
    world.steppingWdgts.add @

  colloquialName: ->
    "Function plot"


  # paintIntoAreaOrBlitFromBackBuffer is inherited from GraphsPlotsChartsWdgt
  # (the whole plot family shares the identical paint scaffold); this class
  # supplies only its renderingHelper below.


  # step() (advance @graphNumber, frozen under SystemTest replay) is inherited from GraphsPlotsChartsWdgt.

  renderingHelper: (context, color, appliedShadow) ->

    @seed = @graphNumber
    circleRadius = 5
    height = @height()
    width = @width()

    if appliedShadow?
      @simpleShadow context, color, appliedShadow
      return

    context.fillStyle = WorldWdgt.preferencesAndSettings.editableItemBackgroundColor.toString()
    context.fillRect 0, 0, width, height

    availableHeight = height - 2 * circleRadius
    availableWidth = width - 2 * circleRadius

    context.globalAlpha = (if appliedShadow? then appliedShadow.alpha else 1) * @alpha

    context.fillStyle = '#325FA2'
    angle = @seededRandom()
    for xPos in [0..width]
      i = xPos/width * 1000
      heightPerc = 0.5 + Math.sin(10*angle+i/(300*(angle+0.01)))/3 - i/(5000+50000*angle)
      context.fillRect xPos, availableHeight * heightPerc, 2,2

    @drawBoundingBox context, color, appliedShadow
