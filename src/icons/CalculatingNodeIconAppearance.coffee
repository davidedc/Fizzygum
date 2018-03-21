class CalculatingNodeIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// Rectangle Drawing
    context.beginPath()
    context.rect 20.5, 17.5, 60, 66
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 19.5, 26.5
    context.lineTo 9.5, 26.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 19, 72.5
    context.lineTo 9, 72.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 81, 51
    context.lineTo 90, 51
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Group 2
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 28.53, 34.5
    context.bezierCurveTo 27.62, 34.5, 48.5, 34.5, 48.5, 34.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 38.5, 23.5
    context.lineTo 38.5, 45.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 58.5, 34.5
    context.lineTo 74.5, 34.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Group
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 29.5, 72.5
    context.lineTo 45.5, 56.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 29.5, 56.5
    context.lineTo 45.5, 72.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Group 3
    #// Bezier 9 Drawing
    context.beginPath()
    context.moveTo 58.5, 63.5
    context.lineTo 75.5, 63.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Rectangle 2 Drawing
    context.beginPath()
    context.rect 65.5, 54.5, 4, 4
    context.fillStyle = iconColorString
    context.fill()
    #// Rectangle 3 Drawing
    context.beginPath()
    context.rect 65.5, 68.5, 4, 4
    context.fillStyle = iconColorString
    context.fill()
    #// Oval Drawing
    @oval context, 88.5, 48, 6, 6
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 2 Drawing
    @oval context, 6.5, 69.5, 6, 6
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 3 Drawing
    @oval context, 6.5, 23.5, 6, 6
    context.fillStyle = iconColorString
    context.fill()

