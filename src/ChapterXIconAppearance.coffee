class ChapterXIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    #// Group 2
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 32.44, 44.54
    context.bezierCurveTo 26.27, 43.97, 16.31, 41.48, 16.68, 25.95
    context.bezierCurveTo 17.04, 10.96, 26.86, 7.81, 32.46, 7.28
    context.bezierCurveTo 38.07, 6.76, 42.83, 9.97, 43.36, 10.27
    context.lineTo 43.36, 18.82
    context.lineTo 42.54, 18.82
    context.bezierCurveTo 42.15, 18.43, 40.88, 13.49, 33.76, 14
    context.bezierCurveTo 25.28, 14.61, 25.03, 23.85, 25.03, 25.97
    context.bezierCurveTo 25.03, 28.2, 24.79, 36.9, 32.67, 37.82
    context.bezierCurveTo 40.88, 38.78, 42.22, 33.43, 42.62, 33.03
    context.lineTo 43.36, 33.03
    context.lineTo 43.36, 41.46
    context.bezierCurveTo 42.77, 41.76, 38.61, 45.1, 32.44, 44.54
    context.closePath()
    context.moveTo 70.42, 43.84
    context.lineTo 62.81, 43.84
    context.lineTo 62.81, 30.43
    context.bezierCurveTo 62.81, 29.34, 62.45, 27.4, 61.13, 25.98
    context.bezierCurveTo 59.81, 24.57, 55.97, 24.11, 55.25, 24.67
    context.lineTo 55.25, 43.84
    context.lineTo 47.68, 43.84
    context.lineTo 47.68, 6.37
    context.lineTo 55.25, 6.37
    context.lineTo 55.25, 19.78
    context.bezierCurveTo 56.49, 18.61, 59.04, 16.6, 62.77, 17.31
    context.bezierCurveTo 69.26, 18.55, 70.42, 22.93, 70.42, 26.24
    context.lineTo 70.42, 43.84
    context.closePath()
    context.moveTo 83.87, 43.84
    context.lineTo 76.22, 43.84
    context.lineTo 76.22, 34.38
    context.lineTo 83.87, 34.38
    context.lineTo 83.87, 43.84
    context.closePath()
    context.fillStyle = black
    context.fill()
    #// Group
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 63.9, 91
    context.lineTo 53.85, 91
    context.lineTo 48.61, 82.55
    context.lineTo 43.22, 91
    context.lineTo 33.37, 91
    context.lineTo 43.49, 76.32
    context.lineTo 33.55, 61.61
    context.lineTo 43.59, 61.61
    context.lineTo 48.73, 69.91
    context.lineTo 53.9, 61.61
    context.lineTo 63.78, 61.61
    context.lineTo 53.81, 76.08
    context.lineTo 63.9, 91
    context.closePath()
    context.fillStyle = black
    context.fill()
