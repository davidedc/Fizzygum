class BarPlotIconAppearance extends IconAppearance

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
    #// bars
    #// bar 5 Drawing
    context.beginPath()
    context.rect 78, 43, 11, 43
    context.fillStyle = iconColorString
    context.fill()
    #// bar 4 Drawing
    context.beginPath()
    context.rect 62, 31, 11, 55
    context.fillStyle = iconColorString
    context.fill()
    #// bar 3 Drawing
    context.beginPath()
    context.rect 45, 14, 11, 72
    context.fillStyle = iconColorString
    context.fill()
    #// bar 2 Drawing
    context.beginPath()
    context.rect 29, 22, 11, 64
    context.fillStyle = iconColorString
    context.fill()
    #// bar 1 Drawing
    context.beginPath()
    context.rect 14, 46, 10, 40
    context.fillStyle = iconColorString
    context.fill()
