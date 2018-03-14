class VaporwaveSunIconAppearance extends IconAppearance

  sunGradient: nil

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    blue = 'rgba(0, 0, 255, 1)'
    pink = 'rgba(255, 0, 255, 1)'
    yellow = 'rgba(255, 244, 6, 1)'
    #// sun Drawing
    #// Gradient Declarations

    if !@sunGradient?
      colorStops = (g) ->
        g.addColorStop 0, blue
        g.addColorStop 0.43, pink
        g.addColorStop 1, yellow
        g
      @sunGradient = colorStops context.createLinearGradient 50, 83.39, 50, 5.13

    @oval context, 2, 2, 96, 96
    context.fillStyle = @sunGradient
    context.fill()
