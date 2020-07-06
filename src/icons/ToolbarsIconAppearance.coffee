class ToolbarsIconAppearance extends IconAppearance

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

    #// Group 23
    #// Bezier 2 Drawing
    context.beginPath()
    context.moveTo 41.5, 6.5
    context.lineTo 58.5, 6.5
    context.lineTo 58.5, 28.5
    context.bezierCurveTo 58.5, 28.5, 62.75, 24, 66.5, 23.5
    context.bezierCurveTo 70.25, 23, 75.5, 29.5, 75.5, 26.5
    context.bezierCurveTo 75.5, 23.5, 78.25, 22, 76.5, 19.5
    context.bezierCurveTo 74.75, 17, 70.25, 18, 68.5, 16.5
    context.bezierCurveTo 66.75, 15, 67.75, 14.25, 69.5, 13.5
    context.bezierCurveTo 71.25, 12.75, 72, 10.25, 75.5, 13.5
    context.bezierCurveTo 79, 16.75, 81.5, 21.5, 83.5, 26.5
    context.bezierCurveTo 85.5, 31.5, 83.5, 33.5, 83.5, 33.5
    context.lineTo 60.5, 40.5
    context.lineTo 76.5, 84.5
    context.lineTo 58.5, 82.5
    context.lineTo 58.5, 92.5
    context.lineTo 39.5, 92.5
    context.lineTo 39.5, 82.5
    context.lineTo 22.5, 84.5
    context.lineTo 37.5, 40.5
    context.lineTo 30.5, 40.5
    context.lineTo 15.5, 33.5
    context.bezierCurveTo 15.5, 33.5, 15.75, 24.5, 18.5, 19.5
    context.bezierCurveTo 21.25, 14.5, 23.5, 14.25, 26.5, 13.5
    context.bezierCurveTo 29.5, 12.75, 31.5, 15, 30.5, 16.5
    context.bezierCurveTo 29.5, 18, 24.5, 17, 22.5, 19.5
    context.bezierCurveTo 20.5, 22, 20.5, 25.5, 22.5, 26.5
    context.bezierCurveTo 24.5, 27.5, 26, 23, 30.5, 23.5
    context.bezierCurveTo 35, 24, 41.5, 28.5, 41.5, 28.5
    context.lineTo 41.5, 6.5
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    context.strokeStyle = outlineColorString
    context.lineWidth = 7
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 38.85, 36.81
    context.lineTo 22.35, 84.12
    context.bezierCurveTo 22.35, 84.12, 28.76, 82.81, 38.85, 82.22
    context.lineTo 38.85, 36.81
    context.closePath()
    context.moveTo 60.15, 36.81
    context.lineTo 60.15, 82.22
    context.bezierCurveTo 70.24, 82.81, 76.65, 84.12, 76.65, 84.12
    context.lineTo 60.15, 36.81
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// toolbar 3
    #// Group 13
    #// Rectangle 12 Drawing
    context.beginPath()
    context.rect 41.5, 16.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 12 Drawing
    context.beginPath()
    context.moveTo 46.42, 21.12
    context.lineTo 52.58, 21.12
    context.lineTo 52.58, 26.88
    context.lineTo 46.42, 26.88
    context.lineTo 46.42, 21.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Rectangle 13 Drawing
    context.beginPath()
    context.rect 41.5, 7.5, 16, 9
    context.fillStyle = toolbarsHeaderBackgroundColorString
    context.fill()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 13 Drawing
    context.beginPath()
    context.moveTo 43.96, 12.16
    context.lineTo 55.04, 12.16
    context.strokeStyle = toolbarsHeaderLineColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 14
    #// Rectangle 14 Drawing
    context.beginPath()
    context.rect 41.5, 31.5, 16, 16
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 14 Drawing
    context.beginPath()
    context.moveTo 46.42, 36.42
    context.lineTo 52.58, 36.42
    context.lineTo 52.58, 42.58
    context.lineTo 46.42, 42.58
    context.lineTo 46.42, 36.42
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 15
    #// Rectangle 15 Drawing
    context.beginPath()
    context.rect 41.5, 47.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 15 Drawing
    context.beginPath()
    context.moveTo 46.42, 52.12
    context.lineTo 52.58, 52.12
    context.lineTo 52.58, 57.88
    context.lineTo 46.42, 57.88
    context.lineTo 46.42, 52.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 16
    #// Rectangle 16 Drawing
    context.beginPath()
    context.rect 41.5, 62.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 16 Drawing
    context.beginPath()
    context.moveTo 46.42, 67.12
    context.lineTo 52.58, 67.12
    context.lineTo 52.58, 72.88
    context.lineTo 46.42, 72.88
    context.lineTo 46.42, 67.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Group 17
    #// Rectangle 17 Drawing
    context.beginPath()
    context.rect 41.5, 77.5, 16, 15
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 17 Drawing
    context.beginPath()
    context.moveTo 46.42, 82.12
    context.lineTo 52.58, 82.12
    context.lineTo 52.58, 87.88
    context.lineTo 46.42, 87.88
    context.lineTo 46.42, 82.12
    context.closePath()
    context.strokeStyle = iconColorString
    context.lineWidth = 1
    context.stroke()
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 37.99, 38.14
    context.bezierCurveTo 36.88, 38.4, 35.77, 38.4, 34.83, 38.4
    context.bezierCurveTo 30.29, 38.4, 27.21, 37.19, 24.39, 36.06
    context.bezierCurveTo 21.91, 35.11, 15.67, 33.9, 15.58, 33.29
    context.bezierCurveTo 14.73, 29.22, 19.09, 16.93, 24.13, 13.56
    context.bezierCurveTo 25.93, 12.35, 27.81, 12.35, 29.35, 13.47
    context.bezierCurveTo 30.55, 14.34, 30.89, 15.63, 30.38, 16.85
    context.bezierCurveTo 29.78, 18.32, 23.98, 19.44, 22.1, 19.7
    context.bezierCurveTo 22.36, 21.61, 22.5, 24.5, 23.33, 26.9
    context.bezierCurveTo 25.38, 25.6, 29.78, 22.91, 32, 23.51
    context.bezierCurveTo 33.46, 23.94, 37.85, 25.24, 38.45, 29.57
    context.strokeStyle = iconColorString
    context.lineWidth = 3
    context.miterLimit = 4
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 60.96, 38.14
    context.bezierCurveTo 62.07, 38.4, 63.18, 38.4, 64.12, 38.4
    context.bezierCurveTo 68.66, 38.4, 71.73, 37.19, 74.56, 36.06
    context.bezierCurveTo 77.04, 35.11, 83.28, 33.9, 83.37, 33.29
    context.bezierCurveTo 84.22, 29.22, 79.86, 16.93, 74.81, 13.56
    context.bezierCurveTo 73.02, 12.35, 71.14, 12.35, 69.6, 13.47
    context.bezierCurveTo 68.4, 14.34, 68.06, 15.63, 68.57, 16.85
    context.bezierCurveTo 69.17, 18.32, 74.96, 19.44, 76.85, 19.7
    context.bezierCurveTo 76.59, 21.61, 76.45, 24.5, 75.62, 26.9
    context.bezierCurveTo 73.56, 25.6, 69.17, 22.91, 66.95, 23.51
    context.bezierCurveTo 65.49, 23.94, 61.1, 25.24, 60.5, 29.57
    context.strokeStyle = iconColorString
    context.lineWidth = 3
    context.miterLimit = 4
    context.lineCap = 'round'
    context.stroke()

