class GenericPanelIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    toolbarsHeaderLineColorString = Color.WHITE.toString()
    toolbarsHeaderBackgroundColorString = 'rgb(170, 170, 170)'

    #// Group
    #// outline Drawing
    context.beginPath()
    context.moveTo 87.54, 18
    context.lineTo 13.57, 18
    context.bezierCurveTo 10.05, 18, 7.12, 20.67, 7.12, 23.87
    context.lineTo 7, 76.13
    context.bezierCurveTo 7, 79.33, 9.94, 82, 13.46, 82
    context.lineTo 87.43, 82
    context.bezierCurveTo 90.95, 82, 93.88, 79.33, 93.88, 76.13
    context.lineTo 94, 23.87
    context.bezierCurveTo 94, 20.67, 91.06, 18, 87.54, 18
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// slide border Drawing
    context.beginPath()
    context.moveTo 85.84, 20
    context.lineTo 15.27, 20
    context.bezierCurveTo 11.91, 20, 9.11, 22.5, 9.11, 25.5
    context.lineTo 9, 74.5
    context.bezierCurveTo 9, 77.5, 11.8, 80, 15.16, 80
    context.lineTo 85.73, 80
    context.bezierCurveTo 89.09, 80, 91.89, 77.5, 91.89, 74.5
    context.lineTo 92, 25.5
    context.bezierCurveTo 92, 22.5, 89.2, 20, 85.84, 20
    context.closePath()
    context.moveTo 88.53, 74.5
    context.bezierCurveTo 88.53, 75.9, 87.3, 77, 85.73, 77
    context.lineTo 15.16, 77
    context.bezierCurveTo 13.59, 77, 12.36, 75.9, 12.36, 74.5
    context.lineTo 12.47, 25.5
    context.bezierCurveTo 12.47, 24.1, 13.7, 23, 15.27, 23
    context.lineTo 85.84, 23
    context.bezierCurveTo 87.41, 23, 88.64, 24.1, 88.64, 25.5
    context.lineTo 88.53, 74.5
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
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

