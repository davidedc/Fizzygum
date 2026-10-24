class GrayscalePalettePatchProgrammingIconAppearance extends IconAppearance

  # Serialization: the gradient is a live canvas object, so it never rides a file (SWCanvas has no
  # encoder for it at all); paintFunction rebuilds it whenever it is absent. The Duplicator needs no
  # declaration: it clones every gradient as undefined. See
  # docs/architecture/serialization-duplication-reference.md §5.
  @serializationTransients: ["grayscaleGradient"]

  grayscaleGradient: undefined

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
