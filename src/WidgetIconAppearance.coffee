class WidgetIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    # Color Declarations
    blackColorString = 'rgba(0, 0, 0, 1)'
    outlineColorString = 'rgba(184, 184, 184, 1)'
    # outline Drawing
    context.beginPath()
    context.moveTo 75.84, 2.66
    context.bezierCurveTo 76.24, 3.42, 86.61, 23.22, 86.61, 23.22
    context.lineTo 97.42, 43.78
    context.bezierCurveTo 97.71, 44.33, 97.86, 44.94, 97.86, 45.57
    context.bezierCurveTo 97.86, 47.55, 96.4, 49.15, 94.61, 49.16
    context.bezierCurveTo 94.61, 49.16, 89.27, 49.16, 83.91, 49.16
    context.bezierCurveTo 91.29, 50.22, 97, 56.61, 97, 64.27
    context.lineTo 97, 81.73
    context.bezierCurveTo 97, 90.13, 90.13, 97, 81.73, 97
    context.lineTo 64.27, 97
    context.bezierCurveTo 56.14, 97, 49.44, 90.56, 49.02, 82.53
    context.bezierCurveTo 45.32, 91.03, 36.83, 97, 27, 97
    context.bezierCurveTo 13.78, 97, 3, 86.22, 3, 73
    context.bezierCurveTo 3, 63.17, 8.97, 54.68, 17.47, 50.98
    context.bezierCurveTo 9.44, 50.56, 3, 43.86, 3, 35.73
    context.lineTo 3, 18.27
    context.bezierCurveTo 3, 9.87, 9.87, 3, 18.27, 3
    context.lineTo 35.73, 3
    context.bezierCurveTo 44.13, 3, 51, 9.87, 51, 18.27
    context.lineTo 51, 35.73
    context.bezierCurveTo 51, 37.54, 50.68, 39.28, 50.1, 40.89
    context.bezierCurveTo 53.07, 35.24, 59.39, 23.22, 59.39, 23.22
    context.lineTo 70.15, 2.69
    context.lineTo 70.22, 2.54
    context.bezierCurveTo 70.78, 1.55, 71.75, 0.91, 72.82, 0.84
    context.bezierCurveTo 74.07, 0.77, 75.24, 1.48, 75.84, 2.66
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    # shapes Drawing
    context.beginPath()
    context.moveTo 72.84, 4.84
    context.lineTo 72.85, 4.84
    context.bezierCurveTo 71.86, 4.9, 70.97, 5.51, 70.49, 6.46
    context.lineTo 61.03, 24.44
    context.lineTo 51.53, 42.44
    context.lineTo 51.53, 42.45
    context.bezierCurveTo 50.73, 43.95, 51.2, 45.87, 52.58, 46.74
    context.bezierCurveTo 53.01, 47.01, 53.51, 47.16, 54.01, 47.16
    context.lineTo 73, 47.16
    context.lineTo 92, 47.16
    context.lineTo 91.99, 47.16
    context.bezierCurveTo 93.57, 47.16, 94.86, 45.75, 94.86, 44.02
    context.bezierCurveTo 94.86, 43.47, 94.73, 42.93, 94.47, 42.45
    context.lineTo 84.97, 24.44
    context.lineTo 75.5, 6.44
    context.lineTo 75.51, 6.46
    context.bezierCurveTo 74.98, 5.41, 73.95, 4.78, 72.85, 4.84
    context.lineTo 72.84, 4.84
    context.closePath()
    context.moveTo 19, 5
    context.bezierCurveTo 11.3, 5, 5, 11.3, 5, 19
    context.lineTo 5, 35
    context.bezierCurveTo 5, 42.7, 11.3, 49, 19, 49
    context.lineTo 35, 49
    context.bezierCurveTo 42.7, 49, 49, 42.7, 49, 35
    context.lineTo 49, 19
    context.bezierCurveTo 49, 11.3, 42.7, 5, 35, 5
    context.lineTo 19, 5
    context.closePath()
    context.moveTo 19, 11
    context.lineTo 35, 11
    context.bezierCurveTo 39.48, 11, 43, 14.52, 43, 19
    context.lineTo 43, 35
    context.bezierCurveTo 43, 39.48, 39.48, 43, 35, 43
    context.lineTo 19, 43
    context.bezierCurveTo 14.52, 43, 11, 39.48, 11, 35
    context.lineTo 11, 19
    context.bezierCurveTo 11, 14.52, 14.52, 11, 19, 11
    context.closePath()
    context.moveTo 73, 14.28
    context.lineTo 80.03, 27.56
    context.lineTo 87, 40.84
    context.lineTo 73, 40.84
    context.lineTo 59, 40.84
    context.lineTo 65.97, 27.56
    context.lineTo 73, 14.28
    context.closePath()
    context.moveTo 27, 51
    context.bezierCurveTo 14.89, 51, 5, 60.89, 5, 73
    context.bezierCurveTo 5, 85.11, 14.89, 95, 27, 95
    context.bezierCurveTo 39.11, 95, 49, 85.11, 49, 73
    context.bezierCurveTo 49, 60.89, 39.11, 51, 27, 51
    context.closePath()
    context.moveTo 65, 51
    context.bezierCurveTo 57.3, 51, 51, 57.3, 51, 65
    context.lineTo 51, 81
    context.bezierCurveTo 51, 88.7, 57.3, 95, 65, 95
    context.lineTo 81, 95
    context.bezierCurveTo 88.7, 95, 95, 88.7, 95, 81
    context.lineTo 95, 65
    context.bezierCurveTo 95, 57.3, 88.7, 51, 81, 51
    context.lineTo 65, 51
    context.closePath()
    context.moveTo 27, 57
    context.bezierCurveTo 35.87, 57, 43, 64.13, 43, 73
    context.bezierCurveTo 43, 81.87, 35.87, 89, 27, 89
    context.bezierCurveTo 18.13, 89, 11, 81.87, 11, 73
    context.bezierCurveTo 11, 64.13, 18.13, 57, 27, 57
    context.closePath()
    context.moveTo 65, 57
    context.lineTo 81, 57
    context.bezierCurveTo 85.48, 57, 89, 60.52, 89, 65
    context.lineTo 89, 81
    context.bezierCurveTo 89, 85.48, 85.48, 89, 81, 89
    context.lineTo 65, 89
    context.bezierCurveTo 60.52, 89, 57, 85.48, 57, 81
    context.lineTo 57, 65
    context.bezierCurveTo 57, 60.52, 60.52, 57, 65, 57
    context.closePath()
    context.fillStyle = blackColorString
    context.fill()
