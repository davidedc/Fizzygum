class TypewriterIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    if @ownColorInsteadOfWidgetColor? then iconColorString = @ownColorInsteadOfWidgetColor.toString() else iconColorString = @morph.color.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
    #// Group
    #// outline Drawing
    context.beginPath()
    context.moveTo 90.79, 34.25
    context.lineTo 81.16, 34.25
    context.lineTo 81.16, 5
    context.lineTo 20.84, 5
    context.lineTo 20.84, 34.25
    context.lineTo 11.21, 34.25
    context.lineTo 11.21, 38.03
    context.lineTo 8, 38.03
    context.lineTo 8, 55.4
    context.lineTo 11.21, 55.4
    context.lineTo 11.21, 59.33
    context.lineTo 8.02, 81.89
    context.lineTo 8, 95
    context.lineTo 94, 95
    context.lineTo 94, 82.14
    context.lineTo 90.79, 59.33
    context.lineTo 90.79, 55.4
    context.lineTo 94, 55.4
    context.lineTo 94, 38.03
    context.lineTo 90.79, 38.03
    context.lineTo 90.79, 34.25
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// Document lines
    #// Rectangle Drawing
    context.beginPath()
    context.rect 29.5, 16.5, 30, 2
    context.fillStyle = iconColorString
    context.fill()
    #// Rectangle 2 Drawing
    context.beginPath()
    context.rect 29.5, 22.5, 43, 2
    context.fillStyle = iconColorString
    context.fill()
    #// Rectangle 3 Drawing
    context.beginPath()
    context.rect 29.5, 27.5, 9.5, 2
    context.fillStyle = iconColorString
    context.fill()
    #// Rectangle 4 Drawing
    context.beginPath()
    context.rect 29.5, 33.5, 21.5, 2
    context.fillStyle = iconColorString
    context.fill()
    #// Rectangle 5 Drawing
    context.beginPath()
    context.rect 42.5, 27.5, 30, 2
    context.fillStyle = iconColorString
    context.fill()
    #// Rectangle 6 Drawing
    context.beginPath()
    context.rect 63, 16.5, 9.5, 2
    context.fillStyle = iconColorString
    context.fill()
    #// typewriter body Drawing
    context.beginPath()
    context.moveTo 88.69, 36.17
    context.lineTo 79.57, 36.17
    context.lineTo 79.57, 7.75
    context.lineTo 22.38, 7.75
    context.lineTo 22.38, 36.17
    context.lineTo 13.26, 36.17
    context.lineTo 13.26, 39.72
    context.lineTo 10.21, 39.72
    context.lineTo 10.21, 53.22
    context.lineTo 13.26, 53.22
    context.lineTo 13.26, 58.79
    context.lineTo 10.23, 79.99
    context.lineTo 10.21, 92.3
    context.lineTo 91.73, 92.3
    context.lineTo 91.73, 80.22
    context.lineTo 88.69, 58.79
    context.lineTo 88.69, 53.22
    context.lineTo 91.73, 53.22
    context.lineTo 91.73, 39.72
    context.lineTo 88.69, 39.72
    context.lineTo 88.69, 36.17
    context.closePath()
    context.moveTo 77.13, 10.59
    context.lineTo 77.13, 43.28
    context.lineTo 62.39, 43.28
    context.lineTo 62.05, 44.06
    context.bezierCurveTo 62.03, 44.12, 59.25, 50.38, 50.97, 50.38
    context.bezierCurveTo 42.77, 50.38, 40.01, 44.31, 39.9, 44.06
    context.lineTo 39.56, 43.28
    context.lineTo 24.81, 43.28
    context.lineTo 24.81, 10.59
    context.lineTo 77.13, 10.59
    context.closePath()
    context.moveTo 12.65, 50.38
    context.lineTo 12.65, 42.56
    context.lineTo 13.26, 42.56
    context.lineTo 13.26, 50.38
    context.lineTo 12.65, 50.38
    context.closePath()
    context.moveTo 89.3, 80.34
    context.lineTo 89.3, 89.46
    context.lineTo 12.65, 89.46
    context.lineTo 12.65, 80.34
    context.lineTo 15.5, 60.33
    context.lineTo 86.46, 60.33
    context.lineTo 89.3, 80.34
    context.closePath()
    context.moveTo 86.26, 57.49
    context.lineTo 15.69, 57.49
    context.lineTo 15.69, 53.22
    context.lineTo 15.69, 39.72
    context.lineTo 15.69, 39.01
    context.lineTo 22.38, 39.01
    context.lineTo 22.38, 43.28
    context.lineTo 20.56, 43.28
    context.lineTo 20.56, 46.12
    context.lineTo 38.12, 46.12
    context.bezierCurveTo 39.26, 48.12, 42.96, 53.22, 50.97, 53.22
    context.bezierCurveTo 58.99, 53.22, 62.68, 48.12, 63.83, 46.12
    context.lineTo 81.39, 46.12
    context.lineTo 81.39, 43.28
    context.lineTo 79.57, 43.28
    context.lineTo 79.57, 39.01
    context.lineTo 86.26, 39.01
    context.lineTo 86.26, 39.72
    context.lineTo 86.26, 53.22
    context.lineTo 86.26, 57.49
    context.closePath()
    context.moveTo 89.3, 42.56
    context.lineTo 89.3, 50.38
    context.lineTo 88.69, 50.38
    context.lineTo 88.69, 42.56
    context.lineTo 89.3, 42.56
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
    #// keyboard
    #// key 1 Drawing
    @oval context, 20, 76, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// key 2 Drawing
    @oval context, 29, 76, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// key 3 Drawing
    @oval context, 20, 66, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// key 4 Drawing
    @oval context, 29, 66, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// key 5 Drawing
    @oval context, 38, 66, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// key 6 Drawing
    @oval context, 47, 66, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// key 7 Drawing
    @oval context, 56, 66, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// key 8 Drawing
    @oval context, 65, 66, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// key 9 Drawing
    @oval context, 74, 66, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// key 10 Drawing
    @oval context, 65, 76, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// key 11 Drawing
    @oval context, 74, 76, 6.5, 6.5
    context.strokeStyle = iconColorString
    context.lineWidth = 2.5
    context.stroke()
    #// spacebar Drawing
    context.beginPath()
    context.moveTo 59.57, 75
    context.lineTo 41.03, 75
    context.bezierCurveTo 38.64, 75, 36.7, 77.02, 36.7, 79.5
    context.bezierCurveTo 36.7, 81.98, 38.64, 84, 41.03, 84
    context.lineTo 59.57, 84
    context.bezierCurveTo 61.96, 84, 63.9, 81.98, 63.9, 79.5
    context.bezierCurveTo 63.9, 77.02, 61.96, 75, 59.57, 75
    context.closePath()
    context.moveTo 59.57, 81.43
    context.lineTo 41.03, 81.43
    context.bezierCurveTo 40, 81.43, 39.17, 80.56, 39.17, 79.5
    context.bezierCurveTo 39.17, 78.44, 40, 77.57, 41.03, 77.57
    context.lineTo 59.57, 77.57
    context.bezierCurveTo 60.6, 77.57, 61.43, 78.44, 61.43, 79.5
    context.bezierCurveTo 61.43, 80.56, 60.6, 81.43, 59.57, 81.43
    context.closePath()
    context.fillStyle = iconColorString
    context.fill()
