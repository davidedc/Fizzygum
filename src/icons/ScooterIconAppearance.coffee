class ScooterIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    colorString = 'rgb(0, 0, 0)'
    #// Oval Drawing
    @oval context, 10.5, 136.5, 34.5, 34.5
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Oval 2 Drawing
    @oval context, 154, 135.5, 34.5, 34.5
    context.strokeStyle = colorString
    context.lineWidth = 10
    context.stroke()
    #// Oval 3 Drawing
    @arc context, 141, 123, 57, 57, 176, 268, false
    context.strokeStyle = colorString
    context.lineWidth = 7.5
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 171.5, 153.5
    context.lineTo 167, 38
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 8
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 146.5, 36.5
    context.lineTo 190.5, 36.5
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 7
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 28.5, 153.5
    context.lineTo 140.5, 153.5
    context.lineCap = 'round'
    context.strokeStyle = colorString
    context.lineWidth = 7
    context.stroke()
