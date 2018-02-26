class ChapterXXXIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    #// Text Drawing
    context.beginPath()
    context.moveTo 34.57, 40.55
    context.bezierCurveTo 29.13, 40.1, 20.36, 38.14, 20.68, 25.85
    context.bezierCurveTo 21, 14, 29.65, 11.5, 34.58, 11.09
    context.bezierCurveTo 39.52, 10.68, 43.71, 13.21, 44.18, 13.45
    context.lineTo 44.18, 20.21
    context.lineTo 43.46, 20.21
    context.bezierCurveTo 43.12, 19.91, 42, 16, 35.73, 16.41
    context.bezierCurveTo 28.26, 16.89, 28.03, 24.19, 28.03, 25.87
    context.bezierCurveTo 28.03, 27.63, 27.82, 34.51, 34.77, 35.24
    context.bezierCurveTo 42, 36, 43.18, 31.77, 43.54, 31.45
    context.lineTo 44.18, 31.45
    context.lineTo 44.18, 38.11
    context.bezierCurveTo 43.66, 38.36, 40, 41, 34.57, 40.55
    context.closePath()
    context.moveTo 68.02, 40
    context.lineTo 61.32, 40
    context.lineTo 61.32, 29.39
    context.bezierCurveTo 61.32, 28.53, 61, 27, 59.84, 25.88
    context.bezierCurveTo 58.67, 24.76, 55.29, 24.4, 54.66, 24.84
    context.lineTo 54.66, 40
    context.lineTo 47.99, 40
    context.lineTo 47.99, 10.37
    context.lineTo 54.66, 10.37
    context.lineTo 54.66, 20.98
    context.bezierCurveTo 55.75, 20.05, 57.99, 18.46, 61.28, 19.02
    context.bezierCurveTo 67, 20, 68.02, 23.46, 68.02, 26.08
    context.lineTo 68.02, 40
    context.closePath()
    context.moveTo 79.87, 40
    context.lineTo 73.13, 40
    context.lineTo 73.13, 32.52
    context.lineTo 79.87, 32.52
    context.lineTo 79.87, 40
    context.closePath()
    context.moveTo 27.1, 87
    context.lineTo 19.29, 87
    context.lineTo 15.22, 80.85
    context.lineTo 11.03, 87
    context.lineTo 3.37, 87
    context.lineTo 11.24, 76.32
    context.lineTo 3.51, 65.61
    context.lineTo 11.31, 65.61
    context.lineTo 15.31, 71.65
    context.lineTo 19.33, 65.61
    context.lineTo 27.01, 65.61
    context.lineTo 19.26, 76.15
    context.lineTo 27.1, 87
    context.closePath()
    context.moveTo 36.49, 87
    context.lineTo 29.75, 87
    context.lineTo 29.75, 79.52
    context.lineTo 36.49, 79.52
    context.lineTo 36.49, 87
    context.closePath()
    context.moveTo 62.86, 87
    context.lineTo 55.06, 87
    context.lineTo 50.98, 80.85
    context.lineTo 46.79, 87
    context.lineTo 39.14, 87
    context.lineTo 47, 76.32
    context.lineTo 39.27, 65.61
    context.lineTo 47.08, 65.61
    context.lineTo 51.08, 71.65
    context.lineTo 55.09, 65.61
    context.lineTo 62.77, 65.61
    context.lineTo 55.02, 76.15
    context.lineTo 62.86, 87
    context.closePath()
    context.moveTo 72.25, 87
    context.lineTo 65.51, 87
    context.lineTo 65.51, 79.52
    context.lineTo 72.25, 79.52
    context.lineTo 72.25, 87
    context.closePath()
    context.moveTo 98.63, 87
    context.lineTo 90.82, 87
    context.lineTo 86.74, 80.85
    context.lineTo 82.55, 87
    context.lineTo 74.9, 87
    context.lineTo 82.76, 76.32
    context.lineTo 75.03, 65.61
    context.lineTo 82.84, 65.61
    context.lineTo 86.84, 71.65
    context.lineTo 90.86, 65.61
    context.lineTo 98.53, 65.61
    context.lineTo 90.78, 76.15
    context.lineTo 98.63, 87
    context.closePath()
    context.fillStyle = black
    context.fill()

