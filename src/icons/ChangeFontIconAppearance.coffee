class ChangeFontIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    #// A serif Drawing
    context.beginPath()
    context.moveTo 75.17, 68.88
    context.lineTo 64.75, 44.1
    context.lineTo 54.47, 68.88
    context.lineTo 75.17, 68.88
    context.closePath()
    context.moveTo 36.32, 92
    context.lineTo 36.32, 90.37
    context.bezierCurveTo 38.63, 90.11, 40.37, 89.23, 41.53, 87.74
    context.bezierCurveTo 42.68, 86.24, 44.67, 82.19, 47.48, 75.56
    context.lineTo 66.25, 31.4
    context.lineTo 68, 31.4
    context.lineTo 90.42, 82.42
    context.bezierCurveTo 91.91, 85.82, 93.1, 87.92, 94, 88.73
    context.bezierCurveTo 94.89, 89.53, 96.39, 90.08, 98.5, 90.37
    context.lineTo 98.5, 92
    context.lineTo 75.61, 92
    context.lineTo 75.61, 90.37
    context.bezierCurveTo 78.24, 90.14, 79.94, 89.85, 80.7, 89.52
    context.bezierCurveTo 81.46, 89.18, 81.85, 88.35, 81.85, 87.03
    context.bezierCurveTo 81.85, 86.59, 81.7, 85.82, 81.41, 84.71
    context.bezierCurveTo 81.11, 83.59, 80.7, 82.42, 80.18, 81.19
    context.lineTo 76.44, 72.53
    context.lineTo 52.89, 72.53
    context.bezierCurveTo 50.54, 78.42, 49.14, 82.02, 48.69, 83.32
    context.bezierCurveTo 48.23, 84.62, 48.01, 85.66, 48.01, 86.42
    context.bezierCurveTo 48.01, 87.94, 48.62, 89, 49.85, 89.58
    context.bezierCurveTo 50.62, 89.93, 52.05, 90.2, 54.16, 90.37
    context.lineTo 54.16, 92
    context.lineTo 36.32, 92
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// A sans serif Drawing
    context.beginPath()
    context.moveTo 33.67, 14.23
    context.lineTo 33.51, 14.23
    context.lineTo 23.36, 42.21
    context.lineTo 43.65, 42.21
    context.lineTo 33.67, 14.23
    context.closePath()
    context.moveTo 38.12, 7
    context.bezierCurveTo 38.12, 7, 47.47, 30.99, 54.35, 48.63
    context.bezierCurveTo 52.82, 52.25, 51.26, 55.92, 49.88, 59.18
    context.bezierCurveTo 48.11, 54.3, 46.17, 48.93, 46.17, 48.93
    context.lineTo 20.84, 48.93
    context.lineTo 14.13, 67
    context.lineTo 6, 67
    context.bezierCurveTo 6, 67, 22.23, 25.22, 27.61, 11.39
    context.bezierCurveTo 28.67, 8.64, 29.31, 7, 29.31, 7
    context.lineTo 38.12, 7
    context.lineTo 38.12, 7
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
