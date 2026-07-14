class PatchProgrammingIconAppearance extends IconAppearance

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    iconColorString = @_iconColorString()
    outlineColorString = @_outlineColorString()

    #// Group 6
    #// outline Drawing
    @_paintSlideOutline context, outlineColorString
    #// slide border Drawing
    @_paintSlideCard context, iconColorString
    #// Group 8
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 30.43, 50
    context.lineTo 68.41, 50
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.lineCap = 'round'
    context.stroke()
    #// Oval 5 Drawing
    @oval context, 20, 40, 20, 20
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.stroke()
    #// Rectangle Drawing
    context.beginPath()
    context.rect 59, 40, 20, 20
    context.strokeStyle = iconColorString
    context.lineWidth = 3.5
    context.lineJoin = 'round'
    context.stroke()


