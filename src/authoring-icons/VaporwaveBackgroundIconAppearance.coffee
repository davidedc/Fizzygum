class VaporwaveBackgroundIconAppearance extends IconAppearance

  # Serialization: the gradient is a live canvas object, so it never rides a file (SWCanvas has no
  # encoder for it at all); paintFunction rebuilds it whenever it is absent. The Duplicator needs no
  # declaration: it clones every gradient as undefined. See
  # docs/architecture/serialization-duplication-reference.md §5.
  @serializationTransients: ["backgroundGradient"]

  backgroundGradient: undefined

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    blue = 'rgb(0, 0, 159)'
    yellow = Color.YELLOW.toString()
    darkBlue = 'rgb(0, 0, 82)'
    pink = 'rgb(255, 6, 136)'
    #// background Drawing
    #// Gradient Declarations

    if !@backgroundGradient?
      colorStops = (g) ->
        g.addColorStop 0, darkBlue
        g.addColorStop 0.14, blue
        g.addColorStop 0.58, pink
        g.addColorStop 1, yellow
        g
      @backgroundGradient = colorStops context.createLinearGradient 50, 91.61, 50, -28.19

    context.fillStyle = @backgroundGradient
    context.fillRect 0, 0, 100, 99.5
