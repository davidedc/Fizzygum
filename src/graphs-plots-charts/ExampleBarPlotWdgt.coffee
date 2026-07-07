class ExampleBarPlotWdgt extends GraphsPlotsChartsWdgt

  graphNumber: 1
  drawOnlyPartOfBoundingRect: false

  constructor: (@drawOnlyPartOfBoundingRect)->
    super()
    @fps = 0.5
    world.steppingWdgts.add @

  colloquialName: ->
    "Bar plot"


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

    availableHeight = height

    context.globalAlpha = @alpha

    for i in [0..20]
      xPos = (i/21)*width
      heightPerc = 0.2 + Math.sin(i/100)*3 - i/10000 + @seeded_randn_bm() / 20
      if @seededRandom() > 0.5
        context.fillStyle = '#325FA2'
      else
        context.fillStyle = '#FF0000'
      context.fillRect Math.round(xPos), Math.round(availableHeight - (availableHeight * heightPerc)), Math.round((1/20)*width - 2), Math.round(availableHeight * heightPerc)

    @drawBoundingBox context, color, appliedShadow
