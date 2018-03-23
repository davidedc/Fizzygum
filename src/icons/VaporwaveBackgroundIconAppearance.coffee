class VaporwaveBackgroundIconAppearance extends IconAppearance

  backgroundGradient: nil

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    blue = 'rgb(0, 0, 159)'
    yellow = 'rgb(255, 255, 0)'
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

    context.beginPath()
    context.rect 0, 0, 100, 99.5
    context.fillStyle = @backgroundGradient
    context.fill()
