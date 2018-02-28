class ArrowWIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(1, 1, 1, 1)'
    outlineColor = 'rgba(184, 184, 184, 1)'
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 49.44, 99
    context.lineTo 68.58, 79.85
    context.bezierCurveTo 68.58, 79.85, 61.88, 73.15, 52.39, 63.65
    context.lineTo 97, 63.65
    context.lineTo 97, 37.36
    context.lineTo 52.39, 37.36
    context.lineTo 68.59, 21.15
    context.lineTo 49.44, 2
    context.lineTo 1, 50.5
    context.lineTo 49.44, 99
    context.closePath()
    context.fillStyle = outlineColor
    context.fill()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 49.45, 96.06
    context.lineTo 65.58, 79.91
    context.bezierCurveTo 65.58, 79.91, 56.53, 70.85, 47.61, 61.93
    context.lineTo 95.04, 61.93
    context.lineTo 95.04, 39.08
    context.lineTo 47.61, 39.08
    context.lineTo 65.59, 21.09
    context.lineTo 49.45, 4.94
    context.lineTo 3.94, 50.5
    context.lineTo 49.45, 96.06
    context.closePath()
    context.fillStyle = black
    context.fill()

