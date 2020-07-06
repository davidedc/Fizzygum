class TemplatesIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    #// Group
    #// page below
    #// page below bottom right corner Drawing
    context.beginPath()
    context.moveTo 43, 87
    context.lineTo 64.21, 95.76
    context.lineTo 67.11, 87
    context.strokeStyle = Color.BLACK.toString()
    context.lineWidth = 2
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// page below bottom left corner Drawing
    context.beginPath()
    context.moveTo 20.57, 43.92
    context.lineTo 9, 75.06
    context.lineTo 20.57, 78.96
    context.strokeStyle = Color.BLACK.toString()
    context.lineWidth = 2
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// page below top left corner Drawing
    context.beginPath()
    context.moveTo 32.14, 12.78
    context.lineTo 34.07, 5
    context.lineTo 57.21, 12.78
    context.strokeStyle = Color.BLACK.toString()
    context.lineWidth = 2
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// page below top right corner Drawing
    context.beginPath()
    context.moveTo 78.43, 20.57
    context.lineTo 90, 24.46
    context.lineTo 78.43, 53.66
    context.strokeStyle = Color.BLACK.toString()
    context.lineWidth = 2
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// line 3 Drawing
    context.beginPath()
    context.moveTo 28.29, 75.06
    context.lineTo 53.36, 75.06
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// line 2 Drawing
    context.beginPath()
    context.moveTo 28.29, 63.39
    context.lineTo 70.71, 63.39
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// line 1 Drawing
    context.beginPath()
    context.moveTo 28.29, 51.71
    context.lineTo 70.71, 51.71
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// heart Drawing
    context.beginPath()
    context.moveTo 49.49, 40.77
    context.bezierCurveTo 49, 40.77, 48.67, 40.61, 48.35, 40.28
    context.lineTo 40.83, 32.8
    context.bezierCurveTo 38.05, 30.03, 38.05, 25.8, 40.83, 23.04
    context.bezierCurveTo 43.12, 20.76, 47.57, 21.31, 49.49, 24.01
    context.bezierCurveTo 51.43, 21.31, 55.7, 20.59, 58.15, 23.04
    context.lineTo 58.15, 23.04
    context.lineTo 58.15, 23.04
    context.lineTo 58.15, 23.04
    context.bezierCurveTo 59.45, 24.34, 60.11, 26.13, 60.11, 27.92
    context.bezierCurveTo 60.11, 29.71, 59.45, 31.5, 58.15, 32.8
    context.lineTo 50.63, 40.28
    context.bezierCurveTo 50.31, 40.61, 49.98, 40.77, 49.49, 40.77
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1.5
    context.miterLimit = 4
    context.stroke()
    #// first page Drawing
    context.beginPath()
    context.rect 21, 13, 57, 74
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.lineJoin = 'round'
    context.stroke()
