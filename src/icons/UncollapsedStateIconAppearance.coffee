class UncollapsedStateIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 400, 400

  paintFunction: (context) ->
    #// Color Declarations
    colorString = 'rgb(51, 0, 0)'
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 45.5, 137.5
    context.lineTo 200.93, 288.5
    context.lineTo 362.5, 133.5
    context.miterLimit = 30
    context.strokeStyle = colorString
    context.lineWidth = 30
    context.stroke()
