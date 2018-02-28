class ArrowSEIconAppearance extends IconAppearance

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
    context.moveTo 93.37, 16.62
    context.lineTo 63.07, 16.76
    context.bezierCurveTo 63.07, 16.76, 63.03, 27.36, 62.96, 42.39
    context.lineTo 27.8, 7.23
    context.lineTo 6.91, 28.12
    context.lineTo 42.07, 63.28
    context.lineTo 16.42, 63.39
    context.lineTo 16.3, 93.7
    context.lineTo 93.01, 93.34
    context.lineTo 93.37, 16.62
    context.closePath()
    context.fillStyle = outlineColor
    context.fill()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 91.03, 18.96
    context.lineTo 65.48, 19.07
    context.bezierCurveTo 65.48, 19.07, 65.42, 33.4, 65.36, 47.52
    context.lineTo 27.98, 10.14
    context.lineTo 9.82, 28.3
    context.lineTo 47.2, 65.68
    context.lineTo 18.74, 65.8
    context.lineTo 18.63, 91.36
    context.lineTo 90.7, 91.02
    context.lineTo 91.03, 18.96
    context.closePath()
    context.fillStyle = black
    context.fill()
