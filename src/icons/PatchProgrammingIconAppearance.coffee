class PatchProgrammingIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString

    #// Group 6
    #// outline Drawing
    context.beginPath()
    context.moveTo 87.54, 18
    context.lineTo 13.57, 18
    context.bezierCurveTo 10.05, 18, 7.12, 20.67, 7.12, 23.87
    context.lineTo 7, 76.13
    context.bezierCurveTo 7, 79.33, 9.94, 82, 13.46, 82
    context.lineTo 87.43, 82
    context.bezierCurveTo 90.95, 82, 93.88, 79.33, 93.88, 76.13
    context.lineTo 94, 23.87
    context.bezierCurveTo 94, 20.67, 91.06, 18, 87.54, 18
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// slide border Drawing
    context.beginPath()
    context.moveTo 85.84, 20
    context.lineTo 15.27, 20
    context.bezierCurveTo 11.91, 20, 9.11, 22.5, 9.11, 25.5
    context.lineTo 9, 74.5
    context.bezierCurveTo 9, 77.5, 11.8, 80, 15.16, 80
    context.lineTo 85.73, 80
    context.bezierCurveTo 89.09, 80, 91.89, 77.5, 91.89, 74.5
    context.lineTo 92, 25.5
    context.bezierCurveTo 92, 22.5, 89.2, 20, 85.84, 20
    context.closePath()
    context.moveTo 88.53, 74.5
    context.bezierCurveTo 88.53, 75.9, 87.3, 77, 85.73, 77
    context.lineTo 15.16, 77
    context.bezierCurveTo 13.59, 77, 12.36, 75.9, 12.36, 74.5
    context.lineTo 12.47, 25.5
    context.bezierCurveTo 12.47, 24.1, 13.7, 23, 15.27, 23
    context.lineTo 85.84, 23
    context.bezierCurveTo 87.41, 23, 88.64, 24.1, 88.64, 25.5
    context.lineTo 88.53, 74.5
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// Group 8
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 30.43, 50
    context.lineTo 68.41, 50
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.lineCap = 'round'
    context.stroke()
    #// Oval 5 Drawing
    @oval context, 20, 40, 20, 20
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.stroke()
    #// Rectangle Drawing
    context.beginPath()
    context.rect 59, 40, 20, 20
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.lineJoin = 'round'
    context.stroke()


