class ArrowEIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    #// Group
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 49.56, 2
    context.lineTo 30.42, 21.15
    context.bezierCurveTo 30.42, 21.15, 37.12, 27.85, 46.61, 37.35
    context.lineTo 2, 37.35
    context.lineTo 2, 63.64
    context.lineTo 46.61, 63.64
    context.lineTo 30.41, 79.85
    context.lineTo 49.56, 99
    context.lineTo 98, 50.5
    context.lineTo 49.56, 2
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 49.55, 4.94
    context.lineTo 33.42, 21.09
    context.bezierCurveTo 33.42, 21.09, 42.47, 30.15, 51.39, 39.07
    context.lineTo 3.96, 39.07
    context.lineTo 3.96, 61.92
    context.lineTo 51.39, 61.92
    context.lineTo 33.41, 79.91
    context.lineTo 49.55, 96.06
    context.lineTo 95.06, 50.5
    context.lineTo 49.55, 4.94
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()

