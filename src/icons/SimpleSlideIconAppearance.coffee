class SimpleSlideIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString
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
    #// column 1 line 1 Drawing
    context.beginPath()
    context.moveTo 16.86, 33.6
    context.lineTo 44.54, 33.6
    context.strokeStyle = black
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// column 1 line 2 Drawing
    context.beginPath()
    context.moveTo 16.86, 45.34
    context.lineTo 44.54, 45.34
    context.strokeStyle = black
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// column 1 line 3 Drawing
    context.beginPath()
    context.moveTo 16.86, 56.08
    context.lineTo 44.54, 56.08
    context.strokeStyle = black
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// column 1 line 4 Drawing
    context.beginPath()
    context.moveTo 16.86, 67.36
    context.lineTo 44.54, 67.36
    context.strokeStyle = black
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// column 2 line 1 Drawing
    context.beginPath()
    context.moveTo 53.77, 56.08
    context.lineTo 81.45, 56.08
    context.strokeStyle = black
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// column 2 line 2 Drawing
    context.beginPath()
    context.moveTo 53.77, 67.36
    context.lineTo 81.45, 67.36
    context.strokeStyle = black
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// graph bar 1 Drawing
    context.beginPath()
    context.rect 54, 36, 8, 9.5
    context.strokeStyle = black
    context.lineWidth = 1.5
    context.lineJoin = 'round'
    context.stroke()
    #// graph bar 2 Drawing
    context.beginPath()
    context.rect 65, 33, 7, 12.5
    context.strokeStyle = black
    context.lineWidth = 1.5
    context.lineJoin = 'round'
    context.stroke()
    #// graph bar 3 Drawing
    context.beginPath()
    context.rect 75, 28, 8, 17.5
    context.strokeStyle = black
    context.lineWidth = 1.5
    context.lineJoin = 'round'
    context.stroke()
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
    context.fillStyle = black
    context.fill()

