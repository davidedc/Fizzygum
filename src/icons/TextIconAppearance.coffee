class TextIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    #// Group
    #// Group 2
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 40.05, 62.47
    context.lineTo 20.34, 62.47
    context.lineTo 18.36, 68.33
    context.lineTo 20.34, 68.33
    context.bezierCurveTo 22.29, 68.33, 23.69, 68.78, 24.52, 69.67
    context.bezierCurveTo 25.35, 70.56, 25.76, 71.73, 25.76, 73.17
    context.bezierCurveTo 25.76, 74.57, 25.35, 75.72, 24.52, 76.61
    context.bezierCurveTo 23.69, 77.5, 22.29, 77.95, 20.34, 77.95
    context.lineTo 9.42, 77.95
    context.bezierCurveTo 7.47, 77.95, 6.08, 77.5, 5.25, 76.61
    context.bezierCurveTo 4.42, 75.72, 4, 74.56, 4, 73.12
    context.bezierCurveTo 4, 71.68, 4.44, 70.51, 5.31, 69.6
    context.bezierCurveTo 6.18, 68.69, 7.61, 68.27, 9.62, 68.33
    context.lineTo 22.36, 30.71
    context.lineTo 17.06, 30.71
    context.bezierCurveTo 15.11, 30.71, 13.71, 30.27, 12.88, 29.38
    context.bezierCurveTo 12.05, 28.48, 11.64, 27.32, 11.64, 25.88
    context.bezierCurveTo 11.64, 24.44, 12.05, 23.28, 12.88, 22.39
    context.bezierCurveTo 13.71, 21.5, 15.11, 21.05, 17.06, 21.05
    context.lineTo 34.59, 21.1
    context.lineTo 50.73, 68.33
    context.bezierCurveTo 52.63, 68.33, 53.89, 68.58, 54.49, 69.08
    context.bezierCurveTo 55.71, 70.12, 56.31, 71.48, 56.31, 73.17
    context.bezierCurveTo 56.31, 74.57, 55.9, 75.72, 55.09, 76.61
    context.bezierCurveTo 54.27, 77.5, 52.88, 77.95, 50.93, 77.95
    context.lineTo 40.01, 77.95
    context.bezierCurveTo 38.06, 77.95, 36.67, 77.5, 35.83, 76.61
    context.bezierCurveTo 35, 75.72, 34.59, 74.56, 34.59, 73.12
    context.bezierCurveTo 34.59, 71.71, 35, 70.56, 35.83, 69.67
    context.bezierCurveTo 36.67, 68.78, 38.06, 68.33, 40.01, 68.33
    context.lineTo 41.99, 68.33
    context.lineTo 40.05, 62.47
    context.closePath()
    context.moveTo 36.69, 52.85
    context.lineTo 30.16, 33.81
    context.lineTo 23.59, 52.85
    context.lineTo 36.69, 52.85
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 82.89, 77.4
    context.lineTo 82.89, 75.21
    context.bezierCurveTo 80.97, 76.46, 80.85, 76.39, 78.53, 77.01
    context.bezierCurveTo 76.2, 77.64, 74.1, 77.95, 72.2, 77.95
    context.bezierCurveTo 68.08, 77.95, 64.74, 76.62, 62.17, 73.96
    context.bezierCurveTo 59.6, 71.3, 58.31, 68.35, 58.31, 65.13
    context.bezierCurveTo 58.31, 61.2, 59.95, 57.56, 63.23, 54.2
    context.bezierCurveTo 66.52, 50.84, 69.05, 50.16, 74.84, 50.16
    context.bezierCurveTo 77.16, 50.16, 79.84, 51.46, 82.89, 52.07
    context.lineTo 82.89, 49.83
    context.bezierCurveTo 82.89, 48.44, 82.4, 46.29, 81.41, 45.41
    context.bezierCurveTo 80.42, 44.53, 78.55, 43.09, 75.78, 43.09
    context.bezierCurveTo 73.51, 43.09, 70.56, 43.64, 66.94, 44.73
    context.bezierCurveTo 65.6, 45.13, 64.55, 45.32, 63.8, 45.32
    context.bezierCurveTo 62.78, 45.32, 61.91, 44.88, 61.2, 43.98
    context.bezierCurveTo 60.49, 43.08, 60.13, 41.93, 60.13, 40.53
    context.bezierCurveTo 60.13, 39.74, 60.26, 39.06, 60.5, 38.48
    context.bezierCurveTo 60.75, 37.9, 61.1, 37.44, 61.55, 37.09
    context.bezierCurveTo 62, 36.74, 62.94, 36.32, 64.36, 35.83
    context.bezierCurveTo 66.26, 35.2, 68.19, 34.69, 70.16, 34.31
    context.bezierCurveTo 72.13, 33.93, 73.92, 33.74, 75.51, 33.74
    context.bezierCurveTo 80.28, 33.74, 83.98, 35.99, 86.61, 38.5
    context.bezierCurveTo 89.25, 41.01, 90.56, 44.44, 90.56, 48.79
    context.lineTo 90.56, 68.04
    context.lineTo 91.87, 68.04
    context.bezierCurveTo 93.72, 68.04, 95.03, 68.48, 95.82, 69.34
    context.bezierCurveTo 96.61, 70.21, 97, 71.35, 97, 72.74
    context.bezierCurveTo 97, 74.11, 96.61, 75.23, 95.82, 76.1
    context.bezierCurveTo 95.03, 76.97, 93.72, 77.4, 91.87, 77.4
    context.lineTo 82.89, 77.4
    context.closePath()
    context.moveTo 82.89, 59.65
    context.bezierCurveTo 79.82, 58.92, 76.99, 57.56, 74.39, 57.56
    context.bezierCurveTo 71.27, 57.56, 70.59, 58.49, 68.34, 60.34
    context.bezierCurveTo 66.95, 61.53, 66.25, 63.73, 66.25, 64.95
    context.bezierCurveTo 66.25, 65.83, 67.58, 68.54, 68.26, 69.09
    context.bezierCurveTo 69.51, 70.09, 70.22, 70.6, 72.39, 70.6
    context.bezierCurveTo 74.23, 70.6, 76.32, 70.15, 78.66, 69.27
    context.bezierCurveTo 80.99, 68.39, 81.07, 68.19, 82.89, 66.67
    context.lineTo 82.89, 59.65
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()

