class FunctionPlotIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// axes Drawing
    context.beginPath()
    context.moveTo 7, 8
    context.lineTo 11.25, 8
    context.lineTo 11.25, 88.76
    context.lineTo 92, 88.76
    context.lineTo 92, 93
    context.lineTo 7, 93
    context.lineTo 7, 8
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// the function Drawing
    context.beginPath()
    context.moveTo 20.06, 79.26
    context.lineTo 15.23, 75.9
    context.lineTo 26.06, 56.31
    context.bezierCurveTo 30.65, 47.24, 35.32, 43.21, 40.07, 44.24
    context.bezierCurveTo 43.14, 44.9, 54.09, 61.41, 57.5, 57.37
    context.bezierCurveTo 58.98, 57.16, 82.84, 11.04, 82.84, 11.04
    context.lineTo 87.75, 14.04
    context.bezierCurveTo 87.75, 14.04, 64.04, 58.55, 62.73, 60.59
    context.bezierCurveTo 61.13, 62.57, 59.42, 63.75, 57.1, 63.64
    context.bezierCurveTo 54.43, 63.84, 52, 63, 48.31, 59.85
    context.bezierCurveTo 44.62, 56.71, 41.39, 52.14, 38.2, 51.57
    context.bezierCurveTo 35, 51, 32.45, 56.53, 30.62, 59.61
    context.lineTo 20.06, 79.26
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
