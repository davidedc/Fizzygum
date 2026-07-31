class GrayscalePalettePatchProgrammingIconAppearance extends IconAppearance

  grayscaleGradient: nil

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    iconColorString = @_iconColorString()

    #// Gradient Declarations

    if !@grayscaleGradient?
      colorStops = (g) ->
        g.addColorStop 0, Color.BLACK.toString()
        g.addColorStop 0.81, Color.WHITE.toString()
        g
      @grayscaleGradient = colorStops context.createLinearGradient 79, 82, 21, 82


    #// palette swatch
    @_paintPaletteSwatch context, @grayscaleGradient, iconColorString
