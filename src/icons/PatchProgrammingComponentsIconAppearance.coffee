class PatchProgrammingComponentsIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()

    #// Group 2
    #// Rectangle 2 Drawing
    context.beginPath()
    context.rect 66.5, 69.5, 22, 24
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 64.59, 72.77
    context.lineTo 60.59, 72.77
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 64.59, 89.5
    context.lineTo 60.59, 89.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Oval 5 Drawing
    @oval context, 57.5, 87.6, 4, 4
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 6 Drawing
    @oval context, 57.5, 70.7, 4, 4
    context.fillStyle = iconColorString
    context.fill()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 94.05, 72.77
    context.lineTo 90.41, 72.77
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 94.05, 89.5
    context.lineTo 90.41, 89.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Oval 7 Drawing
    @oval context, 93.5, 87.5, 4, 4
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 8 Drawing
    @oval context, 93.5, 70.7, 4, 4
    context.fillStyle = iconColorString
    context.fill()
    #// Group
    #// Rectangle Drawing
    context.beginPath()
    context.rect 13.5, 8.5, 48, 50
    context.strokeStyle = iconColorString
    context.lineWidth = 4
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 13.55, 15.32
    context.lineTo 5.82, 15.32
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 13.16, 50.17
    context.lineTo 5.43, 50.17
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Oval 2 Drawing
    @oval context, 3.5, 47.5, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 3 Drawing
    @oval context, 3.5, 12.5, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 68.41, 15.32
    context.lineTo 60.68, 15.32
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 68.02, 50.17
    context.lineTo 60.3, 50.17
    context.strokeStyle = iconColorString
    context.lineWidth = 2
    context.stroke()
    #// Oval Drawing
    @oval context, 66.5, 47.5, 5, 5
    context.fillStyle = iconColorString
    context.fill()
    #// Oval 4 Drawing
    @oval context, 66.5, 12.5, 5, 5
    context.fillStyle = iconColorString
    context.fill()

