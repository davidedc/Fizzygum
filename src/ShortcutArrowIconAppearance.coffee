class ShortcutArrowIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    # Color Declarations
    widgetColor = @morph.color
    outlineColorString = 'rgba(184, 184, 184, 1)'
    # Group 4
    # outline Drawing
    context.beginPath()
    context.moveTo 81.16, 4
    context.lineTo 19.84, 4
    context.lineTo 19.84, 4
    context.bezierCurveTo 11.09, 4, 4, 11.09, 4, 19.84
    context.lineTo 4, 81.16
    context.lineTo 4, 81.16
    context.bezierCurveTo 4, 89.91, 11.09, 97, 19.84, 97
    context.lineTo 81.16, 97
    context.lineTo 81.16, 97
    context.bezierCurveTo 89.91, 97, 97, 89.91, 97, 81.16
    context.lineTo 97, 19.84
    context.lineTo 97, 19.84
    context.bezierCurveTo 97, 11.09, 89.91, 4, 81.16, 4
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    # enclosing rect Drawing
    context.beginPath()
    context.moveTo 78.82, 7.72
    context.lineTo 22.83, 7.72
    context.lineTo 22.83, 7.72
    context.bezierCurveTo 14.84, 7.72, 8.37, 14.19, 8.37, 22.18
    context.lineTo 8.37, 78.17
    context.lineTo 8.37, 78.17
    context.bezierCurveTo 8.37, 86.16, 14.84, 92.63, 22.83, 92.63
    context.lineTo 78.82, 92.63
    context.lineTo 78.82, 92.63
    context.bezierCurveTo 86.81, 92.63, 93.28, 86.16, 93.28, 78.17
    context.lineTo 93.28, 22.18
    context.lineTo 93.28, 22.18
    context.bezierCurveTo 93.28, 14.19, 86.81, 7.72, 78.82, 7.72
    context.closePath()
    context.moveTo 85.39, 78.17
    context.lineTo 85.39, 78.17
    context.bezierCurveTo 85.39, 81.8, 82.45, 84.74, 78.82, 84.74
    context.lineTo 22.83, 84.74
    context.lineTo 22.83, 84.74
    context.bezierCurveTo 19.2, 84.74, 16.26, 81.8, 16.26, 78.17
    context.lineTo 16.26, 22.18
    context.lineTo 16.26, 22.18
    context.bezierCurveTo 16.26, 18.55, 19.2, 15.61, 22.83, 15.61
    context.lineTo 78.82, 15.61
    context.lineTo 78.82, 15.61
    context.bezierCurveTo 82.45, 15.61, 85.39, 18.55, 85.39, 22.18
    context.lineTo 85.39, 78.17
    context.closePath()
    context.fillStyle = widgetColor
    context.fill()
    # the arrow Drawing
    context.beginPath()
    context.moveTo 57.22, 52.5
    context.bezierCurveTo 59.32, 57.3, 61.42, 62.16, 63.58, 66.95
    context.lineTo 80.52, 33.87
    context.lineTo 45.39, 25.61
    context.bezierCurveTo 47.85, 31.09, 49.05, 33.87, 51.45, 39.37
    context.bezierCurveTo 48.37, 40.19, 39.96, 42.92, 33.54, 51.48
    context.bezierCurveTo 24.46, 63.49, 26.53, 77.54, 26.9, 79.91
    context.bezierCurveTo 27.64, 76.82, 30.09, 67.94, 38.14, 60.81
    context.bezierCurveTo 45.79, 54.01, 54.12, 52.78, 57.22, 52.5
    context.closePath()
    context.fillStyle = widgetColor
    context.fill()
