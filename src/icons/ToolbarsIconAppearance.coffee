class ToolbarsIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    toolbarsHeaderLineColorString = 'rgb(255, 255, 255)'
    toolbarsHeaderBackgroundColorString = 'rgb(170, 170, 170)'

    #// Group 23
    #// outline Drawing
    context.beginPath()
    context.moveTo 5.5, 3.5
    context.lineTo 5.5, 96.5
    context.lineTo 30.1, 96.5
    context.lineTo 30.1, 80.36
    context.lineTo 49.42, 80.36
    context.lineTo 49.42, 96.5
    context.lineTo 73.17, 96.5
    context.lineTo 73.17, 66.8
    context.lineTo 94.5, 66.8
    context.lineTo 94.5, 3.5
    context.lineTo 5.5, 3.5
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()

    #// the four toolbars
    #// toolbar 1
    #// Rectangle 2 Drawing
    context.beginPath()
    context.rect 9.5, 6.5, 16, 9
    context.fillStyle = toolbarsHeaderBackgroundColorString
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 11.96, 11.16
    context.lineTo 23.04, 11.16
    context.strokeStyle = toolbarsHeaderLineColorString
    context.lineWidth = 1
    context.stroke()
    #// Group
    #// Rectangle 3 Drawing
    context.beginPath()
    context.rect 9.5, 15.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 14.42, 20.12
    context.lineTo 20.58, 20.12
    context.lineTo 20.58, 25.88
    context.lineTo 14.42, 25.88
    context.lineTo 14.42, 20.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 2
    #// Rectangle 4 Drawing
    context.beginPath()
    context.rect 9.5, 30.5, 16, 16
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 14.42, 35.42
    context.lineTo 20.58, 35.42
    context.lineTo 20.58, 41.58
    context.lineTo 14.42, 41.58
    context.lineTo 14.42, 35.42
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 3
    #// Rectangle 5 Drawing
    context.beginPath()
    context.rect 9.5, 46.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 14.42, 51.12
    context.lineTo 20.58, 51.12
    context.lineTo 20.58, 56.88
    context.lineTo 14.42, 56.88
    context.lineTo 14.42, 51.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 4
    #// Rectangle 6 Drawing
    context.beginPath()
    context.rect 9.5, 61.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 14.42, 66.12
    context.lineTo 20.58, 66.12
    context.lineTo 20.58, 71.88
    context.lineTo 14.42, 71.88
    context.lineTo 14.42, 66.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 5
    #// Rectangle 7 Drawing
    context.beginPath()
    context.rect 9.5, 76.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 14.42, 81.12
    context.lineTo 20.58, 81.12
    context.lineTo 20.58, 86.88
    context.lineTo 14.42, 86.88
    context.lineTo 14.42, 81.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// toolbar 2
    #// Group 8
    #// Rectangle Drawing
    context.beginPath()
    context.rect 31.5, 15.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 36.42, 20.12
    context.lineTo 42.58, 20.12
    context.lineTo 42.58, 25.88
    context.lineTo 36.42, 25.88
    context.lineTo 36.42, 20.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Rectangle 8 Drawing
    context.beginPath()
    context.rect 31.5, 6.5, 16, 9
    context.fillStyle = toolbarsHeaderBackgroundColorString
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 33.96, 11.17
    context.lineTo 45.04, 11.17
    context.strokeStyle = toolbarsHeaderLineColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 9
    #// Rectangle 9 Drawing
    context.beginPath()
    context.rect 31.5, 30.5, 16, 16
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 9 Drawing
    context.beginPath()
    context.moveTo 36.42, 35.42
    context.lineTo 42.58, 35.42
    context.lineTo 42.58, 41.58
    context.lineTo 36.42, 41.58
    context.lineTo 36.42, 35.42
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 10
    #// Rectangle 10 Drawing
    context.beginPath()
    context.rect 31.5, 46.5, 16, 14
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 36.42, 50.81
    context.lineTo 42.58, 50.81
    context.lineTo 42.58, 56.19
    context.lineTo 36.42, 56.19
    context.lineTo 36.42, 50.81
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 11
    #// Rectangle 11 Drawing
    context.beginPath()
    context.rect 31.5, 60.5, 16, 16
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 11 Drawing
    context.beginPath()
    context.moveTo 36.42, 65.42
    context.lineTo 42.58, 65.42
    context.lineTo 42.58, 71.58
    context.lineTo 36.42, 71.58
    context.lineTo 36.42, 65.42
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// toolbar 3
    #// Group 13
    #// Rectangle 12 Drawing
    context.beginPath()
    context.rect 53.5, 15.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 12 Drawing
    context.beginPath()
    context.moveTo 58.42, 20.12
    context.lineTo 64.58, 20.12
    context.lineTo 64.58, 25.88
    context.lineTo 58.42, 25.88
    context.lineTo 58.42, 20.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Rectangle 13 Drawing
    context.beginPath()
    context.rect 53.5, 6.5, 16, 9
    context.fillStyle = toolbarsHeaderBackgroundColorString
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 13 Drawing
    context.beginPath()
    context.moveTo 55.96, 11.16
    context.lineTo 67.04, 11.16
    context.strokeStyle = toolbarsHeaderLineColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 14
    #// Rectangle 14 Drawing
    context.beginPath()
    context.rect 53.5, 30.5, 16, 16
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 14 Drawing
    context.beginPath()
    context.moveTo 58.42, 35.42
    context.lineTo 64.58, 35.42
    context.lineTo 64.58, 41.58
    context.lineTo 58.42, 41.58
    context.lineTo 58.42, 35.42
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 15
    #// Rectangle 15 Drawing
    context.beginPath()
    context.rect 53.5, 46.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 15 Drawing
    context.beginPath()
    context.moveTo 58.42, 51.12
    context.lineTo 64.58, 51.12
    context.lineTo 64.58, 56.88
    context.lineTo 58.42, 56.88
    context.lineTo 58.42, 51.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 16
    #// Rectangle 16 Drawing
    context.beginPath()
    context.rect 53.5, 61.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 16 Drawing
    context.beginPath()
    context.moveTo 58.42, 66.12
    context.lineTo 64.58, 66.12
    context.lineTo 64.58, 71.88
    context.lineTo 58.42, 71.88
    context.lineTo 58.42, 66.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 17
    #// Rectangle 17 Drawing
    context.beginPath()
    context.rect 53.5, 76.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 17 Drawing
    context.beginPath()
    context.moveTo 58.42, 81.12
    context.lineTo 64.58, 81.12
    context.lineTo 64.58, 86.88
    context.lineTo 58.42, 86.88
    context.lineTo 58.42, 81.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// toolbar 4
    #// Group 19
    #// Rectangle 18 Drawing
    context.beginPath()
    context.rect 74.5, 16.5, 16, 14
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 18 Drawing
    context.beginPath()
    context.moveTo 79.42, 20.81
    context.lineTo 85.58, 20.81
    context.lineTo 85.58, 26.19
    context.lineTo 79.42, 26.19
    context.lineTo 79.42, 20.81
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Rectangle 19 Drawing
    context.beginPath()
    context.rect 74.5, 6.5, 16, 10
    context.fillStyle = toolbarsHeaderBackgroundColorString
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 19 Drawing
    context.beginPath()
    context.moveTo 76.96, 11.18
    context.lineTo 88.04, 11.18
    context.strokeStyle = toolbarsHeaderLineColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 20
    #// Rectangle 20 Drawing
    context.beginPath()
    context.rect 74.5, 30.5, 16, 16
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 20 Drawing
    context.beginPath()
    context.moveTo 79.42, 35.42
    context.lineTo 85.58, 35.42
    context.lineTo 85.58, 41.58
    context.lineTo 79.42, 41.58
    context.lineTo 79.42, 35.42
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 21
    #// Rectangle 21 Drawing
    context.beginPath()
    context.rect 74.5, 46.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 21 Drawing
    context.beginPath()
    context.moveTo 79.42, 51.12
    context.lineTo 85.58, 51.12
    context.lineTo 85.58, 56.88
    context.lineTo 79.42, 56.88
    context.lineTo 79.42, 51.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
