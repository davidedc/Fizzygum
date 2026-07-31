class WindowWithScrollingPanelIconAppearance extends IconAppearance

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    iconColorString = @_iconColorString()

    #// Oval Drawing
    @_paintWindowTitleDots context, iconColorString
    #// Group
    #// Oval 4 Drawing
    @arc context, -17, 32, 44, 44, 270, 90, true
    context.fillStyle = iconColorString
    context.fill()
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 28, 82
    context.lineTo 83, 82
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 82, 33
    context.lineTo 82, 60
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.stroke()
    #// window frame
    @_paintWindowFrame context, iconColorString
