class VaporwaveBackgroundIconAppearance extends IconAppearance

  backgroundGradient: nil

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    blue = 'rgba(0, 0, 159, 1)'
    yellow = 'rgba(255, 255, 0, 1)'
    darkBlue = 'rgba(0, 0, 82, 1)'
    pink = 'rgba(255, 6, 136, 1)'
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
