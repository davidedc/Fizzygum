class GenericPanelIconAppearance extends IconAppearance

  preferredSize: new Point 100, 100
  specificationSize: new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    iconColorString = @_iconColorString()
    outlineColorString = @_outlineColorString()
    toolbarsHeaderLineColorString = Color.WHITE.toString()
    toolbarsHeaderBackgroundColorString = 'rgb(170, 170, 170)'

    #// Group
    #// outline Drawing
    @_paintSlideOutline context, outlineColorString
    #// slide border Drawing
    @_paintSlideCard context, iconColorString
    #// Group 22
    #// Rectangle 3 Drawing
    context.beginPath()
    context.rect 15, 30, 18, 65
    context.fillStyle = outlineColorString
    context.fill()
    #// Group 8
    #// Group 9
    #// Rectangle Drawing
    context.beginPath()
    context.rect 17.5, 40.5, 13, 13
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 21.5, 44.5
    context.lineTo 26.5, 44.5
    context.lineTo 26.5, 49.5
    context.lineTo 21.5, 49.5
    context.lineTo 21.5, 44.5
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Rectangle 8 Drawing
    context.beginPath()
    context.rect 17.5, 32.5, 13, 8
    context.fillStyle = toolbarsHeaderBackgroundColorString
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 10
    #// Rectangle 9 Drawing
    context.beginPath()
    context.rect 17.5, 53.5, 13, 13
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 9 Drawing
    context.beginPath()
    context.moveTo 21.5, 57.5
    context.lineTo 26.5, 57.5
    context.lineTo 26.5, 62.5
    context.lineTo 21.5, 62.5
    context.lineTo 21.5, 57.5
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 11
    #// Rectangle 10 Drawing
    context.beginPath()
    context.rect 17.5, 66.5, 13, 13
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 21.5, 70.5
    context.lineTo 26.5, 70.5
    context.lineTo 26.5, 75.5
    context.lineTo 21.5, 75.5
    context.lineTo 21.5, 70.5
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 12
    #// Rectangle 11 Drawing
    context.beginPath()
    context.rect 17.5, 79.5, 13, 13
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 11 Drawing
    context.beginPath()
    context.moveTo 21.5, 83.5
    context.lineTo 26.5, 83.5
    context.lineTo 26.5, 88.5
    context.lineTo 21.5, 88.5
    context.lineTo 21.5, 83.5
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 19.5, 36.5
    context.lineTo 28.5, 36.5
    context.strokeStyle = toolbarsHeaderLineColorString
    context.lineWidth = 1
    context.stroke()
    #// Rectangle 2 Drawing
    context.beginPath()
    context.rect 69, 3, 17.5, 53
    context.fillStyle = outlineColorString
    context.fill()
    #// Group 19
    #// Group 20
    #// Rectangle 18 Drawing
    context.beginPath()
    context.rect 71.5, 13.5, 13, 13
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 18 Drawing
    context.beginPath()
    context.moveTo 75.5, 17.5
    context.lineTo 80.5, 17.5
    context.lineTo 80.5, 22.5
    context.lineTo 75.5, 22.5
    context.lineTo 75.5, 17.5
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Rectangle 19 Drawing
    context.beginPath()
    context.rect 71.5, 5.5, 13, 8
    context.fillStyle = toolbarsHeaderBackgroundColorString
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 21
    #// Rectangle 20 Drawing
    context.beginPath()
    context.rect 71.5, 26.5, 13, 13
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 20 Drawing
    context.beginPath()
    context.moveTo 75.5, 30.5
    context.lineTo 80.5, 30.5
    context.lineTo 80.5, 35.5
    context.lineTo 75.5, 35.5
    context.lineTo 75.5, 30.5
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 23
    #// Rectangle 21 Drawing
    context.beginPath()
    context.rect 71.5, 39.5, 13, 13
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 21 Drawing
    context.beginPath()
    context.moveTo 75.5, 43.5
    context.lineTo 80.5, 43.5
    context.lineTo 80.5, 48.5
    context.lineTo 75.5, 48.5
    context.lineTo 75.5, 43.5
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 19 Drawing
    context.beginPath()
    context.moveTo 73.5, 9.5
    context.lineTo 82.5, 9.5
    context.strokeStyle = toolbarsHeaderLineColorString
    context.lineWidth = 1
    context.stroke()

