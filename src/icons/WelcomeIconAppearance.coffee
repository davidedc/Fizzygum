class WelcomeIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    #// outline
    #// body and hat outline Drawing
    context.beginPath()
    context.moveTo 97.26, 70.79
    context.bezierCurveTo 97.19, 70.22, 82.93, 34.78, 82.93, 34.78
    context.lineTo 81.81, 33.52
    context.bezierCurveTo 81.67, 31.89, 80.85, 30.39, 79.54, 29.37
    context.lineTo 77.74, 24.85
    context.bezierCurveTo 76.55, 21.85, 75.44, 20.19, 74.35, 19.78
    context.bezierCurveTo 73.84, 19.59, 69.87, 21.34, 69.76, 21.44
    context.lineTo 69.36, 20.02
    context.bezierCurveTo 69.4, 19.91, 70.16, 17.4, 69.66, 14.48
    context.bezierCurveTo 69.19, 11.74, 66.5, 8.12, 61.07, 6.49
    context.bezierCurveTo 61.07, 6.49, 50.53, 3.33, 47.56, 3.82
    context.bezierCurveTo 44.78, 4.28, 41.11, 5.95, 39.45, 11.3
    context.lineTo 37.34, 18.09
    context.lineTo 34.31, 17.18
    context.bezierCurveTo 33.35, 16.89, 31.73, 17.09, 31.2, 18.81
    context.bezierCurveTo 31.2, 18.81, 29.54, 23.97, 29.64, 24.6
    context.bezierCurveTo 29.8, 25.5, 30.41, 26.16, 31.37, 26.44
    context.lineTo 62.16, 36.71
    context.bezierCurveTo 61.96, 37, 61.7, 38.23, 61.7, 38.23
    context.bezierCurveTo 61.68, 38.32, 68.27, 39.64, 69.68, 39.9
    context.lineTo 67.21, 41.42
    context.lineTo 75.41, 63.47
    context.lineTo 53.54, 63.47
    context.lineTo 46.44, 72.61
    context.lineTo 39.34, 63.47
    context.lineTo 30.44, 63.62
    context.bezierCurveTo 30.11, 63.68, 23.97, 65.61, 22.33, 67.01
    context.bezierCurveTo 20.81, 68.31, 19, 73.62, 19, 77.34
    context.lineTo 19, 95.28
    context.lineTo 74.87, 95.28
    context.lineTo 74.87, 79.19
    context.bezierCurveTo 74.87, 79.19, 90.58, 79.14, 90.65, 79.13
    context.bezierCurveTo 92.66, 78.89, 94.46, 77.89, 95.71, 76.31
    context.bezierCurveTo 96.96, 74.74, 97.51, 72.77, 97.26, 70.79
    context.closePath()
    context.moveTo 69.38, 32.39
    context.lineTo 68.73, 32.3
    context.lineTo 69.43, 29.94
    context.bezierCurveTo 69.43, 29.94, 70.59, 30.51, 70.62, 30.59
    context.bezierCurveTo 70.63, 30.61, 69.47, 32.37, 69.38, 32.39
    context.closePath()
    context.strokeStyle = outlineColorString
    context.lineWidth = 3.5
    context.miterLimit = 4
    context.stroke()
    #// head outline Drawing
    @oval context, 32, 31, 31, 35
    context.strokeStyle = outlineColorString
    context.lineWidth = 3.5
    context.stroke()
    #// foreground
    #// body and hat Drawing
    context.beginPath()
    context.moveTo 94.27, 69.39
    context.bezierCurveTo 94.2, 68.86, 81.04, 35.74, 81.04, 35.74
    context.lineTo 80, 34.57
    context.bezierCurveTo 79.87, 33.04, 79.11, 31.64, 77.9, 30.69
    context.lineTo 76.24, 26.46
    context.bezierCurveTo 75.14, 23.66, 74.11, 22.11, 73.11, 21.73
    context.bezierCurveTo 72.64, 21.55, 71.45, 22.1, 71.45, 22.1
    context.bezierCurveTo 70.95, 22.35, 70.75, 22.82, 70.79, 23.26
    context.bezierCurveTo 70.41, 23.06, 70.07, 22.96, 69.75, 22.96
    context.bezierCurveTo 69.25, 22.95, 68.97, 23.18, 68.87, 23.28
    context.bezierCurveTo 68.87, 23.28, 67.83, 25.12, 68.15, 25.54
    context.lineTo 68.92, 26.53
    context.bezierCurveTo 67.79, 26.19, 66.89, 26.13, 66.24, 26.36
    context.lineTo 67.59, 21.94
    context.bezierCurveTo 67.62, 21.84, 68.33, 19.5, 67.87, 16.77
    context.bezierCurveTo 67.43, 14.21, 65.86, 10.83, 60.85, 9.3
    context.bezierCurveTo 60.85, 9.3, 51.11, 6.35, 48.38, 6.81
    context.bezierCurveTo 45.8, 7.24, 42.41, 8.8, 40.88, 13.8
    context.lineTo 38.93, 20.15
    context.lineTo 36.14, 19.29
    context.bezierCurveTo 35.25, 19.02, 33.76, 19.21, 33.26, 20.82
    context.bezierCurveTo 33.26, 20.82, 32.64, 22.87, 32.74, 23.45
    context.bezierCurveTo 32.88, 24.3, 33.45, 24.91, 34.33, 25.18
    context.lineTo 62.77, 33.85
    context.bezierCurveTo 62.58, 34.12, 62.34, 35.27, 62.34, 35.27
    context.bezierCurveTo 62.32, 35.36, 62.27, 35.82, 62.45, 36.35
    context.bezierCurveTo 62.71, 37.12, 63.33, 37.61, 64.2, 37.73
    context.lineTo 70.07, 38.55
    context.bezierCurveTo 70.91, 39.59, 72.05, 40.28, 73.35, 40.53
    context.lineTo 71.08, 41.95
    context.lineTo 79.56, 65.33
    context.lineTo 53.9, 65.33
    context.lineTo 47.34, 73.87
    context.lineTo 40.78, 65.33
    context.lineTo 32.56, 65.46
    context.bezierCurveTo 32.26, 65.52, 26.59, 67.32, 25.08, 68.63
    context.bezierCurveTo 23.67, 69.85, 22, 72.04, 22, 75.52
    context.lineTo 22, 92.28
    context.lineTo 72.68, 92.28
    context.lineTo 72.68, 77.24
    context.bezierCurveTo 72.68, 77.24, 88.09, 77.2, 88.16, 77.19
    context.bezierCurveTo 90.02, 76.96, 91.68, 76.02, 92.83, 74.55
    context.bezierCurveTo 93.99, 73.08, 94.5, 71.25, 94.27, 69.39
    context.closePath()
    context.moveTo 68.52, 33.51
    context.lineTo 67.92, 33.42
    context.lineTo 68.56, 31.22
    context.bezierCurveTo 68.56, 31.22, 69.63, 31.76, 69.66, 31.83
    context.bezierCurveTo 69.67, 31.85, 68.61, 33.49, 68.52, 33.51
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.miterLimit = 4
    context.stroke()
    #// head Drawing
    @oval context, 35, 34, 26, 29
    context.fillStyle = outlineColorString
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.stroke()


