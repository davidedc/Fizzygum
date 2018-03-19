class TextToolbarIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// Bezier Drawing
    context.beginPath()
    context.moveTo 83.25, 10.1
    context.lineTo 16.75, 10.1
    context.lineTo 14.03, 30.23
    context.lineTo 24.25, 30.15
    context.bezierCurveTo 24.25, 24.65, 30, 18.9, 35.5, 18.9
    context.lineTo 43, 18.9
    context.lineTo 43, 76.4
    context.bezierCurveTo 43, 79.2, 40.8, 81.4, 38, 81.4
    context.lineTo 31.75, 82.65
    context.lineTo 31.75, 90.65
    context.lineTo 68.25, 90.65
    context.lineTo 68.25, 82.75
    context.lineTo 62, 81.5
    context.bezierCurveTo 59.2, 81.5, 57, 79.3, 57, 76.5
    context.lineTo 57, 19
    context.lineTo 64.5, 19
    context.bezierCurveTo 70, 19, 75.75, 24.75, 75.75, 30.25
    context.lineTo 85.72, 30.1
    context.lineTo 83.25, 10.1
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 3
    context.miterLimit = 4
    context.lineJoin = 'round'
    context.stroke()


