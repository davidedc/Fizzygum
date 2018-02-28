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
    context.moveTo 90.5, 0.5
    context.lineTo 9, 0.5
    context.lineTo 9, 0.5
    context.bezierCurveTo 0, 0.5, 0.5, 0, 0.5, 9
    context.lineTo 0.5, 90.5
    context.lineTo 0.5, 90.5
    context.bezierCurveTo 0.5, 100, 0, 99.5, 9, 99.5
    context.lineTo 90.5, 99.5
    context.lineTo 90.5, 99.5
    context.bezierCurveTo 100, 99.5, 99.5, 100, 99.5, 90.5
    context.lineTo 99.5, 9
    context.lineTo 99.5, 9
    context.bezierCurveTo 99.5, 0, 100, 0.5, 90.5, 0.5
    context.closePath()
    context.fillStyle = red
    context.fill()
    #// white lozange Drawing
    context.beginPath()
    context.moveTo 92.5, 32.5
    context.bezierCurveTo 92.5, 32.5, 91.5, 26.5, 89, 24
    context.bezierCurveTo 85.5, 21, 82, 20.5, 80, 20.5
    context.bezierCurveTo 68, 19.5, 50, 19.5, 50, 19.5
    context.lineTo 50, 19.5
    context.bezierCurveTo 50, 19.5, 31.5, 19.5, 19.5, 20.5
    context.bezierCurveTo 18, 20.5, 14, 20.5, 11, 24
    context.bezierCurveTo 8, 26.5, 7.5, 32.5, 7.5, 32.5
    context.bezierCurveTo 7.5, 32.5, 6.5, 39.5, 6.5, 46
    context.lineTo 6.5, 53
    context.bezierCurveTo 6.5, 59.5, 7.5, 66.5, 7.5, 66.5
    context.bezierCurveTo 7.5, 66.5, 8, 72.5, 11, 75
    context.bezierCurveTo 14, 78, 18.5, 78, 20.5, 78.5
    context.bezierCurveTo 27.5, 79, 50, 79.5, 50, 79.5
    context.bezierCurveTo 50, 79.5, 68, 79.5, 80, 78.5
    context.bezierCurveTo 82, 78.5, 85.5, 78.5, 89, 75
    context.bezierCurveTo 91.5, 72.5, 92.5, 66.5, 92.5, 66.5
    context.bezierCurveTo 92.5, 66.5, 93.5, 59.5, 93.5, 53
    context.lineTo 93.5, 46.5
    context.bezierCurveTo 93.5, 39.5, 92.5, 32.5, 92.5, 32.5
    context.closePath()
    context.fillStyle = white
    context.fill()
    #// Triangle Drawing
    context.beginPath()
    context.moveTo 41, 60.5
    context.lineTo 64.5, 48.5
    context.lineTo 41, 36.5
    context.lineTo 41, 60.5
    context.closePath()
    context.fillStyle = red
    context.fill()

