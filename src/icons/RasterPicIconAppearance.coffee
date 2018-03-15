class RasterPicIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    # Color Declarations
    widgetColor = @morph.color
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    # outline Drawing
    context.beginPath()
    context.moveTo 92.74, 8
    context.lineTo 7.48, 8
    context.bezierCurveTo 5.13, 8, 3.22, 9.9, 3.22, 12.26
    context.lineTo 3.22, 88.9
    context.bezierCurveTo 3.22, 91.25, 5.13, 93.15, 7.48, 93.15
    context.lineTo 92.74, 93.15
    context.bezierCurveTo 95.1, 93.15, 97, 91.25, 97, 88.9
    context.lineTo 97, 12.26
    context.bezierCurveTo 97, 9.9, 95.1, 8, 92.74, 8
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    # mountains and container Drawing
    context.beginPath()
    context.moveTo 91.13, 9.42
    context.lineTo 9.25, 9.42
    context.bezierCurveTo 6.99, 9.42, 5.16, 11.25, 5.16, 13.51
    context.lineTo 5.16, 87.13
    context.bezierCurveTo 5.16, 89.4, 6.99, 91.22, 9.25, 91.22
    context.lineTo 91.13, 91.22
    context.bezierCurveTo 93.4, 91.22, 95.23, 89.4, 95.23, 87.13
    context.lineTo 95.23, 13.51
    context.bezierCurveTo 95.23, 11.25, 93.4, 9.42, 91.13, 9.42
    context.closePath()
    context.moveTo 91.13, 13.51
    context.lineTo 91.13, 70.24
    context.lineTo 77.83, 55.8
    context.bezierCurveTo 77.05, 54.92, 75.93, 54.41, 74.76, 54.41
    context.bezierCurveTo 73.58, 54.41, 72.46, 54.92, 71.68, 55.8
    context.lineTo 61.02, 67.86
    context.lineTo 28.7, 31.26
    context.bezierCurveTo 27.92, 30.38, 26.8, 29.87, 25.63, 29.87
    context.bezierCurveTo 24.45, 29.87, 23.34, 30.38, 22.56, 31.26
    context.lineTo 9.25, 46.59
    context.lineTo 9.25, 13.51
    context.lineTo 91.13, 13.51
    context.closePath()
    context.moveTo 9.25, 52.78
    context.lineTo 25.63, 33.96
    context.lineTo 58.65, 71.36
    context.lineTo 61.03, 74.05
    context.lineTo 72.33, 87.13
    context.lineTo 9.25, 87.13
    context.lineTo 9.25, 52.78
    context.closePath()
    context.moveTo 77.79, 87.13
    context.lineTo 63.75, 70.96
    context.lineTo 74.76, 58.5
    context.lineTo 91.13, 76.41
    context.lineTo 91.13, 87.13
    context.lineTo 77.79, 87.13
    context.lineTo 77.79, 87.13
    context.closePath()
    context.fillStyle = widgetColor
    context.fill()
    # sun Drawing
    @oval context, 56.25, 23.5, 20.5, 20.75
    context.strokeStyle = widgetColor
    context.lineWidth = 4
    context.stroke()
