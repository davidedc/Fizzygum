class GrayscalePalettePatchProgrammingIconAppearance extends IconAppearance

  grayscaleGradient: nil

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// Gradient Declarations

    if !@grayscaleGradient?
      colorStops = (g) ->
        g.addColorStop 0, 'rgb(0, 0, 0)'
        g.addColorStop 0.81, 'rgb(255, 255, 255)'
        g
      @grayscaleGradient = colorStops context.createLinearGradient 79, 82, 21, 82


    #// background Drawing
    context.beginPath()
    context.rect 21, 19, 58, 63
    context.fillStyle = @grayscaleGradient
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
