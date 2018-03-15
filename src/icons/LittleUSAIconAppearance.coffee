class LittleUSAIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 96.16, 27.93
    context.lineTo 91.98, 24.05
    context.lineTo 90.7, 24.59
    context.lineTo 87.81, 30.51
    context.lineTo 82.78, 32.02
    context.lineTo 73.37, 40.43
    context.lineTo 72.08, 39.78
    context.lineTo 69.3, 32.78
    context.lineTo 60.1, 28.03
    context.lineTo 59.89, 27.93
    context.lineTo 50.36, 25.88
    context.lineTo 50.26, 25.88
    context.lineTo 8.64, 22
    context.lineTo 3.5, 39.35
    context.lineTo 6.07, 52.92
    context.lineTo 12.59, 60.36
    context.lineTo 27.36, 66.29
    context.lineTo 31.1, 66.29
    context.lineTo 36.56, 71.89
    context.lineTo 39.99, 70.92
    context.lineTo 47.05, 78.35
    context.lineTo 54.43, 71.46
    context.lineTo 62.88, 71.78
    context.lineTo 64.7, 69.52
    context.lineTo 73.58, 69.09
    context.lineTo 79.79, 78.57
    context.lineTo 80.64, 79
    context.lineTo 83.53, 78.89
    context.lineTo 84.07, 77.71
    context.lineTo 79.79, 67.04
    context.lineTo 88.03, 54.65
    context.lineTo 86.42, 49.48
    context.lineTo 88.13, 41.93
    context.lineTo 93.7, 38.05
    context.lineTo 92.73, 33.53
    context.lineTo 96.16, 27.93
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 3
    context.miterLimit = 4
    context.stroke()
