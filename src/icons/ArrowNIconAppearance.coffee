class ArrowNIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(1, 1, 1, 1)'
    outlineColor = 'rgba(184, 184, 184, 1)'
    #// Group
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 1.5, 50.94
    context.lineTo 20.65, 70.08
    context.bezierCurveTo 20.65, 70.08, 27.35, 63.38, 36.85, 53.89
    context.lineTo 36.85, 98.5
    context.lineTo 63.14, 98.5
    context.lineTo 63.14, 53.89
    context.lineTo 79.35, 70.09
    context.lineTo 98.5, 50.94
    context.lineTo 50, 2.5
    context.lineTo 1.5, 50.94
    context.closePath()
    context.fillStyle = outlineColor
    context.fill()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 4.44, 50.95
    context.lineTo 20.59, 67.08
    context.bezierCurveTo 20.59, 67.08, 29.65, 58.03, 38.57, 49.11
    context.lineTo 38.57, 96.54
    context.lineTo 61.42, 96.54
    context.lineTo 61.42, 49.11
    context.lineTo 79.41, 67.09
    context.lineTo 95.56, 50.95
    context.lineTo 50, 5.44
    context.lineTo 4.44, 50.95
    context.closePath()
    context.fillStyle = black
    context.fill()

