class Plot3DIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// Group
    #// axes Drawing
    context.beginPath()
    context.moveTo 50.98, 58.41
    context.lineTo 50.98, 30.88
    context.bezierCurveTo 50.98, 30.06, 50.32, 29.39, 49.5, 29.39
    context.bezierCurveTo 48.68, 29.39, 48.02, 30.06, 48.02, 30.88
    context.lineTo 48.02, 58.44
    context.lineTo 21.92, 77.36
    context.bezierCurveTo 21.26, 77.84, 21.11, 78.78, 21.6, 79.45
    context.bezierCurveTo 22.07, 80.12, 23.01, 80.27, 23.67, 79.79
    context.lineTo 49.53, 61.03
    context.lineTo 76.85, 79.81
    context.bezierCurveTo 77.1, 79.97, 77.39, 80.06, 77.68, 80.06
    context.bezierCurveTo 78.16, 80.06, 78.62, 79.84, 78.91, 79.4
    context.bezierCurveTo 79.37, 78.72, 79.21, 77.79, 78.53, 77.33
    context.lineTo 50.98, 58.41
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// letter y Drawing
    context.beginPath()
    context.moveTo 48.02, 19.57
    context.lineTo 48.02, 23.43
    context.bezierCurveTo 48.02, 24.25, 48.68, 24.92, 49.5, 24.92
    context.bezierCurveTo 50.32, 24.92, 50.98, 24.25, 50.98, 23.43
    context.lineTo 50.98, 19.57
    context.lineTo 55, 15.53
    context.bezierCurveTo 55.58, 14.95, 55.58, 14.01, 55, 13.43
    context.bezierCurveTo 54.42, 12.85, 53.49, 12.85, 52.91, 13.43
    context.lineTo 49.5, 16.86
    context.lineTo 46.1, 13.45
    context.bezierCurveTo 45.52, 12.87, 44.59, 12.87, 44.01, 13.45
    context.bezierCurveTo 43.43, 14.03, 43.43, 14.97, 44.01, 15.55
    context.lineTo 48.02, 19.57
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// letter x Drawing
    context.beginPath()
    context.moveTo 90.16, 83.04
    context.lineTo 93.55, 79.63
    context.bezierCurveTo 94.13, 79.05, 94.13, 78.11, 93.55, 77.53
    context.bezierCurveTo 92.98, 76.94, 92.04, 76.94, 91.46, 77.53
    context.lineTo 88.07, 80.94
    context.lineTo 84.67, 77.53
    context.bezierCurveTo 84.09, 76.94, 83.16, 76.94, 82.58, 77.53
    context.bezierCurveTo 82, 78.11, 82, 79.05, 82.58, 79.63
    context.lineTo 85.97, 83.04
    context.lineTo 82.58, 86.45
    context.bezierCurveTo 82, 87.03, 82, 87.97, 82.58, 88.55
    context.bezierCurveTo 82.86, 88.85, 83.23, 89, 83.62, 89
    context.bezierCurveTo 84, 89, 84.37, 88.85, 84.67, 88.57
    context.lineTo 88.07, 85.14
    context.lineTo 91.46, 88.55
    context.bezierCurveTo 91.76, 88.85, 92.13, 89, 92.52, 89
    context.bezierCurveTo 92.9, 89, 93.27, 88.85, 93.57, 88.57
    context.bezierCurveTo 94.15, 87.99, 94.15, 87.05, 93.57, 86.47
    context.lineTo 90.16, 83.04
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// letter z Drawing
    context.beginPath()
    context.moveTo 16.75, 79.14
    context.bezierCurveTo 16.9, 78.78, 16.9, 78.36, 16.75, 78
    context.bezierCurveTo 16.6, 77.64, 16.3, 77.35, 15.95, 77.2
    context.bezierCurveTo 15.77, 77.12, 15.58, 77.08, 15.38, 77.08
    context.lineTo 6.48, 77.08
    context.bezierCurveTo 5.67, 77.08, 5, 77.75, 5, 78.57
    context.bezierCurveTo 5, 79.39, 5.67, 80.06, 6.48, 80.06
    context.lineTo 11.81, 80.06
    context.lineTo 5.44, 86.45
    context.bezierCurveTo 5.31, 86.59, 5.19, 86.75, 5.12, 86.94
    context.bezierCurveTo 4.97, 87.3, 4.97, 87.72, 5.12, 88.08
    context.bezierCurveTo 5.27, 88.43, 5.56, 88.73, 5.92, 88.88
    context.bezierCurveTo 6.1, 88.96, 6.29, 89, 6.48, 89
    context.lineTo 15.38, 89
    context.bezierCurveTo 16.2, 89, 16.87, 88.33, 16.87, 87.51
    context.bezierCurveTo 16.87, 86.69, 16.2, 86.02, 15.38, 86.02
    context.lineTo 10.06, 86.02
    context.lineTo 16.42, 79.63
    context.bezierCurveTo 16.57, 79.49, 16.67, 79.31, 16.75, 79.14
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
