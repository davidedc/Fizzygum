class VideoPlayIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    white = 'rgba(255, 255, 255, 1)'
    outlineColor = 'rgba(184, 184, 184, 1)'
    red = 'rgba(255, 38, 0, 1)'
    #// Group
    #// outline Drawing
    context.beginPath()
    context.moveTo 95.28, 31.43
    context.bezierCurveTo 95.28, 31.43, 94.37, 25.01, 91.6, 22.19
    context.bezierCurveTo 88.09, 18.48, 84.15, 18.46, 82.35, 18.24
    context.bezierCurveTo 69.41, 17.3, 50.02, 17.3, 50.02, 17.3
    context.lineTo 49.98, 17.3
    context.bezierCurveTo 49.98, 17.3, 30.59, 17.3, 17.65, 18.24
    context.bezierCurveTo 15.85, 18.46, 11.91, 18.48, 8.4, 22.19
    context.bezierCurveTo 5.63, 25.01, 4.72, 31.43, 4.72, 31.43
    context.bezierCurveTo 4.72, 31.43, 3.8, 38.96, 3.8, 46.5
    context.lineTo 3.8, 53.56
    context.bezierCurveTo 3.8, 61.1, 4.72, 68.63, 4.72, 68.63
    context.bezierCurveTo 4.72, 68.63, 5.63, 75.05, 8.4, 77.88
    context.bezierCurveTo 11.91, 81.59, 16.53, 81.47, 18.58, 81.86
    context.bezierCurveTo 25.97, 82.57, 50, 82.8, 50, 82.8
    context.bezierCurveTo 50, 82.8, 69.41, 82.77, 82.35, 81.82
    context.bezierCurveTo 84.16, 81.61, 88.09, 81.59, 91.6, 77.88
    context.bezierCurveTo 94.37, 75.05, 95.28, 68.63, 95.28, 68.63
    context.bezierCurveTo 95.28, 68.63, 96.2, 61.09, 96.2, 53.56
    context.lineTo 96.2, 46.5
    context.bezierCurveTo 96.2, 38.96, 95.28, 31.43, 95.28, 31.43
    context.closePath()
    context.fillStyle = outlineColor
    context.fill()
    #// red lozange Drawing
    context.beginPath()
    context.moveTo 92.49, 33.04
    context.bezierCurveTo 92.49, 33.04, 91.64, 27.17, 89.04, 24.59
    context.bezierCurveTo 85.75, 21.2, 82.05, 21.19, 80.36, 20.99
    context.bezierCurveTo 68.22, 20.13, 50.02, 20.13, 50.02, 20.13
    context.lineTo 49.98, 20.13
    context.bezierCurveTo 49.98, 20.13, 31.78, 20.13, 19.64, 20.99
    context.bezierCurveTo 17.95, 21.19, 14.25, 21.2, 10.96, 24.59
    context.bezierCurveTo 8.36, 27.17, 7.51, 33.04, 7.51, 33.04
    context.bezierCurveTo 7.51, 33.04, 6.65, 39.92, 6.65, 46.81
    context.lineTo 6.65, 53.26
    context.bezierCurveTo 6.65, 60.15, 7.51, 67.03, 7.51, 67.03
    context.bezierCurveTo 7.51, 67.03, 8.36, 72.89, 10.96, 75.47
    context.bezierCurveTo 14.26, 78.86, 18.59, 78.76, 20.52, 79.11
    context.bezierCurveTo 27.45, 79.76, 50, 79.97, 50, 79.97
    context.bezierCurveTo 50, 79.97, 68.22, 79.95, 80.36, 79.08
    context.bezierCurveTo 82.05, 78.88, 85.75, 78.86, 89.04, 75.47
    context.bezierCurveTo 91.64, 72.89, 92.49, 67.03, 92.49, 67.03
    context.bezierCurveTo 92.49, 67.03, 93.35, 60.14, 93.35, 53.26
    context.lineTo 93.35, 46.81
    context.bezierCurveTo 93.35, 39.92, 92.49, 33.04, 92.49, 33.04
    context.closePath()
    context.fillStyle = red
    context.fill()
    #// Triangle Drawing
    context.beginPath()
    context.moveTo 41.04, 61.08
    context.lineTo 64.47, 49.17
    context.lineTo 41.04, 37.18
    context.lineTo 41.04, 61.08
    context.closePath()
    context.fillStyle = white
    context.fill()


