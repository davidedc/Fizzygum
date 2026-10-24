class ColorPalettePatchProgrammingIconAppearance extends IconAppearance

  # Serialization: the gradient is a live canvas object, so it never rides a file (SWCanvas has no
  # encoder for it at all); paintFunction rebuilds it whenever it is absent. The Duplicator needs no
  # declaration: it clones every gradient as undefined. See
  # docs/architecture/serialization-duplication-reference.md §5.
  @serializationTransients: ["colorGradient"]

  colorGradient: undefined

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    iconColorString = @_iconColorString()

    #// Gradient Declarations

    if !@colorGradient?
      colorStops = (g) ->
        g.addColorStop 0, Color.RED.toString()
        g.addColorStop 0.15, Color.MAGENTA.toString()
        g.addColorStop 0.33, Color.BLUE.toString()
        g.addColorStop 0.49, Color.CYAN.toString()
        g.addColorStop 0.67, Color.LIME.toString()
        g.addColorStop 0.84, Color.YELLOW.toString()
        g.addColorStop 1, Color.RED.toString()
        g
      @colorGradient = colorStops context.createLinearGradient 79, 82, 21, 82


    #// palette swatch
    @_paintPaletteSwatch context, @colorGradient, iconColorString
