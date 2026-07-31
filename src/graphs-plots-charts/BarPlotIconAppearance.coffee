class BarPlotIconAppearance extends IconAppearance

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    iconColorString = @_iconColorString()

    #// axes Drawing
    @_paintPlotAxes context, iconColorString
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
