class FizzygumLogoIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    whiteColorString = Color.WHITE.toString()
    outlineColorString = WorldMorph.preferencesAndSettings.outlineColorString

    #// bubble outline Drawing
    context.beginPath()
    context.moveTo 98, 49.68
    context.bezierCurveTo 98, 21.6, 77.18, 3, 51.5, 3
    context.bezierCurveTo 25.82, 3, 5, 23.9, 5, 49.68
    context.bezierCurveTo 5, 59.58, 10.93, 71.63, 13.31, 76.3
    context.bezierCurveTo 15.69, 80.98, 12.68, 88.84, 1, 95.37
    context.bezierCurveTo 1, 95.37, 46.24, 98.63, 60.89, 94.61
    context.bezierCurveTo 75.55, 90.59, 98, 77.77, 98, 49.68
    context.closePath()
    context.fillStyle = outlineColorString
    context.fill()
    #// red bubble Drawing
    context.beginPath()
    context.moveTo 95, 49.7
    context.bezierCurveTo 95, 23.41, 75.52, 6, 51.5, 6
    context.bezierCurveTo 27.48, 6, 8, 25.57, 8, 49.7
    context.bezierCurveTo 8, 58.97, 13.54, 70.25, 15.77, 74.62
    context.bezierCurveTo 18, 79, 18.92, 87.29, 8, 93.41
    context.bezierCurveTo 8, 93.41, 46.58, 95.53, 60.29, 91.77
    context.bezierCurveTo 74, 88, 95, 76, 95, 49.7
    context.closePath()
    context.fillStyle = Color.RED.toString()
    context.fill()
    #// twinkles and bubbles
    #// bubbles
    #// bubble 1 Drawing
    @oval context, 65, 29, 5, 5
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 2 Drawing
    @oval context, 60, 45, 9, 9
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 3 Drawing
    @oval context, 53, 35, 6, 6
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 4 Drawing
    @oval context, 40, 45, 8, 8
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 5 Drawing
    @oval context, 39, 30, 6, 6
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 7 Drawing
    @oval context, 28, 37, 4, 4
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 8 Drawing
    @oval context, 26, 52, 5, 5
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 9 Drawing
    @oval context, 32, 69, 4, 4
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 10 Drawing
    @oval context, 50, 74, 3, 3
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 12 Drawing
    @oval context, 72, 56, 4, 4
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 13 Drawing
    @oval context, 53, 58, 4, 4
    context.fillStyle = whiteColorString
    context.fill()
    #// bubble 20 Drawing
    @oval context, 62, 66, 6, 6
    context.fillStyle = whiteColorString
    context.fill()
    #// twinkles
    #// twinkle 1
    #// Bezier 3 Drawing
    context.beginPath()
    context.moveTo 52, 17.98
    context.lineTo 52, 19.98
    context.strokeStyle = whiteColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 48, 22
    context.lineTo 50, 22
    context.strokeStyle = whiteColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 5 Drawing
    context.beginPath()
    context.moveTo 54, 22
    context.lineTo 56, 22
    context.strokeStyle = whiteColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 6 Drawing
    context.beginPath()
    context.moveTo 52, 23.98
    context.lineTo 52, 25.98
    context.strokeStyle = whiteColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// twinkle
    #// Bezier 7 Drawing
    context.beginPath()
    context.moveTo 44, 60.48
    context.lineTo 44, 62.48
    context.strokeStyle = whiteColorString
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 8 Drawing
    context.beginPath()
    context.moveTo 40.5, 64
    context.lineTo 42.5, 64
    context.strokeStyle = whiteColorString
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 9 Drawing
    context.beginPath()
    context.moveTo 45.5, 64
    context.lineTo 47.5, 64
    context.strokeStyle = whiteColorString
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 10 Drawing
    context.beginPath()
    context.moveTo 44, 65.48
    context.lineTo 44, 67.48
    context.strokeStyle = whiteColorString
    context.lineWidth = 1.5
    context.lineCap = 'round'
    context.stroke()
    #// twinkle 2
    #// Bezier 11 Drawing
    context.beginPath()
    context.moveTo 77.5, 37.98
    context.lineTo 77.5, 39.98
    context.strokeStyle = whiteColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 12 Drawing
    context.beginPath()
    context.moveTo 73.5, 42
    context.lineTo 75.5, 42
    context.strokeStyle = whiteColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 13 Drawing
    context.beginPath()
    context.moveTo 79.5, 42
    context.lineTo 81.5, 42
    context.strokeStyle = whiteColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
    #// Bezier 14 Drawing
    context.beginPath()
    context.moveTo 77.5, 43.98
    context.lineTo 77.5, 45.98
    context.strokeStyle = whiteColorString
    context.lineWidth = 2
    context.lineCap = 'round'
    context.stroke()
