class FolderIconAppearance extends IconAppearance

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
    context.moveTo 89.18, 21.7
    context.lineTo 44.61, 21.7
    context.lineTo 44.61, 19.44
    context.bezierCurveTo 44.61, 15.33, 40, 12, 36.11, 12
    context.lineTo 12.5, 12
    context.bezierCurveTo 9, 12, 4, 14.89, 4, 19
    context.lineTo 4, 79.24
    context.bezierCurveTo 4, 83.53, 6.5, 87, 10.82, 87
    context.lineTo 89.18, 87
    context.bezierCurveTo 93.5, 87, 97, 83.53, 97, 79.24
    context.lineTo 97, 29.45
    context.bezierCurveTo 97, 25.17, 93.5, 21.7, 89.18, 21.7
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    # folder Drawing
    context.beginPath()
    context.moveTo 87.57, 24.63
    context.lineTo 42.23, 24.63
    context.lineTo 42.23, 21.63
    context.lineTo 42.23, 21.63
    context.bezierCurveTo 42.23, 17.84, 39.16, 14.77, 35.37, 14.77
    context.lineTo 12.85, 14.77
    context.lineTo 12.86, 14.77
    context.bezierCurveTo 9.07, 14.77, 6, 17.84, 6, 21.63
    context.lineTo 6, 31.2
    context.bezierCurveTo 6, 31.29, 6, 31.38, 6, 31.51
    context.bezierCurveTo 6, 31.64, 6, 31.69, 6, 31.78
    context.lineTo 6, 77.68
    context.lineTo 6, 77.68
    context.bezierCurveTo 6, 81.63, 9.2, 84.83, 13.15, 84.83
    context.lineTo 87.57, 84.83
    context.lineTo 87.57, 84.83
    context.bezierCurveTo 91.52, 84.83, 94.72, 81.63, 94.72, 77.68
    context.lineTo 94.72, 31.77
    context.lineTo 94.72, 31.78
    context.bezierCurveTo 94.72, 27.83, 91.52, 24.63, 87.57, 24.63
    context.closePath()
    context.moveTo 12.85, 17.27
    context.lineTo 35.37, 17.27
    context.lineTo 35.36, 17.27
    context.bezierCurveTo 37.8, 17.27, 39.77, 19.24, 39.77, 21.68
    context.lineTo 39.77, 24.67
    context.lineTo 8.45, 24.67
    context.lineTo 8.45, 21.67
    context.lineTo 8.45, 21.68
    context.bezierCurveTo 8.45, 19.24, 10.42, 17.27, 12.86, 17.27
    context.lineTo 12.85, 17.27
    context.closePath()
    context.moveTo 92.26, 77.68
    context.lineTo 92.26, 77.67
    context.bezierCurveTo 92.26, 80.27, 90.16, 82.37, 87.56, 82.37
    context.lineTo 13.14, 82.37
    context.lineTo 13.15, 82.37
    context.bezierCurveTo 10.55, 82.37, 8.45, 80.27, 8.45, 77.67
    context.lineTo 8.45, 27.08
    context.lineTo 87.57, 27.08
    context.lineTo 87.56, 27.08
    context.bezierCurveTo 90.16, 27.08, 92.26, 29.18, 92.26, 31.78
    context.lineTo 92.26, 77.67
    context.lineTo 92.26, 77.68
    context.closePath()
    context.fillStyle = blackColorString
    context.fill()

