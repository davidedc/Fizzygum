class TrashcanIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    # Color Declarations
    blackColorString = 'rgba(0, 0, 0, 1)'
    outlineColorString = 'rgba(184, 184, 184, 1)'
    # Group
    # outline Drawing
    context.beginPath()
    context.moveTo 74.98, 96.7
    context.bezierCurveTo 78.77, 96.7, 83.78, 92.8, 83.9, 88.99
    context.lineTo 86.08, 24.08
    context.lineTo 94.7, 24.08
    context.lineTo 94.7, 15.42
    context.lineTo 70.45, 15.42
    context.lineTo 70.45, 10.46
    context.bezierCurveTo 70.45, 6.53, 65.21, 3.3, 61.3, 3.3
    context.lineTo 39.7, 3.3
    context.bezierCurveTo 35.79, 3.3, 30.55, 6.53, 30.55, 10.46
    context.lineTo 30.55, 15.42
    context.lineTo 6.3, 15.42
    context.lineTo 6.3, 24.08
    context.lineTo 14.92, 24.08
    context.lineTo 17.1, 88.99
    context.bezierCurveTo 17.22, 92.8, 20.21, 96.7, 24, 96.7
    context.lineTo 74.98, 96.7
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    # main shape Drawing
    context.beginPath()
    context.moveTo 74.98, 94.68
    context.bezierCurveTo 78.77, 94.68, 81.76, 91.79, 81.87, 87.98
    context.lineTo 84.06, 22.06
    context.lineTo 92.68, 22.06
    context.lineTo 92.68, 17.44
    context.lineTo 68.43, 17.44
    context.lineTo 68.43, 12.48
    context.bezierCurveTo 68.43, 8.55, 65.21, 5.32, 61.3, 5.32
    context.lineTo 39.7, 5.32
    context.bezierCurveTo 35.79, 5.32, 32.57, 8.55, 32.57, 12.48
    context.lineTo 32.57, 17.44
    context.lineTo 8.32, 17.44
    context.lineTo 8.32, 22.06
    context.lineTo 16.94, 22.06
    context.lineTo 19.13, 87.98
    context.bezierCurveTo 19.24, 91.79, 22.23, 94.68, 26.02, 94.68
    context.lineTo 74.98, 94.68
    context.closePath()
    context.moveTo 37.17, 12.48
    context.bezierCurveTo 37.17, 11.09, 38.32, 9.94, 39.7, 9.94
    context.lineTo 61.3, 9.94
    context.bezierCurveTo 62.68, 9.94, 63.83, 11.09, 63.83, 12.48
    context.lineTo 63.83, 17.44
    context.lineTo 37.17, 17.44
    context.lineTo 37.17, 12.48
    context.closePath()
    context.moveTo 23.72, 87.87
    context.lineTo 21.54, 22.06
    context.lineTo 79.35, 22.06
    context.lineTo 77.16, 87.87
    context.bezierCurveTo 77.16, 89.14, 76.13, 90.06, 74.86, 90.06
    context.lineTo 26.02, 90.06
    context.bezierCurveTo 24.87, 90.06, 23.84, 89.14, 23.72, 87.87
    context.closePath()
    context.fillStyle = blackColorString
    context.fill()
    # corrugation 1 Drawing
    context.beginPath()
    context.rect 48, 38, 5, 35.9
    context.fillStyle = blackColorString
    context.fill()
    # corrugation 2 Drawing
    context.beginPath()
    context.rect 34, 38, 4, 35.9
    context.fillStyle = blackColorString
    context.fill()
    # corrugation 3 Drawing
    context.beginPath()
    context.rect 63, 38, 4, 35.9
    context.fillStyle = blackColorString
    context.fill()

