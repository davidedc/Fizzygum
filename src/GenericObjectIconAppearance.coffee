class GenericObjectIconAppearance extends IconAppearance

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
    context.moveTo 85.5, 20.73
    context.lineTo 68.35, 3.5
    context.bezierCurveTo 68.03, 3.18, 67.6, 3, 67.14, 3
    context.lineTo 15.71, 3
    context.bezierCurveTo 14.77, 3, 14, 3.77, 14, 4.72
    context.lineTo 14, 94.28
    context.bezierCurveTo 14, 95.23, 14.77, 96, 15.71, 96
    context.lineTo 84.29, 96
    context.bezierCurveTo 85.23, 96, 86, 95.23, 86, 94.28
    context.lineTo 86, 21.94
    context.bezierCurveTo 86, 21.49, 85.82, 21.05, 85.5, 20.73
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    # paper Drawing
    context.beginPath()
    context.moveTo 83.64, 22.31
    context.lineTo 67.62, 6.32
    context.bezierCurveTo 67.32, 6.01, 66.91, 5.85, 66.49, 5.85
    context.lineTo 18.44, 5.85
    context.bezierCurveTo 17.56, 5.85, 16.84, 6.56, 16.84, 7.45
    context.lineTo 16.84, 90.6
    context.bezierCurveTo 16.84, 91.49, 17.56, 92.2, 18.44, 92.2
    context.lineTo 82.5, 92.2
    context.bezierCurveTo 83.39, 92.2, 84.11, 91.49, 84.11, 90.6
    context.lineTo 84.11, 23.44
    context.bezierCurveTo 84.11, 23.01, 83.94, 22.61, 83.64, 22.31
    context.closePath()
    context.moveTo 68.09, 11.31
    context.lineTo 78.64, 21.84
    context.lineTo 68.09, 21.84
    context.lineTo 68.09, 11.31
    context.closePath()
    context.moveTo 20.05, 89.01
    context.lineTo 20.05, 9.05
    context.lineTo 64.89, 9.05
    context.lineTo 64.89, 23.44
    context.bezierCurveTo 64.89, 24.32, 65.6, 25.04, 66.49, 25.04
    context.lineTo 80.9, 25.04
    context.lineTo 80.9, 89.01
    context.lineTo 20.05, 89.01
    context.closePath()
    context.fillStyle = blackColorString
    context.fill()

