class ScatterPlotIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// Group
    #// Bezier Drawing
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
    #// Group 2
    #// Oval Drawing
    @oval context, 35, 25, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 2 Drawing
    @oval context, 18, 39, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 3 Drawing
    @oval context, 16, 56, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 4 Drawing
    @oval context, 15, 69, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 5 Drawing
    @oval context, 28, 79, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 6 Drawing
    @oval context, 39, 73, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 7 Drawing
    @oval context, 51, 71, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 8 Drawing
    @oval context, 66, 74, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 9 Drawing
    @oval context, 41, 62, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 10 Drawing
    @oval context, 36, 49, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 11 Drawing
    @oval context, 38, 39, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 12 Drawing
    @oval context, 51, 34, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 13 Drawing
    @oval context, 51, 24, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 14 Drawing
    @oval context, 51, 54, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 15 Drawing
    @oval context, 63, 61, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 16 Drawing
    @oval context, 72, 50, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 17 Drawing
    @oval context, 65, 41, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 18 Drawing
    @oval context, 85, 41, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 19 Drawing
    @oval context, 78, 32, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 20 Drawing
    @oval context, 85, 23, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 21 Drawing
    @oval context, 80, 14, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 22 Drawing
    @oval context, 69, 17, 5, 5
    context.fillStyle = iconColorString
    context.fill()
