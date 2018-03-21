class ElasticWindowIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// Oval Drawing
    @oval context, 11, 11, 6, 6
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 2 Drawing
    @oval context, 22, 11, 6, 6
    context.fillStyle = iconColorString
    context.fill()
    #// window bar bottom Drawing
    context.beginPath()
    context.moveTo 5, 24
    context.lineTo 91, 24
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.stroke()
    #// window border Drawing
    context.beginPath()
    context.rect 4, 4, 88, 88
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.lineJoin = 'round'
    context.stroke()
    #// Group 4
    #// Bezier 20 Drawing
    context.beginPath()
    context.moveTo 82, 83
    context.lineTo 82, 33
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 80.5, 57.65
    context.bezierCurveTo 79.09, 60.86, 77.49, 64.5, 74.07, 64.5
    context.bezierCurveTo 70.64, 64.5, 69.05, 60.86, 67.64, 57.65
    context.bezierCurveTo 66.18, 54.32, 65.09, 52.15, 63.23, 52.15
    context.bezierCurveTo 61.38, 52.15, 60.28, 54.32, 58.83, 57.65
    context.bezierCurveTo 57.42, 60.86, 55.82, 64.5, 52.4, 64.5
    context.bezierCurveTo 48.97, 64.5, 47.38, 60.86, 45.97, 57.65
    context.bezierCurveTo 44.51, 54.32, 43.42, 52.15, 41.56, 52.15
    context.bezierCurveTo 39.71, 52.15, 38.62, 54.32, 37.16, 57.65
    context.bezierCurveTo 35.75, 60.86, 34.16, 64.5, 30.73, 64.5
    context.bezierCurveTo 27.31, 64.5, 25.72, 60.86, 24.31, 57.65
    context.bezierCurveTo 22.85, 54.32, 21.76, 52.15, 19.9, 52.15
    context.bezierCurveTo 18.05, 52.15, 16.96, 54.32, 15.5, 57.65
    context.strokeStyle = iconColorString
    context.lineWidth = 3
    context.miterLimit = 4
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 15, 83
    context.lineTo 15, 33
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
