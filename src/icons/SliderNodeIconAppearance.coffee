class SliderNodeIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// Bezier Drawing
    context.beginPath()
    context.moveTo 60.64, 82.46
    context.lineTo 60.64, 18
    context.bezierCurveTo 60.64, 11.58, 55.42, 6.37, 49, 6.37
    context.bezierCurveTo 42.59, 6.37, 37.37, 11.58, 37.37, 18
    context.bezierCurveTo 37.37, 18.12, 37.38, 18.24, 37.38, 18.36
    context.lineTo 37.39, 81.96
    context.lineTo 37.38, 82.1
    context.bezierCurveTo 37.38, 82.22, 37.37, 82.34, 37.37, 82.46
    context.bezierCurveTo 37.37, 88.87, 42.59, 94.09, 49, 94.09
    context.bezierCurveTo 55.42, 94.09, 60.64, 88.87, 60.64, 82.46
    context.closePath()
    context.moveTo 40.37, 82.46
    context.bezierCurveTo 40.37, 82.4, 40.37, 82.35, 40.38, 82.3
    context.lineTo 40.39, 82.01
    context.lineTo 40.39, 18.4
    context.lineTo 40.38, 18.16
    context.bezierCurveTo 40.37, 18.11, 40.37, 18.06, 40.37, 18
    context.bezierCurveTo 40.37, 13.24, 44.24, 9.37, 49, 9.37
    context.bezierCurveTo 53.76, 9.37, 57.64, 13.24, 57.64, 18
    context.lineTo 57.64, 82.46
    context.bezierCurveTo 57.64, 87.22, 53.76, 91.09, 49, 91.09
    context.bezierCurveTo 44.24, 91.09, 40.37, 87.22, 40.37, 82.46
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Oval Drawing
    @oval context, 42, 57, 14, 14
    context.fillStyle = iconColorString
    context.fill()
    #// Group
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 60, 50
    context.lineTo 69, 50
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Oval 2 Drawing
    @oval context, 67.5, 47, 6, 6
    context.fillStyle = iconColorString
    context.fill()
