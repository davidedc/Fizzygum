class ExampleFunctionPlotWdgt extends GraphsPlotsChartsWdgt

  fps: 2

  colloquialName: ->
    "function plot"


  # The paint scaffold is GraphsPlotsChartsAppearance, inherited via
  # GraphsPlotsChartsWdgt (the whole plot family shares it); this class
  # supplies only its drawPlot tail below.


  # step() (advance @graphNumber, frozen under SystemTest replay) is inherited from GraphsPlotsChartsWdgt.

  drawPlot: (context, color, appliedShadow) ->

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
