class WindowWithCroppingPanelIconAppearance extends IconAppearance

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
    #// window frame
    @_paintWindowFrame context, iconColorString

