class ArrowNWIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 6.63, 83.38
    context.lineTo 36.93, 83.24
    context.bezierCurveTo 36.93, 83.24, 36.97, 72.64, 37.04, 57.61
    context.lineTo 72.2, 92.77
    context.lineTo 93.09, 71.88
    context.lineTo 57.93, 36.72
    context.lineTo 83.58, 36.61
    context.lineTo 83.7, 6.3
    context.lineTo 6.99, 6.66
    context.lineTo 6.63, 83.38
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 8.97, 81.04
    context.lineTo 34.52, 80.93
    context.bezierCurveTo 34.52, 80.93, 34.58, 66.6, 34.64, 52.48
    context.lineTo 72.02, 89.86
    context.lineTo 90.18, 71.7
    context.lineTo 52.8, 34.32
    context.lineTo 81.26, 34.2
    context.lineTo 81.37, 8.64
    context.lineTo 9.3, 8.98
    context.lineTo 8.97, 81.04
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()

