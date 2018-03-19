class DashboardsIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString

    #// Group 6
    #// outline Drawing
    context.beginPath()
    context.moveTo 87.54, 18
    context.lineTo 13.57, 18
    context.bezierCurveTo 10.05, 18, 7.12, 20.67, 7.12, 23.87
    context.lineTo 7, 76.13
    context.bezierCurveTo 7, 79.33, 9.94, 82, 13.46, 82
    context.lineTo 87.43, 82
    context.bezierCurveTo 90.95, 82, 93.88, 79.33, 93.88, 76.13
    context.lineTo 94, 23.87
    context.bezierCurveTo 94, 20.67, 91.06, 18, 87.54, 18
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// slide border Drawing
    context.beginPath()
    context.moveTo 85.84, 20
    context.lineTo 15.27, 20
    context.bezierCurveTo 11.91, 20, 9.11, 22.5, 9.11, 25.5
    context.lineTo 9, 74.5
    context.bezierCurveTo 9, 77.5, 11.8, 80, 15.16, 80
    context.lineTo 85.73, 80
    context.bezierCurveTo 89.09, 80, 91.89, 77.5, 91.89, 74.5
    context.lineTo 92, 25.5
    context.bezierCurveTo 92, 22.5, 89.2, 20, 85.84, 20
    context.closePath()
    context.moveTo 88.53, 74.5
    context.bezierCurveTo 88.53, 75.9, 87.3, 77, 85.73, 77
    context.lineTo 15.16, 77
    context.bezierCurveTo 13.59, 77, 12.36, 75.9, 12.36, 74.5
    context.lineTo 12.47, 25.5
    context.bezierCurveTo 12.47, 24.1, 13.7, 23, 15.27, 23
    context.lineTo 85.84, 23
    context.bezierCurveTo 87.41, 23, 88.64, 24.1, 88.64, 25.5
    context.lineTo 88.53, 74.5
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Group 7
    #// Group
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 22, 27
    context.lineTo 23.2, 27
    context.lineTo 23.2, 46.8
    context.lineTo 46, 46.8
    context.lineTo 46, 48
    context.lineTo 22, 48
    context.lineTo 22, 27
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Group 2
    #// Oval Drawing
    @oval context, 35, 30, 3, 3
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 2 Drawing
    @oval context, 27, 40, 3, 3
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 3 Drawing
    @oval context, 27, 29, 3, 3
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 10 Drawing
    @oval context, 31, 35, 3, 3
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 11 Drawing
    @oval context, 37, 35, 3, 3
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 12 Drawing
    @oval context, 43, 33, 3, 3
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 13 Drawing
    @oval context, 43, 28, 3, 3
    context.fillStyle = iconColorString
    context.fill()
    #// Group 5
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 56, 27
    context.lineTo 57.17, 27
    context.lineTo 57.17, 46.8
    context.lineTo 79.41, 46.8
    context.lineTo 79.41, 48
    context.lineTo 56, 48
    context.lineTo 56, 27
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Bezier 2 Drawing
    context.save()
    context.translate 60.06, 23.23
    context.beginPath()
    context.moveTo 1.4, 20.37
    context.lineTo 0, 19.37
    context.lineTo 3.13, 13.52
    context.bezierCurveTo 4.45, 10.81, 5.8, 9.61, 7.17, 9.91
    context.bezierCurveTo 8.06, 10.11, 11.22, 15.04, 12.2, 13.83
    context.bezierCurveTo 12.63, 13.77, 17.52, 4, 17.52, 4
    context.lineTo 18.94, 4.89
    context.bezierCurveTo 18.94, 4.89, 14.09, 14.19, 13.71, 14.8
    context.bezierCurveTo 13.25, 15.39, 12.76, 15.74, 12.09, 15.71
    context.bezierCurveTo 11.32, 15.77, 10.62, 15.52, 9.55, 14.58
    context.bezierCurveTo 8.49, 13.64, 7.55, 12.27, 6.63, 12.1
    context.bezierCurveTo 5.71, 11.93, 4.97, 13.58, 4.44, 14.5
    context.lineTo 1.4, 20.37
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    context.restore()
    #// Group 3
    #// Rectangle 3 Drawing
    context.beginPath()
    context.rect 43, 55, 3, 15
    context.fillStyle = iconColorString
    context.fill()
    #// Rectangle 4 Drawing
    context.beginPath()
    context.rect 37, 63, 4, 7
    context.fillStyle = iconColorString
    context.fill()
    #// Rectangle 5 Drawing
    context.beginPath()
    context.rect 32, 65, 3, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Rectangle 6 Drawing
    context.beginPath()
    context.rect 26, 63, 4, 7
    context.fillStyle = iconColorString
    context.fill()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 22, 53
    context.lineTo 23.2, 53
    context.lineTo 23.2, 72.8
    context.lineTo 46, 72.8
    context.lineTo 46, 74
    context.lineTo 22, 74
    context.lineTo 22, 53
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Group 4
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 69.37, 64.35
    context.lineTo 69.37, 57.47
    context.bezierCurveTo 69.37, 57.26, 69.2, 57.1, 69, 57.1
    context.bezierCurveTo 68.8, 57.1, 68.63, 57.26, 68.63, 57.47
    context.lineTo 68.63, 64.36
    context.lineTo 62.18, 69.09
    context.bezierCurveTo 62.02, 69.21, 61.98, 69.44, 62.1, 69.61
    context.bezierCurveTo 62.22, 69.78, 62.45, 69.82, 62.62, 69.7
    context.lineTo 69.01, 65.01
    context.lineTo 75.76, 69.7
    context.bezierCurveTo 75.82, 69.74, 75.89, 69.76, 75.97, 69.76
    context.bezierCurveTo 76.09, 69.76, 76.2, 69.71, 76.27, 69.6
    context.bezierCurveTo 76.39, 69.43, 76.35, 69.2, 76.18, 69.08
    context.lineTo 69.37, 64.35
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 68.63, 54.64
    context.lineTo 68.63, 55.61
    context.bezierCurveTo 68.63, 55.81, 68.8, 55.98, 69, 55.98
    context.bezierCurveTo 69.2, 55.98, 69.37, 55.81, 69.37, 55.61
    context.lineTo 69.37, 54.64
    context.lineTo 70.36, 53.63
    context.bezierCurveTo 70.5, 53.49, 70.5, 53.25, 70.36, 53.11
    context.bezierCurveTo 70.22, 52.96, 69.99, 52.96, 69.84, 53.11
    context.lineTo 69, 53.96
    context.lineTo 68.16, 53.11
    context.bezierCurveTo 68.02, 52.96, 67.79, 52.96, 67.64, 53.11
    context.bezierCurveTo 67.5, 53.26, 67.5, 53.49, 67.64, 53.64
    context.lineTo 68.63, 54.64
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 79.05, 70.51
    context.lineTo 79.89, 69.66
    context.bezierCurveTo 80.03, 69.51, 80.03, 69.28, 79.89, 69.13
    context.bezierCurveTo 79.75, 68.99, 79.52, 68.99, 79.37, 69.13
    context.lineTo 78.53, 69.98
    context.lineTo 77.7, 69.13
    context.bezierCurveTo 77.55, 68.99, 77.32, 68.99, 77.18, 69.13
    context.bezierCurveTo 77.04, 69.28, 77.04, 69.51, 77.18, 69.66
    context.lineTo 78.02, 70.51
    context.lineTo 77.18, 71.36
    context.bezierCurveTo 77.04, 71.51, 77.04, 71.74, 77.18, 71.89
    context.bezierCurveTo 77.25, 71.96, 77.34, 72, 77.43, 72
    context.bezierCurveTo 77.53, 72, 77.62, 71.96, 77.7, 71.89
    context.lineTo 78.53, 71.04
    context.lineTo 79.37, 71.89
    context.bezierCurveTo 79.45, 71.96, 79.54, 72, 79.63, 72
    context.bezierCurveTo 79.73, 72, 79.82, 71.96, 79.9, 71.89
    context.bezierCurveTo 80.04, 71.75, 80.04, 71.51, 79.9, 71.37
    context.lineTo 79.05, 70.51
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 60.9, 69.53
    context.bezierCurveTo 60.94, 69.44, 60.94, 69.34, 60.9, 69.25
    context.bezierCurveTo 60.87, 69.16, 60.79, 69.09, 60.71, 69.05
    context.bezierCurveTo 60.66, 69.03, 60.61, 69.02, 60.57, 69.02
    context.lineTo 58.37, 69.02
    context.bezierCurveTo 58.17, 69.02, 58, 69.19, 58, 69.39
    context.bezierCurveTo 58, 69.6, 58.17, 69.76, 58.37, 69.76
    context.lineTo 59.68, 69.76
    context.lineTo 58.11, 71.36
    context.bezierCurveTo 58.08, 71.4, 58.05, 71.44, 58.03, 71.49
    context.bezierCurveTo 57.99, 71.58, 57.99, 71.68, 58.03, 71.77
    context.bezierCurveTo 58.07, 71.86, 58.14, 71.93, 58.23, 71.97
    context.bezierCurveTo 58.27, 71.99, 58.32, 72, 58.37, 72
    context.lineTo 60.57, 72
    context.bezierCurveTo 60.77, 72, 60.93, 71.83, 60.93, 71.63
    context.bezierCurveTo 60.93, 71.42, 60.77, 71.25, 60.57, 71.25
    context.lineTo 59.25, 71.25
    context.lineTo 60.82, 69.66
    context.bezierCurveTo 60.86, 69.62, 60.89, 69.58, 60.9, 69.53
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
