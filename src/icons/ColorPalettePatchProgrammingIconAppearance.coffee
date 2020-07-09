class ColorPalettePatchProgrammingIconAppearance extends IconAppearance

  colorGradient: nil

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

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


    #// background Drawing
    context.beginPath()
    context.rect 21, 19, 58, 63
    context.fillStyle = @colorGradient
    context.fill()
    #// Rectangle Drawing
    context.beginPath()
    context.rect 20.5, 17.5, 60, 66
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 81, 51
    context.lineTo 90, 51
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Oval Drawing
    @oval context, 88.5, 48, 6, 6
    context.fillStyle = iconColorString
    context.fill()
