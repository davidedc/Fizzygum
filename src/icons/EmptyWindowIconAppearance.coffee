class EmptyWindowIconAppearance extends IconAppearance

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
    #// dashed content box
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 19, 33
    context.lineTo 14, 33
    context.lineTo 14, 39
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.lineCap = 'square'
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 14, 45
    context.lineTo 14, 53
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 14, 60
    context.bezierCurveTo 14, 59.5, 14, 69, 14, 69
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 14, 77
    context.lineTo 14, 82
    context.lineTo 21, 82
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 77, 82
    context.lineTo 82, 82
    context.lineTo 82, 75
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 11 Drawing
    context.beginPath()
    context.moveTo 82, 68
    context.lineTo 82, 60
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 12 Drawing
    context.beginPath()
    context.moveTo 82, 53
    context.lineTo 82, 44
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 13 Drawing
    context.beginPath()
    context.moveTo 82, 38.94
    context.bezierCurveTo 82, 39.69, 82, 33, 82, 33
    context.lineTo 75, 33
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 14 Drawing
    context.beginPath()
    context.moveTo 26, 33
    context.lineTo 38, 33
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 15 Drawing
    context.beginPath()
    context.moveTo 43, 33
    context.lineTo 53, 33
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 16 Drawing
    context.beginPath()
    context.moveTo 58, 33
    context.lineTo 70, 33
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 17 Drawing
    context.beginPath()
    context.moveTo 26, 82
    context.lineTo 38, 82
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 18 Drawing
    context.beginPath()
    context.moveTo 43, 82
    context.lineTo 53, 82
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// Bezier 19 Drawing
    context.beginPath()
    context.moveTo 58, 82
    context.lineTo 70, 82
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()

