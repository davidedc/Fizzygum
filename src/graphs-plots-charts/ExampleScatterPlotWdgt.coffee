class ExampleScatterPlotWdgt extends GraphsPlotsChartsWdgt


  graphNumber: 1
  drawOnlyPartOfBoundingRect: false

  constructor: (@drawOnlyPartOfBoundingRect)->
    super()
    @fps = 1
    world.steppingWdgts.add @

  colloquialName: ->
    "Scatter plot"


  # paintIntoAreaOrBlitFromBackBuffer is inherited from GraphsPlotsChartsWdgt
  # (the whole plot family shares the identical paint scaffold); this class
  # supplies only its _renderingHelper below.


  # step() (advance @graphNumber, frozen under SystemTest replay) is inherited from GraphsPlotsChartsWdgt.

  _renderingHelper: (context, color, appliedShadow) ->

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

    context.globalAlpha = @alpha

    context.lineWidth = 1

    context.beginPath()
    for i in [0...100]
      widthPerc = 0.4 + @seeded_randn_bm() / 10
      heightPerc = 0.4 + @seeded_randn_bm() / 10

      context.moveTo Math.round(2 * circleRadius + availableWidth * widthPerc),Math.round(circleRadius + availableHeight * heightPerc)
      context.arc Math.round(circleRadius + availableWidth * widthPerc),Math.round(circleRadius + availableHeight * heightPerc),circleRadius,0,2*Math.PI
    context.strokeStyle = '#325FA2'
    context.stroke()

    context.beginPath()
    for i in [0...100]
      widthPerc = 0.6 + @seeded_randn_bm() / 10
      heightPerc = 0.6 + @seeded_randn_bm() / 10

      context.moveTo Math.round(2 * circleRadius + availableWidth * widthPerc),Math.round(circleRadius + availableHeight * heightPerc)
      context.arc Math.round(circleRadius + availableWidth * widthPerc),Math.round(circleRadius + availableHeight * heightPerc),circleRadius,0,2*Math.PI

    context.strokeStyle = '#FF0000'
    context.stroke()

    @drawBoundingBox context, color, appliedShadow


