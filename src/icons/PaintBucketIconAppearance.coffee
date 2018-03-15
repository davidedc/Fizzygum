class PaintBucketIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    # Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    # Bezier 2 Drawing
    context.beginPath()
    context.moveTo 82.94, 30.28
    context.lineTo 82.94, 22.75
    context.bezierCurveTo 82.94, 22.54, 82.94, 22.34, 82.94, 22.23
    context.bezierCurveTo 82.94, 14.29, 66.23, 10, 50.47, 10
    context.bezierCurveTo 34.71, 10, 18, 14.29, 18, 22.23
    context.bezierCurveTo 18, 22.44, 18, 22.65, 18, 22.75
    context.lineTo 18, 80.46
    context.bezierCurveTo 18, 80.56, 18, 80.66, 18, 80.77
    context.bezierCurveTo 18, 88.71, 34.71, 93, 50.47, 93
    context.bezierCurveTo 66.23, 93, 82.94, 88.71, 82.94, 80.77
    context.bezierCurveTo 82.94, 80.66, 82.94, 80.56, 82.94, 80.46
    context.lineTo 82.94, 71.94
    context.bezierCurveTo 84.74, 72.36, 86.33, 72.57, 87.81, 72.57
    context.bezierCurveTo 90.98, 72.57, 93.52, 70.73, 95.32, 68.96
    context.bezierCurveTo 101.56, 62.79, 96.69, 47.63, 82.94, 30.28
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    # bucket Drawing
    context.beginPath()
    context.moveTo 80.88, 31.06
    context.lineTo 80.88, 23.98
    context.bezierCurveTo 80.88, 23.79, 80.88, 23.59, 80.88, 23.49
    context.bezierCurveTo 80.88, 16.03, 65.22, 12, 50.44, 12
    context.bezierCurveTo 35.67, 12, 20, 16.03, 20, 23.49
    context.bezierCurveTo 20, 23.69, 20, 23.89, 20, 23.98
    context.lineTo 20, 78.21
    context.bezierCurveTo 20, 78.31, 20, 78.41, 20, 78.51
    context.bezierCurveTo 20, 85.97, 35.67, 90, 50.44, 90
    context.bezierCurveTo 65.22, 90, 80.88, 85.97, 80.88, 78.51
    context.bezierCurveTo 80.88, 78.41, 80.88, 78.31, 80.88, 78.21
    context.lineTo 80.88, 69.27
    context.bezierCurveTo 82.57, 69.66, 84.06, 69.86, 85.45, 69.86
    context.bezierCurveTo 88.42, 69.86, 90.8, 69.08, 92.49, 67.41
    context.bezierCurveTo 98.34, 61.61, 93.78, 47.37, 80.88, 31.06
    context.closePath()
    context.moveTo 30.61, 17.8
    context.bezierCurveTo 35.87, 15.93, 43.01, 14.95, 50.54, 14.95
    context.bezierCurveTo 58.08, 14.95, 65.12, 15.93, 70.47, 17.8
    context.bezierCurveTo 74.84, 19.27, 77.61, 21.23, 77.91, 23.1
    context.lineTo 77.91, 23.1
    context.lineTo 77.91, 23.69
    context.bezierCurveTo 77.61, 25.46, 75.13, 27.32, 70.97, 28.8
    context.bezierCurveTo 65.51, 26.93, 58.18, 25.95, 50.54, 25.95
    context.bezierCurveTo 42.81, 25.95, 35.67, 26.93, 30.11, 28.8
    context.bezierCurveTo 28.23, 28.11, 26.74, 27.32, 25.55, 26.54
    context.lineTo 25.55, 26.54
    context.bezierCurveTo 24.56, 25.85, 23.47, 24.87, 23.27, 23.69
    context.lineTo 23.27, 23.1
    context.lineTo 23.27, 23.1
    context.bezierCurveTo 23.47, 21.33, 26.25, 19.37, 30.61, 17.8
    context.closePath()
    context.moveTo 37.15, 42.16
    context.bezierCurveTo 37.15, 40.78, 35.37, 39.21, 33.19, 39.21
    context.bezierCurveTo 30.91, 39.21, 30.02, 40.98, 29.92, 42.16
    context.lineTo 29.92, 60.92
    context.bezierCurveTo 29.92, 62.89, 29.32, 62.89, 28.92, 62.89
    context.bezierCurveTo 28.63, 62.89, 27.73, 62.89, 27.73, 60.92
    context.lineTo 27.73, 31.16
    context.bezierCurveTo 30.71, 32.34, 34.38, 33.32, 38.44, 33.91
    context.bezierCurveTo 38.25, 34.5, 38.25, 35.09, 38.25, 35.18
    context.lineTo 38.25, 49.53
    context.bezierCurveTo 38.25, 49.82, 37.95, 50.12, 37.65, 50.12
    context.bezierCurveTo 37.35, 50.12, 37.06, 49.82, 37.06, 49.53
    context.lineTo 37.15, 42.16
    context.lineTo 37.15, 42.16
    context.closePath()
    context.moveTo 42.41, 31.45
    context.bezierCurveTo 38.84, 31.06, 35.47, 30.47, 32.69, 29.68
    context.bezierCurveTo 37.75, 28.31, 44, 27.52, 50.54, 27.52
    context.bezierCurveTo 57.09, 27.52, 63.33, 28.31, 68.39, 29.68
    context.bezierCurveTo 63.43, 31.06, 57.19, 31.84, 50.54, 31.84
    context.bezierCurveTo 47.76, 31.84, 45.09, 31.65, 42.41, 31.45
    context.closePath()
    context.moveTo 77.81, 76.35
    context.bezierCurveTo 76.62, 77.92, 74.04, 79.49, 70.37, 80.67
    context.bezierCurveTo 69.98, 80.77, 69.78, 81.26, 69.88, 81.65
    context.bezierCurveTo 69.98, 81.94, 70.27, 82.14, 70.57, 82.14
    context.bezierCurveTo 70.67, 82.14, 70.77, 82.14, 70.77, 82.14
    context.bezierCurveTo 73.74, 81.16, 76.12, 79.88, 77.71, 78.6
    context.lineTo 77.71, 78.7
    context.bezierCurveTo 77.61, 80.57, 74.84, 82.53, 70.27, 84.11
    context.bezierCurveTo 65.02, 85.97, 57.88, 86.95, 50.34, 86.95
    context.bezierCurveTo 42.81, 86.95, 35.77, 85.97, 30.41, 84.11
    context.bezierCurveTo 25.85, 82.53, 23.17, 80.57, 22.97, 78.7
    context.bezierCurveTo 22.97, 78.6, 22.97, 78.6, 22.97, 78.51
    context.bezierCurveTo 27.44, 82.34, 37.85, 84.99, 50.24, 84.99
    context.bezierCurveTo 51.14, 84.99, 52.13, 84.99, 53.02, 84.99
    context.bezierCurveTo 53.42, 84.99, 53.81, 84.6, 53.81, 84.2
    context.bezierCurveTo 53.81, 83.81, 53.42, 83.42, 53.02, 83.42
    context.bezierCurveTo 52.13, 83.42, 51.24, 83.42, 50.34, 83.42
    context.bezierCurveTo 36.16, 83.42, 25.95, 80.08, 23.07, 76.35
    context.lineTo 23.07, 28.7
    context.bezierCurveTo 23.07, 28.7, 23.17, 28.7, 23.17, 28.8
    context.bezierCurveTo 23.27, 28.9, 23.37, 28.99, 23.47, 29.09
    context.bezierCurveTo 23.97, 29.49, 24.66, 30.27, 24.66, 30.76
    context.lineTo 24.66, 61.02
    context.bezierCurveTo 24.66, 64.07, 26.35, 66.03, 28.92, 66.03
    context.bezierCurveTo 30.11, 66.03, 32.99, 65.54, 32.99, 61.02
    context.lineTo 32.99, 42.36
    context.bezierCurveTo 32.99, 42.36, 33.09, 42.36, 33.19, 42.36
    context.bezierCurveTo 33.58, 42.36, 33.88, 42.55, 34.08, 42.65
    context.lineTo 34.08, 49.62
    context.bezierCurveTo 34.08, 51.59, 35.77, 53.26, 37.75, 53.26
    context.bezierCurveTo 39.73, 53.26, 41.42, 51.59, 41.42, 49.62
    context.lineTo 41.42, 35.28
    context.bezierCurveTo 41.42, 35.09, 41.52, 34.69, 41.72, 34.5
    context.bezierCurveTo 41.82, 34.4, 42.01, 34.4, 42.21, 34.4
    context.lineTo 42.21, 34.4
    context.bezierCurveTo 44.89, 34.69, 47.76, 34.79, 50.54, 34.79
    context.bezierCurveTo 61.25, 34.79, 72.55, 32.63, 77.81, 28.6
    context.lineTo 77.81, 65.05
    context.bezierCurveTo 76.42, 64.56, 74.84, 63.87, 73.25, 63.18
    context.bezierCurveTo 64.52, 58.96, 54.71, 51.69, 45.48, 42.55
    context.bezierCurveTo 44.89, 41.96, 43.9, 41.96, 43.3, 42.55
    context.bezierCurveTo 42.71, 43.14, 42.71, 44.12, 43.3, 44.71
    context.bezierCurveTo 52.72, 54.05, 62.94, 61.61, 71.96, 65.93
    context.bezierCurveTo 74.04, 66.91, 76.03, 67.7, 77.81, 68.29
    context.lineTo 77.81, 76.35
    context.closePath()
    context.moveTo 90.3, 65.15
    context.bezierCurveTo 88.52, 66.91, 85.25, 67.21, 80.88, 66.13
    context.lineTo 80.88, 36.17
    context.bezierCurveTo 85.35, 42.26, 88.62, 48.15, 90.4, 53.16
    context.bezierCurveTo 92.49, 58.86, 92.39, 63.08, 90.3, 65.15
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
