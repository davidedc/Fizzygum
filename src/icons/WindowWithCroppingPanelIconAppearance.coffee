class WindowWithCroppingPanelIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// Oval Drawing
    @oval context, 11, 11, 6, 6
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 2 Drawing
    @oval context, 22, 11, 6, 6
    context.fillStyle = iconColorString
    context.fill()
    #// Group
    #// Oval 4 Drawing
    @arc context, -17, 32, 44, 44, 270, 90, true
    context.fillStyle = iconColorString
    context.fill()
    #// window bar bottom Drawing
    context.beginPath()
    context.moveTo 5, 24
    context.lineTo 91, 24
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.stroke()
    #// window border Drawing
    context.beginPath()
    context.rect 4, 4, 88, 88
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.lineJoin = 'round'
    context.stroke()

