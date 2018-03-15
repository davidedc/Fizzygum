class ArrowSIconAppearance extends IconAppearance

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
    context.moveTo 98.5, 50.06
    context.lineTo 79.35, 30.92
    context.bezierCurveTo 79.35, 30.92, 72.65, 37.62, 63.15, 47.11
    context.lineTo 63.15, 2.5
    context.lineTo 36.86, 2.5
    context.lineTo 36.86, 47.11
    context.lineTo 20.65, 30.91
    context.lineTo 1.5, 50.06
    context.lineTo 50, 98.5
    context.lineTo 98.5, 50.06
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 95.56, 50.05
    context.lineTo 79.41, 33.92
    context.bezierCurveTo 79.41, 33.92, 70.35, 42.97, 61.43, 51.89
    context.lineTo 61.43, 4.46
    context.lineTo 38.58, 4.46
    context.lineTo 38.58, 51.89
    context.lineTo 20.59, 33.91
    context.lineTo 4.44, 50.05
    context.lineTo 50, 95.56
    context.lineTo 95.56, 50.05
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
