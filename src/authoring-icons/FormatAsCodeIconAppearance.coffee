class FormatAsCodeIconAppearance extends IconAppearance

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    outlineColorString = @_outlineColorString()
    iconColorString = @_iconColorString()
    #// Group
    #// cket 2 Drawing
    context.beginPath()
    context.moveTo 60.58, 28
    context.lineTo 83, 50.5
    context.lineTo 60.58, 73
    context.strokeStyle = outlineColorString
    context.lineWidth = 10
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// bra 2 Drawing
    context.beginPath()
    context.moveTo 39.42, 28
    context.lineTo 17, 50.5
    context.lineTo 39.42, 73
    context.strokeStyle = outlineColorString
    context.lineWidth = 10
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// cket Drawing
    context.beginPath()
    context.moveTo 60.58, 28
    context.lineTo 83, 50.5
    context.lineTo 60.58, 73
    context.strokeStyle = iconColorString
    context.lineWidth = 5
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// bra Drawing
    context.beginPath()
    context.moveTo 39.42, 28
    context.lineTo 17, 50.5
    context.lineTo 39.42, 73
    context.strokeStyle = iconColorString
    context.lineWidth = 5
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()

