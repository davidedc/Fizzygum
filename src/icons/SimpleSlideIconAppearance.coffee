class SimpleSlideIconAppearance extends IconAppearance

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    iconColorString = @_iconColorString()
    outlineColorString = @_outlineColorString()
    #// Group
    #// outline Drawing
    @_paintSlideOutline context, outlineColorString
    #// column 1 line 1 Drawing
    context.beginPath()
    context.moveTo 16.86, 33.6
    context.lineTo 44.54, 33.6
    context.strokeStyle = iconColorString
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// column 1 line 2 Drawing
    context.beginPath()
    context.moveTo 16.86, 45.34
    context.lineTo 44.54, 45.34
    context.strokeStyle = iconColorString
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// column 1 line 3 Drawing
    context.beginPath()
    context.moveTo 16.86, 56.08
    context.lineTo 44.54, 56.08
    context.strokeStyle = iconColorString
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// column 1 line 4 Drawing
    context.beginPath()
    context.moveTo 16.86, 67.36
    context.lineTo 44.54, 67.36
    context.strokeStyle = iconColorString
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// column 2 line 1 Drawing
    context.beginPath()
    context.moveTo 53.77, 56.08
    context.lineTo 81.45, 56.08
    context.strokeStyle = iconColorString
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// column 2 line 2 Drawing
    context.beginPath()
    context.moveTo 53.77, 67.36
    context.lineTo 81.45, 67.36
    context.strokeStyle = iconColorString
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// graph bar 1 Drawing
    context.beginPath()
    context.rect 54, 36, 8, 9.5
    context.strokeStyle = iconColorString
    context.lineWidth = 1.5
    context.lineJoin = 'round'
    context.stroke()
    #// graph bar 2 Drawing
    context.beginPath()
    context.rect 65, 33, 7, 12.5
    context.strokeStyle = iconColorString
    context.lineWidth = 1.5
    context.lineJoin = 'round'
    context.stroke()
    #// graph bar 3 Drawing
    context.beginPath()
    context.rect 75, 28, 8, 17.5
    context.strokeStyle = iconColorString
    context.lineWidth = 1.5
    context.lineJoin = 'round'
    context.stroke()
    #// slide border Drawing
    @_paintSlideCard context, iconColorString

