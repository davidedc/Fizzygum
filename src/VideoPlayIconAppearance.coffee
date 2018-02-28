class VideoPlayIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    white = 'rgba(255, 255, 255, 1)'
    red = 'rgba(255, 38, 0, 1)'
    #// Group
    #// background Drawing
    context.beginPath()
    context.moveTo 90.65, 0.5
    context.lineTo 9.36, 0.5
    context.lineTo 9.36, 0.5
    context.bezierCurveTo 0.05, 0.5, 0.5, 0.05, 0.5, 9.36
    context.lineTo 0.5, 90.65
    context.lineTo 0.5, 90.65
    context.bezierCurveTo 0.5, 99.96, 0.05, 99.5, 9.36, 99.5
    context.lineTo 90.65, 99.5
    context.lineTo 90.65, 99.5
    context.bezierCurveTo 99.96, 99.5, 99.5, 99.96, 99.5, 90.65
    context.lineTo 99.5, 9.36
    context.lineTo 99.5, 9.36
    context.bezierCurveTo 99.5, 0.05, 99.96, 0.5, 90.65, 0.5
    context.closePath()
    context.fillStyle = red
    context.fill()
    #// white lozange Drawing
    context.beginPath()
    context.moveTo 92.49, 32.54
    context.bezierCurveTo 92.49, 32.54, 91.64, 26.68, 89.04, 24.1
    context.bezierCurveTo 85.75, 20.71, 82.05, 20.69, 80.36, 20.49
    context.bezierCurveTo 68.22, 19.63, 50.02, 19.63, 50.02, 19.63
    context.lineTo 49.98, 19.63
    context.bezierCurveTo 49.98, 19.63, 31.78, 19.63, 19.64, 20.49
    context.bezierCurveTo 17.95, 20.69, 14.25, 20.71, 10.96, 24.1
    context.bezierCurveTo 8.36, 26.68, 7.51, 32.54, 7.51, 32.54
    context.bezierCurveTo 7.51, 32.54, 6.65, 39.42, 6.65, 46.31
    context.lineTo 6.65, 52.76
    context.bezierCurveTo 6.65, 59.65, 7.51, 66.53, 7.51, 66.53
    context.bezierCurveTo 7.51, 66.53, 8.36, 72.4, 10.96, 74.98
    context.bezierCurveTo 14.26, 78.37, 18.59, 78.26, 20.52, 78.62
    context.bezierCurveTo 27.45, 79.27, 50, 79.48, 50, 79.48
    context.bezierCurveTo 50, 79.48, 68.22, 79.45, 80.36, 78.58
    context.bezierCurveTo 82.05, 78.39, 85.75, 78.37, 89.04, 74.98
    context.bezierCurveTo 91.64, 72.4, 92.49, 66.53, 92.49, 66.53
    context.bezierCurveTo 92.49, 66.53, 93.35, 59.64, 93.35, 52.76
    context.lineTo 93.35, 46.31
    context.bezierCurveTo 93.35, 39.42, 92.49, 32.54, 92.49, 32.54
    context.closePath()
    context.fillStyle = white
    context.fill()
    #// Triangle Drawing
    context.beginPath()
    context.moveTo 41.04, 60.59
    context.lineTo 64.47, 48.67
    context.lineTo 41.04, 36.68
    context.lineTo 41.04, 60.59
    context.closePath()
    context.fillStyle = red
    context.fill()

