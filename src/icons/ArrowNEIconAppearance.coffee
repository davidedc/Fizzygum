class ArrowNEIconAppearance extends IconAppearance

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
    context.moveTo 16.12, 7.13
    context.lineTo 16.26, 37.43
    context.bezierCurveTo 16.26, 37.43, 26.86, 37.47, 41.89, 37.54
    context.lineTo 6.73, 72.7
    context.lineTo 27.62, 93.59
    context.lineTo 62.78, 58.43
    context.lineTo 62.89, 84.08
    context.lineTo 93.2, 84.2
    context.lineTo 92.84, 7.49
    context.lineTo 16.12, 7.13
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 18.46, 9.47
    context.lineTo 18.57, 35.02
    context.bezierCurveTo 18.57, 35.02, 32.9, 35.08, 47.02, 35.14
    context.lineTo 9.64, 72.52
    context.lineTo 27.8, 90.68
    context.lineTo 65.18, 53.3
    context.lineTo 65.3, 81.76
    context.lineTo 90.86, 81.87
    context.lineTo 90.52, 9.8
    context.lineTo 18.46, 9.47
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()

