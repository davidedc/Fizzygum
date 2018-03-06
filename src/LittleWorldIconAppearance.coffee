class LittleWorldIconAppearance extends IconAppearance

  constructor: (@morph) ->
    super
    @preferredSize = new Point 100, 100
    @specificationSize = new Point 100, 100

  paintFunction: (context) ->
    #// Color Declarations
    black = 'rgba(0, 0, 0, 1)'
    #// Group 3
    #// Bezier 4 Drawing
    context.beginPath()
    context.moveTo 62, 10
    context.lineTo 65, 15
    context.lineTo 75, 19
    context.lineTo 73, 22
    context.lineTo 78, 30
    context.lineTo 78, 44
    context.lineTo 81, 55
    context.lineTo 89, 52
    context.lineTo 90, 48
    context.lineTo 93, 52
    context.strokeStyle = black
    context.lineWidth = 3.5
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// Bezier Drawing
    context.beginPath()
    context.moveTo 43, 10
    context.lineTo 48.2, 15.8
    context.lineTo 50.5, 18.3
    context.lineTo 50.2, 20.7
    context.lineTo 46.6, 21.8
    context.lineTo 46.4, 21.8
    context.lineTo 39.3, 24.6
    context.lineTo 34.1, 34.3
    context.lineTo 27.8, 33
    context.lineTo 24.7, 36.1
    context.lineTo 26.6, 38.5
    context.lineTo 31.5, 43.3
    context.lineTo 33.3, 43
    context.lineTo 41.3, 42.7
    context.lineTo 44.7, 43.9
    context.lineTo 48, 47
    context.lineTo 55.1, 47
    context.lineTo 57.1, 49.1
    context.lineTo 61.1, 52.1
    context.lineTo 65, 54.4
    context.lineTo 66.7, 58.6
    context.lineTo 61.4, 68.3
    context.lineTo 57.7, 71.6
    context.lineTo 54.2, 77.8
    context.lineTo 51, 79.5
    context.lineTo 47.9, 81.3
    context.lineTo 48, 85.8
    context.lineTo 45, 88.8
    context.lineTo 42.8, 75.5
    context.lineTo 42.5, 69.1
    context.lineTo 38.9, 65.7
    context.lineTo 35.9, 62
    context.lineTo 34.9, 56.1
    context.lineTo 34.6, 52.8
    context.lineTo 31.8, 50
    context.lineTo 28.4, 48.8
    context.lineTo 23.5, 45
    context.lineTo 20.4, 43.7
    context.lineTo 13.9, 36.6
    context.lineTo 14, 26
    context.strokeStyle = black
    context.lineWidth = 3.5
    context.miterLimit = 4
    context.lineCap = 'round'
    context.lineJoin = 'round'
    context.stroke()
    #// @oval Drawing
    @oval context, 6, 7, 87, 87
    context.strokeStyle = black
    context.lineWidth = 3.5
    context.stroke()
