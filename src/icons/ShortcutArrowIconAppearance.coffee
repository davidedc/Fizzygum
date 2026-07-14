class ShortcutArrowIconAppearance extends IconAppearance

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    # Color Declarations
    iconColorString = @_iconColorString()
    outlineColorString = @_outlineColorString()
    # Group 4
    # outline Drawing
    @_paintRoundedSquareBadge context, outlineColorString, iconColorString
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
    context.fillStyle = iconColorString
    context.fill()
