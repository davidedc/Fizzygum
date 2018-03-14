class ArrowSWIconAppearance extends IconAppearance

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
    context.moveTo 83.88, 92.87
    context.lineTo 83.74, 62.57
    context.bezierCurveTo 83.74, 62.57, 73.14, 62.53, 58.11, 62.46
    context.lineTo 93.27, 27.3
    context.lineTo 72.38, 6.41
    context.lineTo 37.22, 41.57
    context.lineTo 37.11, 15.92
    context.lineTo 6.8, 15.8
    context.lineTo 7.16, 92.51
    context.lineTo 83.88, 92.87
    context.closePath()
    context.fillStyle = outlineColor
    context.fill()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 81.54, 90.53
    context.lineTo 81.43, 64.98
    context.bezierCurveTo 81.43, 64.98, 67.1, 64.92, 52.98, 64.86
    context.lineTo 90.36, 27.48
    context.lineTo 72.2, 9.32
    context.lineTo 34.82, 46.7
    context.lineTo 34.7, 18.24
    context.lineTo 9.14, 18.13
    context.lineTo 9.48, 90.2
    context.lineTo 81.54, 90.53
    context.closePath()
    context.fillStyle = black
    context.fill()
