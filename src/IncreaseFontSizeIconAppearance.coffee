class IncreaseFontSizeIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    #// Group
    #// letter a Drawing
    context.beginPath()
    context.moveTo 37.91, 19.09
    context.bezierCurveTo 37.42, 17.84, 36.06, 17, 34.52, 17
    context.bezierCurveTo 32.98, 17, 31.62, 17.84, 31.13, 19.09
    context.lineTo 9.41, 74.96
    context.bezierCurveTo 8.79, 76.56, 9.8, 78.3, 11.67, 78.84
    context.bezierCurveTo 13.55, 79.38, 15.56, 78.51, 16.19, 76.9
    context.lineTo 20.88, 64.84
    context.lineTo 47.93, 64.84
    context.bezierCurveTo 48.01, 64.84, 48.07, 64.8, 48.14, 64.8
    context.lineTo 52.85, 76.9
    context.bezierCurveTo 53.35, 78.19, 54.74, 79, 56.23, 79
    context.bezierCurveTo 56.61, 79, 56.99, 78.95, 57.36, 78.84
    context.bezierCurveTo 59.23, 78.3, 60.24, 76.57, 59.62, 74.97
    context.lineTo 37.91, 19.09
    context.closePath()
    context.moveTo 23.26, 58.71
    context.lineTo 34.52, 29.74
    context.lineTo 45.78, 58.71
    context.lineTo 23.26, 58.71
    context.closePath()
    context.fillStyle = black
    context.fill()
    #// arrow up Drawing
    context.beginPath()
    context.moveTo 91.5, 56.79
    context.lineTo 74.97, 40.34
    context.lineTo 58.44, 56.79
    context.lineTo 91.5, 56.79
    context.closePath()
    context.fillStyle = black
    context.fill()

