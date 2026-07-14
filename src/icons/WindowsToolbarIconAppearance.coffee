class WindowsToolbarIconAppearance extends IconAppearance

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    iconColorString = @_iconColorString()

    #// Oval Drawing
    @_paintWindowTitleDots context, iconColorString
    #// window frame
    @_paintWindowFrame context, iconColorString
